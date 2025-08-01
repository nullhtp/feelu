import 'package:flutter/material.dart';

import 'braille_piano_key.dart';

class BraillePianoWidget extends StatefulWidget {
  final Function(bool, bool, bool) onSubmitInput;

  const BraillePianoWidget({super.key, required this.onSubmitInput});

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
        widget.onSubmitInput(
          _currentKeysPressed[0],
          _currentKeysPressed[1],
          _currentKeysPressed[2],
        );
      }

      setState(() {
        _currentKeysPressed = [false, false, false];
      });
    });
  }

  void _handleSpaceKey() {
    widget.onSubmitInput(false, false, false);
    setState(() {
      _currentKeysPressed = [false, false, false];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
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
