import 'dart:async';

import 'package:flutter/material.dart';

import '../core/braille_vibration.dart';
import '../core/interfaces.dart';
import '../feature/braille_fullscreen/braille_fullscreen_screen.dart';

enum BrailleSource { general, speech, photo, assistant }

class BrailleTextOutputService implements Outputable {
  final BuildContext context;
  BrailleTextOutputService({required this.context});

  final StreamController<String> _fullscreenController =
      StreamController<String>.broadcast();

  Stream<String> get fullscreenStream => _fullscreenController.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> process(String data) async {
    // Trigger fullscreen navigation when processing text
    if (data.isNotEmpty) {
      _fullscreenController.add(data);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BrailleFullscreenScreen(sourceText: data),
        ),
      );
    }
  }

  Future<void> vibrateSymbol(String? character) async {
    if (character != null) {
      await BrailleVibrationService.instance.vibrateBraille(character);
    }
  }

  @override
  Future<void> dispose() async {
    await _fullscreenController.close();
  }
}
