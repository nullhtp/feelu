import '../core/di/service_locator.dart';
import '../core/interfaces.dart';
import '../core/services/services.dart';

/// Text-to-Speech service for offline speech synthesis
class TtsOutputService implements Outputable {
  final ITtsService _ttsService = ServiceLocator.get<ITtsService>();

  /// Initialize the TTS service
  @override
  Future<bool> initialize() async {
    return true;
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
  }
}
