import 'package:flutter_gemma/flutter_gemma.dart';

import '../core/gemma_service.dart';
import '../core/interfaces.dart';

/// Service class that handles all Gemma AI model operations
class LlmDecodeService implements Transformable {
  static LlmDecodeService? _instance;
  static LlmDecodeService get instance => _instance ??= LlmDecodeService._();

  LlmDecodeService._();

  @override
  Future<void> dispose() async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<String> transform(String data) async {
    return await sendMessage(data);
  }

  Future<String> sendMessage(String text) async {
    if (text.isEmpty) {
      return '';
    }
    final session = await GemmaService.instance.createSession();

    try {
      // Create and send the user's message

      text =
          'Decode the following text you should only return the decoded text without any other text or explanation: $text ';

      final userMessage = Message.text(text: text, isUser: true);
      await session.addQueryChunk(userMessage);

      // Generate and stream the response
      final response = await session.getResponse();
      print(response);
      return response;
    } catch (e) {
      throw Exception('Error generating response: $e');
    } finally {
      await session.close();
    }
  }
}
