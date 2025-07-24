import 'package:flutter/material.dart';

class StatusIndicatorWidget extends StatelessWidget {
  final bool isListening;
  final bool isProcessing;
  final Animation<double> pulseAnimation;

  const StatusIndicatorWidget({
    super.key,
    required this.isListening,
    required this.isProcessing,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white30, width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SPEECH VIBRO',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                  letterSpacing: 1.2,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Swipe left to return',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Text(
                    'Swipe down to repeat | Swipe up to force listen',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade300,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatusContainer(),
        ],
      ),
    );
  }

  Widget _buildStatusContainer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusColor(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white30, width: 1),
      ),
      child: Row(
        children: [
          Icon(_getStatusIcon(), color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getStatusText(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (isListening) _buildPulsingIndicator(),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (isListening) return Colors.red.shade900;
    if (isProcessing) return Colors.orange.shade900;
    return Colors.green.shade900;
  }

  IconData _getStatusIcon() {
    if (isListening) return Icons.mic;
    if (isProcessing) return Icons.sync;
    return Icons.check_circle;
  }

  String _getStatusText() {
    if (isListening) return 'Listening... Speak now!';
    if (isProcessing) return 'Processing with AI...';
    return 'Ready to listen';
  }

  Widget _buildPulsingIndicator() {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: pulseAnimation.value,
          child: Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
