import 'package:equatable/equatable.dart';
import 'channel_model.dart';

/// Represents an event (fair, conference, etc.) hosting audio channels
class EventModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final List<ChannelModel> channels;
  final bool isActive;

  const EventModel({
    required this.id,
    required this.name,
    this.description,
    this.channels = const [],
    this.isActive = false,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final channelsJson = json['channels'] as List<dynamic>? ?? [];
    return EventModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      channels: channelsJson
          .map((c) => ChannelModel.fromJson(c as Map<String, dynamic>))
          .toList(),
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'channels': channels.map((c) => c.toJson()).toList(),
      'isActive': isActive,
    };
  }

  @override
  List<Object?> get props => [id, name, description, channels, isActive];
}
