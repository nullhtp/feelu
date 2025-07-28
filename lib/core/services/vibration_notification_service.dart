import 'package:vibration/vibration.dart';

abstract class IVibrationNotification {
  Future<bool> isAvailable();
  Future<void> vibrateCustom(int amplitude, int duration);
  Future<void> vibrateError();
  Future<void> vibrateWarning();
  Future<void> vibrateNotification();
  Future<void> vibratePattern({
    required List<int> pattern,
    int amplitude = 128,
  });
  Future<void> cancel();
}

class VibrationNotificationService implements IVibrationNotification {
  /// Check if vibration is available on device
  @override
  Future<bool> isAvailable() async {
    return await Vibration.hasVibrator();
  }

  /// Short vibration with low amplitude for first part of braille symbol
  Future<void> vibrateWarning() async {
    final hasVibrator = await isAvailable();
    if (!hasVibrator) return;

    // Check if custom vibration is supported
    final hasCustomVibrator = await Vibration.hasCustomVibrationsSupport();

    if (hasCustomVibrator) {
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

  Future<void> vibrateNotification() async {
    final hasVibrator = await isAvailable();
    if (!hasVibrator) return;
    await Vibration.vibrate(duration: 100);
  }

  Future<void> vibrateError() async {
    final hasVibrator = await isAvailable();
    if (!hasVibrator) return;
    await Vibration.vibrate(
      pattern: [100, 100, 100, 100, 100, 100, 100, 100, 100, 100],
      amplitude: 100,
    );
  }

  /// Custom vibration with amplitude and duration
  Future<void> vibrateCustom(int amplitude, int duration) async {
    final hasVibrator = await isAvailable();
    if (!hasVibrator) return;
    final hasCustomVibrator = await Vibration.hasCustomVibrationsSupport();
    if (hasCustomVibrator) {
      await Vibration.vibrate(duration: duration, amplitude: amplitude);
    } else {
      await Vibration.vibrate(duration: duration);
    }
  }

  /// Stop any ongoing vibration
  Future<void> cancel() async {
    await Vibration.cancel();
  }

  /// Flexible vibration pattern function
  Future<void> vibratePattern({
    required List<int> pattern,
    int amplitude = 128,
  }) async {
    final hasVibrator = await isAvailable();
    if (!hasVibrator) return;

    final hasCustomVibrator = await Vibration.hasCustomVibrationsSupport();

    if (hasCustomVibrator) {
      await Vibration.vibrate(pattern: pattern, amplitude: amplitude);
    } else {
      // Fallback: use the first duration from pattern or default to 200ms
      final duration = pattern.isNotEmpty ? pattern.first : 200;
      await Vibration.vibrate(duration: duration);
    }
  }
}
