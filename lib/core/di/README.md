# Dependency Injection (DI) Implementation

## Overview

This module implements a dependency injection system for the FeelU app using the `get_it` package. The implementation provides a clean, testable alternative to the singleton pattern while maintaining backward compatibility during migration.

## Architecture

```
lib/core/di/
├── service_locator.dart      # Main DI container interface
├── service_registration.dart # Service registration helper
└── README.md               # This documentation
```

## Key Components

### 1. ServiceLocator

The main interface for dependency injection:

```dart
import 'package:feelu/core/di/service_locator.dart';

// Get a service instance
final appConfig = ServiceLocator.get<AppConfig>();

// Check if service is registered
if (ServiceLocator.isRegistered<CameraService>()) {
  final camera = ServiceLocator.get<CameraService>();
}
```

### 2. ServiceRegistration

Helper class for registering existing singleton services:

```dart
import 'package:feelu/core/di/service_registration.dart';

// Register all services at app startup
await ServiceRegistration.registerAllServices();

// Register specific service groups
await ServiceRegistration.registerCoreServices();
```

## Usage Examples

### Basic Service Registration

```dart
// Singleton registration (same instance every time)
ServiceLocator.registerSingleton<AppConfig>(AppConfig());

// Lazy singleton (created on first access)
ServiceLocator.registerLazySingleton<AppConfig>(() => AppConfig());

// Factory registration (new instance every time)
ServiceLocator.registerFactory<AppConfig>(() => AppConfig());
```

### Using Services in Widgets

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late final AppConfig _config;
  late final CameraService _camera;

  @override
  void initState() {
    super.initState();
    
    // Get services from DI container
    _config = ServiceLocator.get<AppConfig>();
    _camera = ServiceLocator.get<CameraService>();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _config.getAccessToken(),
      builder: (context, snapshot) {
        // Use the injected service
        return Text(snapshot.data ?? 'No token');
      },
    );
  }
}
```

### Using Extension Methods

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Use extension method for convenient access
    final config = context.getService<AppConfig>();
    
    return Text('Has token: ${config.hasAccessToken}');
  }
}
```

## Migration Guide

### From Singleton to DI

**Before (Singleton Pattern):**
```dart
class OldService {
  static OldService? _instance;
  static OldService get instance => _instance ??= OldService._();
  
  OldService._();
  
  void doSomething() {
    // Implementation
  }
}

// Usage
OldService.instance.doSomething();
```

**After (DI Pattern):**
```dart
class NewService {
  void doSomething() {
    // Implementation
  }
}

// Registration (in service_registration.dart)
ServiceLocator.registerLazySingleton<NewService>(() => NewService());

// Usage
final service = ServiceLocator.get<NewService>();
service.doSomething();
```

### Gradual Migration Strategy

1. **Phase 1**: Add DI infrastructure (✅ Complete)
2. **Phase 2**: Register existing singletons with DI
3. **Phase 3**: Update screens to use DI instead of direct singleton access
4. **Phase 4**: Refactor services to remove singleton pattern
5. **Phase 5**: Add comprehensive tests

## Testing Benefits

### Easy Mocking

```dart
// Create mock service
class MockAppConfig extends AppConfig {
  @override
  Future<String?> getAccessToken() async => 'mock-token';
}

// Use in tests
test('should handle valid token', () {
  // Arrange
  ServiceLocator.registerSingleton<AppConfig>(MockAppConfig());
  
  // Act & Assert
  final businessLogic = BusinessLogic(ServiceLocator.get<AppConfig>());
  // Test with mock...
});
```

### Isolated Testing

```dart
setUp(() async {
  // Reset DI container before each test
  await ServiceLocator.reset();
});

tearDown(() async {
  // Clean up after each test
  await ServiceLocator.reset();
});
```

## Best Practices

### 1. Constructor Injection

**Preferred approach:**
```dart
class BusinessLogic {
  final AppConfig _config;
  final CameraService _camera;
  
  // Constructor injection - easy to test
  BusinessLogic({
    required AppConfig config,
    required CameraService camera,
  }) : _config = config, _camera = camera;
  
  // Factory method for DI
  factory BusinessLogic.fromDI() {
    return BusinessLogic(
      config: ServiceLocator.get<AppConfig>(),
      camera: ServiceLocator.get<CameraService>(),
    );
  }
}
```

### 2. Service Interfaces

```dart
// Define interface
abstract class IApiService {
  Future<String> fetchData();
}

// Implementation
class ApiService implements IApiService {
  @override
  Future<String> fetchData() {
    // Implementation
  }
}

// Mock for testing
class MockApiService implements IApiService {
  @override
  Future<String> fetchData() async => 'mock-data';
}

// Register interface, not implementation
ServiceLocator.registerLazySingleton<IApiService>(() => ApiService());
```

### 3. Avoid Service Locator Anti-pattern

**Avoid:**
```dart
class BadExample {
  void doSomething() {
    // Don't access ServiceLocator directly in business logic
    final config = ServiceLocator.get<AppConfig>();
  }
}
```

**Prefer:**
```dart
class GoodExample {
  final AppConfig _config;
  
  GoodExample(this._config); // Inject dependency
  
  void doSomething() {
    // Use injected dependency
  }
}
```

## Service Lifecycle

### Singleton
- Single instance throughout app lifecycle
- Use for stateful services (caches, connections)

### Lazy Singleton
- Created on first access
- Use for expensive-to-create services

### Factory
- New instance every time
- Use for stateless operations or when fresh state is needed

## Error Handling

```dart
try {
  final service = ServiceLocator.get<MyService>();
  // Use service...
} catch (e) {
  // Handle case where service is not registered
  print('Service not available: $e');
}

// Or check first
if (ServiceLocator.isRegistered<MyService>()) {
  final service = ServiceLocator.get<MyService>();
}
```

## Integration with App Lifecycle

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize DI before running app
  await ServiceLocator.init();
  await ServiceRegistration.registerAllServices();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // App configuration...
    );
  }
  
  @override
  void dispose() {
    // Clean up services when app closes
    ServiceLocator.disposeAll();
    super.dispose();
  }
}
```

## Future Enhancements

- [ ] Add automatic service discovery
- [ ] Implement scoped services
- [ ] Add service health checks
- [ ] Create DI code generation
- [ ] Add performance monitoring

## References

- [get_it package documentation](https://pub.dev/packages/get_it)
- [Dependency Injection patterns in Flutter](https://flutter.dev/docs/development/data-and-backend/state-mgmt/options#dependency-injection)
- [Testing with Dependency Injection](https://flutter.dev/docs/cookbook/testing/unit/mocking) 