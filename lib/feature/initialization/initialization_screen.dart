import 'package:flutter/material.dart';

import '../../core/gemma_service.dart';
import '../../core/vibration_notification_service.dart';
import '../../outputs/tts.dart';
import '../braille_input/braille_input_screen.dart';

enum ServiceStatus { pending, checking, success, error, retrying }

class ServiceInitializationState {
  final String name;
  String description;
  ServiceStatus status;
  String? errorMessage;
  String? fixInstructions;
  double? progress;

  ServiceInitializationState({
    required this.name,
    required this.description,
    this.status = ServiceStatus.pending,
    this.errorMessage,
    this.fixInstructions,
    this.progress,
  });
}

class InitializationScreen extends StatefulWidget {
  const InitializationScreen({super.key});

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  late List<ServiceInitializationState> services;
  int currentServiceIndex = 0;
  bool isComplete = false;
  bool hasErrors = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _startInitialization();
  }

  void _initializeServices() {
    services = [
      ServiceInitializationState(
        name: 'Vibration Service',
        description: 'Checking device vibration capabilities',
      ),
      ServiceInitializationState(
        name: 'Text-to-Speech',
        description: 'Initializing speech synthesis engine',
      ),
      ServiceInitializationState(
        name: 'Gemma AI Model',
        description: 'Loading AI model for braille translation',
      ),
    ];
  }

  Future<void> _startInitialization() async {
    for (int i = 0; i < services.length; i++) {
      if (mounted) {
        setState(() {
          currentServiceIndex = i;
          services[i].status = ServiceStatus.checking;
        });
      }

      await _initializeService(i);

      // If service failed, stop and show error
      if (services[i].status == ServiceStatus.error) {
        if (mounted) {
          setState(() {
            isComplete = true;
            hasErrors = true;
          });
        }
        return;
      }

      // Add small delay between services for better UX
      if (i < services.length - 1) {
        await Future.delayed(const Duration(milliseconds: 800));
      }
    }

    if (mounted) {
      setState(() {
        isComplete = true;
        hasErrors = false;
      });

      // Auto-navigate to braille screen after successful initialization
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const BrailleInputScreen()),
        );
      }
    }
  }

  Future<void> _initializeService(int index) async {
    final service = services[index];

    try {
      switch (index) {
        case 0: // Vibration Service
          await _initializeVibrationService(service);
          break;
        case 1: // TTS Service
          await _initializeTtsService(service);
          break;
        case 2: // Gemma Service
          await _initializeGemmaService(service);
          break;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          service.status = ServiceStatus.error;
          service.errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _initializeVibrationService(
    ServiceInitializationState service,
  ) async {
    try {
      final isAvailable = await VibrationNotificationService.isAvailable();

      if (mounted) {
        setState(() {
          if (isAvailable) {
            service.status = ServiceStatus.success;
          } else {
            service.status = ServiceStatus.error;
            service.errorMessage = 'Vibration not available on this device';
            service.fixInstructions =
                'This device does not support vibration. The app will work without haptic feedback.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          service.status = ServiceStatus.error;
          service.errorMessage = 'Failed to check vibration capabilities: $e';
          service.fixInstructions =
              'Please ensure your device supports vibration and try restarting the app.';
        });
      }
    }
  }

  Future<void> _initializeTtsService(ServiceInitializationState service) async {
    try {
      final ttsService = TtsService();
      final success = await ttsService.initialize();

      if (mounted) {
        setState(() {
          if (success) {
            service.status = ServiceStatus.success;
          } else {
            service.status = ServiceStatus.error;
            service.errorMessage = 'Failed to initialize Text-to-Speech';
            service.fixInstructions =
                'Please ensure your device has TTS capabilities enabled in system settings.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          service.status = ServiceStatus.error;
          service.errorMessage = 'TTS initialization error: $e';
          service.fixInstructions =
              'Go to Settings > Accessibility > Text-to-Speech and ensure it\'s enabled.';
        });
      }
    }
  }

  Future<void> _initializeGemmaService(
    ServiceInitializationState service,
  ) async {
    try {
      final gemmaService = GemmaService.instance;

      // Listen to loading progress
      gemmaService.downloadProgressStream.listen((progress) {
        if (mounted && progress != null) {
          setState(() {
            service.progress = progress;
          });
        }
      });

      gemmaService.loadingMessageStream.listen((message) {
        if (mounted) {
          setState(() {
            service.description = message;
          });
        }
      });

      await gemmaService.initialize();

      if (mounted) {
        setState(() {
          if (gemmaService.isInitialized) {
            service.status = ServiceStatus.success;
            service.description = 'AI model ready';
          } else {
            service.status = ServiceStatus.error;
            service.errorMessage = gemmaService.errorMessage ?? 'Unknown error';
            service.fixInstructions = _getGemmaFixInstructions(
              gemmaService.errorMessage,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          service.status = ServiceStatus.error;
          service.errorMessage = 'Gemma initialization error: $e';
          service.fixInstructions = _getGemmaFixInstructions(e.toString());
        });
      }
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

  Future<void> _retryService(int index) async {
    if (mounted) {
      setState(() {
        isComplete = false;
        hasErrors = false;
        currentServiceIndex = 0;
        for (var service in services) {
          service.status = ServiceStatus.pending;
          service.errorMessage = null;
          service.fixInstructions = null;
          service.progress = null;
        }
      });
    }
    _startInitialization();
  }

  Future<void> _skipToNextScreen() async {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const BrailleInputScreen()),
      );
    }
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
              // Header
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
              const SizedBox(height: 10),

              // Current Step Display
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isComplete) ...[
                        _buildCurrentStep(),
                      ] else if (hasErrors) ...[
                        _buildErrorState(),
                      ] else ...[
                        _buildSuccessState(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    final service = services[currentServiceIndex];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Step indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < services.length; i++) ...[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < currentServiceIndex
                      ? Colors.green
                      : i == currentServiceIndex
                      ? Colors.blue
                      : Colors.grey[700],
                ),
              ),
              if (i < services.length - 1)
                Container(
                  width: 40,
                  height: 2,
                  color: i < currentServiceIndex
                      ? Colors.green
                      : Colors.grey[700],
                ),
            ],
          ],
        ),
        const SizedBox(height: 60),

        // Status icon
        _buildStatusIcon(service.status),
        const SizedBox(height: 24),

        // Service name
        Text(
          service.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        // Description
        Text(
          service.description,
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
          textAlign: TextAlign.center,
        ),

        // Progress bar for downloading
        if (service.progress != null) ...[
          const SizedBox(height: 32),
          SizedBox(
            width: 280,
            child: LinearProgressIndicator(
              value: service.progress,
              backgroundColor: Colors.grey[800],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorState() {
    final service = services[currentServiceIndex];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error, color: Colors.red, size: 64),
        const SizedBox(height: 15),
        Text(
          'Initialization Failed: ${service.name}',
          style: TextStyle(
            color: Colors.red,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Error message
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red[900]?.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[700]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Error: ${service.errorMessage}',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _retryService(currentServiceIndex),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextButton(
                onPressed: _skipToNextScreen,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Skip',
                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 64),
        const SizedBox(height: 24),
        const Text(
          'All Services Ready!',
          style: TextStyle(
            color: Colors.green,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Launching Braille Interface...',
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildStatusIcon(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.pending:
        return Icon(
          Icons.radio_button_unchecked,
          color: Colors.grey[600],
          size: 48,
        );
      case ServiceStatus.checking:
      case ServiceStatus.retrying:
        return const SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        );
      case ServiceStatus.success:
        return const Icon(Icons.check_circle, color: Colors.green, size: 48);
      case ServiceStatus.error:
        return const Icon(Icons.error, color: Colors.red, size: 48);
    }
  }
}
