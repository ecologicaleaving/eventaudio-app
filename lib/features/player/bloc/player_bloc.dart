import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/shared_prefs_helper.dart';
import 'player_event.dart';
import 'player_state.dart';

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final _logger = Logger('PlayerBloc');

  PlayerBloc() : super(const PlayerState()) {
    on<ConnectToChannel>(_onConnect);
    on<DisconnectFromChannel>(_onDisconnect);
    on<ToggleMute>(_onToggleMute);
    on<SetVolume>(_onSetVolume);
    on<PlayerBackgroundEntered>(_onBackground);
    on<PlayerForegroundEntered>(_onForeground);
    on<SelectLanguage>(_onSelectLanguage);
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
      // TODO(issue-2): WebRTC/mediasoup connection via WebRtcService
      _logger.info('Connecting to channel', {
        'serverUrl': event.serverUrl,
        'channelId': event.channelId,
      });

      // Save to recent channels
      await SharedPrefsHelper.addRecentChannel(
        channelId: event.channelId,
        channelName: event.channelId,
      );

      // Placeholder — actual connection in issue-2
      emit(state.copyWith(
        status: PlayerStatus.connecting,
        channelId: event.channelId,
      ));
    } catch (e, stack) {
      _logger.error('Connection failed', e, stack);
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
    // TODO(issue-2): close WebRTC transport
    emit(const PlayerState(status: PlayerStatus.disconnected));
  }

  Future<void> _onToggleMute(
    ToggleMute event,
    Emitter<PlayerState> emit,
  ) async {
    final newMuted = !state.isMuted;
    _logger.debug('Mute toggled', {'muted': newMuted});
    // TODO(issue-2): apply to audio track
    emit(state.copyWith(isMuted: newMuted));
  }

  Future<void> _onSetVolume(
    SetVolume event,
    Emitter<PlayerState> emit,
  ) async {
    final clamped = event.volume.clamp(0.0, 1.0);
    await SharedPrefsHelper.setVolume(clamped);
    emit(state.copyWith(volume: clamped));
  }

  Future<void> _onBackground(
    PlayerBackgroundEntered event,
    Emitter<PlayerState> emit,
  ) async {
    _logger.debug('App backgrounded — keeping audio alive via foreground service');
    // TODO(issue-3): activate flutter_foreground_task to keep audio alive
  }

  Future<void> _onForeground(
    PlayerForegroundEntered event,
    Emitter<PlayerState> emit,
  ) async {
    _logger.debug('App foregrounded');
  }

  Future<void> _onSelectLanguage(
    SelectLanguage event,
    Emitter<PlayerState> emit,
  ) async {
    _logger.info('Language selected', {
      'language': event.language,
      'channelId': event.channelId,
    });

    emit(state.copyWith(
      status: PlayerStatus.connecting,
      channelId: event.channelId,
      selectedLanguage: event.language,
      errorMessage: null,
    ));

    try {
      // TODO(issue-4): WebRTC join via WebRtcService.joinChannel(event.channelId)
      await SharedPrefsHelper.addRecentChannel(
        channelId: event.channelId,
        channelName: event.channelId,
      );

      // Simulate connected state until real WebRTC is wired in issue-4
      emit(state.copyWith(
        status: PlayerStatus.connected,
        channelId: event.channelId,
        selectedLanguage: event.language,
      ));
    } catch (e, stack) {
      _logger.error('Language selection / join failed', e, stack);
      emit(state.copyWith(
        status: PlayerStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
