import 'package:speech_to_text/speech_to_text.dart';

import '../di/service_locator.dart';
import 'logging_service.dart';

abstract class ISpeechRecognitionService {
  bool get isInitialized;
  Future<void> initialize();
  Future<String> startListening();
  Future<void> stopListening();
  Future<void> dispose();
}

class SpeechRecognitionService implements ISpeechRecognitionService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  final ILoggingService _loggingService = ServiceLocator.get<ILoggingService>();

  // Getters
  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize() async {
    try {
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          _loggingService.error('Speech recognition error: ${error.errorMsg}');
        },
        onStatus: (status) {
          _loggingService.debug('Speech recognition status: $status');
          if (status == 'done') {
            _isListening = false;
          }
        },
      );

      _loggingService.debug('Speech recognition initialized: $_isInitialized');
    } catch (e) {
      _loggingService.error('Speech recognition initialization error: $e');
      _isInitialized = false;
    }
  }

  @override
  Future<String> startListening() async {
    if (_isListening) {
      _loggingService.error('Already listening');
      return '';
    }

    try {
      _isListening = true;

      String recognizedText = '';
      String lastRecognizedText = '';
      bool hasNewText = false;
      DateTime lastTextTime = DateTime.now();
      bool shouldContinue = true;

      // Start listening for speech with continuous partial results
      await _speechToText.listen(
        onResult: (result) {
          _loggingService.debug(
            'Speech recognition result: ${result.recognizedWords}, final: ${result.finalResult}',
          );

          // Update recognized text
          recognizedText = result.recognizedWords;

          // Check if we have new text (text has changed)
          if (recognizedText != lastRecognizedText &&
              recognizedText.isNotEmpty) {
            lastRecognizedText = recognizedText;
            lastTextTime = DateTime.now();
            hasNewText = true;
            _loggingService.debug('New text detected, resetting timer');
          }

          // If this is a final result, we're done
          if (result.finalResult && recognizedText.isNotEmpty) {
            shouldContinue = false;
            _loggingService.debug('Final result received');
          }
        },
        listenFor: const Duration(minutes: 5), // Extended total time limit
        pauseFor: const Duration(
          seconds: 5,
        ), // Very short pause to get more frequent updates
        localeId: 'en_US',
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
          autoPunctuation: true,
        ),
      );

      // Custom loop to handle 3-second silence detection
      while (shouldContinue) {
        await Future.delayed(const Duration(milliseconds: 500));

        // Check if it's been more than 3 seconds since last text update
        final timeSinceLastText = DateTime.now().difference(lastTextTime);

        if (hasNewText && timeSinceLastText.inSeconds >= 3) {
          _loggingService.debug('3 seconds of silence detected, stopping...');
          break;
        }

        // Safety timeout after 5 minutes
        if (DateTime.now().difference(lastTextTime).inMinutes >= 5) {
          _loggingService.debug('5 minute timeout reached');
          break;
        }
      }

      // Stop listening if still active
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }

      _isListening = false;
      return recognizedText;
    } catch (e) {
      _loggingService.error('Error starting speech recognition: $e');
      _isListening = false;
      return '';
    }
  }

  /// Stop listening
  @override
  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
    }
  }

  @override
  Future<void> dispose() async {
    await stopListening();
  }
}
