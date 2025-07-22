import 'package:flutter_gemma/core/chat.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import '../core/gemma_service.dart';
import '../core/interfaces.dart';

/// Service class that handles all Gemma AI model operations
class LlmDecodeService implements Transformable {
  static LlmDecodeService? _instance;
  static LlmDecodeService get instance => _instance ??= LlmDecodeService._();

  LlmDecodeService._();

  InferenceChat? _chat;
  @override
  Future<void> initialize() async {
    GemmaService.instance.initialize();
    _chat = await GemmaService.instance.createChat(
      supportImage: true,
      temperature: 0,
    );
  }

  @override
  Future<String> transform(String data) async {
    return await sendMessage(data);
  }

  Future<String> sendMessage(String text) async {
    if (_chat == null) {
      throw Exception('Model not initialized');
    }

    if (text.isEmpty) {
      return '';
    }

    try {
      // Create and send the user's message

      text =
          'Decode the following text you should only return the decoded text without any other text or explanation: $text';

      final userMessage = Message.text(text: text, isUser: true);
      await _chat!.addQueryChunk(userMessage);

      // Generate and stream the response
      final response = await _chat!.generateChatResponse();
      print(response);
      return response;
    } catch (e) {
      throw Exception('Error generating response: $e');
    }
  }
}
