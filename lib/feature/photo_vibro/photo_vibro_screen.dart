import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../../core/services/camera_service.dart';
import '../braille_input/braille_input_screen.dart';
import 'photo_vibro_service.dart';
import 'widgets/widgets.dart';

class PhotoVibroScreen extends StatefulWidget {
  const PhotoVibroScreen({super.key});

  @override
  State<PhotoVibroScreen> createState() => _PhotoVibroScreenState();
}

class _PhotoVibroScreenState extends State<PhotoVibroScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late final IPhotoVibroService _photoVibroService;
  late final ICameraService _cameraService;

  PhotoVibroState _currentState = PhotoVibroState.ready;

  late StreamSubscription<PhotoVibroState> _stateSubscription;
  late StreamSubscription<String> _errorSubscription;

  @override
  void initState() {
    super.initState();

    // Get services from DI container
    _photoVibroService = ServiceLocator.get<IPhotoVibroService>();
    _cameraService = ServiceLocator.get<ICameraService>();

    _initializeAnimations();
    _initializeService();
    _subscribeToStreams();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeService() async {
    try {
      await _photoVibroService.initialize(context);
    } catch (e) {
      _showError('Failed to initialize photo vibro: ${e.toString()}');
    }
  }

  void _subscribeToStreams() {
    _stateSubscription = _photoVibroService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _currentState = state;
        });
        _handleStateChange(state);
      }
    });

    _errorSubscription = _photoVibroService.errorStream.listen((error) {
      _showError(error);
    });
  }

  void _handleStateChange(PhotoVibroState state) {
    switch (state) {
      case PhotoVibroState.capturing:
        _pulseController.repeat(reverse: true);
        break;
      case PhotoVibroState.ready:
      case PhotoVibroState.processing:
        _pulseController.stop();
        break;
    }
  }

  void _showError(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _capturePhoto() async {
    await _photoVibroService.captureAndProcess();
  }

  void _navigateToBrailleInput() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const BrailleInputScreen()),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _stateSubscription.cancel();
    _errorSubscription.cancel();
    _photoVibroService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: PhotoVibroGestureDetector(
          onSwipeRight: _navigateToBrailleInput,
          onSwipeDown: () {},
          onTap: _capturePhoto,
          child: Stack(
            children: [
              // Camera preview background
              CameraPreviewWidget(
                cameraController: _cameraService.cameraController,
              ),

              // Main content overlay
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Status indicator
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: CameraStatusIndicatorWidget(
                          isCapturing:
                              _currentState == PhotoVibroState.capturing,
                          isProcessing:
                              _currentState == PhotoVibroState.processing,
                          pulseAnimation: _pulseAnimation,
                        ),
                      ),
                    ),

                    // Recognition result
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: RecognitionResultWidget(
                          recognitionResult:
                              _currentState == PhotoVibroState.ready
                              ? 'Tap to capture photo'
                              : _currentState == PhotoVibroState.capturing
                              ? 'Capturing...'
                              : 'Processing...',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
