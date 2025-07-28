import 'package:flutter_gemma/flutter_gemma.dart';

import '../core/di/service_locator.dart';
import '../core/interfaces.dart';
import '../core/services/services.dart';

abstract class ILlmDecodeService implements Transformable {}

/// Service class that handles all Gemma AI model operations
class LlmDecodeService implements ILlmDecodeService {
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
          'Decode the following text you should only return the decoded text without any other text or explanation: $text ';

      final userMessage = Message.text(text: text, isUser: true);
      await session.addQueryChunk(userMessage);

      // Generate and stream the response
      final response = await session.getResponse();
      _loggingService.info('LLM Decode Response: $response');
      return response;
    } catch (e) {
      throw Exception('Error generating response: $e');
    } finally {
      await session.close();
    }
  }
}
