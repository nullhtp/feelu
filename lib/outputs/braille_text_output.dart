import 'dart:async';

import '../core/braille_vibration.dart';
import '../core/interfaces.dart';
import '../feature/braille_input/braille_service.dart';

class BrailleTextOutputService implements Outputable {
  static BrailleTextOutputService? _instance;
  static BrailleTextOutputService get instance =>
      _instance ??= BrailleTextOutputService._();
  BrailleTextOutputService._();

  // Braille mapping: char -> 6-bit string
  static final Map<String, String> _charToBraille = {
    for (final entry in BrailleService.brailleMap.entries)
      entry.value: entry.key,
  };

  final StreamController<List<BrailleSymbol>> _symbolsController =
      StreamController<List<BrailleSymbol>>.broadcast();

  Stream<List<BrailleSymbol>> get symbolsStream => _symbolsController.stream;
  List<BrailleSymbol> _currentSymbols = [];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> process(String data) async {
    final symbols = <BrailleSymbol>[];

    for (int i = 0; i < data.length; i++) {
      final char = data[i].toLowerCase();
      final brailleCode = _charToBraille[char] ?? '000000';
      symbols.add(
        BrailleSymbol(character: char, brailleCode: brailleCode, index: i),
      );
    }

    _currentSymbols = symbols;
    _symbolsController.add(symbols);
  }

  Future<void> vibrateSymbol(String? character) async {
    if (character != null) {
      await BrailleOutputService.instance.vibrateBraille(character);
    }
  }

  List<BrailleSymbol> get currentSymbols => _currentSymbols;

  @override
  Future<void> dispose() async {
    await _symbolsController.close();
  }
}

/// Represents a single braille symbol with its character and code
class BrailleSymbol {
  final String character;
  final String brailleCode;
  final int index;

  BrailleSymbol({
    required this.character,
    required this.brailleCode,
    required this.index,
  });
}
