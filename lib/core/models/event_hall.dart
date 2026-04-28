import 'package:equatable/equatable.dart';

/// Represents a hall (sala) at an event — maps to the server's `/events/:id/halls` endpoint.
/// Each hall groups one or more audio channels, one per language.
class EventHall extends Equatable {
  final String hallId;
  final String hallName;
  final String eventId;

  /// ISO 639-1 language codes, e.g. ['it', 'en', 'de']
  final List<String> languages;

  final int listenerCount;
  final bool isLive;

  const EventHall({
    required this.hallId,
    required this.hallName,
    required this.eventId,
    this.languages = const [],
    this.listenerCount = 0,
    this.isLive = false,
  });

  factory EventHall.fromJson(Map<String, dynamic> json) {
    final rawLangs = json['languages'] as List<dynamic>? ?? [];
    return EventHall(
      hallId: json['hallId'] as String? ?? json['id'] as String,
      hallName: json['hallName'] as String? ?? json['name'] as String,
      eventId: json['eventId'] as String? ?? '',
      languages: rawLangs.map((e) => e.toString()).toList(),
      listenerCount: (json['listenerCount'] as num?)?.toInt() ?? 0,
      isLive: json['isLive'] as bool? ?? json['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'hallId': hallId,
        'hallName': hallName,
        'eventId': eventId,
        'languages': languages,
        'listenerCount': listenerCount,
        'isLive': isLive,
      };

  @override
  List<Object?> get props =>
      [hallId, hallName, eventId, languages, listenerCount, isLive];
}
