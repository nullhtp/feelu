import 'package:flutter/material.dart';

import '../../../../core/widgets/icon_paths.dart';
import '../../../../core/widgets/icon_text_widget.dart';

class StatusIndicatorWidget extends StatelessWidget {
  final bool isListening;
  final bool isProcessing;

  const StatusIndicatorWidget({
    super.key,
    required this.isListening,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    return Center(child: _buildIconTextWidget());
  }

  Widget _buildIconTextWidget() {
    if (isListening) {
      // Green ear icon when listening
      return IconTextWidget(
        svgIcon: IconPaths.ear,
        text: 'Listening...',
        iconColor: Colors.green,
        textColor: Colors.green,
      );
    } else if (isProcessing) {
      // Gemma-3n icon when summarizing
      return IconTextWidget(
        imageIcon: IconPaths.gemma3n,
        text: 'Summarizing...',
        textColor: Colors.white,
      );
    } else {
      // Muted ear icon when ready
      return IconTextWidget(
        svgIcon: IconPaths.ear,
        text: 'Tap to listen',
        iconColor: Colors.grey,
        textColor: Colors.grey,
      );
    }
  }
}
