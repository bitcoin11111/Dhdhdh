import 'package:hive_flutter/hive_flutter.dart';
import '../models/server.dart';
import '../models/subscription.dart';
import '../models/app_settings.dart';

/// Hive-based persistent storage
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late Box<Server> _serversBox;
  late Box<Subscription> _subsBox;
  late Box<AppSettings> _settingsBox;
  late Box<String> _logsBox;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    Hive.registerAdapter(ServerAdapter());
    Hive.registerAdapter(SubscriptionAdapter());
    Hive.registerAdapter(AppSettingsAdapter());

    _serversBox = await Hive.openBox<Server>('servers');
    _subsBox = await Hive.openBox<Subscription>('subscriptions');
    _settingsBox = await Hive.openBox<AppSettings>('settings');
    _logsBox = await Hive.openBox<String>('logs');

    // Initialize default settings if not exists
    if (_settingsBox.isEmpty) {
      await _settingsBox.put('main', AppSettings());
    }

    _initialized = true;
  }

  // Servers
  List<Server> getServers() => _serversBox.values.toList();
  Server? getServer(int id) => _serversBox.get(id);
  Future<void> saveServer(Server server) => _serversBox.put(server.id, server);
  Future<void> saveServers(List<Server> servers) async {
    await _serversBox.clear();
    for (final s in servers) {
      await _serversBox.put(s.id, s);
    }
  }
  Future<void> deleteServer(int id) => _serversBox.delete(id);
  Future<void> clearServers() => _serversBox.clear();

  // Subscriptions
  List<Subscription> getSubscriptions() => _subsBox.values.toList();
  Future<void> saveSubscription(Subscription sub) => _subsBox.put(sub.id, sub);
  Future<void> deleteSubscription(int id) => _subsBox.delete(id);

  // Settings
  AppSettings getSettings() => _settingsBox.get('main') ?? AppSettings();
  Future<void> saveSettings(AppSettings settings) => _settingsBox.put('main', settings);

  // Logs
  List<String> getLogs() => _logsBox.values.toList().reversed.toList();
  Future<void> addLog(String log) => _logsBox.add(log);
  Future<void> clearLogs() => _logsBox.clear();

  Future<void> close() async {
    await Hive.close();
  }
}
