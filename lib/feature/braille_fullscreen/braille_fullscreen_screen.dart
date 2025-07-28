import 'package:flutter/material.dart';

import '../../core/domain/braille_code_map.dart';
import '../../core/vibration_notification_service.dart';
import '../../feature/braille_input/braille_symbol.dart';
import 'widgets/braille_text_widget.dart';

class BrailleFullscreenScreen extends StatefulWidget {
  final String sourceText;
  final String sourceTitle;
  final Color themeColor;

  BrailleFullscreenScreen({
    super.key,
    required this.sourceText,
    this.sourceTitle = 'BRAILLE OUTPUT',
    this.themeColor = Colors.white30,
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
    VibrationNotificationService.vibratePattern(
      pattern: [150, 100, 150, 100, 300],
      amplitude: 150,
    );

    // Announce screen entry
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _navigateBack() {
    VibrationNotificationService.vibratePattern(
      pattern: [100, 50, 100],
      amplitude: 100,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          // Full-screen gesture detection following app patterns
          onPanUpdate: (details) {
            const double swipeThreshold = 5.0;

            // Swipe left to go back (consistent with other screens)
            if (details.delta.dx < -swipeThreshold) {
              _navigateBack();
            }
          },
          child: Column(
            children: [
              // Minimal status bar for screen readers
              _buildStatusBar(),

              // Main braille display area (maximized for touch)
              Expanded(child: _buildBrailleDisplayArea()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Source indicator
          Icon(
            Icons.visibility,
            color: Colors.white70,
            size: 16,
            semanticLabel: widget.sourceTitle,
          ),
          const SizedBox(width: 8),

          // Status text
          Expanded(
            child: Text(
              'BRAILLE ACTIVE',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
              semanticsLabel: 'Braille display active',
            ),
          ),

          // Character count
          Text(
            '${widget.sourceText.length} chars',
            style: TextStyle(color: Colors.white70, fontSize: 12),
            semanticsLabel: '${widget.sourceText.length} characters',
          ),
        ],
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
        border: Border.all(color: widget.themeColor.withOpacity(0.3), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: BrailleTextWidget(
        symbolSize: 40.0, // Larger for better touch accessibility
        spacing: 16.0, // More spacing for easier navigation
        symbols: _brailleSymbols,
      ),
    );
  }
}
