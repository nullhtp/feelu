import 'package:feelu/core/services/logging_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoggingService Tests', () {
    late ILoggingService loggingService;

    setUp(() {
      loggingService = LoggingService(isDebugMode: true);
    });

    test('should implement ILoggingService interface', () {
      expect(loggingService, isA<ILoggingService>());
    });

    test('should not throw when logging debug message', () {
      expect(() => loggingService.debug('Test debug message'), returnsNormally);
    });

    test('should not throw when logging info message', () {
      expect(() => loggingService.info('Test info message'), returnsNormally);
    });

    test('should not throw when logging warning message', () {
      expect(
        () => loggingService.warning('Test warning message'),
        returnsNormally,
      );
    });

    test('should not throw when logging error message', () {
      expect(() => loggingService.error('Test error message'), returnsNormally);
    });

    test('should handle error object and stack trace', () {
      final error = Exception('Test error');
      final stackTrace = StackTrace.current;

      expect(
        () => loggingService.error('Error occurred', error, stackTrace),
        returnsNormally,
      );
    });
  });

  group('MockLoggingService Tests', () {
    late MockLoggingService mockLoggingService;

    setUp(() {
      mockLoggingService = MockLoggingService();
    });

    test('should capture debug logs', () {
      mockLoggingService.debug('Debug message');

      expect(mockLoggingService.logs.length, equals(1));
      expect(mockLoggingService.logs.first.level, equals('DEBUG'));
      expect(mockLoggingService.logs.first.message, equals('Debug message'));
    });

    test('should capture info logs', () {
      mockLoggingService.info('Info message');

      expect(mockLoggingService.logs.length, equals(1));
      expect(mockLoggingService.logs.first.level, equals('INFO'));
      expect(mockLoggingService.logs.first.message, equals('Info message'));
    });

    test('should capture warning logs', () {
      mockLoggingService.warning('Warning message');

      expect(mockLoggingService.logs.length, equals(1));
      expect(mockLoggingService.logs.first.level, equals('WARNING'));
      expect(mockLoggingService.logs.first.message, equals('Warning message'));
    });

    test('should capture error logs', () {
      mockLoggingService.error('Error message');

      expect(mockLoggingService.logs.length, equals(1));
      expect(mockLoggingService.logs.first.level, equals('ERROR'));
      expect(mockLoggingService.logs.first.message, equals('Error message'));
    });

    test('should capture multiple logs', () {
      mockLoggingService.debug('Debug');
      mockLoggingService.info('Info');
      mockLoggingService.warning('Warning');
      mockLoggingService.error('Error');

      expect(mockLoggingService.logs.length, equals(4));
    });

    test('should clear logs', () {
      mockLoggingService.debug('Test');
      expect(mockLoggingService.logs.length, equals(1));

      mockLoggingService.clear();
      expect(mockLoggingService.logs.length, equals(0));
    });

    test('should check for logs with specific level', () {
      mockLoggingService.debug('Debug message');
      mockLoggingService.error('Error message');

      expect(mockLoggingService.hasLogWithLevel('DEBUG'), isTrue);
      expect(mockLoggingService.hasLogWithLevel('ERROR'), isTrue);
      expect(mockLoggingService.hasLogWithLevel('INFO'), isFalse);
    });

    test('should check for logs with specific message', () {
      mockLoggingService.info('User logged in successfully');
      mockLoggingService.error('Database connection failed');

      expect(mockLoggingService.hasLogWithMessage('logged in'), isTrue);
      expect(mockLoggingService.hasLogWithMessage('connection failed'), isTrue);
      expect(mockLoggingService.hasLogWithMessage('not found'), isFalse);
    });

    test('should capture error objects and stack traces', () {
      final error = Exception('Test exception');
      final stackTrace = StackTrace.current;

      mockLoggingService.error('Something went wrong', error, stackTrace);

      final logEntry = mockLoggingService.logs.first;
      expect(logEntry.error, equals(error));
      expect(logEntry.stackTrace, equals(stackTrace));
    });
  });

  group('LogEntry Tests', () {
    test('should create log entry with timestamp', () {
      final logEntry = LogEntry('INFO', 'Test message', null, null);

      expect(logEntry.level, equals('INFO'));
      expect(logEntry.message, equals('Test message'));
      expect(logEntry.timestamp, isA<DateTime>());
    });

    test('should create string representation', () {
      final logEntry = LogEntry('ERROR', 'Error occurred', null, null);
      final stringRep = logEntry.toString();

      expect(stringRep, contains('[ERROR]'));
      expect(stringRep, contains('Error occurred'));
    });
  });

  group('DI Integration Tests', () {
    test('should work as interface implementation', () {
      // This demonstrates how DI makes it easy to swap implementations

      // Production implementation
      ILoggingService prodLogger = LoggingService();
      expect(prodLogger, isA<LoggingService>());

      // Test implementation
      ILoggingService testLogger = MockLoggingService();
      expect(testLogger, isA<MockLoggingService>());

      // Both implement the same interface
      expect(prodLogger, isA<ILoggingService>());
      expect(testLogger, isA<ILoggingService>());
    });

    test('should enable easy testing with mock', () {
      // Arrange
      final mockLogger = MockLoggingService();
      final businessLogic = ExampleBusinessLogic(mockLogger);

      // Act
      businessLogic.performOperation();

      // Assert
      expect(mockLogger.hasLogWithLevel('INFO'), isTrue);
      expect(mockLogger.hasLogWithMessage('Operation started'), isTrue);
      expect(mockLogger.hasLogWithMessage('Operation completed'), isTrue);
    });
  });
}

/// Example business logic class that uses logging service
class ExampleBusinessLogic {
  final ILoggingService _logger;

  ExampleBusinessLogic(this._logger);

  void performOperation() {
    _logger.info('Operation started');

    // Simulate some work
    try {
      // Do something...
      _logger.debug('Processing data...');
    } catch (e) {
      _logger.error('Operation failed', e);
      return;
    }

    _logger.info('Operation completed');
  }
}
