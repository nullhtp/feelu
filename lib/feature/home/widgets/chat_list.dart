import 'package:feelu/feature/home/widgets/chat_message_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

class ChatList extends StatelessWidget {
  final List<Message> messages;
  final bool isAwaitingResponse;

  const ChatList({
    super.key,
    required this.messages,
    required this.isAwaitingResponse,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            reverse: true, // Show latest messages at the bottom
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 16.0,
            ),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              // To show messages from bottom to top
              final message = messages[messages.length - 1 - index];
              return ChatMessageWidget(message: message);
            },
          ),
        ),
        if (isAwaitingResponse)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Gemma is thinking...'),
              ],
            ),
          ),
      ],
    );
  }
}
