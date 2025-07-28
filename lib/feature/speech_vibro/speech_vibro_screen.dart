import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../braille_input/braille_input_screen.dart';
import 'speech_vibro_service.dart';
import 'widgets/speech_vibro_gesture_detector.dart';
import 'widgets/status_indicator_widget.dart';

class SpeechVibroScreen extends StatefulWidget {
  const SpeechVibroScreen({super.key});

  @override
  State<SpeechVibroScreen> createState() => _SpeechVibroScreenState();
}

class _SpeechVibroScreenState extends State<SpeechVibroScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final ISpeechVibroService _speechVibroService =
      ServiceLocator.get<ISpeechVibroService>();

  SpeechVibroState _currentState = SpeechVibroState.ready;

  late StreamSubscription<SpeechVibroState> _stateSubscription;

  @override
  void initState() {
    super.initState();

    _initializeAnimations();
    _initializeService();
    _subscribeToStreams();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeService() async {
    await _speechVibroService.initialize(context);
  }

  void _subscribeToStreams() {
    _stateSubscription = _speechVibroService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _currentState = state;
        });
        _handleStateChange(state);
      }
    });
  }

  void _handleStateChange(SpeechVibroState state) {
    switch (state) {
      case SpeechVibroState.listening:
        _pulseController.repeat(reverse: true);
        break;
      case SpeechVibroState.ready:
      case SpeechVibroState.processing:
        _pulseController.stop();
        break;
    }
  }

  Future<void> _startListening() async {
    await _speechVibroService.forceListen();
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
    _speechVibroService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SpeechVibroGestureDetector(
          onSwipeLeft: _navigateToBrailleInput,
          onSwipeDown: () {},
          onSwipeUp: () {}, // Remove swipe up to listen functionality
          child: GestureDetector(
            onTap: _startListening,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: StatusIndicatorWidget(
                  isListening: _currentState == SpeechVibroState.listening,
                  isProcessing: _currentState == SpeechVibroState.processing,
                  pulseAnimation: _pulseAnimation,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
