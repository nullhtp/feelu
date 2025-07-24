import 'package:flutter/material.dart';

import '../models/service_initialization_state.dart';
import 'service_status_icon.dart';

class CurrentServiceWidget extends StatelessWidget {
  final ServiceInitializationState service;

  const CurrentServiceWidget({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Status icon
        ServiceStatusIcon(status: service.status),
        const SizedBox(height: 24),

        // Service name
        Text(
          service.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        // Description
        Text(
          service.description,
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
          textAlign: TextAlign.center,
        ),

        // Progress bar for downloading
        if (service.progress != null) ...[
          const SizedBox(height: 32),
          SizedBox(
            width: 280,
            child: LinearProgressIndicator(
              value: service.progress,
              backgroundColor: Colors.grey[800],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
        ],
      ],
    );
  }
}
