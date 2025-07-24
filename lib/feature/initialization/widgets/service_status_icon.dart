import 'package:flutter/material.dart';

import '../models/service_initialization_state.dart';

class ServiceStatusIcon extends StatelessWidget {
  final ServiceStatus status;
  final double size;

  const ServiceStatusIcon({super.key, required this.status, this.size = 48});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case ServiceStatus.pending:
        return Icon(
          Icons.radio_button_unchecked,
          color: Colors.grey[600],
          size: size,
        );
      case ServiceStatus.checking:
      case ServiceStatus.retrying:
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        );
      case ServiceStatus.success:
        return Icon(Icons.check_circle, color: Colors.green, size: size);
      case ServiceStatus.error:
        return Icon(Icons.error, color: Colors.red, size: size);
    }
  }
}
