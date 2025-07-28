import 'dart:io';

import 'package:flutter_tts/flutter_tts.dart';

import '../di/service_locator.dart';
import 'logging_service.dart';

abstract class ITtsService {
  Future<bool> initialize();
  Future<void> dispose();
  Future<void> speak(String text);
  Future<void> stop();
  Future<void> pause();
}

/// Text-to-Speech service for offline speech synthesis
class TtsService implements ITtsService {
  final ILoggingService _loggingService = ServiceLocator.get<ILoggingService>();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  // TTS Configuration
  double _volume = 1.0;
  double _pitch = 1.0;
  double _speechRate = 0.5;
  String? _selectedLanguage;
  String? _selectedEngine;
  List<dynamic> _languages = [];
  List<dynamic> _engines = [];

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;
  double get volume => _volume;
  double get pitch => _pitch;
  double get speechRate => _speechRate;
  String? get selectedLanguage => _selectedLanguage;
  String? get selectedEngine => _selectedEngine;
  List<dynamic> get availableLanguages => _languages;
  List<dynamic> get availableEngines => _engines;

  /// Initialize the TTS service
  Future<bool> initialize() async {
    try {
      // Initialize TTS
      await _flutterTts.awaitSpeakCompletion(true);

      // Set up handlers
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        _loggingService.info("TTS: Speech started");
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _loggingService.info("TTS: Speech completed");
      });

      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
        _loggingService.info("TTS: Speech cancelled");
      });

      _flutterTts.setPauseHandler(() {
        _loggingService.info("TTS: Speech paused");
      });

      _flutterTts.setContinueHandler(() {
        _loggingService.info("TTS: Speech continued");
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        _loggingService.error("TTS Error: $msg");
      });

      // Get available languages and engines
      await _getLanguages();
      await _getEngines();

      // Set default configuration
      await _setDefaultConfiguration();

      _isInitialized = true;
      _loggingService.info("TTS Service initialized successfully");
      return true;
    } catch (e) {
      _loggingService.error("TTS initialization error: $e");
      return false;
    }
  }

  /// Get available languages
  Future<void> _getLanguages() async {
    try {
      _languages = await _flutterTts.getLanguages;
      _loggingService.info("Available languages: $_languages");
    } catch (e) {
      _loggingService.error("Error getting languages: $e");
      _languages = [];
    }
  }

  /// Get available engines
  Future<void> _getEngines() async {
    try {
      if (Platform.isAndroid) {
        _engines = await _flutterTts.getEngines;
        _loggingService.info("Available engines: $_engines");
      }
    } catch (e) {
      _loggingService.error("Error getting engines: $e");
      _engines = [];
    }
  }

  /// Set default configuration
  Future<void> _setDefaultConfiguration() async {
    try {
      // Set default language (English if available)
      if (_languages.isNotEmpty) {
        final englishLanguages = _languages.where(
          (lang) => lang.toString().toLowerCase().contains('en'),
        );
        if (englishLanguages.isNotEmpty) {
          _selectedLanguage = englishLanguages.first;
        } else {
          _selectedLanguage = _languages.first;
        }
        await _flutterTts.setLanguage(_selectedLanguage!);
      }

      // Set default engine (if on Android)
      if (Platform.isAndroid && _engines.isNotEmpty) {
        _selectedEngine = _engines.first;
        await _flutterTts.setEngine(_selectedEngine!);
      }

      // Set default voice parameters
      await _flutterTts.setVolume(_volume);
      await _flutterTts.setPitch(_pitch);
      await _flutterTts.setSpeechRate(_speechRate);
    } catch (e) {
      _loggingService.error("Error setting default configuration: $e");
    }
  }

  /// Speak the given text
  Future<bool> speak(String text) async {
    if (!_isInitialized) {
      _loggingService.error("TTS not initialized");
      return false;
    }

    if (text.trim().isEmpty) {
      _loggingService.error("Cannot speak empty text");
      return false;
    }

    try {
      // Stop any ongoing speech
      await stop();

      // Speak the text
      await _flutterTts.speak(text);
      return true;
    } catch (e) {
      _loggingService.error("Error speaking text: $e");
      return false;
    }
  }

  /// Stop speaking
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e) {
      _loggingService.error("Error stopping speech: $e");
    }
  }

  /// Pause speaking
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      _loggingService.error("Error pausing speech: $e");
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      _volume = volume.clamp(0.0, 1.0);
      await _flutterTts.setVolume(_volume);
    } catch (e) {
      _loggingService.error("Error setting volume: $e");
    }
  }

  /// Set pitch (0.5 to 2.0)
  Future<void> setPitch(double pitch) async {
    try {
      _pitch = pitch.clamp(0.5, 2.0);
      await _flutterTts.setPitch(_pitch);
    } catch (e) {
      _loggingService.error("Error setting pitch: $e");
    }
  }

  /// Set speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate) async {
    try {
      _speechRate = rate.clamp(0.0, 1.0);
      await _flutterTts.setSpeechRate(_speechRate);
    } catch (e) {
      _loggingService.error("Error setting speech rate: $e");
    }
  }

  /// Set language
  Future<bool> setLanguage(String language) async {
    try {
      if (_languages.contains(language)) {
        await _flutterTts.setLanguage(language);
        _selectedLanguage = language;
        return true;
      } else {
        _loggingService.error("Language not supported: $language");
        return false;
      }
    } catch (e) {
      _loggingService.error("Error setting language: $e");
      return false;
    }
  }

  /// Set TTS engine (Android only)
  Future<bool> setEngine(String engine) async {
    if (!Platform.isAndroid) {
      _loggingService.error("Engine selection only available on Android");
      return false;
    }

    try {
      if (_engines.contains(engine)) {
        await _flutterTts.setEngine(engine);
        _selectedEngine = engine;
        return true;
      } else {
        _loggingService.error("Engine not available: $engine");
        return false;
      }
    } catch (e) {
      _loggingService.error("Error setting engine: $e");
      return false;
    }
  }

  /// Check if TTS is available on the device
  Future<bool> isLanguageAvailable(String language) async {
    try {
      final result = await _flutterTts.isLanguageAvailable(language);
      return result;
    } catch (e) {
      _loggingService.error("Error checking language availability: $e");
      return false;
    }
  }

  /// Get voices for the current language
  Future<List<dynamic>> getVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      return voices;
    } catch (e) {
      _loggingService.error("Error getting voices: $e");
      return [];
    }
  }

  /// Set voice by name
  Future<bool> setVoice(Map<String, String> voice) async {
    try {
      await _flutterTts.setVoice(voice);
      return true;
    } catch (e) {
      _loggingService.error("Error setting voice: $e");
      return false;
    }
  }

  /// Dispose of the service
  @override
  Future<void> dispose() async {
    stop();
    _isInitialized = false;
  }
}
