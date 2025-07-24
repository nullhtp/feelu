import 'package:flutter/material.dart';

class SummarizedOutputWidget extends StatelessWidget {
  final String summarizedText;

  const SummarizedOutputWidget({super.key, required this.summarizedText});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SUMMARIZED OUTPUT',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: SingleChildScrollView(
                child: Text(
                  summarizedText.isEmpty
                      ? 'Summarized text will appear here...'
                      : summarizedText,
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'monospace',
                    color: summarizedText.isEmpty
                        ? Colors.white60
                        : Colors.white,
                    height: 1.2,
                    fontWeight: FontWeight.bold,
                    shadows: const [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 2,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
