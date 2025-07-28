import 'package:get_it/get_it.dart';

/// Service Locator for Dependency Injection
///
/// This class provides a clean interface for dependency injection
/// while maintaining compatibility with existing singleton patterns.
///
/// Usage:
/// ```dart
/// // Get a service instance
/// final cameraService = ServiceLocator.get<CameraService>();
///
/// // Check if registered
/// if (ServiceLocator.isRegistered<CameraService>()) {
///   // Use the service
/// }
/// ```
class ServiceLocator {
  static final GetIt _getIt = GetIt.instance;

  /// Get instance of registered service
  static T get<T extends Object>() => _getIt.get<T>();

  /// Check if service is registered
  static bool isRegistered<T extends Object>() => _getIt.isRegistered<T>();

  /// Register a service instance
  static void registerSingleton<T extends Object>(T instance) {
    if (!_getIt.isRegistered<T>()) {
      _getIt.registerSingleton<T>(instance);
    }
  }

  /// Register a lazy singleton factory
  static void registerLazySingleton<T extends Object>(T Function() factory) {
    if (!_getIt.isRegistered<T>()) {
      _getIt.registerLazySingleton<T>(factory);
    }
  }

  /// Register a factory (new instance each time)
  static void registerFactory<T extends Object>(T Function() factory) {
    if (!_getIt.isRegistered<T>()) {
      _getIt.registerFactory<T>(factory);
    }
  }

  /// Reset all registrations (useful for testing)
  static Future<void> reset() async {
    await _getIt.reset();
  }

  /// Initialize core services with DI
  /// This allows gradual migration from singleton pattern to DI
  static Future<void> init() async {
    // Core services - these will be migrated gradually
    await _registerCoreServices();
  }

  /// Register core services using existing singleton instances
  static Future<void> _registerCoreServices() async {
    // Import the services dynamically to avoid import issues
    try {
      // We'll register services as they're migrated from singleton pattern
      // For now, this serves as the foundation for future migration

      print('ServiceLocator: Core services registration started');
      print('ServiceLocator: Ready for service registration');
    } catch (e) {
      print('ServiceLocator: Error during initialization: $e');
    }
  }

  /// Helper method to dispose all registered services
  static Future<void> disposeAll() async {
    try {
      // Dispose services that have dispose methods
      await _getIt.reset();
      print('ServiceLocator: All services disposed');
    } catch (e) {
      print('ServiceLocator: Error disposing services: $e');
    }
  }
}

/// Extension to make service access more convenient
extension ServiceLocatorExtension on Object {
  /// Get a service instance from anywhere in the app
  T getService<T extends Object>() => ServiceLocator.get<T>();
}
