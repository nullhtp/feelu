import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../models/service_initialization_state.dart';

class ErrorStateWidget extends StatelessWidget {
  final ServiceInitializationState service;
  final VoidCallback onRetry;

  const ErrorStateWidget({
    super.key,
    required this.service,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final errorMessage = service.errorMessage ?? l10n.gemmaUnknownError;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error, color: Colors.red, size: 64),
        const SizedBox(height: 15),
        Text(
          l10n.initializationErrorTitle(service.name),
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
                l10n.initializationErrorLabel(errorMessage),
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
                child: Text(
                  l10n.retryButtonLabel,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
