import 'dart:async';

import 'package:feelu/core/interfaces.dart';
import 'package:feelu/core/speech_recognition_service.dart';
import 'package:feelu/core/vibration_notification_service.dart';
import 'package:feelu/outputs/braille_output.dart';
import 'package:feelu/transformers/llm_summarization.dart';
import 'package:flutter/material.dart';

import '../braille_input/braille_input_screen.dart';

class SpeechVibroScreen extends StatefulWidget {
  const SpeechVibroScreen({super.key});

  @override
  State<SpeechVibroScreen> createState() => _SpeechVibroScreenState();
}

class _SpeechVibroScreenState extends State<SpeechVibroScreen>
    with TickerProviderStateMixin {
  String _summarizedText = '';
  bool _isListening = false;
  bool _isProcessing = false;
  String _lastMessage = '';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late StreamSubscription<String> _transformedDataSubscription;

  final SpeechRecognitionService _speechRecognitionService =
      SpeechRecognitionService.instance;

  final Pipeline _summarizationPipeline = Pipeline(
    transformable: LlmSummarizationService.instance,
    outputable: BrailleOutputService.instance,
  );

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
    _subscribeToTransformedData();
    // Notify user they've entered speech vibro mode with wave-like pattern
    VibrationNotificationService.vibratePattern(
      pattern: [100, 50, 100, 50, 100, 50, 100, 50, 100],
      amplitude: 100,
    );
  }

  void _subscribeToTransformedData() {
    _transformedDataSubscription = _summarizationPipeline.transformedDataStream
        .listen(
          (transformedData) {
            if (mounted) {
              setState(() {
                _summarizedText = transformedData;
                _lastMessage = transformedData;
              });
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _summarizedText = 'Error processing text: ${error.toString()}';
              });
            }
            VibrationNotificationService.vibrateError();
            print('Error in transformed data stream: $error');
          },
        );
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

  Future<void> _initializeServices() async {
    await _speechRecognitionService.initialize();
    await _summarizationPipeline.initialize();
  }

  Future<void> _startListening() async {
    if (_isListening || _isProcessing) return;

    setState(() {
      _isListening = true;
      _summarizedText = '';
    });

    // Start the pulsing animation
    _pulseController.repeat(reverse: true);

    VibrationNotificationService.vibrateNotification();

    try {
      // Start speech recognition
      final recognizedText = await SpeechRecognitionService.instance
          .startListening();

      setState(() {
        _isListening = false;
      });

      // Stop the pulsing animation
      _pulseController.stop();

      if (recognizedText.isNotEmpty) {
        await _processRecognizedText(recognizedText);
      } else {
        VibrationNotificationService.vibrateWarning();
      }
    } catch (e) {
      setState(() {
        _isListening = false;
      });
      // Stop the pulsing animation
      _pulseController.stop();
      VibrationNotificationService.vibrateWarning();
      print('Error during speech recognition: $e');
    }
  }

  Future<void> _processRecognizedText(String text) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await _summarizationPipeline.process(text);
      VibrationNotificationService.vibrateNotification();
    } catch (e) {
      VibrationNotificationService.vibrateError();
      print('Error processing text: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _repeatLastMessage() async {
    if (_lastMessage.isNotEmpty) {
      VibrationNotificationService.vibrateNotification();
      await BrailleOutputService.instance.process(_lastMessage);
      VibrationNotificationService.vibrateNotification();
    } else {
      VibrationNotificationService.vibrateWarning();
    }
  }

  Future<void> _forceListen() async {
    VibrationNotificationService.vibrateNotification();
    await _startListening();
  }

  void _navigateToBrailleInput() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const BrailleInputScreen()),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speechRecognitionService.dispose();
    _summarizationPipeline.dispose();
    _transformedDataSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onPanUpdate: (details) {
            // Swipe left to return to braille input
            if (details.delta.dx < -5) {
              _navigateToBrailleInput();
            }
            // Swipe down to repeat last message
            else if (details.delta.dy > 5) {
              _repeatLastMessage();
            }
            // Swipe up to force listen
            else if (details.delta.dy < -5) {
              _forceListen();
            }
          },
          child: Column(
            children: [
              // Status indicator
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white30, width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SPEECH VIBRO',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Swipe left to return',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white54,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            Text(
                              'Swipe down to repeat | Swipe up to force listen',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade300,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isListening
                            ? Colors.red.shade900
                            : _isProcessing
                            ? Colors.orange.shade900
                            : Colors.green.shade900,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white30, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isListening
                                ? Icons.mic
                                : _isProcessing
                                ? Icons.sync
                                : Icons.check_circle,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isListening
                                  ? 'Listening... Speak now!'
                                  : _isProcessing
                                  ? 'Processing with AI...'
                                  : 'Ready to listen',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (_isListening)
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Summarized text display
              Expanded(
                flex: 1,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white30, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SUMMARIZED OUTPUT',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              _summarizedText.isEmpty
                                  ? 'Summarized text will appear here...'
                                  : _summarizedText,
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: 'monospace',
                                color: _summarizedText.isEmpty
                                    ? Colors.white60
                                    : Colors.white,
                                height: 1.2,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
