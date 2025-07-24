import 'package:flutter_gemma/flutter_gemma.dart';

import '../core/gemma_service.dart';
import '../core/interfaces.dart';

/// Service class that handles image recognition using Gemma AI model
class LlmRecognitionService implements Transformable {
  static LlmRecognitionService? _instance;
  static LlmRecognitionService get instance =>
      _instance ??= LlmRecognitionService._();

  LlmRecognitionService._();

  @override
  Future<void> dispose() async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<String> transform(dynamic imageBytes) async {
    // This method should not be used for image recognition
    if (imageBytes.isEmpty) {
      return 'No image provided';
    }

    final session = await GemmaService.instance.createSession();

    try {
      // Create and send the summarization request
      final text =
          'You are a helpful assistant image recognition. You should return the objects from the image. You should not explain yourself. Final answer should be no more than 10 words. Return only objects you are sure about. If you are not sure on any object, return "Empty"';

      final userMessage = Message.withImage(
        text: text,
        imageBytes: imageBytes,
        isUser: true,
      );
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
