class BrailleService {
  // Braille code mapping (6-dot system simplified to 3-dot for this implementation)
  static const Map<String, String> brailleMap = {
    '100000': 'a',
    '110000': 'b',
    '101000': 'c',
    '101100': 'd',
    '100100': 'e',
    '111000': 'f',
    '111100': 'g',
    '110100': 'h',
    '011000': 'i',
    '011100': 'j',
    '100010': 'k',
    '110010': 'l',
    '101010': 'm',
    '101110': 'n',
    '100110': 'o',
    '111010': 'p',
    '111110': 'q',
    '110110': 'r',
    '011010': 's',
    '011110': 't',
    '100011': 'u',
    '110011': 'v',
    '011101': 'w',
    '101011': 'x',
    '101111': 'y',
    '100111': 'z',
    '000000': ' ',
  };

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
      outputText.add('?');
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
