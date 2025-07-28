import 'package:feelu/core/config/app_config.dart';
import 'package:feelu/core/di/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock service for testing
class MockAppConfig extends AppConfig {
  final String? _mockToken;

  MockAppConfig([this._mockToken]);

  @override
  Future<String?> getAccessToken() async {
    return _mockToken;
  }

  @override
  bool get hasAccessToken => _mockToken != null;
}

// Example business logic that uses DI
class ConfigValidator {
  final AppConfig _config;

  ConfigValidator(this._config);

  Future<bool> isValidConfiguration() async {
    final token = await _config.getAccessToken();
    return token != null && token.length > 10;
  }
}

void main() {
  group('ServiceLocator Tests', () {
    setUp(() async {
      // Reset the service locator before each test
      await ServiceLocator.reset();
    });

    tearDown(() async {
      // Clean up after each test
      await ServiceLocator.reset();
    });

    test('should register and retrieve services', () {
      // Arrange
      final mockConfig = MockAppConfig('test-token-123');

      // Act
      ServiceLocator.registerSingleton<AppConfig>(mockConfig);
      final retrievedConfig = ServiceLocator.get<AppConfig>();

      // Assert
      expect(retrievedConfig, equals(mockConfig));
      expect(ServiceLocator.isRegistered<AppConfig>(), isTrue);
    });

    test('should register lazy singleton', () {
      // Arrange & Act
      ServiceLocator.registerLazySingleton<AppConfig>(
        () => MockAppConfig('lazy-token'),
      );

      // Assert
      expect(ServiceLocator.isRegistered<AppConfig>(), isTrue);

      final config1 = ServiceLocator.get<AppConfig>();
      final config2 = ServiceLocator.get<AppConfig>();

      // Should return the same instance (singleton behavior)
      expect(identical(config1, config2), isTrue);
    });

    test('should register factory for new instances', () {
      // Arrange & Act
      ServiceLocator.registerFactory<AppConfig>(
        () => MockAppConfig('factory-token'),
      );

      // Assert
      expect(ServiceLocator.isRegistered<AppConfig>(), isTrue);

      final config1 = ServiceLocator.get<AppConfig>();
      final config2 = ServiceLocator.get<AppConfig>();

      // Should return different instances (factory behavior)
      expect(identical(config1, config2), isFalse);
    });

    test('should not register service twice', () {
      // Arrange
      final mockConfig1 = MockAppConfig('token1');
      final mockConfig2 = MockAppConfig('token2');

      // Act
      ServiceLocator.registerSingleton<AppConfig>(mockConfig1);
      ServiceLocator.registerSingleton<AppConfig>(
        mockConfig2,
      ); // Should not override

      // Assert
      final retrievedConfig = ServiceLocator.get<AppConfig>();
      expect(
        retrievedConfig,
        equals(mockConfig1),
      ); // Should still be the first one
    });

    test('should reset all services', () async {
      // Arrange
      ServiceLocator.registerSingleton<AppConfig>(MockAppConfig('test'));
      expect(ServiceLocator.isRegistered<AppConfig>(), isTrue);

      // Act
      await ServiceLocator.reset();

      // Assert
      expect(ServiceLocator.isRegistered<AppConfig>(), isFalse);
    });
  });

  group('DI Testing Benefits', () {
    late ServiceLocator serviceLocator;

    setUp(() async {
      await ServiceLocator.reset();
    });

    test('should make business logic easily testable with mocks', () async {
      // Arrange - Inject mock dependencies
      final mockConfig = MockAppConfig('valid-token-1234567890');
      ServiceLocator.registerSingleton<AppConfig>(mockConfig);

      final validator = ConfigValidator(ServiceLocator.get<AppConfig>());

      // Act
      final isValid = await validator.isValidConfiguration();

      // Assert
      expect(isValid, isTrue);
    });

    test('should test failure scenarios with mock', () async {
      // Arrange - Inject mock with invalid token
      final mockConfig = MockAppConfig('short'); // Too short token
      ServiceLocator.registerSingleton<AppConfig>(mockConfig);

      final validator = ConfigValidator(ServiceLocator.get<AppConfig>());

      // Act
      final isValid = await validator.isValidConfiguration();

      // Assert
      expect(isValid, isFalse);
    });

    test('should test null token scenario', () async {
      // Arrange - Inject mock with no token
      final mockConfig = MockAppConfig(null);
      ServiceLocator.registerSingleton<AppConfig>(mockConfig);

      final validator = ConfigValidator(ServiceLocator.get<AppConfig>());

      // Act
      final isValid = await validator.isValidConfiguration();

      // Assert
      expect(isValid, isFalse);
    });
  });

  group('Service Integration Tests', () {
    test('should initialize services successfully', () async {
      // This test verifies that the service locator initializes properly

      // Arrange & Act
      await ServiceLocator.init();

      // Assert - Just verify that init completes without errors
      // In a full integration test, you would check specific services
      expect(true, isTrue); // ServiceLocator.init() completed successfully
    });
  });
}
