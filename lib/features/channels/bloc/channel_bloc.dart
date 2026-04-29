import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/logger.dart';
import 'channel_event.dart';
import 'channel_state.dart';

class ChannelBloc extends Bloc<ChannelEvent, ChannelState> {
  final _logger = Logger('ChannelBloc');

  ChannelBloc() : super(const ChannelInitial()) {
    on<LoadChannels>(_onLoadChannels);
    on<RefreshChannels>(_onRefreshChannels);
    on<SelectChannel>(_onSelectChannel);
  }

  Future<void> _onLoadChannels(
    LoadChannels event,
    Emitter<ChannelState> emit,
  ) async {
    emit(const ChannelLoading());
    try {
      // TODO(issue-2): implement HTTP call to EventAudio API
      // GET ${AppConstants.apiBaseUrl}/events/${event.eventId}/channels
      _logger.info('Loading channels', {
        'serverUrl': event.serverUrl,
        'eventId': event.eventId,
      });
      // Placeholder until backend integration is implemented
      emit(const ChannelError('Backend not yet connected'));
    } catch (e, stack) {
      _logger.error('Failed to load channels', e, stack);
      emit(ChannelError(e.toString()));
    }
  }

  Future<void> _onRefreshChannels(
    RefreshChannels event,
    Emitter<ChannelState> emit,
  ) async {
    final current = state;
    if (current is ChannelLoaded) {
      // Re-trigger load with existing event context
      _logger.info('Refreshing channels');
    }
  }

  Future<void> _onSelectChannel(
    SelectChannel event,
    Emitter<ChannelState> emit,
  ) async {
    final current = state;
    if (current is ChannelLoaded) {
      emit(current.copyWith(selectedChannelId: event.channelId));
      _logger.info('Channel selected', {'channelId': event.channelId});
    }
  }
}
