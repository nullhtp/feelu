import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../../core/interfaces.dart';
import '../../core/services/services.dart';
import '../../core/widgets/icon_paths.dart';
import '../../core/widgets/icon_text_widget.dart';
import '../../core/widgets/swipe_gesture_detector.dart';
import '../../core/extensions/context_extensions.dart';
import '../../feature/braille_fullscreen/braille_fullscreen_screen.dart';
import '../../feature/photo_vibro/photo_vibro_screen.dart';
import '../../feature/speech_vibro/speech_vibro_screen.dart';
import '../../outputs/braille_text_output.dart';
import '../../outputs/tts_output.dart';
import '../../transformers/llm_assistant.dart';
import '../../transformers/llm_decode.dart';
import 'braille_service.dart';
import 'widgets/braille_piano_widget.dart';

enum BrailleInputState {
  ready,
  processingTransform,
  processingOutput,
  processingAssistant,
}

class BrailleInputScreen extends StatefulWidget {
  const BrailleInputScreen({super.key});

  @override
  State<BrailleInputScreen> createState() => _BrailleInputScreenState();
}

class _BrailleInputScreenState extends State<BrailleInputScreen> {
  final IBrailleService _brailleService = ServiceLocator.get<IBrailleService>();
  late BrailleTextOutputService _brailleTextOutputService;

  final IBrailleVibrationService _brailleVibrationService =
      ServiceLocator.get<IBrailleVibrationService>();
  final ILlmDecodeService _llmDecodeService =
      ServiceLocator.get<ILlmDecodeService>();
  final ILlmAssistantService _llmAssistantService =
      ServiceLocator.get<ILlmAssistantService>();
  final ILoggingService _loggingService = ServiceLocator.get<ILoggingService>();

  String _displayText = '';
  bool _isSpeaking = false; // Add flag to prevent multiple speak calls
  BrailleInputState _currentState = BrailleInputState.ready;

  late Pipeline _outputPipeline;
  late Pipeline _assistantPipeline;

  @override
  void initState() {
    super.initState();

    // Initialize display text with current service state
    _displayText = _brailleService.getDisplayText();

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
              sourceTitle: context.l10n.brailleAssistantOutputTitle,
            themeColor: Colors.green.withValues(alpha: 0.3),
            brailleVibrationService: _brailleVibrationService,
          ),
        ),
      );
    });
  }

  void _submitCurrentInput(bool key1, bool key2, bool key3) {
    _brailleService.processKeyInput(key1, key2, key3);

    setState(() => _displayText = _brailleService.getDisplayText());
  }

  void _handleBackspace() {
    _brailleService.backspace();
    setState(() => _displayText = _brailleService.getDisplayText());
    _loggingService.warning('Backspace pressed');
  }

  void _handleClearAll() {
    _brailleService.clearOutput();
    setState(() => _displayText = _brailleService.getDisplayText());
    _loggingService.warning('Clear all pressed');
  }

  Future<void> _speakText() async {
    final textToSpeak = _displayText.trim();
    if (textToSpeak.isEmpty) {
      // Speak a message indicating no text
      _loggingService.warning('No text to speak');
    } else {
      // Speak the inputted text
      _loggingService.info('Speaking text');

      // Set state to transform phase
      setState(() {
        _currentState = BrailleInputState.processingTransform;
      });

      // Listen for transform completion to switch to output phase
      final subscription = _outputPipeline.transformedDataStream.listen((_) {
        if (mounted) {
          setState(() {
            _currentState = BrailleInputState.processingOutput;
          });
        }
      });

      await _outputPipeline.process(textToSpeak);

      // Clean up and reset state
      subscription.cancel();
      if (mounted) {
        setState(() {
          _currentState = BrailleInputState.ready;
        });
      }

      _loggingService.info('Text spoken');
    }
  }

  Future<void> _askAssistant() async {
    final textToSpeak = _displayText.trim();
    if (textToSpeak.isEmpty) {
      // Speak a message indicating no text
      _loggingService.warning('No text to ask assistant');
    } else {
      // Set state to processing assistant
      setState(() {
        _currentState = BrailleInputState.processingAssistant;
      });

      _loggingService.info('Asking assistant');
      await _assistantPipeline.process(textToSpeak);

      // Reset state
      if (mounted) {
        setState(() {
          _currentState = BrailleInputState.ready;
        });
      }

      _loggingService.info('Assistant asked');
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
        child: Stack(
          children: [
            // Main layout
            Column(
              children: [
                // Main content area (top)
                Expanded(flex: 2, child: Center(child: _buildMainContent())),

                // Piano input widget (bottom)
                Expanded(
                  child: BraillePianoWidget(onSubmitInput: _submitCurrentInput),
                ),
              ],
            ),

            // Gesture detector overlay covering only the top area (excluding piano)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom:
                  MediaQuery.of(context).size.height /
                  3, // Leave bottom third for piano
              child: SwipeGestureDetector(
                onSwipeLeftThreeFingers: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const PhotoVibroScreen(),
                    ),
                  );
                },
                onSwipeRightThreeFingers: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const SpeechVibroScreen(),
                    ),
                  );
                },
                onSwipeUpThreeFingers: () async {
                  if (!_isSpeaking) {
                    _isSpeaking = true;
                    try {
                      await _askAssistant();
                    } catch (e) {
                      _loggingService.error('Error asking assistant: $e');
                    } finally {
                      _isSpeaking = false;
                    }
                  }
                },
                onSwipeDownThreeFingers: () async {
                  if (!_isSpeaking) {
                    _isSpeaking = true;
                    try {
                      await _speakText();
                    } catch (e) {
                      _loggingService.error('Error speaking text: $e');
                    } finally {
                      _isSpeaking = false;
                    }
                  }
                },
                onTap: () {
                  // Delete functionality - tap anywhere to delete
                  _handleBackspace();
                },
                onLongPress: () {
                  // Clear all text - three finger tap to clear all
                  _handleClearAll();
                },
                child: Container(
                  // Transparent container that covers only the top area
                  color: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    final l10n = context.l10n;
    switch (_currentState) {
      case BrailleInputState.ready:
        return IconTextWidget(
          svgIcon: IconPaths.keyboard,
          text: _displayText,
          iconColor: Colors.grey,
          textColor: Colors.grey,
        );
      case BrailleInputState.processingTransform:
        return IconTextWidget(
          imageIcon: IconPaths.gemma3n,
          text: l10n.brailleDecoding,
          textColor: Colors.white,
        );
      case BrailleInputState.processingOutput:
        return IconTextWidget(
          svgIcon: IconPaths.speak2,
          text: l10n.brailleSpeaking,
          iconColor: Colors.green,
          textColor: Colors.green,
        );
      case BrailleInputState.processingAssistant:
        return IconTextWidget(
          imageIcon: IconPaths.gemma3n,
          text: l10n.braillePreparingAnswer,
          textColor: Colors.white,
        );
    }
  }
}
