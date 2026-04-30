import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

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

  Timer? _hallPollTimer;
  String? _pollingEventId;
  String? _pollingHallId;

  PlayerBloc() : super(const PlayerState()) {
    on<ConnectToChannel>(_onConnect);
    on<DisconnectFromChannel>(_onDisconnect);
    on<ToggleMute>(_onToggleMute);
    on<SetVolume>(_onSetVolume);
    on<PlayerBackgroundEntered>(_onBackground);
    on<PlayerForegroundEntered>(_onForeground);
    on<PlayerHallEntered>(_onHallEntered);
    on<SelectLanguage>(_onSelectLanguage);
    on<_WebRtcStateChanged>(_onWebRtcStateChanged);
    on<_HallDetailUpdated>(_onHallDetailUpdated);
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
    _stopHallPolling();
    await _cleanup();
    emit(const PlayerState(status: PlayerStatus.disconnected));
  }

  Future<void> _onToggleMute(
    ToggleMute event,
    Emitter<PlayerState> emit,
  ) async {
    final newMuted = !state.isMuted;
    _logger.debug('Mute toggled', {'muted': newMuted});

    // setAllConsumers iterates _peerConsumerIds directly — broadcaster
    // consumers are included even when not in state.peers.
    await _webRtcService?.setAllConsumers(paused: newMuted);

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

  void _onHallEntered(
    PlayerHallEntered event,
    Emitter<PlayerState> emit,
  ) {
    // Avvia il polling activeChannels subito, prima che l'utente selezioni una lingua.
    // Senza questo, la grid è vuota e l'utente non può connettersi.
    _startHallPolling(event.eventId, event.hallId);
  }

  Future<void> _onSelectLanguage(
    SelectLanguage event,
    Emitter<PlayerState> emit,
  ) async {
    emit(state.copyWith(
      status: PlayerStatus.connecting,
      channelId: event.channelId,
      selectedLanguage: event.language,
      errorMessage: null,
    ));

    try {
      final serverUrl =
          event.serverUrl.isNotEmpty ? event.serverUrl : AppConstants.wsUrl;

      if (_webRtcService == null || !_webRtcService!.isConnectedAndReady) {
        await _audioService.initializeAudioEngine();
        final volume = SharedPrefsHelper.getVolume();
        await _audioService.setVolume(volume);
        final deviceId = await SharedPrefsHelper.getDeviceId();

        _webRtcService?.dispose();
        _webRtcService = WebRtcService(serverUrl: serverUrl);

        await _webRtcSub?.cancel();
        _webRtcSub = _webRtcService!.stateStream.listen((s) {
          if (!isClosed) add(_WebRtcStateChanged(s));
        });

        await _webRtcService!.connect(deviceId, 'Visitor');

        ForegroundServiceManager.init();
        await ForegroundServiceManager.startService(
          channelName: event.channelId,
          status: 'In ascolto',
        );
      }

      await _webRtcService!.joinChannel(event.channelId, event.channelId);

      await SharedPrefsHelper.addRecentChannel(
        channelId: event.channelId,
        channelName: event.channelId,
      );

      emit(state.copyWith(
        status: PlayerStatus.connected,
        channelId: event.channelId,
        selectedLanguage: event.language,
      ));

      // Avvia polling hall detail per aggiornare activeChannels ogni 5s.
      // channelId format: "eventId:hallId:language"
      final parts = event.channelId.split(':');
      if (parts.length >= 2) {
        _startHallPolling(parts[0], parts[1]);
      }
    } catch (e, stack) {
      _logger.error('SelectLanguage failed', e, stack);
      emit(state.copyWith(
        status: PlayerStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onHallDetailUpdated(
    _HallDetailUpdated event,
    Emitter<PlayerState> emit,
  ) {
    emit(state.copyWith(
      activeChannels: event.activeChannels,
      sourceLanguage: event.sourceLanguage,
      clearSourceLanguage: event.sourceLanguage == null,
    ));
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

  // ── Hall detail polling ────────────────────────────────────────

  void _startHallPolling(String eventId, String hallId) {
    _stopHallPolling();
    _pollingEventId = eventId;
    _pollingHallId = hallId;
    // Prima fetch immediata, poi ogni 5s.
    _fetchHallDetail();
    _hallPollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchHallDetail();
    });
    _logger.debug('Hall polling started', {'eventId': eventId, 'hallId': hallId});
  }

  void _stopHallPolling() {
    _hallPollTimer?.cancel();
    _hallPollTimer = null;
    _pollingEventId = null;
    _pollingHallId = null;
  }

  Future<void> _fetchHallDetail() async {
    final eventId = _pollingEventId;
    final hallId = _pollingHallId;
    if (eventId == null || hallId == null || isClosed) return;
    try {
      final uri = Uri.parse(
          '${AppConstants.apiBaseUrl}/events/$eventId/halls/$hallId');
      final resp = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode != 200) return;
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final activeChannels = (json['activeChannels'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final sourceLanguage = json['sourceLanguage'] as String?;
      if (!isClosed) {
        add(_HallDetailUpdated(
          activeChannels: activeChannels,
          sourceLanguage: sourceLanguage,
        ));
      }
    } catch (_) {
      // ignora errori di polling silenziosamente
    }
  }

  @override
  Future<void> close() async {
    _stopHallPolling();
    await _cleanup();
    return super.close();
  }
}

// ─────────────────────────────────────────────
// Internal events
// ─────────────────────────────────────────────

class _WebRtcStateChanged extends PlayerEvent {
  final WebRtcState webRtcState;

  const _WebRtcStateChanged(this.webRtcState);

  @override
  List<Object?> get props => [webRtcState];
}

class _HallDetailUpdated extends PlayerEvent {
  final List<String> activeChannels;
  final String? sourceLanguage;

  const _HallDetailUpdated({
    required this.activeChannels,
    this.sourceLanguage,
  });

  @override
  List<Object?> get props => [activeChannels, sourceLanguage];
}
