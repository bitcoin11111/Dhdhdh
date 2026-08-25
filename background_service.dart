import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'vpn_service.dart';
import 'ping_service.dart';
import 'storage_service.dart';

const String pingTask = 'shieldvpn.ping_check';
const String fallbackTask = 'shieldvpn.fallback';

/// Background task manager for auto-checking and fallback
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  final _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // Initialize WorkManager
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    // Initialize notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notifications.initialize(initSettings);

    _initialized = true;
  }

  /// Schedule periodic ping checks
  Future<void> schedulePingChecks({required int intervalMinutes}) async {
    await Workmanager().registerPeriodicTask(
      pingTask,
      pingTask,
      frequency: Duration(minutes: intervalMinutes),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  /// Cancel all background tasks
  Future<void> cancelAll() async {
    await Workmanager().cancelAll();
  }

  /// Show notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'shieldvpn_channel',
      'ShieldVPN',
      channelDescription: 'VPN status and fallback notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  void dispose() {
    _notifications.cancelAll();
  }
}

/// Top-level callback for WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case pingTask:
        await _performPingCheck();
        break;
      case fallbackTask:
        await _performFallback();
        break;
    }
    return Future.value(true);
  });
}

Future<void> _performPingCheck() async {
  final storage = StorageService();
  await storage.init();

  final settings = storage.getSettings();
  if (!settings.autoSwitch) return;

  final servers = storage.getServers();
  if (servers.isEmpty) return;

  final pingService = PingService();
  await pingService.checkNow(servers);

  // Save updated servers
  final updated = pingService.pingStream.first;
  await storage.saveServers(await updated);
}

Future<void> _performFallback() async {
  final storage = StorageService();
  await storage.init();

  final settings = storage.getSettings();
  if (!settings.fallbackEnabled) return;

  // Check if current connection is alive
  final vpn = VPNService();
  // If not, trigger fallback via notification
}
