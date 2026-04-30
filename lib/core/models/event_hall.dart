import 'package:equatable/equatable.dart';

/// Represents a hall (sala) at an event — maps to the server's `/events/:id/halls` endpoint.
/// Each hall groups one or more audio channels, one per language.
class EventHall extends Equatable {
  final String hallId;
  final String hallName;
  final String eventId;

  /// ISO 639-1 language codes, e.g. ['it', 'en', 'de']
  final List<String> languages;

  /// Canali con almeno un producer attivo (da API activeChannels).
  final List<String> activeChannels;

  /// Lingua ISO parlata dall'originale (es. 'it'), null se nessuno speaker attivo.
  final String? sourceLanguage;

  final int listenerCount;
  final bool isLive;

  /// Whether the hall requires a PIN to enter (optional, defaults to false).
  final bool requiresPin;

  const EventHall({
    required this.hallId,
    required this.hallName,
    required this.eventId,
    this.languages = const [],
    this.activeChannels = const [],
    this.sourceLanguage,
    this.listenerCount = 0,
    this.isLive = false,
    this.requiresPin = false,
  });

  /// Creates an [EventHall] from a JSON map.
  ///
  /// [contextEventId] — pass the eventId from the URL/context when the
  /// server response (e.g. `GET /events/:eventId/halls`) omits the field.
  factory EventHall.fromJson(
    Map<String, dynamic> json, {
    String? contextEventId,
  }) {
    final rawLangs = json['languages'] as List<dynamic>? ?? [];
    final rawActive = json['activeChannels'] as List<dynamic>? ?? [];
    return EventHall(
      hallId: json['hallId'] as String? ?? json['id'] as String,
      hallName: json['hallName'] as String? ?? json['name'] as String,
      // Server hall list responses don't include eventId — fall back to context.
      eventId: json['eventId'] as String? ?? contextEventId ?? '',
      languages: rawLangs.map((e) => e.toString()).toList(),
      activeChannels: rawActive.map((e) => e.toString()).toList(),
      sourceLanguage: json['sourceLanguage'] as String?,
      listenerCount: (json['listenerCount'] as num?)?.toInt() ?? 0,
      isLive: json['isLive'] as bool? ?? json['isActive'] as bool? ?? false,
      requiresPin: json['requiresPin'] as bool? ??
          json['pinRequired'] as bool? ??
          json['hasPin'] as bool? ??
          false,
    );
  }

  Map<String, dynamic> toJson() => {
        'hallId': hallId,
        'hallName': hallName,
        'eventId': eventId,
        'languages': languages,
        'activeChannels': activeChannels,
        'sourceLanguage': sourceLanguage,
        'listenerCount': listenerCount,
        'isLive': isLive,
        'requiresPin': requiresPin,
      };

  @override
  List<Object?> get props => [
        hallId, hallName, eventId, languages, activeChannels, sourceLanguage,
        listenerCount, isLive, requiresPin,
      ];
}
