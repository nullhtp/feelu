import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Configuration service to manage app configuration and API keys
///
/// This service follows dependency injection principles and can be
/// easily tested and mocked.
class AppConfig {
  String? _accessToken;

  /// Gets the Hugging Face access token from assets
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

  /// Clear cached token (useful for testing)
  void clearCache() {
    _accessToken = null;
  }

  /// Check if token is available in cache
  bool get hasAccessToken => _accessToken != null && _accessToken!.isNotEmpty;
}
