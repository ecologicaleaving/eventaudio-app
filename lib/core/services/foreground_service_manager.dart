import 'dart:io';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../utils/logger.dart';

/// Manages Android foreground service and iOS background audio session.
/// Ensures audio playback continues when app is minimized or screen is off.
///
/// Copied from StageConnect (100% reusable — no transmit-side logic).
/// Notification strings updated for EventAudio branding.
class ForegroundServiceManager {
  static final Logger _logger = Logger('ForegroundServiceManager');
  static bool _isRunning = false;

  /// Whether the foreground service is currently running.
  static bool get isRunning => _isRunning;

  /// Initialize the foreground task configuration.
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'eventaudio_channel',
        channelName: 'EventAudio Audio',
        channelDescription: 'Audio streaming service',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        isSticky: true,
        showWhen: false,
        playSound: false,
        enableVibration: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
    _logger.info('Foreground service manager initialized');
  }

  /// Start foreground service when joining a channel.
  static Future<bool> startService({
    required String channelName,
    String status = 'In ascolto',
  }) async {
    if (_isRunning) {
      _logger.warning('Foreground service already running');
      return true;
    }

    if (!Platform.isAndroid) {
      // iOS handles background audio via AVAudioSession (configured natively
      // with .playback category — no foreground service required).
      _isRunning = true;
      _logger.info('iOS background audio session active');
      return true;
    }

    try {
      // Request necessary permissions.
      final notificationPermission =
          await FlutterForegroundTask.checkNotificationPermission();
      if (notificationPermission != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }

      // Start the foreground service.
      final success = await FlutterForegroundTask.startService(
        notificationTitle: channelName,
        notificationText: status,
      );

      if (success) {
        _isRunning = true;
        _logger.info('Foreground service started for channel: $channelName');
        return true;
      } else {
        _logger.error('Failed to start foreground service');
        return false;
      }
    } catch (e) {
      _logger.error('Exception starting foreground service: $e');
      return false;
    }
  }

  /// Update notification content (channel, status).
  static Future<void> updateNotification({
    String? channelName,
    String? status,
    String? speakerName,
  }) async {
    if (!_isRunning || !Platform.isAndroid) return;

    try {
      final text = speakerName != null
          ? '$speakerName sta parlando'
          : (status ?? 'In ascolto');

      await FlutterForegroundTask.updateService(
        notificationTitle: channelName,
        notificationText: text,
      );
    } catch (e) {
      _logger.error('Exception updating notification: $e');
    }
  }

  /// Stop foreground service when leaving a channel.
  static Future<void> stopService() async {
    if (!_isRunning) return;

    if (Platform.isAndroid) {
      try {
        await FlutterForegroundTask.stopService();
        _logger.info('Foreground service stopped');
      } catch (e) {
        _logger.error('Exception stopping foreground service: $e');
      }
    }

    _isRunning = false;
  }

  /// Check if battery optimization is disabled (Android only).
  static Future<bool> isBatteryOptimizationDisabled() async {
    if (!Platform.isAndroid) return true;
    return await FlutterForegroundTask.isIgnoringBatteryOptimizations;
  }

  /// Request to disable battery optimization.
  static Future<void> requestBatteryOptimizationDisable() async {
    if (!Platform.isAndroid) return;
    await FlutterForegroundTask.requestIgnoreBatteryOptimization();
  }
}
