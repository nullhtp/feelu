import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechRecognitionService {
  static SpeechRecognitionService? _instance;
  static SpeechRecognitionService get instance =>
      _instance ??= SpeechRecognitionService._();

  SpeechRecognitionService._();

  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;

  Future<void> initialize() async {
    try {
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          if (kDebugMode) {
            print('Speech recognition error: ${error.errorMsg}');
          }
        },
        onStatus: (status) {
          if (kDebugMode) {
            print('Speech recognition status: $status');
          }
          if (status == 'done') {
            _isListening = false;
          }
        },
      );

      if (kDebugMode) {
        print('Speech recognition initialized: $_isInitialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Speech recognition initialization error: $e');
      }
      _isInitialized = false;
    }
  }

  Future<String> startListening() async {
    if (_isListening) {
      if (kDebugMode) {
        print('Already listening');
      }
      return '';
    }

    try {
      _isListening = true;

      String recognizedText = '';
      bool isComplete = false;

      // Start listening for speech
      await _speechToText.listen(
        onResult: (result) {
          if (kDebugMode) {
            print('Speech recognition result: ${result.recognizedWords}');
          }
          recognizedText = result.recognizedWords;
          if (result.finalResult) {
            isComplete = true;
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
        listenOptions: SpeechListenOptions(
          partialResults: false,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
        ),
      );

      // Wait for completion or timeout
      int timeout = 0;
      while (!isComplete && timeout < 30) {
        await Future.delayed(const Duration(seconds: 1));
        timeout++;
      }

      // Stop listening if still active
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }

      _isListening = false;
      return recognizedText;
    } catch (e) {
      if (kDebugMode) {
        print('Error starting speech recognition: $e');
      }
      _isListening = false;
      return '';
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
    }
  }

  /// Check if speech recognition is available
  Future<bool> isAvailable() async {
    return _isInitialized;
  }

  Future<void> dispose() async {
    await stopListening();
  }
}
