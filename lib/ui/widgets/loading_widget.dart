import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final String loadingMessage;
  final double? downloadProgress;

  const LoadingWidget({
    super.key,
    required this.loadingMessage,
    this.downloadProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            loadingMessage,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          if (downloadProgress != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 16.0,
              ),
              child: LinearProgressIndicator(value: downloadProgress),
            ),
        ],
      ),
    );
  }
}
