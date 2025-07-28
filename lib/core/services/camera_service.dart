import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../di/service_locator.dart';
import 'logging_service.dart';

abstract class ICameraService {
  CameraController? get cameraController;

  Future<bool> initialize();
  Future<void> dispose();
  Future<Uint8List?> captureImage();
}

class CameraService implements ICameraService {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;

  final ILoggingService _loggingService = ServiceLocator.get<ILoggingService>();

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isCameraReady =>
      _isInitialized && (_cameraController?.value.isInitialized ?? false);

  @override
  CameraController? get cameraController => _cameraController;
  List<CameraDescription> get cameras => _cameras;

  /// Initialize the camera service - finds available cameras and sets up rear camera
  @override
  Future<bool> initialize() async {
    if (isInitialized) {
      return true;
    }

    try {
      _loggingService.debug('CameraService: Starting initialization...');

      // Get available cameras
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        throw Exception('No cameras available on this device');
      }

      _loggingService.debug('CameraService: Found ${_cameras.length} cameras');

      // Find rear camera (back camera)
      final rearCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _loggingService.debug('CameraService: Using camera: ${rearCamera.name}');

      // Initialize camera controller
      _cameraController = CameraController(
        rearCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      _isInitialized = true;

      _loggingService.debug(
        'CameraService: Initialization completed successfully',
      );

      return true;
    } catch (e) {
      final errorMsg = 'Failed to initialize camera: ${e.toString()}';
      _loggingService.error(errorMsg);
      return false;
    }
  }

  /// Capture an image and return the bytes
  @override
  Future<Uint8List?> captureImage() async {
    if (!isCameraReady) {
      throw Exception('Camera is not initialized or ready');
    }

    try {
      // Provide haptic feedback for capture
      _loggingService.info('CameraService: Capturing image');

      final XFile image = await _cameraController!.takePicture();
      final Uint8List imageBytes = await image.readAsBytes();

      _loggingService.debug(
        'CameraService: Image captured successfully (${imageBytes.length} bytes)',
      );

      return imageBytes;
    } catch (e) {
      final errorMsg = 'Failed to capture image: ${e.toString()}';
      _loggingService.error(errorMsg);
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await _cameraController?.dispose();
      _cameraController = null;
      _isInitialized = false;

      _loggingService.debug('CameraService: Disposed successfully');
    } catch (e) {
      _loggingService.error('CameraService: Error during disposal: $e');
    }
  }
}
