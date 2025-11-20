import 'dart:ui';

class BrailleAlphabet {
  static final Map<String, Map<String, String>> _patternMaps = {
    'en': _englishBrailleMap,
    'es': _englishBrailleMap,
    'ru': _russianBrailleMap,
  };

  static String _localeKey = 'en';
  static Map<String, String> _currentPatternMap = _englishBrailleMap;
  static Map<String, String> _currentCharMap =
      _buildCharMap(_currentPatternMap);

  static void updateLocale(Locale locale) {
    final key = _patternMaps.containsKey(locale.languageCode)
        ? locale.languageCode
        : 'en';
    if (key == _localeKey) return;

    _localeKey = key;
    _currentPatternMap = _patternMaps[key]!;
    _currentCharMap = _buildCharMap(_currentPatternMap);
  }

  static String? characterForPattern(String pattern) =>
      _currentPatternMap[pattern];

  static String? patternForCharacter(String character) =>
      _currentCharMap[character.toLowerCase()];

  static Map<String, String> get patternMap => _currentPatternMap;
  static Map<String, String> get charMap => _currentCharMap;
}

const Map<String, String> _englishBrailleMap = {
  '100000': 'a',
  '110000': 'b',
  '100100': 'c',
  '100110': 'd',
  '100010': 'e',
  '110100': 'f',
  '110110': 'g',
  '110010': 'h',
  '010100': 'i',
  '010110': 'j',
  '101000': 'k',
  '111000': 'l',
  '101100': 'm',
  '101110': 'n',
  '101010': 'o',
  '111100': 'p',
  '111110': 'q',
  '111010': 'r',
  '011100': 's',
  '011110': 't',
  '101001': 'u',
  '111001': 'v',
  '010111': 'w',
  '101101': 'x',
  '101111': 'y',
  '101011': 'z',
  '000000': ' ',
};

const Map<String, String> _russianBrailleMap = {
  '100000': 'а',
  '110000': 'б',
  '100100': 'ц',
  '100110': 'д',
  '100010': 'е',
  '110100': 'ф',
  '110110': 'г',
  '110010': 'х',
  '010100': 'и',
  '010110': 'й',
  '101000': 'к',
  '111000': 'л',
  '101100': 'м',
  '101110': 'н',
  '101010': 'о',
  '111100': 'п',
  '111110': 'щ',
  '111010': 'р',
  '011100': 'с',
  '011110': 'т',
  '101001': 'у',
  '111001': 'в',
  '010111': 'ж',
  '101101': 'з',
  '101111': 'ч',
  '101011': 'ш',
  '000000': ' ',
  '110111': 'ё',
  '100001': 'ъ',
  '100101': 'ы',
  '100111': 'ь',
  '100011': 'э',
  '110001': 'ю',
  '110101': 'я',
};

Map<String, String> _buildCharMap(Map<String, String> patternMap) => {
      for (final entry in patternMap.entries) entry.value: entry.key,
    };
