import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/core/chat.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import '../domain/model.dart';
import 'model_downloader.dart';

abstract class IAiModelService {
  Stream<String> get loadingMessageStream;
  Stream<double?> get downloadProgressStream;

  bool get isInitialized;
  String? get errorMessage;

  Future<void> initialize();
  Future<InferenceChat> createChat({
    bool supportImage = true,
    double temperature = 0,
  });
  Future<InferenceModelSession> createSession();
  void dispose();
}

class GemmaService implements IAiModelService {
  InferenceModel? _inferenceModel;
  late final ModelDownloader _downloaderDataSource;

  double? _downloadProgress;
  String? _errorMessage;
  String _loadingMessage = 'Initializing...';
  bool _canRetry = false;
  bool _isModelLoading = false;

  // Stream controllers for state updates
  final _modelLoadingController = StreamController<bool>.broadcast();
  final _loadingMessageController = StreamController<String>.broadcast();
  final _downloadProgressController = StreamController<double?>.broadcast();
  final _errorMessageController = StreamController<String?>.broadcast();
  final _canRetryController = StreamController<bool>.broadcast();

  // Stream getters
  @override
  Stream<String> get loadingMessageStream => _loadingMessageController.stream;

  @override
  Stream<double?> get downloadProgressStream =>
      _downloadProgressController.stream;

  // Getters for current state
  bool get isModelLoading => _isModelLoading;
  String get loadingMessage => _loadingMessage;
  double? get downloadProgress => _downloadProgress;
  bool get canRetry => _canRetry;

  @override
  String? get errorMessage => _errorMessage;

  @override
  bool get isInitialized => _inferenceModel != null;

  /// Initialize the Gemma service
  @override
  Future<void> initialize() async {
    _downloaderDataSource = ModelDownloader(model: Model.gemma3nNetwork);
    await _initializeModel();
  }

  /// Send a message and get a response stream
  @override
  Future<InferenceChat> createChat({
    bool supportImage = true,
    double temperature = 0,
  }) async {
    return await _inferenceModel!.createChat(
      supportImage: supportImage,
      temperature: temperature,
      randomSeed: 1,
      topK: 1,
    );
  }

  @override
  Future<InferenceModelSession> createSession() async {
    return await _inferenceModel!.createSession(
      temperature: 0,
      randomSeed: 1,
      topK: 1,
    );
  }

  /// Dispose of resources
  @override
  void dispose() {
    _modelLoadingController.close();
    _loadingMessageController.close();
    _downloadProgressController.close();
    _errorMessageController.close();
    _canRetryController.close();
  }

  /// Initialize the AI model
  Future<void> _initializeModel() async {
    _updateState(
      isModelLoading: true,
      errorMessage: null,
      canRetry: false,
      loadingMessage: 'Initializing...',
      downloadProgress: null,
    );

    try {
      final gemma = FlutterGemmaPlugin.instance;
      final isModelInstalled = await _downloaderDataSource
          .checkModelExistence();

      if (!isModelInstalled) {
        _updateState(loadingMessage: 'Downloading Gemma 3N model...');

        await _downloaderDataSource.downloadModel(
          onProgress: (progress) {
            _updateState(
              downloadProgress: progress,
              loadingMessage:
                  'Downloading model... ${(progress * 100).toStringAsFixed(1)}%',
            );
          },
          maxRetries: 3,
        );
      }

      _updateState(
        loadingMessage: 'Initializing AI model...',
        downloadProgress: null,
      );

      final modelManager = gemma.modelManager;
      await modelManager.setModelPath(
        await _downloaderDataSource.getFilePath(),
      );

      _inferenceModel = await gemma.createModel(
        modelType: ModelType.gemmaIt,
        maxTokens: 2048,
        supportImage: true,
        maxNumImages: 1,
      );

      _updateState(isModelLoading: false, errorMessage: null);
    } catch (e) {
      debugPrint("Error initializing model: $e");

      // Check if it's a corrupted model issue
      bool isCorruptionIssue =
          e.toString().contains('file_size') ||
          e.toString().contains('Length and offset too large') ||
          e.toString().contains('validation');

      String errorMsg;
      if (isCorruptionIssue) {
        errorMsg =
            'The AI model file appears to be corrupted. Please try clearing and re-downloading it.';

        // Auto-clear corrupted model
        try {
          await _downloaderDataSource.clearCorruptedModel();
        } catch (clearError) {
          debugPrint("Error clearing corrupted model: $clearError");
        }
      } else if (e.toString().contains('NetworkException') ||
          e.toString().contains('SocketException')) {
        errorMsg =
            'Network error occurred. Please check your internet connection and try again.';
      } else {
        errorMsg = 'Failed to initialize AI model: ${e.toString()}';
      }

      _updateState(
        isModelLoading: false,
        errorMessage: errorMsg,
        canRetry: true,
      );
    }
  }

  /// Update internal state and notify listeners
  void _updateState({
    bool? isModelLoading,
    String? loadingMessage,
    double? downloadProgress,
    String? errorMessage,
    bool? canRetry,
  }) {
    if (isModelLoading != null && _isModelLoading != isModelLoading) {
      _isModelLoading = isModelLoading;
      _modelLoadingController.add(_isModelLoading);
    }

    if (loadingMessage != null && _loadingMessage != loadingMessage) {
      _loadingMessage = loadingMessage;
      _loadingMessageController.add(_loadingMessage);
    }

    if (downloadProgress != _downloadProgress) {
      _downloadProgress = downloadProgress;
      _downloadProgressController.add(_downloadProgress);
    }

    if (errorMessage != _errorMessage) {
      _errorMessage = errorMessage;
      _errorMessageController.add(_errorMessage);
    }

    if (canRetry != null && _canRetry != canRetry) {
      _canRetry = canRetry;
      _canRetryController.add(_canRetry);
    }
  }
}
