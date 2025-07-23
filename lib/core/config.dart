import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Configuration service to manage sensitive data like API keys
class Config {
  static Config? _instance;
  static Config get instance => _instance ??= Config._();

  Config._();

  String? _accessToken;

  /// Gets the Hugging Face access token from multiple sources
  Future<String?> getAccessToken() async {
    if (_accessToken != null) {
      return _accessToken;
    }

    // Try to load from assets (read-only, included in app bundle)
    try {
      final assetContent = await rootBundle.loadString('assets/config.json');
      final config = jsonDecode(assetContent) as Map<String, dynamic>;
      _accessToken = config['hf_access_token'] as String?;

      if (_accessToken != null && _accessToken!.isNotEmpty) {
        if (kDebugMode) {
          print('Access token loaded from assets/config.json');
        }
        return _accessToken;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error reading config file from assets: $e');
      }
    }

    return null;
  }
}
