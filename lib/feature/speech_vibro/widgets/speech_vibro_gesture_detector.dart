import 'package:flutter/material.dart';

class SpeechVibroGestureDetector extends StatelessWidget {
  final Widget child;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeDown;
  final VoidCallback onSwipeUp;

  const SpeechVibroGestureDetector({
    super.key,
    required this.child,
    required this.onSwipeLeft,
    required this.onSwipeDown,
    required this.onSwipeUp,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        const double swipeThreshold = 5.0;

        // Swipe left to return to braille input
        if (details.delta.dx < -swipeThreshold) {
          onSwipeLeft();
        }
        // Swipe down to repeat last message
        else if (details.delta.dy > swipeThreshold) {
          onSwipeDown();
        }
        // Swipe up to force listen
        else if (details.delta.dy < -swipeThreshold) {
          onSwipeUp();
        }
      },
      child: child,
    );
  }
}
