import 'package:flutter/material.dart';

import '../../core/domain/braille_code_map.dart';
import '../../core/domain/braille_symbol.dart';
import '../../core/services/services.dart';
import '../../core/widgets/swipe_gesture_detector.dart';
import 'widgets/braille_text_widget.dart';

class BrailleFullscreenScreen extends StatefulWidget {
  final String sourceText;
  final String sourceTitle;
  final Color themeColor;
  final IBrailleVibrationService brailleVibrationService;

  const BrailleFullscreenScreen({
    super.key,
    required this.sourceText,
    this.sourceTitle = 'BRAILLE OUTPUT',
    this.themeColor = Colors.white30,
    required this.brailleVibrationService,
  });

  @override
  State<BrailleFullscreenScreen> createState() =>
      _BrailleFullscreenScreenState();
}

class _BrailleFullscreenScreenState extends State<BrailleFullscreenScreen> {
  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  List<BrailleSymbol> _brailleSymbols = [];

  @override
  void dispose() {
    super.dispose();
  }

  List<BrailleSymbol> convertToBrailleSymbols(String text) {
    final symbols = <BrailleSymbol>[];

    for (int i = 0; i < text.length; i++) {
      final char = text[i].toLowerCase();
      final brailleCode = charToBraille[char] ?? '000000';
      symbols.add(
        BrailleSymbol(character: char, brailleCode: brailleCode, index: i),
      );
    }

    return symbols;
  }

  Future<void> _initializeScreen() async {
    // Process the text when screen opens
    if (widget.sourceText.isNotEmpty) {
      _brailleSymbols = convertToBrailleSymbols(widget.sourceText);
    }

    // Provide entrance notification
    widget.brailleVibrationService.vibrateBraille('o');

    // Announce screen entry
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _navigateBack() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SwipeGestureDetector(
          // Four-finger swipe navigation for accessibility
          onSwipeDownThreeFingers: _navigateBack,
          child: Column(
            children: [
              // Minimal status bar for screen readers

              // Main braille display area (maximized for touch)
              Expanded(child: _buildBrailleDisplayArea()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrailleDisplayArea() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: BrailleTextWidget(
        symbolSize: 40.0, // Larger for better touch accessibility
        spacing: 16.0, // More spacing for easier navigation
        symbols: _brailleSymbols,
        brailleVibrationService: widget.brailleVibrationService,
      ),
    );
  }
}
