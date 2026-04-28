import 'package:equatable/equatable.dart';

/// Represents an audio channel at an event
class ChannelModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? language;
  final int listenerCount;
  final bool isActive;

  const ChannelModel({
    required this.id,
    required this.name,
    this.description,
    this.language,
    this.listenerCount = 0,
    this.isActive = false,
  });

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    return ChannelModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      language: json['language'] as String?,
      listenerCount: (json['listenerCount'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (language != null) 'language': language,
      'listenerCount': listenerCount,
      'isActive': isActive,
    };
  }

  ChannelModel copyWith({
    String? id,
    String? name,
    String? description,
    String? language,
    int? listenerCount,
    bool? isActive,
  }) {
    return ChannelModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      language: language ?? this.language,
      listenerCount: listenerCount ?? this.listenerCount,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [id, name, description, language, listenerCount, isActive];
}
