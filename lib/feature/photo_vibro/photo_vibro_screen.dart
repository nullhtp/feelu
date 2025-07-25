import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/camera_service.dart';
import '../../outputs/braille_text_widget.dart';
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

  final PhotoVibroService _photoVibroService = PhotoVibroService.instance;
  final CameraService _cameraService = CameraService.instance;

  PhotoVibroState _currentState = PhotoVibroState.ready;
  String _recognitionResult = '';

  late StreamSubscription<PhotoVibroState> _stateSubscription;
  late StreamSubscription<String> _resultSubscription;
  late StreamSubscription<String> _errorSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeService();
    _subscribeToStreams();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeService() async {
    try {
      await _photoVibroService.initialize();
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

    _resultSubscription = _photoVibroService.recognitionResultStream.listen((
      result,
    ) {
      if (mounted) {
        setState(() {
          _recognitionResult = result;
        });
      }
    });

    _errorSubscription = _photoVibroService.errorStream.listen((error) {
      _showError(error);
    });
  }

  void _handleStateChange(PhotoVibroState state) {
    switch (state) {
      case PhotoVibroState.capturing:
      case PhotoVibroState.processing:
        _pulseController.repeat(reverse: true);
        break;
      case PhotoVibroState.ready:
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

  Future<void> _captureImage() async {
    await _photoVibroService.captureAndProcess();
  }

  Future<void> _repeatLastResult() async {
    await _photoVibroService.repeatLastResult();
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
    _resultSubscription.cancel();
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
          onSwipeDown: _repeatLastResult,
          onTap: _captureImage,
          child: Column(
            children: [
              CameraStatusIndicatorWidget(
                isCapturing: _currentState == PhotoVibroState.capturing,
                isProcessing: _currentState == PhotoVibroState.processing,
                pulseAnimation: _pulseAnimation,
              ),
              Expanded(
                child: Stack(
                  children: [
                    // Camera preview
                    CameraPreviewWidget(
                      cameraController: _cameraService.cameraController,
                      isInitialized: _cameraService.isCameraReady,
                    ),
                    // Recognition result overlay with braille text widget
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: _recognitionResult.isNotEmpty
                          ? Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.shade300,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.psychology,
                                        color: Colors.green.shade300,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'AI RECOGNITION RESULT',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade300,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _recognitionResult,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Braille text widget display
                                  Container(
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade900,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    child: BrailleTextWidget(
                                      service:
                                          _photoVibroService.brailleTextService,
                                      symbolSize: 45.0,
                                      spacing: 8.0,
                                      symbolsPerRow: 4,
                                      activeColor: Colors.green.shade300,
                                      inactiveColor: Colors.grey.shade600,
                                      backgroundColor: Colors.grey.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
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
