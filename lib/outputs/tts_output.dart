import '../core/di/service_locator.dart';
import '../core/interfaces.dart';
import '../core/services/services.dart';

/// Text-to-Speech service for offline speech synthesis
class TtsOutputService implements Outputable {
  final ITtsService _ttsService = ServiceLocator.get<ITtsService>();
  bool _isInitialized = false;

  /// Initialize the TTS service
  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    final initialized = await _ttsService.initialize();
    if (!initialized) {
      throw Exception('Failed to initialize Text-to-Speech service');
    }
    _isInitialized = true;
  }

  /// Implementation of Outputable interface - processes text for speech output
  @override
  Future<void> process(String data) async {
    await _ttsService.speak(data);
  }

  /// Dispose of the service
  @override
  Future<void> dispose() async {
    await _ttsService.stop();
    _isInitialized = false;
  }
}
