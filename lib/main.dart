import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'screens/splash_screen.dart';
import 'services/ad_service.dart';
import 'services/audio_service.dart';
import 'services/iap_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final storage = StorageService();
  await storage.init();
  final ads = AdService(storage);
  final iap = IapService(storage);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: storage),
        Provider.value(value: ads),
        Provider.value(value: iap),
        Provider.value(value: AudioService(storage)),
      ],
      child: const StackTowerApp(),
    ),
  );
  // Consent + SDK init run in the background so the splash is not blocked.
  ads.init();
  iap.init();
}

class StackTowerApp extends StatelessWidget {
  const StackTowerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stack Tower',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFFD53369),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
