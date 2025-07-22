import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'braille_service.dart';
import 'widgets/braille_piano_widget.dart';

class BrailleInputScreen extends StatefulWidget {
  const BrailleInputScreen({super.key});

  @override
  State<BrailleInputScreen> createState() => _BrailleInputScreenState();
}

class _BrailleInputScreenState extends State<BrailleInputScreen> {
  late BrailleService _brailleService;
  String _displayText = '';

  @override
  void initState() {
    super.initState();
    _brailleService = BrailleService();
  }

  void _onTextGenerated(String text) {
    setState(() {
      _displayText = text;
    });
    // Debug: Add haptic feedback when text is generated
    HapticFeedback.lightImpact();
  }

  void _backspace() {
    setState(() {
      _brailleService.backspace();
      _displayText = _brailleService.getDisplayText();
    });
  }

  void _clearAllText() {
    setState(() {
      _brailleService.clearOutput();
      _displayText = _brailleService.getDisplayText();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Text display area (top)
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: () {
                  // Delete functionality - tap anywhere in text area to delete
                  HapticFeedback.heavyImpact();
                  _backspace();
                },
                onLongPress: () {
                  // Clear all text - long press anywhere in text area
                  HapticFeedback.heavyImpact();
                  _clearAllText();
                },
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white30, width: 2),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TEXT OUTPUT',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            'Tap to delete | Long press to clear all',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white54,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              _displayText.isEmpty
                                  ? 'Text appears here...'
                                  : _displayText,
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: 'monospace',
                                color: _displayText.isEmpty
                                    ? Colors.white60
                                    : Colors.white,
                                height: 1.2,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Piano input widget (bottom)
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.all(8),
                child: BraillePianoWidget(
                  brailleService: _brailleService,
                  onTextGenerated: _onTextGenerated,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
