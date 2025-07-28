import 'package:flutter/material.dart';

class BraillePianoKey extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isPressed;
  final Color keyColor;
  final Color pressedColor;
  final bool isSpaceKey;

  const BraillePianoKey({
    super.key,
    required this.label,
    required this.onPressed,
    this.isPressed = false,
    this.keyColor = Colors.white,
    this.pressedColor = Colors.blue,
    this.isSpaceKey = false,
  });

  @override
  State<BraillePianoKey> createState() => _BraillePianoKeyState();
}

class _BraillePianoKeyState extends State<BraillePianoKey>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isCurrentlyPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isCurrentlyPressed = true;
    });
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isCurrentlyPressed = false;
    });
    _animationController.reverse();
    widget.onPressed();
  }

  void _handleTapCancel() {
    setState(() {
      _isCurrentlyPressed = false;
    });
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Semantics(
            label: '${widget.label} key',
            hint: 'Tap to input braille dot',
            child: GestureDetector(
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: _isCurrentlyPressed || widget.isPressed
                      ? widget.pressedColor
                      : widget.keyColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white30, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                    if (_isCurrentlyPressed || widget.isPressed)
                      BoxShadow(
                        color: widget.pressedColor.withOpacity(0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: _isCurrentlyPressed || widget.isPressed
                              ? Colors.white
                              : Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
