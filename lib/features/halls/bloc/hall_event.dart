import 'package:equatable/equatable.dart';

abstract class HallEvent extends Equatable {
  const HallEvent();

  @override
  List<Object?> get props => [];
}

/// Load halls from the server — called on screen init or after a QR scan
class LoadHalls extends HallEvent {
  /// The base server URL (e.g. https://eventaudio.8020solutions.org)
  final String serverUrl;

  /// Optional event ID — if null, falls back to GET /channels (MVP)
  final String? eventId;

  const LoadHalls({required this.serverUrl, this.eventId});

  @override
  List<Object?> get props => [serverUrl, eventId];
}

/// Pull-to-refresh: reload with the same context
class RefreshHalls extends HallEvent {
  const RefreshHalls();
}
