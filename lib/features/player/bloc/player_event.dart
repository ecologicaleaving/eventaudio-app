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

/// Utente è entrato nella schermata sala — avvia subito il polling activeChannels
class PlayerHallEntered extends PlayerEvent {
  final String eventId;
  final String hallId;

  const PlayerHallEntered({required this.eventId, required this.hallId});

  @override
  List<Object?> get props => [eventId, hallId];
}

/// Visitor selected a language chip → connect to that language's channel
class SelectLanguage extends PlayerEvent {
  final String language;
  final String channelId;
  final String serverUrl;

  const SelectLanguage({
    required this.language,
    required this.channelId,
    required this.serverUrl,
  });

  @override
  List<Object?> get props => [language, channelId, serverUrl];
}

