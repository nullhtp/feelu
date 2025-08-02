import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static bool devEnv() {
    String devEnv = dotenv.isInitialized
        ? dotenv.env['DEV_ENV'] ?? 'false'
        : 'false';
    return devEnv == 'true';
  }

  static bool disableVibration() {
    String disableVibration = dotenv.isInitialized
        ? dotenv.env['DISABLE_VIBRATION'] ?? 'false'
        : 'false';

    return disableVibration == 'true';
  }
}
