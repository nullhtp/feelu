import 'package:flutter/material.dart';

class PhotoVibroGestureDetector extends StatelessWidget {
  final Widget child;
  final VoidCallback onSwipeRight;
  final VoidCallback onSwipeDown;
  final VoidCallback onTap;

  const PhotoVibroGestureDetector({
    super.key,
    required this.child,
    required this.onSwipeRight,
    required this.onSwipeDown,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onPanUpdate: (details) {
        const double swipeThreshold = 5.0;

        // Swipe right to return to braille input
        if (details.delta.dx > swipeThreshold) {
          onSwipeRight();
        }
        // Swipe down to repeat last result
        else if (details.delta.dy > swipeThreshold) {
          onSwipeDown();
        }
      },
      child: child,
    );
  }
}
