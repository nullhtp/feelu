import 'package:vibration/vibration.dart';

class VibrationService {
  /// Check if vibration is available on device
  static Future<bool> isAvailable() async {
    return await Vibration.hasVibrator();
  }

  /// Short vibration with low amplitude for first part of braille symbol
  static Future<void> vibrateWarning() async {
    final hasVibrator = await isAvailable();
    if (!hasVibrator) return;

    // Check if custom vibration is supported
    final hasCustomVibrator = await Vibration.hasCustomVibrationsSupport();

    if (hasCustomVibrator) {
      // Custom vibration pattern: short burst with low intensity
      await Vibration.vibrate(
        pattern: [100, 100, 100, 100],
        duration: 100, // 100ms duration
        amplitude: 50, // Low amplitude (0-255 scale)
      );
    } else {
      // Fallback to basic vibration
      await Vibration.vibrate(duration: 100);
    }
  }

  /// Stop any ongoing vibration
  static Future<void> cancel() async {
    await Vibration.cancel();
  }
}
