import 'dart:async';

import 'package:feelu/core/di/service_locator.dart';
import 'package:feelu/core/interfaces.dart';
import 'package:feelu/core/services/services.dart';
import 'package:feelu/outputs/braille_text_output.dart';
import 'package:feelu/transformers/llm_summarization.dart';
import 'package:flutter/material.dart';

enum SpeechVibroState { ready, listening, processing }

abstract class ISpeechVibroService {
  Stream<SpeechVibroState> get stateStream;

  Future<void> initialize(BuildContext context);
  Future<void> startListening();
  Future<void> forceListen();
  void dispose();
}

class SpeechVibroService implements ISpeechVibroService {
  final ISpeechRecognitionService _speechRecognitionService =
      ServiceLocator.get<ISpeechRecognitionService>();
  final ILoggingService _loggingService = ServiceLocator.get<ILoggingService>();
  late BrailleTextOutputService _brailleTextService;

  late Pipeline _summarizationPipeline;

  final StreamController<String> _summarizedTextController =
      StreamController<String>.broadcast();
  final StreamController<SpeechVibroState> _stateController =
      StreamController<SpeechVibroState>.broadcast();

  Stream<String> get summarizedTextStream => _summarizedTextController.stream;
  @override
  Stream<SpeechVibroState> get stateStream => _stateController.stream;

  SpeechVibroState _currentState = SpeechVibroState.ready;
  String _lastMessage = '';
  StreamSubscription<String>? _transformedDataSubscription;

  SpeechVibroState get currentState => _currentState;
  String get lastMessage => _lastMessage;
  BrailleTextOutputService get brailleTextService => _brailleTextService;
  ILlmSummarizationService get llmSummarizationService =>
      ServiceLocator.get<ILlmSummarizationService>();

  @override
  Future<void> initialize(BuildContext context) async {
    try {
      await _speechRecognitionService.initialize();
      _brailleTextService = BrailleTextOutputService(context: context);
      _summarizationPipeline = Pipeline(
        transformable: llmSummarizationService,
        outputable: _brailleTextService,
      );
      _subscribeToTransformedData();

      await _summarizationPipeline.initialize();

      ServiceLocator.get<IBrailleVibrationService>().vibrateBraille('s');
    } catch (e) {
      _loggingService.error('Failed to initialize services: ${e.toString()}');
      rethrow;
    }
  }

  void _subscribeToTransformedData() {
    _transformedDataSubscription = _summarizationPipeline.transformedDataStream
        .listen(
          (transformedData) {
            _lastMessage = transformedData;
            if (!_summarizedTextController.isClosed) {
              _summarizedTextController.add(transformedData);
            }
          },
          onError: (error) {
            final errorMessage = 'Error processing text: ${error.toString()}';
            _loggingService.error(errorMessage);
          },
        );
  }

  @override
  Future<void> startListening() async {
    if (_currentState != SpeechVibroState.ready) return;

    _updateState(SpeechVibroState.listening);
    if (!_summarizedTextController.isClosed) {
      _summarizedTextController.add('');
    }

    _loggingService.info('Listening');

    try {
      final recognizedText = await _speechRecognitionService.startListening();

      _updateState(SpeechVibroState.ready);

      if (recognizedText.isNotEmpty) {
        await _processRecognizedText(recognizedText);
      } else {
        _loggingService.warning('No text recognized');
      }
    } catch (e) {
      _updateState(SpeechVibroState.ready);
      _loggingService.error('Error during speech recognition: ${e.toString()}');
    }
  }

  Future<void> _processRecognizedText(String text) async {
    _updateState(SpeechVibroState.processing);

    try {
      await _summarizationPipeline.process(text);
      _loggingService.info('Processing recognized text');
    } catch (e) {
      _loggingService.error(
        'Error processing recognized text: ${e.toString()}',
      );
    } finally {
      _updateState(SpeechVibroState.ready);
    }
  }

  @override
  Future<void> forceListen() async {
    _loggingService.info('Force listening');
    await startListening();
  }

  void _updateState(SpeechVibroState newState) {
    _currentState = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  @override
  void dispose() {
    _speechRecognitionService.dispose();
    _summarizationPipeline.dispose();
    _transformedDataSubscription?.cancel();
    _summarizedTextController.close();
    _stateController.close();
  }
}
