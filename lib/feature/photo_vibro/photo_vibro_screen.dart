import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../../core/services/camera_service.dart';
import '../../core/widgets/icon_paths.dart';
import '../../core/widgets/icon_text_widget.dart';
import '../../core/widgets/swipe_gesture_detector.dart';
import '../braille_input/braille_input_screen.dart';
import 'photo_vibro_service.dart';
import 'widgets/camera_preview_widget.dart';

class PhotoVibroScreen extends StatefulWidget {
  const PhotoVibroScreen({super.key});

  @override
  State<PhotoVibroScreen> createState() => _PhotoVibroScreenState();
}

class _PhotoVibroScreenState extends State<PhotoVibroScreen> {
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

    _initializeService();
    _subscribeToStreams();
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
      }
    });

    _errorSubscription = _photoVibroService.errorStream.listen((error) {
      _showError(error);
    });
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
        child: SwipeGestureDetector(
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
                child: Center(child: _buildMainContent()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_currentState) {
      case PhotoVibroState.ready:
        return IconTextWidget(
          svgIcon: IconPaths.eye,
          text: 'Tap to see',
          iconColor: Colors.grey,
          textColor: Colors.grey,
        );
      case PhotoVibroState.capturing:
        return IconTextWidget(
          svgIcon: IconPaths.eye,
          text: 'Capturing...',
          iconColor: Colors.green,
          textColor: Colors.green,
        );
      case PhotoVibroState.processing:
        return IconTextWidget(
          imageIcon: IconPaths.gemma3n,
          text: 'Describing...',
          textColor: Colors.white,
        );
    }
  }
}
