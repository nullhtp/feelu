import 'package:feelu/feature/initialization/initialization_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'core/di/service_locator.dart';
import 'core/di/service_registration.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file only if it exists
  await dotenv.load(fileName: '.env');

  // Initialize dependency injection
  await ServiceLocator.init();
  await ServiceRegistration.registerAllServices();

  // Set app-wide landscape orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Enable wake lock to keep the app always on
  await WakelockPlus.enable();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const InitializationScreen(),
    );
  }
}
