import '../../feature/braille_input/braille_service.dart';
import '../../feature/initialization/initialization_service.dart';
import '../../feature/photo_vibro/photo_vibro_service.dart';
import '../../feature/speech_vibro/speech_vibro_service.dart';
import '../../transformers/transformers.dart';
import '../config/app_config.dart';
import '../services/services.dart';
import 'service_locator.dart';

/// Service Registration Helper
///
/// This class handles the registration of existing singleton services
/// with the dependency injection container, allowing for gradual migration.
class ServiceRegistration {
  /// Register all available services with the DI container
  static Future<void> registerAllServices() async {
    await registerCoreServices();
    await registerTransformers();
    await registerFeatureServices();
  }

  /// Register core services
  static Future<void> registerCoreServices() async {
    // Braille vibration service
    ServiceLocator.registerLazySingleton<IBrailleVibrationService>(
      () => BrailleVibrationService(),
    );

    // New AppConfig service (DI-friendly)
    ServiceLocator.registerLazySingleton<AppConfig>(() => AppConfig());

    // Logging service (interface-based DI)
    ServiceLocator.registerLazySingleton<ILoggingService>(
      () => LoggingService(),
    );

    // Camera service
    ServiceLocator.registerLazySingleton<ICameraService>(() => CameraService());

    // Speech recognition service
    ServiceLocator.registerLazySingleton<ISpeechRecognitionService>(
      () => SpeechRecognitionService(),
    );

    // Gemma AI service
    ServiceLocator.registerLazySingleton<IAiModelService>(() => GemmaService());

    // Vibration notification service
    ServiceLocator.registerLazySingleton<IVibrationNotification>(
      () => VibrationNotificationService(),
    );

    ServiceLocator.registerLazySingleton<ITtsService>(() => TtsService());
  }

  static Future<void> registerTransformers() async {
    ServiceLocator.registerLazySingleton<ILlmAssistantService>(
      () => LlmAssistantService(),
    );
    ServiceLocator.registerLazySingleton<ILlmDecodeService>(
      () => LlmDecodeService(),
    );
    ServiceLocator.registerLazySingleton<ILlmRecognitionService>(
      () => LlmRecognitionService(),
    );
    ServiceLocator.registerLazySingleton<ILlmSummarizationService>(
      () => LlmSummarizationService(),
    );
  }

  static Future<void> registerFeatureServices() async {
    ServiceLocator.registerLazySingleton<IBrailleService>(
      () => BrailleService(),
    );
    ServiceLocator.registerLazySingleton<IPhotoVibroService>(
      () => PhotoVibroService(),
    );
    ServiceLocator.registerLazySingleton<ISpeechVibroService>(
      () => SpeechVibroService(),
    );
    ServiceLocator.registerLazySingleton<IInitializationService>(
      () => InitializationService(),
    );
  }
}
