import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Configuration service to manage sensitive data like API keys
class Config {
  static Config? _instance;
  static Config get instance => _instance ??= Config._();

  Config._();

  String? _accessToken;

  /// Gets the Hugging Face access token from environment variables or config file
  Future<String?> getAccessToken() async {
    if (_accessToken != null) {
      return _accessToken;
    }

    // Try to get from environment variable first
    _accessToken = Platform.environment['HF_ACCESS_TOKEN'];

    if (_accessToken != null && _accessToken!.isNotEmpty) {
      if (kDebugMode) {
        print('Access token loaded from environment variable');
      }
      return _accessToken;
    }

    // Try to load from local config file
    try {
      final configFile = File('config.json');
      if (await configFile.exists()) {
        final configContent = await configFile.readAsString();
        final config = jsonDecode(configContent) as Map<String, dynamic>;
        _accessToken = config['hf_access_token'] as String?;

        if (_accessToken != null && _accessToken!.isNotEmpty) {
          if (kDebugMode) {
            print('Access token loaded from config.json');
          }
          return _accessToken;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error reading config file: $e');
      }
    }

    if (kDebugMode) {
      print(
        'No access token found. Please set HF_ACCESS_TOKEN environment variable or create config.json',
      );
    }

    return null;
  }

  /// Clears the cached access token (useful for testing or when token changes)
  void clearCache() {
    _accessToken = null;
  }
}
