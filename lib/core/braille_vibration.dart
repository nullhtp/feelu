import 'dart:async';

import 'package:flutter/services.dart';

import 'domain/braille_code_map.dart';
import 'vibration_notification_service.dart';

/// Braille Output Service: Converts text to braille and vibrates each symbol
class BrailleVibrationService {
  static BrailleVibrationService? _instance;
  static BrailleVibrationService get instance =>
      _instance ??= BrailleVibrationService._();
  BrailleVibrationService._();

  Future<void> vibrateBraille(String data) async {
    for (final char in data.toLowerCase().split('')) {
      final braille = charToBraille[char] ?? '000000';
      await _vibrateBrailleSymbol(braille);
      // Small pause between symbols
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Vibrate for a single braille symbol (6 bits)
  Future<void> _vibrateBrailleSymbol(String braille) async {
    if (braille.length != 6) return;
    final firstHalf = braille.substring(0, 3);
    final secondHalf = braille.substring(3, 6);
    await _vibrateBrailleHalf(firstHalf);
    // Short pause between halves
    await Future.delayed(const Duration(milliseconds: 60));
    await _vibrateBrailleHalf(secondHalf);
  }

  /// Vibrate for a 3-bit half (string of '0'/'1')
  Future<void> _vibrateBrailleHalf(String half) async {
    if (half == '000') {
      // All blank: use HapticFeedback.lightImpact
      await HapticFeedback.lightImpact();
      return;
    }
    // Map each 3-bit pattern to a vibration amplitude and pattern
    final int bits = int.parse(half, radix: 2);
    // Example mapping: (customize as needed)
    final Map<int, List<int>> patternMap = {
      1: [40, 200], // 001
      2: [120, 200], // 010
      3: [250, 200], // 011
      4: [40, 500], // 100
      5: [120, 500], // 101
      6: [250, 500], // 110
      7: [250, 1000], // 111
    };
    final pattern = patternMap[bits];
    if (pattern == null) {
      return;
    }
    // Use VibrationNotificationService for custom vibration
    await VibrationNotificationService.vibrateCustom(
      pattern.first,
      pattern.last,
    );
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
