import 'dart:async';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../core/di/service_locator.dart';
import '../../core/services/services.dart';
import 'models/service_initialization_state.dart';

abstract class IInitializationService {
  Stream<List<ServiceInitializationState>> get servicesStream;
  Stream<int> get currentIndexStream;
  Stream<bool> get completionStream;
  void initialize(AppLocalizations localizations);
  Future<bool> startInitialization();
  Future<void> retryInitialization();
  void dispose();
}

class InitializationService implements IInitializationService {
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
  late AppLocalizations _localizations;

  @override
  Stream<List<ServiceInitializationState>> get servicesStream =>
      _servicesController.stream;
  @override
  Stream<int> get currentIndexStream => _currentIndexController.stream;
  @override
  Stream<bool> get completionStream => _completionController.stream;

  List<ServiceInitializationState> _services = [];
  int _currentIndex = 0;
  bool _isInitializing = false;

  List<ServiceInitializationState> get services => List.unmodifiable(_services);
  int get currentIndex => _currentIndex;
  bool get isInitializing => _isInitializing;

  @override
  void initialize(AppLocalizations localizations) {
    _localizations = localizations;
    _services = [];
    _currentIndex = 0;
    _isInitializing = false;
    _initializeServices();
    _servicesController.add(_services);
  }

  void _initializeServices() {
    _services.add(
      ServiceInitializationState(
        name: _localizations.serviceVibrationName,
        description: _localizations.serviceVibrationDescription,
        initiator: _initializeVibrationService,
      ),
    );
    _services.add(
      ServiceInitializationState(
        name: _localizations.serviceCameraName,
        description: _localizations.serviceCameraDescription,
        initiator: _initializeCameraService,
      ),
    );
    _services.add(
      ServiceInitializationState(
        name: _localizations.serviceTtsName,
        description: _localizations.serviceTtsDescription,
        initiator: _initializeTtsService,
      ),
    );
    _services.add(
      ServiceInitializationState(
        name: _localizations.serviceSpeechRecognitionName,
        description: _localizations.serviceSpeechRecognitionDescription,
        initiator: _initializeSpeechRecognitionService,
      ),
    );
    _services.add(
      ServiceInitializationState(
        name: _localizations.serviceGemmaName,
        description: _localizations.serviceGemmaDescription,
        initiator: _initializeGemmaService,
      ),
    );
  }

  @override
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
      final initiator = _services[index].initiator;
      if (initiator != null) {
        return await initiator(index);
      }

      return false;
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
          _localizations.vibrationUnavailableError,
          _localizations.vibrationUnavailableFix,
        );
        return false;
      }
    } catch (e) {
      _updateServiceError(
        index,
        _localizations.vibrationCheckFailedError('$e'),
        _localizations.vibrationCheckFailedFix,
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
          _localizations.cameraInitFailedError,
          _localizations.cameraInitFailedFix,
        );
        return false;
      }
    } catch (e) {
      _updateServiceError(
        index,
        _localizations.cameraInitError('$e'),
        _localizations.cameraInitErrorFix,
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
          _localizations.ttsInitFailedError,
          _localizations.ttsInitFailedFix,
        );
        return false;
      }
    } catch (e) {
      _updateServiceError(
        index,
        _localizations.ttsInitError('$e'),
        _localizations.ttsInitErrorFix,
      );
      return false;
    }
  }

  Future<bool> _initializeSpeechRecognitionService(int index) async {
    try {
      await _speechRecognitionService.initialize();

      if (_speechRecognitionService.isInitialized) {
        _updateServiceDescription(index, _localizations.speechRecognitionReady);
        _updateServiceStatus(index, ServiceStatus.success);
        return true;
      } else {
        _updateServiceError(
          index,
          _localizations.speechInitFailedError,
          _localizations.speechInitFailedFix,
        );
        return false;
      }
    } catch (e) {
      _updateServiceError(
        index,
        _localizations.speechInitError('$e'),
        _localizations.speechInitErrorFix,
      );
      return false;
    }
  }

  Future<bool> _initializeGemmaService(int index) async {
    try {
      final progressSubscription =
          _aiModelService.downloadProgressStream.listen((progress) {
        if (progress != null) {
          _updateServiceProgress(index, progress);
          final progressPercent = '${(progress * 100).toStringAsFixed(1)}%';
          _updateServiceDescription(
            index,
            _localizations.gemmaDownloading(progressPercent),
          );
        }
      });

      _updateServiceDescription(index, _localizations.gemmaInitializing);

      await _aiModelService.initialize();

      await progressSubscription.cancel();

      if (_aiModelService.isInitialized) {
        _updateServiceDescription(index, _localizations.gemmaReady);
        _updateServiceStatus(index, ServiceStatus.success);
        return true;
      } else {
        final error =
            _aiModelService.errorMessage ?? _localizations.gemmaUnknownError;
        _updateServiceError(
          index,
          _localizations.gemmaInitError(error),
          _getGemmaFixInstructions(error),
        );
        return false;
      }
    } catch (e) {
      final errorMessage = e.toString();
      _updateServiceError(
        index,
        _localizations.gemmaInitError(errorMessage),
        _getGemmaFixInstructions(errorMessage),
      );
      return false;
    }
  }

  String _getGemmaFixInstructions(String? error) {
    if (error == null) return _localizations.gemmaFixRestart;

    final lowerError = error.toLowerCase();
    if (lowerError.contains('network') || lowerError.contains('connection')) {
      return _localizations.gemmaFixNetwork;
    } else if (lowerError.contains('corrupted') ||
        lowerError.contains('validation')) {
      return _localizations.gemmaFixCorrupted;
    } else if (lowerError.contains('storage') || lowerError.contains('space')) {
      return _localizations.gemmaFixStorage;
    } else {
      return _localizations.gemmaFixRestart;
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

  @override
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

  @override
  void dispose() {
    _servicesController.close();
    _currentIndexController.close();
    _completionController.close();
  }
}
