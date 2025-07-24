import 'package:flutter/material.dart';

import '../braille_input/braille_input_screen.dart';
import 'models/service_initialization_state.dart';
import 'initialization_service.dart';
import 'widgets/widgets.dart';

class InitializationScreen extends StatefulWidget {
  const InitializationScreen({super.key});

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  final InitializationService _initializationService =
      InitializationService.instance;

  List<ServiceInitializationState> _services = [];
  int _currentIndex = 0;
  bool _isComplete = false;
  bool _hasErrors = false;

  @override
  void initState() {
    super.initState();
    _setupListeners();
    _initializationService.initialize();
    _startInitialization();
  }

  void _setupListeners() {
    _initializationService.servicesStream.listen((services) {
      if (mounted) {
        setState(() {
          _services = services;
          _hasErrors = services.any((service) => service.isError);
        });
      }
    });

    _initializationService.currentIndexStream.listen((index) {
      if (mounted) {
        setState(() {
          _currentIndex = index;
        });
      }
    });

    _initializationService.completionStream.listen((isComplete) {
      if (mounted) {
        setState(() {
          _isComplete = isComplete;
        });

        // Auto-navigate to braille screen after successful initialization
        if (isComplete && !_hasErrors) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              _navigateToBrailleScreen();
            }
          });
        }
      }
    });
  }

  Future<void> _startInitialization() async {
    await _initializationService.startInitialization();
  }

  Future<void> _retryInitialization() async {
    setState(() {
      _isComplete = false;
      _hasErrors = false;
    });
    await _initializationService.retryInitialization();
  }

  void _navigateToBrailleScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const BrailleInputScreen()),
    );
  }

  @override
  void dispose() {
    // Note: We don't dispose the service here as it might be used elsewhere
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 10),
              _buildStepIndicator(),
              const SizedBox(height: 40),
              Expanded(child: Center(child: _buildCurrentState())),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FeelU',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Initializing Services...',
          style: TextStyle(color: Colors.grey[400], fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    if (_services.isEmpty) {
      return const SizedBox.shrink();
    }

    return ServiceStepIndicator(
      services: _services,
      currentIndex: _currentIndex,
    );
  }

  Widget _buildCurrentState() {
    if (_services.isEmpty) {
      return const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
      );
    }

    if (!_isComplete) {
      return CurrentServiceWidget(service: _services[_currentIndex]);
    } else if (_hasErrors) {
      return ErrorStateWidget(
        service: _services[_currentIndex],
        onRetry: _retryInitialization,
        onSkip: _navigateToBrailleScreen,
      );
    } else {
      return const SuccessStateWidget();
    }
  }
}
