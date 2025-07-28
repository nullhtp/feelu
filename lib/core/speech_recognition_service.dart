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
      String lastRecognizedText = '';
      bool hasNewText = false;
      DateTime lastTextTime = DateTime.now();
      bool shouldContinue = true;

      // Start listening for speech with continuous partial results
      await _speechToText.listen(
        onResult: (result) {
          if (kDebugMode) {
            print(
              'Speech recognition result: ${result.recognizedWords}, final: ${result.finalResult}',
            );
          }

          // Update recognized text
          recognizedText = result.recognizedWords;

          // Check if we have new text (text has changed)
          if (recognizedText != lastRecognizedText &&
              recognizedText.isNotEmpty) {
            lastRecognizedText = recognizedText;
            lastTextTime = DateTime.now();
            hasNewText = true;
            if (kDebugMode) {
              print('New text detected, resetting timer');
            }
          }

          // If this is a final result, we're done
          if (result.finalResult && recognizedText.isNotEmpty) {
            shouldContinue = false;
            if (kDebugMode) {
              print('Final result received');
            }
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
          if (kDebugMode) {
            print('3 seconds of silence detected, stopping...');
          }
          break;
        }

        // Safety timeout after 5 minutes
        if (DateTime.now().difference(lastTextTime).inMinutes >= 5) {
          if (kDebugMode) {
            print('5 minute timeout reached');
          }
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
