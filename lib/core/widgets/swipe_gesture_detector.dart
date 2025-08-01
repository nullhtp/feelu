import 'dart:math';

import 'package:flutter/material.dart';

class SwipeGestureDetector extends StatefulWidget {
  final Widget child;

  // Single finger swipe callbacks
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;

  // Two finger swipe callbacks
  final VoidCallback? onSwipeLeftTwoFingers;
  final VoidCallback? onSwipeRightTwoFingers;
  final VoidCallback? onSwipeUpTwoFingers;
  final VoidCallback? onSwipeDownTwoFingers;

  // Three finger swipe callbacks
  final VoidCallback? onSwipeLeftThreeFingers;
  final VoidCallback? onSwipeRightThreeFingers;
  final VoidCallback? onSwipeUpThreeFingers;
  final VoidCallback? onSwipeDownThreeFingers;

  // Four finger swipe callbacks
  final VoidCallback? onSwipeLeftFourFingers;
  final VoidCallback? onSwipeRightFourFingers;
  final VoidCallback? onSwipeUpFourFingers;
  final VoidCallback? onSwipeDownFourFingers;

  // Multi-finger tap callbacks
  final VoidCallback? onTap;
  final VoidCallback? onTapTwoFingers;
  final VoidCallback? onTapThreeFingers;
  final VoidCallback? onTapFourFingers;
  final VoidCallback? onLongPress;
  final double minSwipeDistance;
  final double minSwipeVelocity;

  const SwipeGestureDetector({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeUp,
    this.onSwipeDown,
    this.onSwipeLeftTwoFingers,
    this.onSwipeRightTwoFingers,
    this.onSwipeUpTwoFingers,
    this.onSwipeDownTwoFingers,
    this.onSwipeLeftThreeFingers,
    this.onSwipeRightThreeFingers,
    this.onSwipeUpThreeFingers,
    this.onSwipeDownThreeFingers,
    this.onSwipeLeftFourFingers,
    this.onSwipeRightFourFingers,
    this.onSwipeUpFourFingers,
    this.onSwipeDownFourFingers,
    this.onTap,
    this.onTapTwoFingers,
    this.onTapThreeFingers,
    this.onTapFourFingers,
    this.onLongPress,
    this.minSwipeDistance = 50.0,
    this.minSwipeVelocity = 300.0,
  });

  @override
  State<SwipeGestureDetector> createState() => _SwipeGestureDetectorState();
}

class _SwipeGestureDetectorState extends State<SwipeGestureDetector> {
  Offset? _startPosition;
  Offset? _lastPosition;
  DateTime? _gestureStartTime;
  DateTime? _lastMoveTime;
  int _maxFingerCount = 0;
  final Set<int> _activePointers = <int>{};

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        _activePointers.add(event.pointer);
        print(
          'onPointerDown - pointer: ${event.pointer}, total: ${_activePointers.length}',
        );
        // Only set start position if this is the first pointer
        if (_activePointers.length == 1) {
          _startPosition = event.position;
          _lastPosition = event.position;
          _gestureStartTime = DateTime.now();
          _lastMoveTime = DateTime.now();
          _maxFingerCount = 1;
        } else {
          // Update max finger count
          _maxFingerCount = _activePointers.length;
        }
      },
      onPointerMove: (event) {
        // Track movement to calculate velocity later
        if (_startPosition != null) {
          _lastPosition = event.position;
          _lastMoveTime = DateTime.now();
        }
      },
      onPointerUp: (event) {
        print(
          'onPointerUp - pointer: ${event.pointer}, remaining: ${_activePointers.length - 1}',
        );
        _activePointers.remove(event.pointer);

        // Process swipe when all pointers are removed
        if (_activePointers.isEmpty && _startPosition != null) {
          _processSwipeGesture();
        }
      },
      onPointerCancel: (event) {
        print('onPointerCancel - pointer: ${event.pointer}');
        _activePointers.remove(event.pointer);

        // Process swipe when all pointers are removed
        if (_activePointers.isEmpty && _startPosition != null) {
          _processSwipeGesture();
        }
      },
      child: GestureDetector(
        onLongPress: widget.onLongPress,
        behavior: HitTestBehavior.translucent,
        child: widget.child,
      ),
    );
  }

  void _processSwipeGesture() {
    if (_startPosition == null || _lastPosition == null) {
      _resetGestureState();
      return;
    }

    final fingerCount = _maxFingerCount;
    final deltaX = _lastPosition!.dx - _startPosition!.dx;
    final deltaY = _lastPosition!.dy - _startPosition!.dy;
    final distance = sqrt(deltaX * deltaX + deltaY * deltaY);

    // Calculate velocity
    final timeDiff = _lastMoveTime!
        .difference(_gestureStartTime!)
        .inMilliseconds;
    final velocity = timeDiff > 0
        ? (distance / timeDiff) * 1000
        : 0; // pixels per second

    print(
      'Swipe gesture - fingers: $fingerCount, distance: $distance, velocity: $velocity',
    );
    print('Delta X: $deltaX, Delta Y: $deltaY');

    // Check if the swipe distance and velocity meet the threshold
    if (distance > widget.minSwipeDistance &&
        velocity > widget.minSwipeVelocity) {
      // Determine swipe direction based on the larger delta
      if (deltaX.abs() > deltaY.abs()) {
        // Horizontal swipe
        if (deltaX < 0) {
          // Swipe left
          print('Swipe left with $fingerCount fingers');
          _handleSwipeLeft(fingerCount);
        } else {
          // Swipe right
          print('Swipe right with $fingerCount fingers');
          _handleSwipeRight(fingerCount);
        }
      } else {
        // Vertical swipe
        if (deltaY < 0) {
          // Swipe up
          print('Swipe up with $fingerCount fingers');
          _handleSwipeUp(fingerCount);
        } else {
          // Swipe down
          print('Swipe down with $fingerCount fingers');
          _handleSwipeDown(fingerCount);
        }
      }
    } else {
      // Gesture didn't meet swipe threshold, treat as tap
      print(
        'Gesture treated as tap - fingers: $fingerCount, distance: $distance, velocity: $velocity',
      );
      _handleTap(fingerCount);
    }

    _resetGestureState();
  }

  void _resetGestureState() {
    _startPosition = null;
    _lastPosition = null;
    _gestureStartTime = null;
    _lastMoveTime = null;
    _maxFingerCount = 0;
  }

  void _handleTap(int fingerCount) {
    switch (fingerCount) {
      case 1:
        widget.onTap?.call();
        break;
      case 2:
        widget.onTapTwoFingers?.call();
        break;
      case 3:
        widget.onTapThreeFingers?.call();
        break;
      case 4:
        widget.onTapFourFingers?.call();
        break;
    }
  }

  void _handleSwipeLeft(int fingerCount) {
    switch (fingerCount) {
      case 1:
        widget.onSwipeLeft?.call();
        break;
      case 2:
        widget.onSwipeLeftTwoFingers?.call();
        break;
      case 3:
        widget.onSwipeLeftThreeFingers?.call();
        break;
      case 4:
        widget.onSwipeLeftFourFingers?.call();
        break;
    }
  }

  void _handleSwipeRight(int fingerCount) {
    switch (fingerCount) {
      case 1:
        widget.onSwipeRight?.call();
        break;
      case 2:
        widget.onSwipeRightTwoFingers?.call();
        break;
      case 3:
        widget.onSwipeRightThreeFingers?.call();
        break;
      case 4:
        widget.onSwipeRightFourFingers?.call();
        break;
    }
  }

  void _handleSwipeUp(int fingerCount) {
    switch (fingerCount) {
      case 1:
        widget.onSwipeUp?.call();
        break;
      case 2:
        widget.onSwipeUpTwoFingers?.call();
        break;
      case 3:
        widget.onSwipeUpThreeFingers?.call();
        break;
      case 4:
        widget.onSwipeUpFourFingers?.call();
        break;
    }
  }

  void _handleSwipeDown(int fingerCount) {
    switch (fingerCount) {
      case 1:
        widget.onSwipeDown?.call();
        break;
      case 2:
        widget.onSwipeDownTwoFingers?.call();
        break;
      case 3:
        widget.onSwipeDownThreeFingers?.call();
        break;
      case 4:
        widget.onSwipeDownFourFingers?.call();
        break;
    }
  }
}
