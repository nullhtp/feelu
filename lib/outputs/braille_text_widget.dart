import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/interfaces.dart';
import '../feature/braille_input/braille_service.dart';
import 'braille_output.dart';

/// Braille Text Widget Output Service: Displays text as touchable braille symbols
class BrailleTextWidgetService implements Outputable {
  static BrailleTextWidgetService? _instance;
  static BrailleTextWidgetService get instance =>
      _instance ??= BrailleTextWidgetService._();
  BrailleTextWidgetService._();

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

  Future<void> vibrateSymbol(String brailleCode) async {
    // Create a single character string to process through the BrailleOutputService
    // Find the character that corresponds to this braille code
    String? character;
    for (final entry in _charToBraille.entries) {
      if (entry.value == brailleCode) {
        character = entry.key;
        break;
      }
    }

    if (character != null) {
      await BrailleOutputService.instance.process(character);
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

/// Widget that displays braille symbols as touchable elements with vertical scrolling
class BrailleTextWidget extends StatefulWidget {
  final BrailleTextWidgetService service;
  final double symbolSize;
  final double spacing;
  final Color activeColor;
  final Color inactiveColor;
  final Color backgroundColor;
  final int symbolsPerRow;

  const BrailleTextWidget({
    super.key,
    required this.service,
    this.symbolSize = 60.0,
    this.spacing = 16.0,
    this.activeColor = Colors.black,
    this.inactiveColor = Colors.grey,
    this.backgroundColor = Colors.white,
    this.symbolsPerRow = 3,
  });

  @override
  State<BrailleTextWidget> createState() => _BrailleTextWidgetState();
}

class _BrailleTextWidgetState extends State<BrailleTextWidget> {
  List<BrailleSymbol> _symbols = [];
  StreamSubscription<List<BrailleSymbol>>? _symbolsSubscription;
  final Map<int, GlobalKey> _symbolKeys = {};
  int? _lastVibratedIndex;
  Timer? _vibrationCooldown;

  @override
  void initState() {
    super.initState();
    _symbolsSubscription = widget.service.symbolsStream.listen((symbols) {
      setState(() {
        _symbols = symbols;
        _updateSymbolKeys();
      });
    });
    // Initialize with current symbols if any
    _symbols = widget.service.currentSymbols;
    _updateSymbolKeys();
  }

  void _updateSymbolKeys() {
    _symbolKeys.clear();
    for (int i = 0; i < _symbols.length; i++) {
      _symbolKeys[i] = GlobalKey();
    }
  }

  @override
  void dispose() {
    _symbolsSubscription?.cancel();
    _vibrationCooldown?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_symbols.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        child: const Center(
          child: Text(
            'No braille text to display',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      color: widget.backgroundColor,
      padding: const EdgeInsets.all(16.0),
      child: GestureDetector(
        onPanUpdate: (details) => _handlePanUpdate(details),
        onPanEnd: (details) => _resetVibrationState(),
        child: SingleChildScrollView(
          child: Wrap(
            spacing: widget.spacing,
            runSpacing: widget.spacing,
            children: _symbols
                .asMap()
                .entries
                .map(
                  (entry) => Container(
                    key: _symbolKeys[entry.key],
                    child: BrailleSymbolWidget(
                      symbol: entry.value,
                      symbolSize: widget.symbolSize,
                      activeColor: widget.activeColor,
                      inactiveColor: widget.inactiveColor,
                      onTap: () => _onSymbolTap(entry.value),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    // Find which symbol is under the current position
    for (int i = 0; i < _symbols.length; i++) {
      final key = _symbolKeys[i];
      if (key?.currentContext != null) {
        final symbolRenderBox =
            key!.currentContext!.findRenderObject() as RenderBox?;
        if (symbolRenderBox != null) {
          final symbolPosition = symbolRenderBox.localToGlobal(Offset.zero);
          final symbolLocalPosition = renderBox.globalToLocal(symbolPosition);

          final symbolRect = Rect.fromLTWH(
            symbolLocalPosition.dx,
            symbolLocalPosition.dy,
            widget.symbolSize,
            widget.symbolSize * 1.5,
          );

          if (symbolRect.contains(localPosition)) {
            _vibrateSymbolOnSlide(i);
            break;
          }
        }
      }
    }
  }

  void _vibrateSymbolOnSlide(int index) {
    // Prevent too frequent vibrations and avoid repeating the same symbol
    if (_lastVibratedIndex == index || _vibrationCooldown?.isActive == true) {
      return;
    }

    _lastVibratedIndex = index;
    _onSymbolTap(_symbols[index]);

    // Set cooldown to prevent spam
    _vibrationCooldown?.cancel();
    _vibrationCooldown = Timer(const Duration(milliseconds: 150), () {
      // Cooldown expired
    });
  }

  void _resetVibrationState() {
    _lastVibratedIndex = null;
    _vibrationCooldown?.cancel();
  }

  Future<void> _onSymbolTap(BrailleSymbol symbol) async {
    // Provide haptic feedback
    await HapticFeedback.mediumImpact();

    // Vibrate the symbol using braille output service
    await widget.service.vibrateSymbol(symbol.brailleCode);
  }
}

/// Widget representing a single braille symbol (6 dots)
class BrailleSymbolWidget extends StatelessWidget {
  final BrailleSymbol symbol;
  final double symbolSize;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const BrailleSymbolWidget({
    super.key,
    required this.symbol,
    required this.symbolSize,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: symbolSize,
        height: symbolSize * 1.5, // Taller to accommodate 3x2 dot layout
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8.0),
          color: Colors.white,
        ),
        child: Stack(
          children: [
            // Character label at the bottom
            Positioned(
              bottom: 4,
              left: 0,
              right: 0,
              child: Text(
                symbol.character == ' ' ? '⎵' : symbol.character,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Braille dots in 3x2 grid layout
            _buildBrailleDots(),
          ],
        ),
      ),
    );
  }

  Widget _buildBrailleDots() {
    final dots = symbol.brailleCode.split('').map((e) => e == '1').toList();
    final dotSize = symbolSize * 0.12;
    final dotSpacing = symbolSize * 0.15;

    return Positioned(
      top: 8,
      left: symbolSize * 0.2,
      child: SizedBox(
        width: symbolSize * 0.6,
        height: symbolSize * 0.8,
        child: Column(
          children: [
            // Top row of dots (positions 1, 4)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDot(dots[0], dotSize), // Position 1
                _buildDot(dots[3], dotSize), // Position 4
              ],
            ),
            SizedBox(height: dotSpacing),
            // Middle row of dots (positions 2, 5)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDot(dots[1], dotSize), // Position 2
                _buildDot(dots[4], dotSize), // Position 5
              ],
            ),
            SizedBox(height: dotSpacing),
            // Bottom row of dots (positions 3, 6)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDot(dots[2], dotSize), // Position 3
                _buildDot(dots[5], dotSize), // Position 6
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(bool isActive, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? activeColor : inactiveColor,
        border: Border.all(
          color: isActive ? activeColor : inactiveColor.withOpacity(0.3),
          width: 1,
        ),
      ),
    );
  }
}
