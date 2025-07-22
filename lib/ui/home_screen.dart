import 'package:feelu/core/model.dart';
import 'package:feelu/core/model_downloader.dart';
import 'package:feelu/ui/widgets/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/chat.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  InferenceModel? _inferenceModel;
  InferenceChat? _chat;

  final List<Message> _messages = [];

  bool _isModelLoading = true;
  String _loadingMessage = 'Initializing...';
  double? _downloadProgress;
  bool _isAwaitingResponse = false;
  String? _errorMessage;
  bool _canRetry = false;

  Uint8List? _selectedImage;

  final _textController = TextEditingController();

  late final ModelDownloader _downloaderDataSource;

  @override
  void initState() {
    super.initState();
    _downloaderDataSource = ModelDownloader(model: Model.gemma3nNetwork);
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    setState(() {
      _isModelLoading = true;
      _errorMessage = null;
      _canRetry = false;
      _loadingMessage = 'Initializing...';
      _downloadProgress = null;
    });

    try {
      final gemma = FlutterGemmaPlugin.instance;
      final isModelInstalled = await _downloaderDataSource
          .checkModelExistence();

      if (!isModelInstalled) {
        setState(() {
          _loadingMessage = 'Downloading Gemma 3N model...';
        });

        await _downloaderDataSource.downloadModel(
          onProgress: (progress) {
            setState(() {
              _downloadProgress = progress;
              _loadingMessage =
                  'Downloading model... ${(progress * 100).toStringAsFixed(1)}%';
            });
          },
          maxRetries: 3,
        );
      }

      setState(() {
        _loadingMessage = 'Initializing AI model...';
        _downloadProgress = null;
      });

      final modelManager = gemma.modelManager;
      await modelManager.setModelPath(
        await _downloaderDataSource.getFilePath(),
      );

      _inferenceModel = await gemma.createModel(
        modelType: ModelType.gemmaIt,
        maxTokens: 2048,
      );

      _chat = await _inferenceModel!.createChat(supportImage: true);

      setState(() {
        _isModelLoading = false;
        _errorMessage = null;
      });
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

      setState(() {
        _isModelLoading = false;
        _errorMessage = errorMsg;
        _canRetry = true;
      });
    }
  }

  void _retryInitialization() {
    _initializeModel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FeelU'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.blue.shade100],
          ),
        ),
        child: _isModelLoading
            ? LoadingWidget(
                loadingMessage: _loadingMessage,
                downloadProgress: _downloadProgress,
              )
            : _errorMessage != null
            ? ErrorDisplayWidget(
                errorMessage: _errorMessage!,
                canRetry: _canRetry,
                onRetry: _retryInitialization,
                downloaderDataSource: _downloaderDataSource,
              )
            : Column(
                children: [
                  Expanded(
                    child: ChatList(
                      messages: _messages,
                      isAwaitingResponse: _isAwaitingResponse,
                    ),
                  ),
                  ChatInputArea(
                    textController: _textController,
                    selectedImage: _selectedImage,
                    isAwaitingResponse: _isAwaitingResponse,
                    onSendMessage: _sendMessage,
                    onRemoveImage: () {
                      setState(() => _selectedImage = null);
                    },
                  ),
                ],
              ),
      ),
    );
  }

  void _sendMessage() async {
    final text = _textController.text.trim();

    if (text.isEmpty) {
      return;
    }

    if (_isAwaitingResponse) return;

    setState(() {
      _isAwaitingResponse = true;
    });

    // 1. Create the user's message object.
    // Use a default prompt if the user only provides an image.
    final userMessage = Message.text(text: text, isUser: true);

    // 2. Add the user's message to the UI and clear the input fields.
    setState(() {
      _messages.add(userMessage);
      _selectedImage = null; // Clear the image preview
    });

    _textController.clear();
    FocusScope.of(context).unfocus();

    try {
      // 3. Send the user's message to the Gemma chat instance.
      await _chat!.addQueryChunk(userMessage);

      // 4. Add an empty placeholder for the AI's response.
      // We will update THIS message instead of adding new ones.
      final responsePlaceholder = Message(text: '', isUser: false);
      setState(() {
        _messages.add(responsePlaceholder);
      });

      // 5. Listen to the stream and aggregate the tokens.
      final responseStream = _chat!.generateChatResponseAsync();

      await for (final token in responseStream) {
        if (!mounted) return;
        setState(() {
          // Get the last message in the list (our placeholder).
          final lastMessage = _messages.last;
          // Append the new token to its text.
          final updatedText = lastMessage.text + token;
          // Replace the old message with the updated one.
          _messages[_messages.length - 1] = Message(
            text: updatedText,
            isUser: false,
          );
        });
      }
    } catch (e) {
      debugPrint("Error during chat generation: $e");
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error generating response: $e'),
            backgroundColor: Colors.red,
          ),
        );
        // If an error occurs, remove the empty AI message placeholder.
        setState(() {
          if (_messages.isNotEmpty && !_messages.last.isUser) {
            _messages.removeLast();
          }
        });
      }
    } finally {
      // 6. Once the stream is complete, allow the user to send another message.
      if (mounted) {
        setState(() {
          _isAwaitingResponse = false;
        });
      }
    }
  }
}
