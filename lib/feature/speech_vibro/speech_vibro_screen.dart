import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../../core/widgets/swipe_gesture_detector.dart';
import '../braille_input/braille_input_screen.dart';
import 'speech_vibro_service.dart';
import 'widgets/status_indicator_widget.dart';

class SpeechVibroScreen extends StatefulWidget {
  const SpeechVibroScreen({super.key});

  @override
  State<SpeechVibroScreen> createState() => _SpeechVibroScreenState();
}

class _SpeechVibroScreenState extends State<SpeechVibroScreen>
    with TickerProviderStateMixin {
  final ISpeechVibroService _speechVibroService =
      ServiceLocator.get<ISpeechVibroService>();

  SpeechVibroState _currentState = SpeechVibroState.ready;

  late StreamSubscription<SpeechVibroState> _stateSubscription;

  @override
  void initState() {
    super.initState();

    _initializeService();
    _subscribeToStreams();
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
      }
    });
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
    _stateSubscription.cancel();
    _speechVibroService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Full screen gesture detector
            Positioned.fill(
              child: SwipeGestureDetector(
                onSwipeLeft: _navigateToBrailleInput,
                onTap: _startListening,
                child: Container(
                  color: Colors.transparent,
                  child: Center(
                    child: StatusIndicatorWidget(
                      isListening: _currentState == SpeechVibroState.listening,
                      isProcessing:
                          _currentState == SpeechVibroState.processing,
                    ),
                  ),
                ),
              ),
            ),

            // Centered status indicator
          ],
        ),
      ),
    );
  }
}
