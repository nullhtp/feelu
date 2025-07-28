import 'package:flutter_gemma/flutter_gemma.dart';

import '../core/di/service_locator.dart';
import '../core/interfaces.dart';
import '../core/services/services.dart';

abstract class ILlmAssistantService implements Transformable {}

/// Service class that handles all Gemma AI model operations
class LlmAssistantService implements ILlmAssistantService {
  final IAiModelService _aiModelService = ServiceLocator.get<IAiModelService>();
  final ILoggingService _loggingService = ServiceLocator.get<ILoggingService>();

  @override
  Future<void> dispose() async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<String> transform(dynamic data) async {
    return await sendMessage(data);
  }

  Future<String> sendMessage(String text) async {
    if (text.isEmpty) {
      return '';
    }
    final session = await _aiModelService.createSession();

    try {
      // Create and send the user's message
      text =
          'You are a helpful assistant for a blind person. You should be very short and concise. You should not explain yourself. Final answer should be no more than 10 words. $text';

      final userMessage = Message.text(text: text, isUser: true);
      await session.addQueryChunk(userMessage);

      // Generate and stream the response
      final response = await session.getResponse();
      _loggingService.info('LLM Assistant Response: $response');
      return response;
    } catch (e) {
      throw Exception('Error generating response: $e');
    } finally {
      await session.close();
    }
  }
}
