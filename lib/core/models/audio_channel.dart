import 'package:equatable/equatable.dart';

/// Represents a single audio channel for a specific language inside a hall.
/// Maps to one WebRTC producer stream on the mediasoup SFU.
class AudioChannel extends Equatable {
  final String channelId;

  /// ISO 639-1 language code, e.g. 'it', 'en'
  final String language;

  /// Number of active producers (0 = no one speaking / inactive)
  final int producerCount;

  const AudioChannel({
    required this.channelId,
    required this.language,
    this.producerCount = 0,
  });

  factory AudioChannel.fromJson(Map<String, dynamic> json) {
    return AudioChannel(
      channelId: json['channelId'] as String? ?? json['id'] as String,
      language: json['language'] as String,
      producerCount: (json['producerCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'channelId': channelId,
        'language': language,
        'producerCount': producerCount,
      };

  @override
  List<Object?> get props => [channelId, language, producerCount];
}
