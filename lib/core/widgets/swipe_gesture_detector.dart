import 'package:flutter/material.dart';

class SwipeGestureDetector extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double minSwipeDistance;
  final double minSwipeVelocity;

  SwipeGestureDetector({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeUp,
    this.onSwipeDown,
    this.onTap,
    this.onLongPress,
    this.minSwipeDistance = 50.0,
    this.minSwipeVelocity = 300.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onPanStart: (details) {
        // Store the start position for calculating swipe distance
        _startPosition = details.globalPosition;
      },
      onPanEnd: (details) {
        if (_startPosition == null) return;

        final endPosition = details.globalPosition;
        final deltaX = endPosition.dx - _startPosition!.dx;
        final deltaY = endPosition.dy - _startPosition!.dy;
        final velocity = details.velocity;

        // Check if the swipe distance and velocity meet the threshold
        if ((deltaX.abs() > minSwipeDistance ||
                deltaY.abs() > minSwipeDistance) &&
            (velocity.pixelsPerSecond.dx.abs() > minSwipeVelocity ||
                velocity.pixelsPerSecond.dy.abs() > minSwipeVelocity)) {
          // Determine swipe direction based on the larger delta
          if (deltaX.abs() > deltaY.abs()) {
            // Horizontal swipe
            if (deltaX < 0 && onSwipeLeft != null) {
              // Swipe left
              onSwipeLeft!();
            } else if (deltaX > 0 && onSwipeRight != null) {
              // Swipe right
              onSwipeRight!();
            }
          } else {
            // Vertical swipe
            if (deltaY < 0 && onSwipeUp != null) {
              // Swipe up
              onSwipeUp!();
            } else if (deltaY > 0 && onSwipeDown != null) {
              // Swipe down
              onSwipeDown!();
            }
          }
        }

        _startPosition = null;
      },
      child: child,
    );
  }

  Offset? _startPosition;
}
