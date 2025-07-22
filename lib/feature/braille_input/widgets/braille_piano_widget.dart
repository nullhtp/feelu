import 'package:flutter/material.dart';

import '../braille_service.dart';
import 'braille_piano_key.dart';

class BraillePianoWidget extends StatefulWidget {
  final BrailleService brailleService;
  final Function(String) onTextGenerated;

  const BraillePianoWidget({
    super.key,
    required this.brailleService,
    required this.onTextGenerated,
  });

  @override
  State<BraillePianoWidget> createState() => _BraillePianoWidgetState();
}

class _BraillePianoWidgetState extends State<BraillePianoWidget> {
  List<bool> _currentKeysPressed = [false, false, false];

  void _handleKeyPress(int keyIndex) {
    setState(() {
      if (keyIndex < 3) {
        _currentKeysPressed[keyIndex] = !_currentKeysPressed[keyIndex];
      }
    });

    // Auto-submit after a longer delay to allow multiple key presses
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted && _currentKeysPressed.any((pressed) => pressed)) {
        _submitCurrentInput();
      }
    });
  }

  void _submitCurrentInput() {
    // Check if any keys are pressed
    if (_currentKeysPressed.any((pressed) => pressed)) {
      widget.brailleService.processKeyInput(
        _currentKeysPressed[0],
        _currentKeysPressed[1],
        _currentKeysPressed[2],
      );

      // Reset key states
      setState(() {
        _currentKeysPressed = [false, false, false];
      });

      widget.onTextGenerated(widget.brailleService.getDisplayText());
    }
  }

  void _handleSpaceKey() {
    widget.brailleService.processSpaceKey();
    widget.onTextGenerated(widget.brailleService.getDisplayText());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white30, width: 2),
      ),
      child: Column(
        children: [
          // Keys layout - 4 keys in horizontal row taking full width
          Expanded(
            child: Row(
              children: [
                // Key 1 (Left dot)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    child: BraillePianoKey(
                      label: 'DOT 1',
                      onPressed: () => _handleKeyPress(0),
                      isPressed: _currentKeysPressed[0],
                      pressedColor: Colors.blue.shade600,
                      keyColor: Colors.grey.shade800,
                      isSpaceKey: false,
                    ),
                  ),
                ),

                // Key 2 (Middle dot)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    child: BraillePianoKey(
                      label: 'DOT 2',
                      onPressed: () => _handleKeyPress(1),
                      isPressed: _currentKeysPressed[1],
                      pressedColor: Colors.green.shade600,
                      keyColor: Colors.grey.shade800,
                      isSpaceKey: false,
                    ),
                  ),
                ),

                // Key 3 (Right dot)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    child: BraillePianoKey(
                      label: 'DOT 3',
                      onPressed: () => _handleKeyPress(2),
                      isPressed: _currentKeysPressed[2],
                      pressedColor: Colors.orange.shade600,
                      keyColor: Colors.grey.shade800,
                      isSpaceKey: false,
                    ),
                  ),
                ),

                // Space key
                Expanded(
                  flex: 2,
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    child: BraillePianoKey(
                      label: 'SPACE',
                      onPressed: _handleSpaceKey,
                      isSpaceKey: false,
                      keyColor: Colors.grey.shade700,
                      pressedColor: Colors.purple.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
