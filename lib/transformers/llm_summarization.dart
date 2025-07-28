import 'package:flutter_gemma/flutter_gemma.dart';

import '../core/di/service_locator.dart';
import '../core/interfaces.dart';
import '../core/services/services.dart';

abstract class ILlmSummarizationService implements Transformable {}

/// Service class that handles text summarization using Gemma AI model
class LlmSummarizationService implements ILlmSummarizationService {
  final IAiModelService _aiModelService = ServiceLocator.get<IAiModelService>();
  final ILoggingService _loggingService = ServiceLocator.get<ILoggingService>();

  @override
  Future<void> dispose() async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<String> transform(dynamic data) async {
    return await summarizeText(data);
  }

  Future<String> summarizeText(String text) async {
    if (text.isEmpty) {
      return '';
    }
    final session = await _aiModelService.createSession();

    try {
      // Create and send the summarization request
      text =
          'You are a helpful speech summarization assistant. Summarize the following text in a very short and concise way, use very basic and short words, you should not explain yourself. Final answer should be less than 10 words. TEXT: "$text"';

      final userMessage = Message.text(text: text, isUser: true);
      await session.addQueryChunk(userMessage);

      // Generate and stream the response
      final response = await session.getResponse();
      _loggingService.info('LLM Summarization Response: $response');
      return response;
    } catch (e) {
      throw Exception('Error generating summarization: $e');
    } finally {
      await session.close();
    }
  }
}
