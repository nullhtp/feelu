import 'dart:async';

import '../../core/di/service_locator.dart';
import '../../core/services/services.dart';
import 'models/service_initialization_state.dart';

class InitializationService {
  final StreamController<List<ServiceInitializationState>> _servicesController =
      StreamController<List<ServiceInitializationState>>.broadcast();
  final StreamController<int> _currentIndexController =
      StreamController<int>.broadcast();
  final StreamController<bool> _completionController =
      StreamController<bool>.broadcast();

  final IVibrationNotification _vibrationNotificationService =
      ServiceLocator.get<IVibrationNotification>();
  final ICameraService _cameraService = ServiceLocator.get<ICameraService>();
  final ITtsService _ttsService = ServiceLocator.get<ITtsService>();
  final ISpeechRecognitionService _speechRecognitionService =
      ServiceLocator.get<ISpeechRecognitionService>();
  final IAiModelService _aiModelService = ServiceLocator.get<IAiModelService>();

  Stream<List<ServiceInitializationState>> get servicesStream =>
      _servicesController.stream;
  Stream<int> get currentIndexStream => _currentIndexController.stream;
  Stream<bool> get completionStream => _completionController.stream;

  List<ServiceInitializationState> _services = [];
  int _currentIndex = 0;
  bool _isInitializing = false;

  List<ServiceInitializationState> get services => List.unmodifiable(_services);
  int get currentIndex => _currentIndex;
  bool get isInitializing => _isInitializing;

  void initialize() {
    _initializeServices();
    _servicesController.add(_services);
  }

  void _initializeServices() {
    _services = [
      ServiceInitializationState(
        name: 'Vibration Service',
        description: 'Checking device vibration capabilities',
      ),
      ServiceInitializationState(
        name: 'Camera Service',
        description: 'Initializing camera for photo recognition',
      ),
      ServiceInitializationState(
        name: 'Text-to-Speech',
        description: 'Initializing speech synthesis engine',
      ),
      ServiceInitializationState(
        name: 'Speech Recognition',
        description: 'Initializing speech recognition engine',
      ),
      ServiceInitializationState(
        name: 'Gemma AI Model',
        description: 'Loading AI model for braille translation',
      ),
    ];
  }

  Future<bool> startInitialization() async {
    if (_isInitializing) return false;

    _isInitializing = true;

    for (int i = 0; i < _services.length; i++) {
      _currentIndex = i;
      _currentIndexController.add(_currentIndex);

      _updateServiceStatus(i, ServiceStatus.checking);

      final success = await _initializeService(i);

      if (!success) {
        _isInitializing = false;
        _completionController.add(false);
        return false;
      }

      // Add delay between services for better UX
      if (i < _services.length - 1) {
        await Future.delayed(const Duration(milliseconds: 800));
      }
    }

    _isInitializing = false;
    _completionController.add(true);
    return true;
  }

  Future<bool> _initializeService(int index) async {
    try {
      switch (index) {
        case 0:
          return await _initializeVibrationService(index);
        case 1:
          return await _initializeCameraService(index);
        case 2:
          return await _initializeTtsService(index);
        case 3:
          return await _initializeSpeechRecognitionService(index);
        case 4:
          return await _initializeGemmaService(index);
        default:
          return false;
      }
    } catch (e) {
      _updateServiceError(index, e.toString());
      return false;
    }
  }

  Future<bool> _initializeVibrationService(int index) async {
    try {
      final isAvailable = await _vibrationNotificationService.isAvailable();

      if (isAvailable) {
        _updateServiceStatus(index, ServiceStatus.success);
        return true;
      } else {
        _updateServiceError(
          index,
          'Vibration not available on this device',
          'This device does not support vibration. The app will work without haptic feedback.',
        );
        return false;
      }
    } catch (e) {
      _updateServiceError(
        index,
        'Failed to check vibration capabilities: $e',
        'Please ensure your device supports vibration and try restarting the app.',
      );
      return false;
    }
  }

  Future<bool> _initializeCameraService(int index) async {
    try {
      final success = await _cameraService.initialize();

      if (success) {
        _updateServiceStatus(index, ServiceStatus.success);
        return true;
      } else {
        _updateServiceError(
          index,
          'Failed to initialize Camera Service',
          'Please ensure your device has camera capabilities enabled in system settings.',
        );
        return false;
      }
    } catch (e) {
      _updateServiceError(
        index,
        'Camera Service initialization error: $e',
        'Go to Settings > Privacy & Security > Camera and ensure it\'s enabled.',
      );
      return false;
    }
  }

  Future<bool> _initializeTtsService(int index) async {
    try {
      final success = await _ttsService.initialize();

      if (success) {
        _updateServiceStatus(index, ServiceStatus.success);
        return true;
      } else {
        _updateServiceError(
          index,
          'Failed to initialize Text-to-Speech',
          'Please ensure your device has TTS capabilities enabled in system settings.',
        );
        return false;
      }
    } catch (e) {
      _updateServiceError(
        index,
        'TTS initialization error: $e',
        'Go to Settings > Accessibility > Text-to-Speech and ensure it\'s enabled.',
      );
      return false;
    }
  }

  Future<bool> _initializeSpeechRecognitionService(int index) async {
    try {
      await _speechRecognitionService.initialize();

      if (_speechRecognitionService.isInitialized) {
        _updateServiceDescription(index, 'Speech recognition ready');
        _updateServiceStatus(index, ServiceStatus.success);
        return true;
      } else {
        _updateServiceError(
          index,
          'Failed to initialize Speech Recognition',
          'Please ensure your device has speech recognition capabilities enabled in system settings.',
        );
        return false;
      }
    } catch (e) {
      _updateServiceError(
        index,
        'Speech recognition initialization error: $e',
        'Go to Settings > Privacy & Security > Speech Recognition and ensure it\'s enabled.',
      );
      return false;
    }
  }

  Future<bool> _initializeGemmaService(int index) async {
    try {
      // Listen to progress and loading messages
      final progressSubscription = _aiModelService.downloadProgressStream
          .listen((progress) {
            if (progress != null) {
              _updateServiceProgress(index, progress);
            }
          });

      final messageSubscription = _aiModelService.loadingMessageStream.listen((
        message,
      ) {
        _updateServiceDescription(index, message);
      });

      await _aiModelService.initialize();

      // Cancel subscriptions
      await progressSubscription.cancel();
      await messageSubscription.cancel();

      if (_aiModelService.isInitialized) {
        _updateServiceDescription(index, 'AI model ready');
        _updateServiceStatus(index, ServiceStatus.success);
        return true;
      } else {
        _updateServiceError(
          index,
          _aiModelService.errorMessage ?? 'Unknown error',
          _getGemmaFixInstructions(_aiModelService.errorMessage),
        );
        return false;
      }
    } catch (e) {
      _updateServiceError(
        index,
        'Gemma initialization error: $e',
        _getGemmaFixInstructions(e.toString()),
      );
      return false;
    }
  }

  String _getGemmaFixInstructions(String? error) {
    if (error == null) return 'Try restarting the app.';

    if (error.contains('Network') || error.contains('connection')) {
      return 'Check your internet connection and try again. The AI model needs to be downloaded on first use.';
    } else if (error.contains('corrupted') || error.contains('validation')) {
      return 'The model file is corrupted. Tap "Retry" to clear and re-download the model.';
    } else if (error.contains('storage') || error.contains('space')) {
      return 'Free up storage space on your device. The AI model requires about 2GB of space.';
    } else {
      return 'Try restarting the app. If the problem persists, clear app data and try again.';
    }
  }

  void _updateServiceStatus(int index, ServiceStatus status) {
    if (index < _services.length) {
      _services[index] = _services[index].copyWith(status: status);
      _servicesController.add(_services);
    }
  }

  void _updateServiceDescription(int index, String description) {
    if (index < _services.length) {
      _services[index] = _services[index].copyWith(description: description);
      _servicesController.add(_services);
    }
  }

  void _updateServiceProgress(int index, double progress) {
    if (index < _services.length) {
      _services[index] = _services[index].copyWith(progress: progress);
      _servicesController.add(_services);
    }
  }

  void _updateServiceError(int index, String error, [String? fixInstructions]) {
    if (index < _services.length) {
      _services[index] = _services[index].copyWith(
        status: ServiceStatus.error,
        errorMessage: error,
        fixInstructions: fixInstructions,
      );
      _servicesController.add(_services);
    }
  }

  Future<void> retryInitialization() async {
    _currentIndex = 0;
    _isInitializing = false;

    // Reset all services
    for (int i = 0; i < _services.length; i++) {
      _services[i] = _services[i].copyWith(
        status: ServiceStatus.pending,
        errorMessage: null,
        fixInstructions: null,
        progress: null,
      );
    }

    _servicesController.add(_services);
    await startInitialization();
  }

  void dispose() {
    _servicesController.close();
    _currentIndexController.close();
    _completionController.close();
  }
}
