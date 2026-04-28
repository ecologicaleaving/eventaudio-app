import 'package:equatable/equatable.dart';

abstract class ChannelEvent extends Equatable {
  const ChannelEvent();

  @override
  List<Object?> get props => [];
}

/// Load channels for an event (by QR code scan or PIN)
class LoadChannels extends ChannelEvent {
  final String serverUrl;
  final String eventId;

  const LoadChannels({required this.serverUrl, required this.eventId});

  @override
  List<Object?> get props => [serverUrl, eventId];
}

/// Refresh the current channel list
class RefreshChannels extends ChannelEvent {
  const RefreshChannels();
}

/// Select a channel to join
class SelectChannel extends ChannelEvent {
  final String channelId;

  const SelectChannel(this.channelId);

  @override
  List<Object?> get props => [channelId];
}
