import 'package:flutter/foundation.dart';

import '../di/service_locator.dart';
import 'vibration_notification_service.dart';

/// Logging service that follows dependency injection principles
///
/// This service provides structured logging functionality throughout the app
/// and can be easily mocked for testing.
abstract class ILoggingService {
  void debug(String message, [Object? error, StackTrace? stackTrace]);
  void info(String message, [Object? error, StackTrace? stackTrace]);
  void warning(String message, [Object? error, StackTrace? stackTrace]);
  void error(String message, [Object? error, StackTrace? stackTrace]);
}

/// Production implementation of the logging service
class LoggingService implements ILoggingService {
  final bool _isDebugMode;
  final IVibrationNotification _vibrationNotificationService =
      ServiceLocator.get<IVibrationNotification>();

  LoggingService({bool isDebugMode = kDebugMode}) : _isDebugMode = isDebugMode;

  @override
  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (_isDebugMode) {
      _log('DEBUG', message, error, stackTrace);
    }
  }

  @override
  void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log('INFO', message, error, stackTrace);
  }

  @override
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _log('WARNING', message, error, stackTrace);
    _vibrationNotificationService.vibrateWarning();
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log('ERROR', message, error, stackTrace);
    _vibrationNotificationService.vibrateError();
  }

  void _log(
    String level,
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] [$level] $message';

    if (kDebugMode) {
      print(logMessage);

      if (error != null) {
        print('Error: $error');
      }

      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }
  }
}

/// Mock implementation for testing
class MockLoggingService implements ILoggingService {
  final List<LogEntry> logs = [];

  @override
  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    logs.add(LogEntry('DEBUG', message, error, stackTrace));
  }

  @override
  void info(String message, [Object? error, StackTrace? stackTrace]) {
    logs.add(LogEntry('INFO', message, error, stackTrace));
  }

  @override
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    logs.add(LogEntry('WARNING', message, error, stackTrace));
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    logs.add(LogEntry('ERROR', message, error, stackTrace));
  }

  void clear() {
    logs.clear();
  }

  bool hasLogWithLevel(String level) {
    return logs.any((log) => log.level == level);
  }

  bool hasLogWithMessage(String message) {
    return logs.any((log) => log.message.contains(message));
  }
}

/// Log entry model for testing
class LogEntry {
  final String level;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  LogEntry(this.level, this.message, this.error, this.stackTrace)
    : timestamp = DateTime.now();

  @override
  String toString() {
    return '[$timestamp] [$level] $message';
  }
}
