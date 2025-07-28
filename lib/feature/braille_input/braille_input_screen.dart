import 'dart:async';

import 'package:feelu/core/braille_vibration.dart';
import 'package:feelu/core/interfaces.dart';
import 'package:feelu/core/vibration_notification_service.dart';
import 'package:feelu/outputs/braille_text_output.dart';
import 'package:feelu/outputs/tts.dart';
import 'package:feelu/transformers/llm_assistant.dart';
import 'package:feelu/transformers/llm_decode.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../photo_vibro/photo_vibro_screen.dart';
import '../speech_vibro/speech_vibro_screen.dart';
import 'braille_service.dart';
import 'widgets/braille_piano_widget.dart';

class BrailleInputScreen extends StatefulWidget {
  const BrailleInputScreen({super.key});

  @override
  State<BrailleInputScreen> createState() => _BrailleInputScreenState();
}

class _BrailleInputScreenState extends State<BrailleInputScreen> {
  late BrailleService _brailleService;
  String _displayText = '';
  bool _isSpeaking = false; // Add flag to prevent multiple speak calls

  late BrailleTextOutputService _brailleTextOutputService;

  final Pipeline _outputPipeline = Pipeline(
    transformable: LlmDecodeService.instance,
    outputable: TtsService.instance,
  );

  late Pipeline _assistantPipeline;

  @override
  void initState() {
    super.initState();
    _brailleService = BrailleService();
    _outputPipeline.initialize();
    _brailleTextOutputService = BrailleTextOutputService(context: context);
    _assistantPipeline = Pipeline(
      transformable: LlmAssistantService.instance,
      outputable: _brailleTextOutputService,
    );

    _assistantPipeline.initialize();

    // Notify user they've entered braille input mode with dot-like pattern
    BrailleVibrationService.instance.vibrateBraille('i');
  }

  void _onTextGenerated(String text) {
    setState(() {
      _displayText = text;
    });
  }

  void _backspace() {
    setState(() {
      _brailleService.backspace();
      _displayText = _brailleService.getDisplayText();
    });
  }

  void _clearAllText() {
    setState(() {
      _brailleService.clearOutput();
      _displayText = _brailleService.getDisplayText();
    });
  }

  Future<void> _speakText() async {
    final textToSpeak = _displayText.trim();
    if (textToSpeak.isEmpty) {
      // Speak a message indicating no text
      VibrationNotificationService.vibrateWarning();
    } else {
      // Speak the inputted text
      VibrationNotificationService.vibrateNotification();
      await _outputPipeline.process(textToSpeak);
      VibrationNotificationService.vibrateNotification();
    }
  }

  Future<void> _askAssistant() async {
    final textToSpeak = _displayText.trim();
    if (textToSpeak.isEmpty) {
      // Speak a message indicating no text
      VibrationNotificationService.vibrateWarning();
    } else {
      // Speak the inputted text
      VibrationNotificationService.vibrateNotification();
      await _assistantPipeline.process(textToSpeak);
      VibrationNotificationService.vibrateNotification();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          // Add swipe down detection for the entire screen
          onPanUpdate: (details) async {
            // Check if swipe is moving downward and not already speaking
            if (details.delta.dy > 5 && !_isSpeaking) {
              try {
                _isSpeaking = true;
                await _speakText();
              } catch (e) {
                print(e);
              } finally {
                _isSpeaking = false;
              }
            }
            if (details.delta.dy < -5 && !_isSpeaking) {
              try {
                _isSpeaking = true;
                await _askAssistant();
              } catch (e) {
                print(e);
              } finally {
                _isSpeaking = false;
              }
            }
            // Swipe right to navigate to speech vibro screen
            if (details.delta.dx > 5) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const SpeechVibroScreen(),
                ),
              );
            }
            // Swipe left to navigate to photo vibro screen
            if (details.delta.dx < -5) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const PhotoVibroScreen(),
                ),
              );
            }
          },
          child: Column(
            children: [
              // Text display area (top)
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () {
                    // Delete functionality - tap anywhere in text area to delete
                    HapticFeedback.mediumImpact();
                    _backspace();
                  },
                  onLongPress: () {
                    // Clear all text - long press anywhere in text area
                    HapticFeedback.heavyImpact();
                    _clearAllText();
                  },
                  child: Container(
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
                              'TEXT OUTPUT',
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
                                  'Tap to delete | Long press to clear all',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white54,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                Text(
                                  'Swipe down to speak text | Swipe up to ask assistant',
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
                                _displayText.isEmpty
                                    ? 'Text appears here...'
                                    : _displayText,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'monospace',
                                  color: _displayText.isEmpty
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
              ),

              // Piano input widget (bottom)
              Expanded(
                flex: 2,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  child: BraillePianoWidget(
                    brailleService: _brailleService,
                    onTextGenerated: _onTextGenerated,
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
