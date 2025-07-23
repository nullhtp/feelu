import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/pigeon.g.dart';

enum Model {
  gemma3nNetwork(
    // Model will be downloaded from network on first use
    url:
        'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task',
    filename: 'gemma-3n-E2B-it-int4.task',
    displayName: 'Gemma 3 Nano E2B IT Multimodal (Network Download)',
    licenseUrl: 'https://ai.google.dev/gemma/terms',
    needsAuth: false,
    localModel: true,
    preferredBackend: PreferredBackend.cpu,
    modelType: ModelType.gemmaIt,
    temperature: 0.1,
    topK: 5,
    supportImage: true,
    maxTokens: 2048,
    maxNumImages: 1,
    topP: 0.95,
  );

  // Define fields for the enum
  final String url;
  final String filename;
  final String displayName;
  final String licenseUrl;
  final bool needsAuth;
  final bool localModel;
  final PreferredBackend preferredBackend;
  final ModelType modelType;
  final double temperature;
  final int topK;
  final double topP;
  final bool supportImage;
  final int maxTokens;
  final int? maxNumImages;

  // Constructor for the enum
  const Model({
    required this.url,
    required this.filename,
    required this.displayName,
    required this.licenseUrl,
    required this.needsAuth,
    this.localModel = false,
    required this.preferredBackend,
    required this.modelType,
    required this.temperature,
    required this.topK,
    required this.topP,
    this.supportImage = false,
    this.maxTokens = 1024,
    this.maxNumImages,
  });
}
