import 'package:equatable/equatable.dart';

abstract class PlayerEvent extends Equatable {
  const PlayerEvent();

  @override
  List<Object?> get props => [];
}

/// Connect to a channel and start receiving audio
class ConnectToChannel extends PlayerEvent {
  final String serverUrl;
  final String channelId;

  const ConnectToChannel({required this.serverUrl, required this.channelId});

  @override
  List<Object?> get props => [serverUrl, channelId];
}

/// Disconnect from the current channel
class DisconnectFromChannel extends PlayerEvent {
  const DisconnectFromChannel();
}

/// Toggle audio mute/unmute
class ToggleMute extends PlayerEvent {
  const ToggleMute();
}

/// Set audio volume (0.0-1.0)
class SetVolume extends PlayerEvent {
  final double volume;

  const SetVolume(this.volume);

  @override
  List<Object?> get props => [volume];
}

/// App entered background
class PlayerBackgroundEntered extends PlayerEvent {
  const PlayerBackgroundEntered();
}

/// App returned to foreground
class PlayerForegroundEntered extends PlayerEvent {
  const PlayerForegroundEntered();
}
