import 'dart:async';

import 'package:feelu/core/interfaces.dart';
import 'package:feelu/core/speech_recognition_service.dart';
import 'package:feelu/core/vibration_notification_service.dart';
import 'package:feelu/outputs/braille_text_output.dart';
import 'package:feelu/transformers/llm_summarization.dart';
import 'package:flutter/material.dart';

enum SpeechVibroState { ready, listening, processing }

class SpeechVibroService {
  static final SpeechVibroService _instance = SpeechVibroService._internal();
  static SpeechVibroService get instance => _instance;
  SpeechVibroService._internal();

  final SpeechRecognitionService _speechRecognitionService =
      SpeechRecognitionService.instance;
  late BrailleTextOutputService _brailleTextService;

  late Pipeline _summarizationPipeline;

  final StreamController<String> _summarizedTextController =
      StreamController<String>.broadcast();
  final StreamController<SpeechVibroState> _stateController =
      StreamController<SpeechVibroState>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  Stream<String> get summarizedTextStream => _summarizedTextController.stream;
  Stream<SpeechVibroState> get stateStream => _stateController.stream;
  Stream<String> get errorStream => _errorController.stream;

  SpeechVibroState _currentState = SpeechVibroState.ready;
  String _lastMessage = '';
  StreamSubscription<String>? _transformedDataSubscription;

  SpeechVibroState get currentState => _currentState;
  String get lastMessage => _lastMessage;
  BrailleTextOutputService get brailleTextService => _brailleTextService;

  Future<void> initialize(BuildContext context) async {
    try {
      await _speechRecognitionService.initialize();
      _brailleTextService = BrailleTextOutputService(context: context);
      _summarizationPipeline = Pipeline(
        transformable: LlmSummarizationService.instance,
        outputable: _brailleTextService,
      );
      _subscribeToTransformedData();

      await _summarizationPipeline.initialize();

      // Notify user they've entered speech vibro mode with wave-like pattern
      VibrationNotificationService.vibratePattern(
        pattern: [100, 50, 100, 50, 100, 50, 100, 50, 100],
        amplitude: 100,
      );
    } catch (e) {
      _errorController.add('Failed to initialize services: ${e.toString()}');
      throw e;
    }
  }

  void _subscribeToTransformedData() {
    _transformedDataSubscription = _summarizationPipeline.transformedDataStream
        .listen(
          (transformedData) {
            _lastMessage = transformedData;
            _summarizedTextController.add(transformedData);
          },
          onError: (error) {
            final errorMessage = 'Error processing text: ${error.toString()}';
            _summarizedTextController.add(errorMessage);
            _errorController.add(errorMessage);
            VibrationNotificationService.vibrateError();
          },
        );
  }

  Future<void> startListening() async {
    if (_currentState != SpeechVibroState.ready) return;

    _updateState(SpeechVibroState.listening);
    _summarizedTextController.add('');

    VibrationNotificationService.vibrateNotification();

    try {
      final recognizedText = await _speechRecognitionService.startListening();

      _updateState(SpeechVibroState.ready);

      if (recognizedText.isNotEmpty) {
        await _processRecognizedText(recognizedText);
      } else {
        VibrationNotificationService.vibrateWarning();
      }
    } catch (e) {
      _updateState(SpeechVibroState.ready);
      VibrationNotificationService.vibrateWarning();
      _errorController.add('Error during speech recognition: ${e.toString()}');
    }
  }

  Future<void> _processRecognizedText(String text) async {
    _updateState(SpeechVibroState.processing);

    try {
      await _summarizationPipeline.process(text);
      VibrationNotificationService.vibrateNotification();
    } catch (e) {
      VibrationNotificationService.vibrateError();
      _errorController.add('Error processing text: ${e.toString()}');
    } finally {
      _updateState(SpeechVibroState.ready);
    }
  }

  Future<void> forceListen() async {
    VibrationNotificationService.vibrateNotification();
    await startListening();
  }

  void _updateState(SpeechVibroState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  void dispose() {
    _speechRecognitionService.dispose();
    _summarizationPipeline.dispose();
    _transformedDataSubscription?.cancel();
    _summarizedTextController.close();
    _stateController.close();
    _errorController.close();
  }
}
