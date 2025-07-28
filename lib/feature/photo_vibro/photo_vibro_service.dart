import 'dart:async';
import 'dart:typed_data';

import 'package:feelu/core/di/service_locator.dart';
import 'package:feelu/core/services/services.dart';
import 'package:feelu/outputs/braille_text_output.dart';
import 'package:feelu/transformers/llm_recognition.dart';
import 'package:flutter/material.dart';

enum PhotoVibroState { ready, capturing, processing }

abstract class IPhotoVibroService {
  Stream<PhotoVibroState> get stateStream;
  Stream<String> get errorStream;

  Future<void> initialize(BuildContext context);
  Future<void> captureAndProcess();
  void dispose();
}

class PhotoVibroService implements IPhotoVibroService {
  final ILoggingService _loggingService = ServiceLocator.get<ILoggingService>();
  final ICameraService _cameraService = ServiceLocator.get<ICameraService>();
  final IBrailleVibrationService _brailleVibrationService =
      ServiceLocator.get<IBrailleVibrationService>();
  late BrailleTextOutputService _brailleTextService;

  final StreamController<PhotoVibroState> _stateController =
      StreamController<PhotoVibroState>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  final ILlmRecognitionService _llmRecognitionService =
      ServiceLocator.get<ILlmRecognitionService>();

  @override
  Stream<PhotoVibroState> get stateStream => _stateController.stream;
  @override
  Stream<String> get errorStream => _errorController.stream;

  PhotoVibroState _currentState = PhotoVibroState.ready;
  String _lastRecognitionResult = '';

  PhotoVibroState get currentState => _currentState;
  String get lastRecognitionResult => _lastRecognitionResult;
  BrailleTextOutputService get brailleTextService => _brailleTextService;

  @override
  Future<void> initialize(BuildContext context) async {
    try {
      // Notify user they've entered photo vibro mode with camera-like pattern
      _brailleVibrationService.vibrateBraille('c');
    } catch (e) {
      _errorController.add('Failed to initialize photo vibro: ${e.toString()}');
      rethrow;
    }
    _brailleTextService = BrailleTextOutputService(context: context);
  }

  @override
  Future<void> captureAndProcess() async {
    if (_currentState != PhotoVibroState.ready) {
      return;
    }

    _updateState(PhotoVibroState.capturing);

    try {
      // Capture image using camera service
      final Uint8List? imageBytes = await _cameraService.captureImage();

      if (imageBytes == null) {
        throw Exception('Failed to capture image');
      }

      _updateState(PhotoVibroState.processing);

      // Process image with LLM recognition
      final recognitionResult = await _llmRecognitionService.transform(
        imageBytes,
      );

      _lastRecognitionResult = recognitionResult;

      // Process through braille text service (this will trigger fullscreen automatically)
      await _brailleTextService.process(recognitionResult);

      _loggingService.info('Image processed');
    } catch (e) {
      _loggingService.error(
        'Error capturing/processing image: ${e.toString()}',
      );
      _errorController.add('Error capturing/processing image: ${e.toString()}');
    } finally {
      _updateState(PhotoVibroState.ready);
    }
  }

  void _updateState(PhotoVibroState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  @override
  void dispose() {
    _stateController.close();
    _errorController.close();
  }
}
