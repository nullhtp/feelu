import 'package:flutter_gemma/flutter_gemma.dart';

import '../core/gemma_service.dart';
import '../core/interfaces.dart';

/// Service class that handles text summarization using Gemma AI model
class LlmSummarizationService implements Transformable {
  static LlmSummarizationService? _instance;
  static LlmSummarizationService get instance =>
      _instance ??= LlmSummarizationService._();

  LlmSummarizationService._();

  @override
  Future<void> dispose() async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<String> transform(String data) async {
    return await summarizeText(data);
  }

  Future<String> summarizeText(String text) async {
    if (text.isEmpty) {
      return '';
    }
    final session = await GemmaService.instance.createSession();

    try {
      // Create and send the summarization request
      text =
          'You are a helpful assistant for morse code text preparation. Summarize the following text in a very short and concise way, use very basic and short words, you should not explain yourself. Final answer should be less than 10 words. TEXT: "$text"';

      final userMessage = Message.text(text: text, isUser: true);
      await session.addQueryChunk(userMessage);

      // Generate and stream the response
      final response = await session.getResponse();
      print('Summarization response: $response');
      return response;
    } catch (e) {
      throw Exception('Error generating summarization: $e');
    } finally {
      await session.close();
    }
  }
}
