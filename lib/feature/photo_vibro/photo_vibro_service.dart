import 'dart:async';
import 'dart:typed_data';

import 'package:feelu/core/camera_service.dart';
import 'package:feelu/core/vibration_notification_service.dart';
import 'package:feelu/outputs/braille_output.dart';
import 'package:feelu/transformers/llm_recognition.dart';

enum PhotoVibroState { ready, capturing, processing }

class PhotoVibroService {
  static final PhotoVibroService _instance = PhotoVibroService._internal();
  static PhotoVibroService get instance => _instance;
  PhotoVibroService._internal();

  final CameraService _cameraService = CameraService.instance;

  final StreamController<PhotoVibroState> _stateController =
      StreamController<PhotoVibroState>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();
  final StreamController<String> _recognitionResultController =
      StreamController<String>.broadcast();

  Stream<PhotoVibroState> get stateStream => _stateController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<String> get recognitionResultStream =>
      _recognitionResultController.stream;

  PhotoVibroState _currentState = PhotoVibroState.ready;
  String _lastRecognitionResult = '';

  PhotoVibroState get currentState => _currentState;
  String get lastRecognitionResult => _lastRecognitionResult;
  bool get isCameraReady => _cameraService.isCameraReady;

  Future<void> initialize() async {
    try {
      // Check if camera service is already initialized
      if (!_cameraService.isInitialized) {
        _errorController.add(
          'Camera service not initialized. Please restart the app.',
        );
        throw Exception(
          'Camera service must be initialized during app startup',
        );
      }

      // Notify user they've entered photo vibro mode with camera-like pattern
      VibrationNotificationService.vibratePattern(
        pattern: [150, 100, 150, 100, 300],
        amplitude: 150,
      );
    } catch (e) {
      _errorController.add('Failed to initialize photo vibro: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> captureAndProcess() async {
    if (!isCameraReady || _currentState != PhotoVibroState.ready) {
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
      final recognitionResult = await LlmRecognitionService.instance.transform(
        imageBytes,
      );

      _lastRecognitionResult = recognitionResult;
      _recognitionResultController.add(recognitionResult);

      // Output result through braille
      await BrailleOutputService.instance.process(recognitionResult);

      VibrationNotificationService.vibrateNotification();
    } catch (e) {
      VibrationNotificationService.vibrateError();
      _errorController.add('Error capturing/processing image: ${e.toString()}');
    } finally {
      _updateState(PhotoVibroState.ready);
    }
  }

  Future<void> repeatLastResult() async {
    if (_lastRecognitionResult.isNotEmpty) {
      VibrationNotificationService.vibrateNotification();
      await BrailleOutputService.instance.process(_lastRecognitionResult);
      VibrationNotificationService.vibrateNotification();
    } else {
      VibrationNotificationService.vibrateWarning();
    }
  }

  void _updateState(PhotoVibroState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  void dispose() {
    _stateController.close();
    _errorController.close();
    _recognitionResultController.close();
  }
}
