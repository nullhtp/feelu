import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/core/chat.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import 'model.dart';
import 'model_downloader.dart';

/// Service class that handles all Gemma AI model operations
class GemmaService {
  static GemmaService? _instance;
  static GemmaService get instance => _instance ??= GemmaService._();

  GemmaService._();

  InferenceModel? _inferenceModel;
  InferenceChat? _chat;
  late final ModelDownloader _downloaderDataSource;

  bool _isModelLoading = false;
  String _loadingMessage = 'Initializing...';
  double? _downloadProgress;
  String? _errorMessage;
  bool _canRetry = false;

  // Stream controllers for state updates
  final _modelLoadingController = StreamController<bool>.broadcast();
  final _loadingMessageController = StreamController<String>.broadcast();
  final _downloadProgressController = StreamController<double?>.broadcast();
  final _errorMessageController = StreamController<String?>.broadcast();
  final _canRetryController = StreamController<bool>.broadcast();

  // Stream getters
  Stream<bool> get modelLoadingStream => _modelLoadingController.stream;
  Stream<String> get loadingMessageStream => _loadingMessageController.stream;
  Stream<double?> get downloadProgressStream =>
      _downloadProgressController.stream;
  Stream<String?> get errorMessageStream => _errorMessageController.stream;
  Stream<bool> get canRetryStream => _canRetryController.stream;

  // Getters for current state
  bool get isModelLoading => _isModelLoading;
  String get loadingMessage => _loadingMessage;
  double? get downloadProgress => _downloadProgress;
  String? get errorMessage => _errorMessage;
  bool get canRetry => _canRetry;
  bool get isInitialized => _inferenceModel != null && _chat != null;

  /// Initialize the Gemma service
  Future<void> initialize() async {
    _downloaderDataSource = ModelDownloader(model: Model.gemma3nNetwork);
    await _initializeModel();
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
      );

      _chat = await _inferenceModel!.createChat(supportImage: true);

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

  /// Retry model initialization
  Future<void> retryInitialization() async {
    await _initializeModel();
  }

  /// Send a message and get a response stream
  Stream<String> sendMessage(String text) async* {
    if (!isInitialized) {
      throw Exception('Model not initialized');
    }

    if (text.isEmpty) {
      return;
    }

    try {
      // Create and send the user's message
      final userMessage = Message.text(text: text, isUser: true);
      await _chat!.addQueryChunk(userMessage);

      // Generate and stream the response
      final responseStream = _chat!.generateChatResponseAsync();
      yield* responseStream;
    } catch (e) {
      debugPrint("Error during chat generation: $e");
      throw Exception('Error generating response: $e');
    }
  }

  /// Clear corrupted model
  Future<void> clearCorruptedModel() async {
    await _downloaderDataSource.clearCorruptedModel();
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

  /// Dispose of resources
  void dispose() {
    _modelLoadingController.close();
    _loadingMessageController.close();
    _downloadProgressController.close();
    _errorMessageController.close();
    _canRetryController.close();
  }
}
