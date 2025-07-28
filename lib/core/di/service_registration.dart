import '../../feature/initialization/initialization_service.dart';
import '../../feature/photo_vibro/photo_vibro_service.dart';
import '../../feature/speech_vibro/speech_vibro_service.dart';
import '../../outputs/tts.dart';
import '../../transformers/llm_assistant.dart';
import '../../transformers/llm_decode.dart';
import '../../transformers/llm_recognition.dart';
import '../../transformers/llm_summarization.dart';
import '../camera_service.dart';
import '../config.dart';
import '../config/app_config.dart';
import '../gemma_service.dart';
import '../services/logging_service.dart';
import '../speech_recognition_service.dart';
import 'service_locator.dart';

/// Service Registration Helper
///
/// This class handles the registration of existing singleton services
/// with the dependency injection container, allowing for gradual migration.
class ServiceRegistration {
  /// Register all available services with the DI container
  static Future<void> registerAllServices() async {
    await registerCoreServices();
    await registerTransformerServices();
    await registerFeatureServices();
    await registerOutputServices();
  }

  /// Register core services
  static Future<void> registerCoreServices() async {
    // Legacy Config service (for backwards compatibility)
    ServiceLocator.registerLazySingleton<Config>(() => Config.instance);

    // New AppConfig service (DI-friendly)
    ServiceLocator.registerLazySingleton<AppConfig>(() => AppConfig());

    // Logging service (interface-based DI)
    ServiceLocator.registerLazySingleton<ILoggingService>(
      () => LoggingService(),
    );

    // Camera service
    ServiceLocator.registerLazySingleton<CameraService>(
      () => CameraService.instance,
    );

    // Speech recognition service
    ServiceLocator.registerLazySingleton<SpeechRecognitionService>(
      () => SpeechRecognitionService.instance,
    );

    // Gemma AI service
    ServiceLocator.registerLazySingleton<GemmaService>(
      () => GemmaService.instance,
    );
  }

  /// Register transformer services
  static Future<void> registerTransformerServices() async {
    // LLM Assistant service
    ServiceLocator.registerLazySingleton<LlmAssistantService>(
      () => LlmAssistantService.instance,
    );

    // LLM Decode service
    ServiceLocator.registerLazySingleton<LlmDecodeService>(
      () => LlmDecodeService.instance,
    );

    // LLM Recognition service
    ServiceLocator.registerLazySingleton<LlmRecognitionService>(
      () => LlmRecognitionService.instance,
    );

    // LLM Summarization service
    ServiceLocator.registerLazySingleton<LlmSummarizationService>(
      () => LlmSummarizationService.instance,
    );
  }

  /// Register feature services
  static Future<void> registerFeatureServices() async {
    // Initialization service
    ServiceLocator.registerLazySingleton<InitializationService>(
      () => InitializationService.instance,
    );

    // Speech vibro service
    ServiceLocator.registerLazySingleton<SpeechVibroService>(
      () => SpeechVibroService.instance,
    );

    // Photo vibro service
    ServiceLocator.registerLazySingleton<PhotoVibroService>(
      () => PhotoVibroService.instance,
    );
  }

  /// Register output services
  static Future<void> registerOutputServices() async {
    // TTS service
    ServiceLocator.registerLazySingleton<TtsService>(() => TtsService.instance);
  }

  /// Convenience method to check if all core services are registered
  static bool areAllCoreServicesRegistered() {
    return ServiceLocator.isRegistered<Config>() &&
        ServiceLocator.isRegistered<AppConfig>() &&
        ServiceLocator.isRegistered<ILoggingService>() &&
        ServiceLocator.isRegistered<CameraService>() &&
        ServiceLocator.isRegistered<SpeechRecognitionService>() &&
        ServiceLocator.isRegistered<GemmaService>();
  }

  /// Convenience method to check if all transformer services are registered
  static bool areAllTransformerServicesRegistered() {
    return ServiceLocator.isRegistered<LlmAssistantService>() &&
        ServiceLocator.isRegistered<LlmDecodeService>() &&
        ServiceLocator.isRegistered<LlmRecognitionService>() &&
        ServiceLocator.isRegistered<LlmSummarizationService>();
  }
}
