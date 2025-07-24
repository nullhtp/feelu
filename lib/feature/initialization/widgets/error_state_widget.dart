import 'package:flutter/material.dart';

import '../models/service_initialization_state.dart';

class ErrorStateWidget extends StatelessWidget {
  final ServiceInitializationState service;
  final VoidCallback onRetry;
  final VoidCallback onSkip;

  const ErrorStateWidget({
    super.key,
    required this.service,
    required this.onRetry,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error, color: Colors.red, size: 64),
        const SizedBox(height: 15),
        Text(
          'Initialization Failed: ${service.name}',
          style: const TextStyle(
            color: Colors.red,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Error message
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red[900]?.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[700]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Error: ${service.errorMessage}',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (service.fixInstructions != null) ...[
                const SizedBox(height: 8),
                Text(
                  service.fixInstructions!,
                  style: TextStyle(color: Colors.red[300], fontSize: 14),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Skip',
                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
