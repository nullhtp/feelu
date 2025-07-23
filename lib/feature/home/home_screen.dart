import 'dart:async';

import 'package:feelu/core/gemma_service.dart';
import 'package:feelu/feature/home/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Message> _messages = [];
  bool _isAwaitingResponse = false;

  final _textController = TextEditingController();
  final _gemmaService = GemmaService.instance;

  // Stream subscriptions
  late final List<StreamSubscription> _subscriptions;

  // Current state from service
  bool _isModelLoading = true;
  String _loadingMessage = 'Initializing...';
  double? _downloadProgress;
  String? _errorMessage;
  bool _canRetry = false;

  @override
  void initState() {
    super.initState();
    _initializeService();
    _subscribeToServiceStreams();
  }

  void _initializeService() async {
    await _gemmaService.initialize();
  }

  void _subscribeToServiceStreams() {
    _subscriptions = [
      _gemmaService.modelLoadingStream.listen((isLoading) {
        if (mounted) {
          setState(() {
            _isModelLoading = isLoading;
          });
        }
      }),
      _gemmaService.loadingMessageStream.listen((message) {
        if (mounted) {
          setState(() {
            _loadingMessage = message;
          });
        }
      }),
      _gemmaService.downloadProgressStream.listen((progress) {
        if (mounted) {
          setState(() {
            _downloadProgress = progress;
          });
        }
      }),
      _gemmaService.errorMessageStream.listen((error) {
        if (mounted) {
          setState(() {
            _errorMessage = error;
          });
        }
      }),
      _gemmaService.canRetryStream.listen((canRetry) {
        if (mounted) {
          setState(() {
            _canRetry = canRetry;
          });
        }
      }),
    ];
  }

  @override
  void dispose() {
    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _textController.dispose();
    super.dispose();
  }

  void _retryInitialization() {
    _gemmaService.retryInitialization();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.accessibility_new),
            onPressed: () {
              Navigator.pop(context);
            },
            tooltip: 'Back to Braille Input',
          ),
        ],
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
                onClearModel: () async {
                  try {
                    await _gemmaService.clearCorruptedModel();
                    _retryInitialization();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error clearing model: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
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
                    isAwaitingResponse: _isAwaitingResponse,
                    onSendMessage: _sendMessage,
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
    final userMessage = Message.text(text: text, isUser: true);

    // 2. Add the user's message to the UI and clear the input fields.
    setState(() {
      _messages.add(userMessage);
    });

    _textController.clear();
    FocusScope.of(context).unfocus();

    try {
      // 3. Add an empty placeholder for the AI's response.
      final responsePlaceholder = Message(text: '', isUser: false);
      setState(() {
        _messages.add(responsePlaceholder);
      });

      // 4. Listen to the response stream and aggregate the tokens.
      final chat = await _gemmaService.createChat();
      chat.addQueryChunk(responsePlaceholder);
      final responseStream = chat.generateChatResponseAsync();

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
      // 5. Once the stream is complete, allow the user to send another message.
      if (mounted) {
        setState(() {
          _isAwaitingResponse = false;
        });
      }
    }
  }
}
