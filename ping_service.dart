import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/server.dart';
import 'battery_service.dart';
import 'night_mode_service.dart';

/// Optimized ping service with battery saving
class PingService {
  static final PingService _instance = PingService._internal();
  factory PingService() => _instance;
  PingService._internal();

  Timer? _checkTimer;
  bool _isRunning = false;
  int _checkInterval = 60;
  int _failThreshold = 3;
  int _fallbackThreshold = 150;

  Server? _bestServer;
  Server? _currentServer;
  int _consecutiveStableChecks = 0;

  final _pingController = StreamController<List<Server>>.broadcast();
  final _bestServerController = StreamController<Server?>.broadcast();
  final _fallbackController = StreamController<Server>.broadcast();
  final _logController = StreamController<String>.broadcast();

  Stream<List<Server>> get pingStream => _pingController.stream;
  Stream<Server?> get bestServerStream => _bestServerController.stream;
  Stream<Server> get fallbackStream => _fallbackController.stream;
  Stream<String> get logStream => _logController.stream;

  Server? get bestServer => _bestServer;
  bool get isRunning => _isRunning;

  final BatteryService _battery = BatteryService();
  final NightModeService _nightMode = NightModeService();

  /// Start periodic ping checks with battery optimization
  void start({
    required List<Server> servers,
    required int interval,
    required Server? currentServer,
    required bool autoSwitch,
    required bool fallbackEnabled,
  }) {
    stop();

    _checkInterval = interval;
    _currentServer = currentServer;
    _isRunning = true;
    _consecutiveStableChecks = 0;

    _log('Ping checker started');

    // Immediate first check
    _checkAll(servers, autoSwitch, fallbackEnabled);

    // Schedule next check with adaptive interval
    _scheduleNextCheck(servers, autoSwitch, fallbackEnabled);
  }

  void _scheduleNextCheck(List<Server> servers, bool autoSwitch, bool fallbackEnabled) {
    _checkTimer?.cancel();

    // Calculate adaptive interval
    var effectiveInterval = _checkInterval;
    effectiveInterval = _battery.getAdaptiveInterval(effectiveInterval);
    effectiveInterval = _nightMode.getEffectiveInterval(effectiveInterval);

    // If connection is stable for a while, check even less frequently
    if (_consecutiveStableChecks > 5) {
      effectiveInterval = (effectiveInterval * 1.5).round();
    }

    _log('Next check in ${effectiveInterval}s');

    _checkTimer = Timer(Duration(seconds: effectiveInterval), () {
      if (_isRunning) {
        _checkAll(servers, autoSwitch, fallbackEnabled);
        _scheduleNextCheck(servers, autoSwitch, fallbackEnabled);
      }
    });
  }

  /// Stop ping checker
  void stop() {
    _checkTimer?.cancel();
    _isRunning = false;
    _log('Ping checker stopped');
  }

  /// Single check of all servers with batching
  Future<void> checkNow(List<Server> servers) async {
    await _checkAll(servers, false, false);
  }

  Future<void> _checkAll(
    List<Server> servers,
    bool autoSwitch,
    bool fallbackEnabled,
  ) async {
    if (!_battery.shouldRunBackgroundTask()) {
      _log('Skipped check: battery optimization');
      return;
    }

    _log('Checking ${servers.length} servers...');

    final updated = <Server>[];
    final hosts = servers.map((s) => _extractHost(s.configJson)).where((h) => h.isNotEmpty).toList();

    // Use batch ping for battery efficiency
    final pingResults = await _battery.batchPing(hosts, batchSize: 4);

    for (var i = 0; i < servers.length; i++) {
      final server = servers[i];
      final host = _extractHost(server.configJson);

      int ping;
      bool alive;

      if (host.isNotEmpty && pingResults.containsKey(i)) {
        ping = pingResults[i] ?? 999;
        alive = ping < 999;
      } else {
        // Fallback to individual check
        final result = await _pingServer(server);
        ping = result.ping;
        alive = result.success;
      }

      Server updatedServer;
      if (alive) {
        updatedServer = server.copyWith(
          ping: ping,
          alive: true,
          lastCheck: DateTime.now().millisecondsSinceEpoch,
          failCount: 0,
        );
      } else {
        final newFailCount = server.failCount + 1;
        updatedServer = server.copyWith(
          alive: newFailCount < _failThreshold,
          lastCheck: DateTime.now().millisecondsSinceEpoch,
          failCount: newFailCount,
        );
      }

      updated.add(updatedServer);
    }

    // Find best alive server
    final alive = updated.where((s) => s.alive).toList();
    if (alive.isNotEmpty) {
      alive.sort((a, b) => a.ping.compareTo(b.ping));
      final newBest = alive.first;

      if (_bestServer == null || newBest.ping <= _bestServer!.ping) {
        _consecutiveStableChecks++;
      } else {
        _consecutiveStableChecks = 0;
      }

      _bestServer = newBest;
      _bestServerController.add(_bestServer);
      _log('Best: ${_bestServer!.name} (${_bestServer!.ping}ms)');
    } else {
      _bestServer = null;
      _consecutiveStableChecks = 0;
      _bestServerController.add(null);
      _log('No alive servers!');
    }

    _pingController.add(updated);

    // Auto-switch logic
    if (autoSwitch && _currentServer != null) {
      _evaluateSwitch(updated, fallbackEnabled);
    }
  }

  Future<PingResult> _pingServer(Server server) async {
    try {
      String host = _extractHost(server.configJson);

      if (host.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 200));
        final simulatedPing = Random().nextInt(120) + 5;
        final isAlive = Random().nextDouble() > 0.1;
        return PingResult(success: isAlive, ping: isAlive ? simulatedPing : 999);
      }

      final stopwatch = Stopwatch()..start();
      final socket = await Socket.connect(
        host,
        _getPort(server.protocol),
        timeout: const Duration(seconds: 3),
      );
      socket.destroy();
      stopwatch.stop();
      return PingResult(success: true, ping: stopwatch.elapsedMilliseconds);
    } catch (e) {
      return PingResult(success: false, ping: 999);
    }
  }

  void _evaluateSwitch(List<Server> updated, bool fallbackEnabled) {
    if (_currentServer == null || _bestServer == null) return;

    final current = updated.firstWhere(
      (s) => s.id == _currentServer!.id,
      orElse: () => _currentServer!,
    );

    // Check if current server died
    if (!current.alive) {
      _log('Current server ${current.name} is DEAD');
      if (fallbackEnabled && _bestServer != null) {
        // During night mode, only fallback if completely dead (already true)
        _log('Triggering fallback to ${_bestServer!.name}');
        _fallbackController.add(_bestServer!);
      }
      return;
    }

    // During night mode, don't switch for performance reasons
    if (_nightMode.shouldAllowFallback()) {
      // Check if current server is much worse than best
      if (_bestServer!.ping < current.ping * 0.6 && current.ping > _fallbackThreshold) {
        _log('Current degraded: ${current.ping}ms vs best ${_bestServer!.ping}ms');
        if (fallbackEnabled) {
          _fallbackController.add(_bestServer!);
          _consecutiveStableChecks = 0;
        }
      }
    }
  }

  String _extractHost(String configJson) {
    try {
      if (configJson.startsWith('vless://') || 
          configJson.startsWith('vmess://') ||
          configJson.startsWith('trojan://')) {
        final uri = Uri.tryParse(configJson);
        return uri?.host ?? '';
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  int _getPort(String protocol) {
    switch (protocol.toLowerCase()) {
      case 'vless':
      case 'vless+reality':
        return 443;
      case 'vmess':
      case 'vmess+ws':
        return 8080;
      case 'trojan':
      case 'trojan+tls':
        return 8443;
      case 'shadowsocks':
        return 3000;
      case 'hysteria2':
        return 8443;
      default:
        return 443;
    }
  }

  void updateCurrentServer(Server? server) {
    _currentServer = server;
    _consecutiveStableChecks = 0;
  }

  void _log(String msg) {
    final time = DateTime.now().toIso8601String();
    _logController.add('[$time] $msg');
  }

  void dispose() {
    stop();
    _pingController.close();
    _bestServerController.close();
    _fallbackController.close();
    _logController.close();
  }
}

class PingResult {
  final bool success;
  final int ping;

  PingResult({required this.success, required this.ping});
}
