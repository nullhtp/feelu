import 'dart:io';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../di/service_locator.dart';
import '../domain/model.dart';
import 'logging_service.dart';

abstract class IModelDownloader {
  Future<void> downloadModel({
    required Function(double) onProgress,
    int maxRetries = 3,
  });
}

class ModelDownloader implements IModelDownloader {
  final Model model;

  final AppConfig _config = ServiceLocator.get<AppConfig>();
  final ILoggingService _loggingService = ServiceLocator.get<ILoggingService>();

  final modelManager = FlutterGemmaPlugin.instance.modelManager;

  // Minimum expected file size in bytes (2GB for a neural network model)
  static const int _minimumModelSize = 2000 * 1024 * 1024;

  ModelDownloader({required this.model});

  String get _preferenceKey => 'model_downloaded_${model.filename}';

  Future<String> getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/${model.filename}';
  }

  /// Validates if the downloaded file is complete and not corrupted
  Future<bool> _validateModelFile(File file) async {
    if (!file.existsSync()) {
      _loggingService.error('Model file does not exist');
      return false;
    }

    final fileSize = await file.length();
    _loggingService.debug(
      'Model file size: $fileSize bytes (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)',
    );

    if (fileSize < _minimumModelSize) {
      _loggingService.error(
        'Model file too small: $fileSize bytes (minimum: $_minimumModelSize)',
      );
      return false;
    }

    // Additional validation: check if file starts with expected format
    try {
      final bytes = await file.openRead(0, 8).toList();
      if (bytes.isNotEmpty) {
        final firstBytes = bytes.expand((x) => x).take(8).toList();
        _loggingService.debug(
          'Model file first 8 bytes: ${firstBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
        );

        // Basic format validation - check if it's not just zeros or corrupted
        if (firstBytes.every((b) => b == 0)) {
          _loggingService.error(
            'Model file appears to be empty or corrupted (all zeros)',
          );
          return false;
        }
      }
    } catch (e) {
      _loggingService.error('Error reading model file for validation: $e');
      return false;
    }

    return true;
  }

  /// Clears corrupted model files and preferences
  Future<void> clearCorruptedModel() async {
    try {
      final filePath = await getFilePath();
      final file = File(filePath);

      if (file.existsSync()) {
        await file.delete();
        _loggingService.debug('Deleted corrupted model file: $filePath');
      }

      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_preferenceKey);
      _loggingService.debug('Cleared model download preference');
    } catch (e) {
      _loggingService.error('Error clearing corrupted model: $e');
    }
  }

  Future<bool> checkModelExistence() async {
    final preferences = await SharedPreferences.getInstance();
    final filePath = await getFilePath();
    final file = File(filePath);

    // Check if file exists and is valid
    if (file.existsSync()) {
      final isValid = await _validateModelFile(file);
      if (!isValid) {
        // File is corrupted, clear it
        await clearCorruptedModel();
        return false;
      }

      // File exists and is valid, mark as downloaded
      await preferences.setBool(_preferenceKey, true);
      return true;
    }

    // File doesn't exist, check remote and compare
    try {
      final accessToken = await _config.getAccessToken();
      final Map<String, String> headers =
          accessToken != null && accessToken.isNotEmpty
          ? {'Authorization': 'Bearer $accessToken'}
          : {};

      final headResponse = await http.head(
        Uri.parse(model.url),
        headers: headers,
      );

      if (headResponse.statusCode == 200) {
        final contentLengthHeader = headResponse.headers['content-length'];
        if (contentLengthHeader != null) {
          final remoteFileSize = int.parse(contentLengthHeader);
          if (file.existsSync() && await file.length() == remoteFileSize) {
            final isValid = await _validateModelFile(file);
            if (isValid) {
              await preferences.setBool(_preferenceKey, true);
              return true;
            } else {
              await clearCorruptedModel();
            }
          }
        }
      }
    } catch (e) {
      _loggingService.error('Error checking model existence: $e');
    }

    await preferences.setBool(_preferenceKey, false);
    return false;
  }

  /// Downloads the model file and tracks progress with retry logic.
  @override
  Future<void> downloadModel({
    required Function(double) onProgress,
    int maxRetries = 3,
  }) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < maxRetries) {
      attempts++;

      try {
        await _attemptDownload(onProgress);

        // Validate the downloaded file
        final filePath = await getFilePath();
        final file = File(filePath);
        final isValid = await _validateModelFile(file);

        if (!isValid) {
          throw Exception('Downloaded model file failed validation');
        }

        // Success!
        final preferences = await SharedPreferences.getInstance();
        await preferences.setBool(_preferenceKey, true);
        return;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        _loggingService.error('Download attempt $attempts failed: $e');

        // Clear any partially downloaded file before retry
        await clearCorruptedModel();

        if (attempts < maxRetries) {
          // Wait before retry (exponential backoff)
          await Future.delayed(Duration(seconds: 2 * attempts));
        }
      }
    }

    // All attempts failed
    await clearCorruptedModel();
    throw lastException ??
        Exception('Download failed after $maxRetries attempts');
  }

  /// Internal method to attempt a single download
  Future<void> _attemptDownload(Function(double) onProgress) async {
    http.StreamedResponse? response;
    IOSink? fileSink;

    try {
      final filePath = await getFilePath();
      final file = File(filePath);

      int downloadedBytes = 0;
      if (file.existsSync()) {
        downloadedBytes = await file.length();
      }

      final request = http.Request('GET', Uri.parse(model.url));

      final accessToken = await _config.getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $accessToken';
      }

      if (downloadedBytes > 0) {
        request.headers['Range'] = 'bytes=$downloadedBytes-';
      }

      response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 206) {
        final contentLength = response.contentLength ?? 0;
        final totalBytes = downloadedBytes + contentLength;

        // Ensure we have enough space and the total size makes sense
        if (totalBytes < _minimumModelSize) {
          throw Exception(
            'Model size too small: $totalBytes bytes (minimum: $_minimumModelSize)',
          );
        }

        fileSink = file.openWrite(mode: FileMode.append);

        int received = downloadedBytes;

        await for (final chunk in response.stream) {
          fileSink.add(chunk);
          received += chunk.length;
          onProgress(totalBytes > 0 ? received / totalBytes : 0.0);
        }
      } else {
        throw Exception(
          'Failed to download the model. Status: ${response.statusCode}',
        );
      }
    } finally {
      if (fileSink != null) await fileSink.close();
    }
  }
}
