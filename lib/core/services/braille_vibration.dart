import 'dart:async';

import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import '../domain/braille_code_map.dart';

abstract class IBrailleVibrationService {
  Future<void> vibrateBraille(String data);
}

/// Braille Output Service: Converts text to braille and vibrates each symbol
class BrailleVibrationService implements IBrailleVibrationService {
  @override
  Future<void> vibrateBraille(String data) async {
    for (final char in data.toLowerCase().split('')) {
      final braille = charToBraille[char] ?? '000000';
      await _vibrateBrailleSymbol(braille);
    }
  }

  /// Vibrate for a single braille symbol (6 bits)
  Future<void> _vibrateBrailleSymbol(String braille) async {
    if (braille.length != 6) return;
    final firstHalf = braille.substring(0, 3);
    final secondHalf = braille.substring(3, 6);
    await vibrateBrailleHalf(firstHalf);
    // Short pause between halves
    await Future.delayed(const Duration(milliseconds: 500));
    await vibrateBrailleHalf(secondHalf);
  }

  /// Vibrate for a 3-bit half (string of '0'/'1')
  Future<void> vibrateBrailleHalf(String half) async {
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
      3: [255, 200], // 011
      4: [40, 400], // 100
      5: [120, 400], // 101
      6: [255, 400], // 110
      7: [255, 700], // 111
    };
    final pattern = patternMap[bits];
    if (pattern == null) {
      return;
    }

    await Vibration.vibrate(duration: pattern.last, amplitude: pattern.first);
  }
}
