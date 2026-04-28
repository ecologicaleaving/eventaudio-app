import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'constants.dart';

/// Helper class for SharedPreferences operations
/// Adapted from StageConnect — nickname removed (visitor is anonymous)
class SharedPrefsHelper {
  static SharedPreferences? _prefs;
  static const _uuid = Uuid();

  /// Initialize SharedPreferences
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance (throws if not initialized)
  static SharedPreferences get _instance {
    if (_prefs == null) {
      throw StateError(
          'SharedPrefsHelper not initialized. Call initialize() first.');
    }
    return _prefs!;
  }

  // Key constants
  static const String _keyDeviceId = 'device_id';
  static const String _keyAudioVolume = 'audio_volume';
  static const String _keyAlwaysOnEnabled = 'always_on_enabled';
  static const String _keyRecentChannels = 'recent_channels';
  static const String _keyFirstLaunchCompleted = 'first_launch_completed';
  static const String _keySavedServer = 'saved_server';
  static const String _keyRecentEvents = 'recent_events';

  /// Maximum number of recent events to store (FIFO)
  static const int _maxRecentEvents = 3;

  /// Get or generate device ID (persistent UUID — identifies anonymous visitor)
  static Future<String> getDeviceId() async {
    String? deviceId = _instance.getString(_keyDeviceId);
    if (deviceId == null) {
      deviceId = _uuid.v4();
      await _instance.setString(_keyDeviceId, deviceId);
    }
    return deviceId;
  }

  /// Get audio volume preference (0.0-1.0)
  static double getVolume() {
    return _instance.getDouble(_keyAudioVolume) ?? UserDefaults.defaultVolume;
  }

  /// Set audio volume preference
  static Future<bool> setVolume(double volume) {
    final clampedVolume = volume.clamp(0.0, 1.0);
    return _instance.setDouble(_keyAudioVolume, clampedVolume);
  }

  /// Get Always-On mode preference
  static bool isAlwaysOnEnabled() {
    return _instance.getBool(_keyAlwaysOnEnabled) ?? false;
  }

  /// Set Always-On mode preference
  static Future<bool> setAlwaysOnEnabled(bool enabled) {
    return _instance.setBool(_keyAlwaysOnEnabled, enabled);
  }

  /// Get recent channels list
  static List<Map<String, dynamic>> getRecentChannels() {
    final String? json = _instance.getString(_keyRecentChannels);
    if (json == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Add channel to recent channels list (maintains last N channels)
  static Future<bool> addRecentChannel({
    required String channelId,
    required String channelName,
    String? eventName,
  }) async {
    final recentChannels = getRecentChannels();

    recentChannels.removeWhere((ch) => ch['id'] == channelId);
    recentChannels.insert(0, {
      'id': channelId,
      'name': channelName,
      if (eventName case final String e) 'event': e,
      'lastJoinedAt': DateTime.now().toIso8601String(),
    });

    if (recentChannels.length > ChannelConstants.recentChannelsLimit) {
      recentChannels.removeRange(
        ChannelConstants.recentChannelsLimit,
        recentChannels.length,
      );
    }

    final String json = jsonEncode(recentChannels);
    return _instance.setString(_keyRecentChannels, json);
  }

  /// Clear recent channels list
  static Future<bool> clearRecentChannels() {
    return _instance.remove(_keyRecentChannels);
  }

  /// Get first launch completed state
  static bool isFirstLaunchCompleted() {
    return _instance.getBool(_keyFirstLaunchCompleted) ?? false;
  }

  /// Mark first launch as completed
  static Future<bool> setFirstLaunchCompleted() {
    return _instance.setBool(_keyFirstLaunchCompleted, true);
  }

  /// Get saved server URL
  static String? getSavedServer() {
    return _instance.getString(_keySavedServer);
  }

  /// Save server URL
  static Future<bool> setSavedServer(String url) {
    return _instance.setString(_keySavedServer, url);
  }

  // ── Recent Events ──────────────────────────────────────────────────────────

  /// Returns the list of recently accessed event IDs (most recent first, max 3).
  static List<String> getRecentEvents() {
    return _instance.getStringList(_keyRecentEvents) ?? [];
  }

  /// Adds [eventId] to the recent events list (max [_maxRecentEvents], FIFO).
  /// If [eventId] already exists it is moved to the front.
  static Future<void> addRecentEvent(String eventId) async {
    final events = getRecentEvents();
    events.remove(eventId);
    events.insert(0, eventId);
    if (events.length > _maxRecentEvents) {
      events.removeRange(_maxRecentEvents, events.length);
    }
    await _instance.setStringList(_keyRecentEvents, events);
  }

  /// Clears the recent events list.
  static Future<void> clearRecentEvents() async {
    await _instance.remove(_keyRecentEvents);
  }

  /// Clear all preferences
  static Future<bool> clearAll() {
    return _instance.clear();
  }
}
