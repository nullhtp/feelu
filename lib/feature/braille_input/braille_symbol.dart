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
