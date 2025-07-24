import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import 'vibration_notification_service.dart';

class CameraService {
  static CameraService? _instance;
  static CameraService get instance => _instance ??= CameraService._();
  CameraService._();

  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;

  // Stream controllers for camera state
  final StreamController<bool> _initializationController =
      StreamController<bool>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  // Stream getters
  Stream<bool> get initializationStream => _initializationController.stream;
  Stream<String> get errorStream => _errorController.stream;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isCameraReady =>
      _isInitialized && (_cameraController?.value.isInitialized ?? false);
  CameraController? get cameraController => _cameraController;
  List<CameraDescription> get cameras => _cameras;

  /// Initialize the camera service - finds available cameras and sets up rear camera
  Future<bool> initialize() async {
    try {
      if (kDebugMode) {
        print('CameraService: Starting initialization...');
      }

      // Get available cameras
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        throw Exception('No cameras available on this device');
      }

      if (kDebugMode) {
        print('CameraService: Found ${_cameras.length} cameras');
      }

      // Find rear camera (back camera)
      final rearCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      if (kDebugMode) {
        print('CameraService: Using camera: ${rearCamera.name}');
      }

      // Initialize camera controller
      _cameraController = CameraController(
        rearCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      _isInitialized = true;
      _initializationController.add(true);

      if (kDebugMode) {
        print('CameraService: Initialization completed successfully');
      }

      return true;
    } catch (e) {
      final errorMsg = 'Failed to initialize camera: ${e.toString()}';
      if (kDebugMode) {
        print('CameraService: $errorMsg');
      }
      _errorController.add(errorMsg);
      _initializationController.add(false);
      return false;
    }
  }

  /// Capture an image and return the bytes
  Future<Uint8List?> captureImage() async {
    if (!isCameraReady) {
      throw Exception('Camera is not initialized or ready');
    }

    try {
      // Provide haptic feedback for capture
      VibrationNotificationService.vibrateNotification();

      final XFile image = await _cameraController!.takePicture();
      final Uint8List imageBytes = await image.readAsBytes();

      if (kDebugMode) {
        print(
          'CameraService: Image captured successfully (${imageBytes.length} bytes)',
        );
      }

      return imageBytes;
    } catch (e) {
      final errorMsg = 'Failed to capture image: ${e.toString()}';
      if (kDebugMode) {
        print('CameraService: $errorMsg');
      }
      _errorController.add(errorMsg);
      VibrationNotificationService.vibrateError();
      rethrow;
    }
  }

  /// Switch to a different camera (front/back)
  Future<bool> switchCamera() async {
    if (_cameras.length <= 1) {
      if (kDebugMode) {
        print('CameraService: Only one camera available, cannot switch');
      }
      return false;
    }

    try {
      final currentLensDirection = _cameraController?.description.lensDirection;

      // Find the opposite camera
      final newCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection != currentLensDirection,
        orElse: () => _cameras.first,
      );

      // Dispose current controller
      await _cameraController?.dispose();

      // Initialize new controller
      _cameraController = CameraController(
        newCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (kDebugMode) {
        print('CameraService: Switched to camera: ${newCamera.name}');
      }

      return true;
    } catch (e) {
      final errorMsg = 'Failed to switch camera: ${e.toString()}';
      if (kDebugMode) {
        print('CameraService: $errorMsg');
      }
      _errorController.add(errorMsg);
      return false;
    }
  }

  /// Get camera info for debugging
  String getCameraInfo() {
    if (!_isInitialized) {
      return 'Camera service not initialized';
    }

    final controller = _cameraController;
    if (controller == null) {
      return 'No camera controller available';
    }

    final camera = controller.description;
    final resolution = controller.value.previewSize;

    return 'Camera: ${camera.name}\n'
        'Direction: ${camera.lensDirection.name}\n'
        'Resolution: ${resolution?.width}x${resolution?.height}\n'
        'Sensor Orientation: ${camera.sensorOrientation}°';
  }

  /// Dispose of camera resources
  Future<void> dispose() async {
    try {
      await _cameraController?.dispose();
      _cameraController = null;
      _isInitialized = false;

      await _initializationController.close();
      await _errorController.close();

      if (kDebugMode) {
        print('CameraService: Disposed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('CameraService: Error during disposal: $e');
      }
    }
  }
}
