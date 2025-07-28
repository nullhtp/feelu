import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../../core/interfaces.dart';
import '../../core/services/services.dart';
import '../../feature/braille_fullscreen/braille_fullscreen_screen.dart';
import '../../feature/photo_vibro/photo_vibro_screen.dart';
import '../../feature/speech_vibro/speech_vibro_screen.dart';
import '../../outputs/braille_text_output.dart';
import '../../outputs/tts_output.dart';
import '../../transformers/llm_assistant.dart';
import '../../transformers/llm_decode.dart';
import 'braille_service.dart';
import 'widgets/braille_piano_widget.dart';

class BrailleInputScreen extends StatefulWidget {
  const BrailleInputScreen({super.key});

  @override
  State<BrailleInputScreen> createState() => _BrailleInputScreenState();
}

class _BrailleInputScreenState extends State<BrailleInputScreen> {
  late final BrailleService _brailleService;
  late BrailleTextOutputService _brailleTextOutputService;

  final IBrailleVibrationService _brailleVibrationService =
      ServiceLocator.get<IBrailleVibrationService>();
  final IVibrationNotification _vibrationNotificationService =
      ServiceLocator.get<IVibrationNotification>();
  final ILlmDecodeService _llmDecodeService =
      ServiceLocator.get<ILlmDecodeService>();
  final ILlmAssistantService _llmAssistantService =
      ServiceLocator.get<ILlmAssistantService>();
  final ILoggingService _loggingService = ServiceLocator.get<ILoggingService>();

  String _displayText = '';
  bool _isSpeaking = false; // Add flag to prevent multiple speak calls

  late Pipeline _outputPipeline;
  late Pipeline _assistantPipeline;

  @override
  void initState() {
    super.initState();

    // Get services from DI container
    _brailleService =
        BrailleService(); // This one doesn't use singleton pattern yet

    // BrailleTextOutputService needs context
    _brailleTextOutputService = BrailleTextOutputService(context: context);

    // Initialize pipelines with DI services
    _outputPipeline = Pipeline(
      transformable: _llmDecodeService,
      outputable: TtsOutputService(),
    );

    _assistantPipeline = Pipeline(
      transformable: _llmAssistantService,
      outputable: _brailleTextOutputService,
    );

    _outputPipeline.initialize();
    _assistantPipeline.initialize();

    // Setup stream listener for braille text output
    _brailleTextOutputService.fullscreenStream.listen((brailleText) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BrailleFullscreenScreen(
            sourceText: brailleText,
            sourceTitle: 'ASSISTANT OUTPUT',
            themeColor: Colors.green.withValues(alpha: 0.3),
            brailleVibrationService: _brailleVibrationService,
          ),
        ),
      );
    });
  }

  void _handleBrailleSymbol(String brailleCode) {
    setState(() {
      _displayText = brailleCode;
    });
    _vibrationNotificationService.vibrateNotification();
  }

  void _handleBackspace() {
    if (_displayText.isNotEmpty) {
      setState(() {
        _displayText = _displayText.substring(0, _displayText.length - 1);
      });
      _vibrationNotificationService.vibrateWarning();
    }
  }

  void _handleClearAll() {
    setState(() {
      _displayText = '';
    });
    _vibrationNotificationService.vibrateWarning();
  }

  Future<void> _speakText() async {
    final textToSpeak = _displayText.trim();
    if (textToSpeak.isEmpty) {
      // Speak a message indicating no text
      _vibrationNotificationService.vibrateWarning();
    } else {
      // Speak the inputted text
      _vibrationNotificationService.vibrateNotification();
      await _outputPipeline.process(textToSpeak);
      _vibrationNotificationService.vibrateNotification();
    }
  }

  Future<void> _askAssistant() async {
    final textToSpeak = _displayText.trim();
    if (textToSpeak.isEmpty) {
      // Speak a message indicating no text
      _vibrationNotificationService.vibrateWarning();
    } else {
      // Speak the inputted text
      _vibrationNotificationService.vibrateNotification();
      await _assistantPipeline.process(textToSpeak);
      _vibrationNotificationService.vibrateNotification();
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
                _loggingService.error('Error speaking text: $e');
              } finally {
                _isSpeaking = false;
              }
            }
            if (details.delta.dy < -5 && !_isSpeaking) {
              try {
                _isSpeaking = true;
                await _askAssistant();
              } catch (e) {
                _loggingService.error('Error asking assistant: $e');
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
                    _handleBackspace();
                  },
                  onLongPress: () {
                    // Clear all text - long press anywhere in text area
                    _handleClearAll();
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
                    onTextGenerated: _handleBrailleSymbol,
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
