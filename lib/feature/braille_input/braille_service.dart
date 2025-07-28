import 'package:feelu/core/domain/braille_code_map.dart';
import 'package:flutter/services.dart';

import '../../core/di/service_locator.dart';
import '../../core/services/services.dart';

abstract class IBrailleService {
  void processKeyInput(bool key1, bool key2, bool key3);
  void backspace();
  void clearOutput();
  String getDisplayText();
}

class BrailleService implements IBrailleService {
  String currentInput = '';
  String firstHalf = '';
  String secondHalf = '';
  List<String> outputText = [];
  bool isFirstHalf = true;
  final IBrailleVibrationService _brailleVibrationService =
      ServiceLocator.get<IBrailleVibrationService>();
  final ILoggingService _loggingService = ServiceLocator.get<ILoggingService>();

  /// Convert 3-key input to half braille pattern
  String convertKeysToBraille(bool key1, bool key2, bool key3) {
    return '${key1 ? '1' : '0'}${key2 ? '1' : '0'}${key3 ? '1' : '0'}';
  }

  /// Process input from the 4th key (space)
  void processSpaceKey() {
    if (isFirstHalf) {
      firstHalf = '000';
      isFirstHalf = false;
    } else {
      secondHalf = '000';
      _processCompleteBraille();
    }
  }

  /// Process input from the 3 main keys
  @override
  void processKeyInput(bool key1, bool key2, bool key3) {
    String pattern = convertKeysToBraille(key1, key2, key3);

    if (isFirstHalf) {
      firstHalf = pattern;
      isFirstHalf = false;
      HapticFeedback.heavyImpact();
    } else {
      secondHalf = pattern;
      _processCompleteBraille();
    }
  }

  /// Combine two halves and convert to character
  void _processCompleteBraille() {
    String fullPattern = firstHalf + secondHalf;
    String? character = brailleMap[fullPattern];

    if (character != null) {
      outputText.add(character);
      _brailleVibrationService.vibrateBraille(character);
    } else {
      // If pattern not found, add a placeholder
      _loggingService.warning('Braille pattern not found: $fullPattern');
    }

    // Reset for next input
    _reset();
  }

  /// Reset input state
  void _reset() {
    firstHalf = '';
    secondHalf = '';
    isFirstHalf = true;
  }

  /// Get current display text
  @override
  String getDisplayText() {
    return outputText.join('');
  }

  /// Clear all output
  @override
  void clearOutput() {
    outputText.clear();
    _reset();
  }

  /// Remove last character or reset current input
  @override
  void backspace() {
    if (!isFirstHalf && (firstHalf.isNotEmpty || secondHalf.isNotEmpty)) {
      // If we're in the middle of input, reset current input
      _reset();
    } else if (outputText.isNotEmpty) {
      // Remove last character
      outputText.removeLast();
      _reset();
    }
  }
}
