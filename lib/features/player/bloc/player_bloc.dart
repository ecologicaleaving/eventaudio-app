import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/services/foreground_service_manager.dart';
import '../../../core/services/webrtc_service.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/shared_prefs_helper.dart';
import 'player_event.dart';
import 'player_state.dart';

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final _logger = Logger('PlayerBloc');

  WebRtcService? _webRtcService;
  final AudioService _audioService = AudioService();
  StreamSubscription<WebRtcState>? _webRtcSub;

  PlayerBloc() : super(const PlayerState()) {
    on<ConnectToChannel>(_onConnect);
    on<DisconnectFromChannel>(_onDisconnect);
    on<ToggleMute>(_onToggleMute);
    on<SetVolume>(_onSetVolume);
    on<PlayerBackgroundEntered>(_onBackground);
    on<PlayerForegroundEntered>(_onForeground);
    on<_WebRtcStateChanged>(_onWebRtcStateChanged);
  }

  Future<void> _onConnect(
    ConnectToChannel event,
    Emitter<PlayerState> emit,
  ) async {
    emit(state.copyWith(
      status: PlayerStatus.connecting,
      channelId: event.channelId,
      errorMessage: null,
    ));

    try {
      // Save to recent channels.
      await SharedPrefsHelper.addRecentChannel(
        channelId: event.channelId,
        channelName: event.channelId,
      );

      // Initialize audio engine.
      await _audioService.initializeAudioEngine();

      // Apply persisted volume.
      final savedVolume = SharedPrefsHelper.getVolume();
      await _audioService.setVolume(savedVolume);

      // Get or generate device ID (anonymous visitor).
      final deviceId = await SharedPrefsHelper.getDeviceId();

      // Create and connect WebRTC service.
      final serverUrl = event.serverUrl.isNotEmpty
          ? event.serverUrl
          : AppConstants.wsUrl;

      _webRtcService?.dispose();
      _webRtcService = WebRtcService(serverUrl: serverUrl);

      // Subscribe to WebRTC state changes.
      await _webRtcSub?.cancel();
      _webRtcSub = _webRtcService!.stateStream.listen((webRtcState) {
        if (!isClosed) add(_WebRtcStateChanged(webRtcState));
      });

      // Connect device to signaling server.
      await _webRtcService!.connect(deviceId, 'Visitor');

      // Join the requested channel (recv transport only).
      await _webRtcService!.joinChannel(
        event.channelId,
        event.channelId,
      );

      // Start foreground service so audio keeps playing with screen off.
      ForegroundServiceManager.init();
      await ForegroundServiceManager.startService(
        channelName: event.channelId,
        status: 'In ascolto',
      );

      emit(state.copyWith(
        status: PlayerStatus.connected,
        channelId: event.channelId,
        volume: savedVolume,
      ));

      _logger.info('Connected and joined channel ${event.channelId}');
    } catch (e, stack) {
      _logger.error('Connection failed', e, stack);
      await _cleanup();
      emit(state.copyWith(
        status: PlayerStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDisconnect(
    DisconnectFromChannel event,
    Emitter<PlayerState> emit,
  ) async {
    _logger.info('Disconnecting from channel');
    await _cleanup();
    emit(const PlayerState(status: PlayerStatus.disconnected));
  }

  Future<void> _onToggleMute(
    ToggleMute event,
    Emitter<PlayerState> emit,
  ) async {
    final newMuted = !state.isMuted;
    _logger.debug('Mute toggled', {'muted': newMuted});

    if (_webRtcService != null && state.channelId != null) {
      // Pause/resume all incoming peer consumers.
      for (final peer in _webRtcService!.state.peers) {
        await _webRtcService!.setAudioFromPeer(
          peer.deviceId,
          paused: newMuted,
        );
      }
    }

    emit(state.copyWith(isMuted: newMuted));
  }

  Future<void> _onSetVolume(
    SetVolume event,
    Emitter<PlayerState> emit,
  ) async {
    final clamped = event.volume.clamp(0.0, 1.0);
    await SharedPrefsHelper.setVolume(clamped);
    await _audioService.setVolume(clamped);
    emit(state.copyWith(volume: clamped));
  }

  Future<void> _onBackground(
    PlayerBackgroundEntered event,
    Emitter<PlayerState> emit,
  ) async {
    _logger.debug('App backgrounded — foreground service keeps audio alive');
    // ForegroundServiceManager already started on connect; nothing extra needed.
    // The service keeps the process alive on Android; iOS uses AVAudioSession.
  }

  Future<void> _onForeground(
    PlayerForegroundEntered event,
    Emitter<PlayerState> emit,
  ) async {
    _logger.debug('App foregrounded');
  }

  void _onWebRtcStateChanged(
    _WebRtcStateChanged event,
    Emitter<PlayerState> emit,
  ) {
    final webRtcState = event.webRtcState;

    // Map WebRTC connection status to player status.
    switch (webRtcState.status) {
      case WebRtcConnectionStatus.reconnecting:
        emit(state.copyWith(status: PlayerStatus.connecting));
      case WebRtcConnectionStatus.connected:
        if (state.status != PlayerStatus.connected) {
          emit(state.copyWith(status: PlayerStatus.connected));
        }
      case WebRtcConnectionStatus.disconnected:
        emit(state.copyWith(
          status: PlayerStatus.error,
          errorMessage: webRtcState.errorMessage ?? 'Connessione persa',
        ));
      default:
        break;
    }

    // Update notification with active peers.
    if (webRtcState.peers.isNotEmpty && state.channelId != null) {
      ForegroundServiceManager.updateNotification(
        channelName: state.channelId,
        status: '${webRtcState.peers.length} speaker attivi',
      );
    }
  }

  Future<void> _cleanup() async {
    await _webRtcSub?.cancel();
    _webRtcSub = null;
    await _webRtcService?.disconnect();
    _webRtcService?.dispose();
    _webRtcService = null;
    await _audioService.dispose();
    await ForegroundServiceManager.stopService();
  }

  @override
  Future<void> close() async {
    await _cleanup();
    return super.close();
  }
}

// ─────────────────────────────────────────────
// Internal event — bridges WebRTC stream into Bloc
// ─────────────────────────────────────────────

class _WebRtcStateChanged extends PlayerEvent {
  final WebRtcState webRtcState;

  const _WebRtcStateChanged(this.webRtcState);

  @override
  List<Object?> get props => [webRtcState];
}
