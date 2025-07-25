import 'dart:async';

import 'package:flutter/material.dart';

import '../braille_input/braille_input_screen.dart';
import 'speech_vibro_service.dart';
import 'widgets/widgets.dart';

class SpeechVibroScreen extends StatefulWidget {
  const SpeechVibroScreen({super.key});

  @override
  State<SpeechVibroScreen> createState() => _SpeechVibroScreenState();
}

class _SpeechVibroScreenState extends State<SpeechVibroScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final SpeechVibroService _speechVibroService = SpeechVibroService.instance;

  SpeechVibroState _currentState = SpeechVibroState.ready;
  String _summarizedText = '';

  late StreamSubscription<SpeechVibroState> _stateSubscription;
  late StreamSubscription<String> _textSubscription;
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
      await _speechVibroService.initialize();
    } catch (e) {
      _showError('Failed to initialize: ${e.toString()}');
    }
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

    _textSubscription = _speechVibroService.summarizedTextStream.listen((text) {
      if (mounted) {
        setState(() {
          _summarizedText = text;
        });
      }
    });

    _errorSubscription = _speechVibroService.errorStream.listen((error) {
      _showError(error);
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

  Future<void> _repeatLastMessage() async {
    await _speechVibroService.repeatLastMessage();
  }

  Future<void> _forceListen() async {
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
    _textSubscription.cancel();
    _errorSubscription.cancel();
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
          onSwipeDown: _repeatLastMessage,
          onSwipeUp: _forceListen,
          child: Column(
            children: [
              StatusIndicatorWidget(
                isListening: _currentState == SpeechVibroState.listening,
                isProcessing: _currentState == SpeechVibroState.processing,
                pulseAnimation: _pulseAnimation,
              ),
              Expanded(
                child: SummarizedOutputWidget(summarizedText: _summarizedText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
