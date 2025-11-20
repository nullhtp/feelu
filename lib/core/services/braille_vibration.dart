import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
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
      final braille = BrailleAlphabet.patternForCharacter(char) ?? '000000';
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

class BrailleAudioService implements IBrailleVibrationService {
  BrailleAudioService() {
    _init(); // fire-and-forget; no await needed here
  }

  static const _beepAsset =
      'audio/beep.wav'; // path relative to pubspec asset list
  final AudioPlayer _player = AudioPlayer();

  bool _ready = false;

  Future<void> _init() async {
    // Pre-cache once so later playbacks have zero lag
    await _player.setSource(AssetSource(_beepAsset));
    await _player.setReleaseMode(ReleaseMode.stop);
    _ready = true;
  }

  @override
  Future<void> vibrateBraille(String data) async {
    for (final char in data.toLowerCase().split('')) {
      final braille = BrailleAlphabet.patternForCharacter(char) ?? '000000';
      await _playBrailleSymbol(braille);
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> _playBrailleSymbol(String braille) async {
    if (braille.length != 6) return;
    await _playBrailleHalf(braille.substring(0, 3));
    await Future.delayed(const Duration(milliseconds: 60));
    await _playBrailleHalf(braille.substring(3, 6));
  }

  Future<void> _playBrailleHalf(String half) async {
    // 000 → quiet click so timing stays consistent
    if (half == '000') {
      await _playBeep(volume: 0.2, duration: 60);
      return;
    }
    const map = <int, List<int>>{
      1: [40, 200],
      2: [120, 200],
      3: [255, 200],
      4: [40, 500],
      5: [120, 500],
      6: [255, 500],
      7: [255, 1000],
    };

    final bits = int.parse(half, radix: 2);
    final pattern = map[bits];
    if (pattern == null) return;

    await _playBeep(
      volume: pattern[0] / 255.0, // to 0-1
      duration: pattern[1],
    );
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _playBeep({
    required double volume,
    required int duration,
  }) async {
    if (!_ready) await _init();

    await _player.setVolume(volume.clamp(0.0, 1.0));
    await _player.seek(Duration.zero); // rewind
    await _player.resume(); // play
    await Future.delayed(Duration(milliseconds: duration));
    await _player.pause(); // DON’T stop → keeps buffer in RAM
  }

  Future<void> dispose() => _player.dispose();
}
