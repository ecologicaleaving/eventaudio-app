import 'package:equatable/equatable.dart';
import '../../../core/models/channel_model.dart';
import '../../../core/models/event_model.dart';

abstract class ChannelState extends Equatable {
  const ChannelState();

  @override
  List<Object?> get props => [];
}

class ChannelInitial extends ChannelState {
  const ChannelInitial();
}

class ChannelLoading extends ChannelState {
  const ChannelLoading();
}

class ChannelLoaded extends ChannelState {
  final EventModel event;
  final List<ChannelModel> channels;
  final String? selectedChannelId;

  const ChannelLoaded({
    required this.event,
    required this.channels,
    this.selectedChannelId,
  });

  ChannelLoaded copyWith({
    EventModel? event,
    List<ChannelModel>? channels,
    String? selectedChannelId,
  }) {
    return ChannelLoaded(
      event: event ?? this.event,
      channels: channels ?? this.channels,
      selectedChannelId: selectedChannelId ?? this.selectedChannelId,
    );
  }

  @override
  List<Object?> get props => [event, channels, selectedChannelId];
}

class ChannelError extends ChannelState {
  final String message;

  const ChannelError(this.message);

  @override
  List<Object?> get props => [message];
}
