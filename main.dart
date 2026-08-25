import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'services/storage_service.dart';
import 'services/background_service.dart';
import 'services/battery_service.dart';
import 'services/night_mode_service.dart';
import 'services/adblock_service.dart';
import 'services/split_tunnel_service.dart';
import 'services/widget_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize all services
  final storage = StorageService();
  await storage.init();

  final battery = BatteryService();
  await battery.init();

  final nightMode = NightModeService();
  final settings = storage.getSettings();
  nightMode.setEnabled(settings.nightMode);
  nightMode.setHours(settings.nightModeStart, settings.nightModeEnd);

  final adBlock = AdBlockService();
  await adBlock.init();
  if (settings.adBlockEnabled && settings.adBlockAutoUpdate) {
    await adBlock.updateBlocklists();
  }

  final splitTunnel = SplitTunnelService();
  await splitTunnel.init();

  // Initialize background service
  final bg = BackgroundService();
  await bg.init();

  if (settings.autoSwitch) {
    await bg.schedulePingChecks(intervalMinutes: settings.checkInterval ~/ 60);
  }

  // Set app shortcuts
  await WidgetService.setShortcuts();

  runApp(const ShieldVPNApp());
}

class ShieldVPNApp extends StatelessWidget {
  const ShieldVPNApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShieldVPN',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ru', 'RU'),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A1A1A),
          brightness: Brightness.light,
        ),
        fontFamily: 'Inter',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A1A1A),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Inter',
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
