import 'package:flutter/material.dart';

import '../models/service_initialization_state.dart';

class ServiceStepIndicator extends StatelessWidget {
  final List<ServiceInitializationState> services;
  final int currentIndex;

  const ServiceStepIndicator({
    super.key,
    required this.services,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < services.length; i++) ...[
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getStepColor(i),
            ),
          ),
          if (i < services.length - 1)
            Container(
              width: 40,
              height: 2,
              color: i < currentIndex ? Colors.green : Colors.grey[700],
            ),
        ],
      ],
    );
  }

  Color _getStepColor(int index) {
    if (index < currentIndex) {
      return Colors.green;
    } else if (index == currentIndex) {
      return Colors.blue;
    } else {
      return Colors.grey[700]!;
    }
  }
}
