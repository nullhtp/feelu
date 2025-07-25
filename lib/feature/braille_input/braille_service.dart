import 'package:feelu/core/domain/braille_code_map.dart';
import 'package:feelu/core/vibration_notification_service.dart';

class BrailleService {
  String currentInput = '';
  String firstHalf = '';
  String secondHalf = '';
  List<String> outputText = [];
  bool isFirstHalf = true;

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
  void processKeyInput(bool key1, bool key2, bool key3) {
    String pattern = convertKeysToBraille(key1, key2, key3);

    if (isFirstHalf) {
      firstHalf = pattern;
      isFirstHalf = false;
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
    } else {
      // If pattern not found, add a placeholder
      VibrationNotificationService.vibrateWarning();
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
  String getDisplayText() {
    return outputText.join('');
  }

  /// Get current input state for UI display
  String getCurrentInputState() {
    if (isFirstHalf) {
      return 'Ready for first half';
    } else {
      return 'First: $firstHalf - Ready for second half';
    }
  }

  /// Clear all output
  void clearOutput() {
    outputText.clear();
    _reset();
  }

  /// Remove last character or reset current input
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
