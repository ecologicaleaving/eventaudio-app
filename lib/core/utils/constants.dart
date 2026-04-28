/// Audio codec defaults and configuration constants
class AudioConstants {
  /// Default sample rate in Hz (48kHz standard for low latency)
  static const int defaultSampleRate = 48000;

  /// Default target bitrate in bps (64 kbps - VoIP quality standard)
  static const int defaultBitrate = 64000;

  /// Default audio buffer size in samples (256 = ~5.3ms @ 48kHz)
  static const int defaultBufferSize = 256;

  /// Default codec name
  static const String defaultCodec = 'opus';

  /// Default number of audio channels (1 = mono)
  static const int defaultChannels = 1;
}

/// Network constants
class NetworkConstants {
  /// Default EventAudio server URL (mirrors AppConstants.serverUrl)
  static const String defaultServerUrl = AppConstants.serverUrl;

  /// Default WebSocket port
  static const int defaultPort = 3005;

  /// Maximum saved servers in history
  static const int maxSavedServers = 10;

  /// Heartbeat interval in seconds
  static const int heartbeatInterval = 5;
}

/// Channel constants
class ChannelConstants {
  /// Maximum channels per event
  static const int maxChannels = 32;

  /// Recent channels history size
  static const int recentChannelsLimit = 10;
}

/// User preference defaults — anonymous visitor (no nickname required)
class UserDefaults {
  /// Default audio volume (0.0-1.0)
  static const double defaultVolume = 0.8;

  /// Battery warning threshold percentage
  static const int batteryWarningThreshold = 20;
}

/// App metadata
class AppConstants {
  /// App version
  static const String appVersion = '0.1.0';

  /// EventAudio server base URL — VPS production (nginx TLS).
  static const String serverUrl = String.fromEnvironment(
    'SERVER_URL',
    defaultValue: 'https://eventaudio.8020solutions.org',
  );

  /// WebSocket / Socket.IO signaling URL — same host as [serverUrl].
  static const String wsUrl = String.fromEnvironment(
    'SERVER_URL',
    defaultValue: 'https://eventaudio.8020solutions.org',
  );

  /// Package name
  static const String packageName = 'it.eventaudio.app';

  /// Minimum Android API level
  static const int minAndroidApi = 26; // Android 8.0

  /// Target Android API level
  static const int targetAndroidApi = 34; // Android 14

  /// Minimum iOS version
  static const String minIosVersion = '13.0';
}
