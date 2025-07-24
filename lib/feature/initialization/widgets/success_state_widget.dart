import 'package:flutter/material.dart';

class SuccessStateWidget extends StatelessWidget {
  const SuccessStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 64),
        const SizedBox(height: 24),
        const Text(
          'All Services Ready!',
          style: TextStyle(
            color: Colors.green,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Launching Braille Interface...',
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
        ),
      ],
    );
  }
}
