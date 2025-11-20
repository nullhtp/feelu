import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

class SuccessStateWidget extends StatelessWidget {
  const SuccessStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 64),
        const SizedBox(height: 24),
        Text(
          l10n.initializationSuccessTitle,
          style: const TextStyle(
            color: Colors.green,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.initializationSuccessSubtitle,
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
        ),
      ],
    );
  }
}
