import 'package:flutter/foundation.dart';

/// Log levels for structured logging
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

/// Structured logger for Stage Connect
class Logger {
  final String _tag;

  Logger(this._tag);

  /// Log a debug message (only in debug builds)
  void debug(String message, [Map<String, dynamic>? context]) {
    if (kDebugMode) {
      _log(LogLevel.debug, message, context);
    }
  }

  /// Log an info message
  void info(String message, [Map<String, dynamic>? context]) {
    _log(LogLevel.info, message, context);
  }

  /// Log a warning message
  void warning(String message, [Map<String, dynamic>? context]) {
    _log(LogLevel.warning, message, context);
  }

  /// Log an error message
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    final context = <String, dynamic>{};
    if (error != null) context['error'] = error.toString();
    if (stackTrace != null) context['stackTrace'] = stackTrace.toString();
    _log(LogLevel.error, message, context);
  }

  /// Log a critical error
  void critical(String message, [Object? error, StackTrace? stackTrace]) {
    final context = <String, dynamic>{};
    if (error != null) context['error'] = error.toString();
    if (stackTrace != null) context['stackTrace'] = stackTrace.toString();
    _log(LogLevel.critical, message, context);
  }

  /// Internal logging method
  void _log(LogLevel level, String message, [Map<String, dynamic>? context]) {
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.toString().split('.').last.toUpperCase();
    final contextStr =
        context != null && context.isNotEmpty ? ' | $context' : '';

    // Use debugPrint for debug builds, print for release
    final logMessage = '[$timestamp] [$levelStr] [$_tag] $message$contextStr';

    if (kDebugMode) {
      debugPrint(logMessage);
    } else {
      // In production, we could send to analytics/crash reporting here
      debugPrint(logMessage);
    }
  }
}

/// Global logger factory
class LoggerFactory {
  static final Map<String, Logger> _loggers = {};

  /// Get or create a logger for a specific tag
  static Logger getLogger(String tag) {
    return _loggers.putIfAbsent(tag, () => Logger(tag));
  }
}
