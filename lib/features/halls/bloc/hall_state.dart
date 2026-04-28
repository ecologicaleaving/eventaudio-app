import 'package:equatable/equatable.dart';
import '../../../core/models/event_hall.dart';

abstract class HallState extends Equatable {
  const HallState();

  @override
  List<Object?> get props => [];
}

/// Initial state — no fetch triggered yet
class HallInitial extends HallState {
  const HallInitial();
}

/// HTTP request in flight
class HallLoading extends HallState {
  const HallLoading();
}

/// Halls fetched successfully (list may be empty)
class HallLoaded extends HallState {
  final List<EventHall> halls;
  final String serverUrl;
  final String? eventId;

  const HallLoaded({
    required this.halls,
    required this.serverUrl,
    this.eventId,
  });

  HallLoaded copyWith({
    List<EventHall>? halls,
    String? serverUrl,
    String? eventId,
  }) {
    return HallLoaded(
      halls: halls ?? this.halls,
      serverUrl: serverUrl ?? this.serverUrl,
      eventId: eventId ?? this.eventId,
    );
  }

  @override
  List<Object?> get props => [halls, serverUrl, eventId];
}

/// HTTP or parsing error
class HallError extends HallState {
  final String message;

  /// True when the server returned 404 — event ID was not found.
  final bool isNotFound;

  const HallError(this.message, {this.isNotFound = false});

  @override
  List<Object?> get props => [message, isNotFound];
}
