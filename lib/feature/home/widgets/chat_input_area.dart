import 'package:flutter/material.dart';

class ChatInputArea extends StatelessWidget {
  final TextEditingController textController;
  final bool isAwaitingResponse;
  final VoidCallback onSendMessage;

  const ChatInputArea({
    super.key,
    required this.textController,
    required this.isAwaitingResponse,
    required this.onSendMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // UI Enhancement: Styled the input area for a cleaner, modern look.
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(13, 0, 0, 0),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: textController,
                      decoration: InputDecoration(
                        hintText: 'Translate this menu...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(Icons.send),
                    onPressed: isAwaitingResponse ? null : onSendMessage,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
