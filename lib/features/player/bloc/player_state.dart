import 'package:equatable/equatable.dart';

enum PlayerStatus {
  idle,
  connecting,
  connected,
  disconnected,
  error,
}

class PlayerState extends Equatable {
  final PlayerStatus status;
  final String? channelId;
  final String? channelName;

  /// Currently selected language (ISO 639-1)
  final String? selectedLanguage;

  final bool isMuted;
  final double volume;
  final String? errorMessage;

  const PlayerState({
    this.status = PlayerStatus.idle,
    this.channelId,
    this.channelName,
    this.selectedLanguage,
    this.isMuted = false,
    this.volume = 0.8,
    this.errorMessage,
  });

  bool get isConnected => status == PlayerStatus.connected;
  bool get isConnecting => status == PlayerStatus.connecting;
  bool get isPlaying => isConnected && !isMuted;

  PlayerState copyWith({
    PlayerStatus? status,
    String? channelId,
    String? channelName,
    String? selectedLanguage,
    bool? isMuted,
    double? volume,
    String? errorMessage,
  }) {
    return PlayerState(
      status: status ?? this.status,
      channelId: channelId ?? this.channelId,
      channelName: channelName ?? this.channelName,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      isMuted: isMuted ?? this.isMuted,
      volume: volume ?? this.volume,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        channelId,
        channelName,
        selectedLanguage,
        isMuted,
        volume,
        errorMessage,
      ];
}
