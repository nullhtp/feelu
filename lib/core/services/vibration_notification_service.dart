import 'package:vibration/vibration.dart';

abstract class IVibrationNotification {
  Future<bool> isAvailable();
  Future<void> vibrateError();
  Future<void> vibrateWarning();
  Future<void> vibrateNotification();
}

class VibrationNotificationService implements IVibrationNotification {
  /// Check if vibration is available on device
  @override
  Future<bool> isAvailable() async {
    return await Vibration.hasVibrator();
  }

  /// Short vibration with low amplitude for first part of braille symbol
  @override
  Future<void> vibrateWarning() async {
    if (await Vibration.hasCustomVibrationsSupport()) {
      // Custom vibration pattern: short burst with low intensity
      await Vibration.vibrate(
        pattern: [100, 100, 200, 200],
        duration: 100, // 100ms duration
        amplitude: 50, // Low amplitude (0-255 scale)
      );
    } else {
      // Fallback to basic vibration
      await Vibration.vibrate(duration: 100);
    }
  }

  @override
  Future<void> vibrateNotification() async {
    await Vibration.vibrate(duration: 100);
  }

  @override
  Future<void> vibrateError() async {
    await Vibration.vibrate(
      pattern: [100, 100, 100, 100, 100, 100, 100, 100, 100, 100],
      amplitude: 100,
    );
  }
}
