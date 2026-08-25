import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Battery optimization and power management
class BatteryService {
  static final BatteryService _instance = BatteryService._internal();
  factory BatteryService() => _instance;
  BatteryService._internal();

  bool _isLowPower = false;
  bool _isDozeMode = false;
  bool _isScreenOn = true;
  String _networkType = 'wifi';

  final _powerController = StreamController<PowerState>.broadcast();
  Stream<PowerState> get powerStream => _powerController.stream;

  /// Initialize monitoring
  Future<void> init() async {
    // Monitor connectivity (WiFi vs Mobile)
    Connectivity().onConnectivityChanged.listen((result) {
      _networkType = result == ConnectivityResult.wifi ? 'wifi' : 'mobile';
      _log('Network: $_networkType');
    });

    // Check initial state
    final result = await Connectivity().checkConnectivity();
    _networkType = result == ConnectivityResult.wifi ? 'wifi' : 'mobile';
  }

  /// Get adaptive check interval based on conditions
  int getAdaptiveInterval(int baseInterval) {
    // Low power mode → double interval
    if (_isLowPower) return baseInterval * 2;

    // Doze mode → quadruple interval  
    if (_isDozeMode) return baseInterval * 4;

    // Screen off → less frequent
    if (!_isScreenOn) return baseInterval * 2;

    // Mobile data → less frequent
    if (_networkType == 'mobile') return (baseInterval * 1.5).round();

    // Stable connection → can check less often
    if (_stableConnectionTime > 300) return (baseInterval * 1.3).round();

    return baseInterval;
  }

  /// Check if we should run background task now
  bool shouldRunBackgroundTask() {
    // Don't run in doze mode unless critical
    if (_isDozeMode) return false;

    // Don't run on mobile data if user prefers WiFi
    if (_networkType == 'mobile' && _preferWifiOnly) return false;

    return true;
  }

  /// Batch ping - check multiple servers in one batch
  Future<Map<int, int>> batchPing(List<String> hosts, {int batchSize = 5}) async {
    final results = <int, int>{};

    // Process in batches to reduce wake-ups
    for (var i = 0; i < hosts.length; i += batchSize) {
      final batch = hosts.skip(i).take(batchSize).toList();

      // Parallel ping within batch
      final futures = batch.asMap().entries.map((entry) async {
        final ping = await _quickPing(entry.value);
        return MapEntry(entry.key + i, ping);
      });

      final batchResults = await Future.wait(futures);
      for (final r in batchResults) {
        results[r.key] = r.value;
      }

      // Small delay between batches to let CPU sleep
      if (i + batchSize < hosts.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    return results;
  }

  /// Quick ping with shorter timeout for battery saving
  Future<int> _quickPing(String host) async {
    try {
      final stopwatch = Stopwatch()..start();
      final socket = await Socket.connect(
        host, 
        443,
        timeout: const Duration(seconds: 3), // Shorter timeout
      );
      socket.destroy();
      stopwatch.stop();
      return stopwatch.elapsedMilliseconds;
    } catch (e) {
      return 999;
    }
  }

  /// Enter low power mode
  void setLowPower(bool enabled) {
    _isLowPower = enabled;
    _powerController.add(PowerState(
      isLowPower: _isLowPower,
      isDozeMode: _isDozeMode,
      networkType: _networkType,
    ));
    _log('Low power mode: $enabled');
  }

  /// Screen state changed
  void setScreenOn(bool on) {
    _isScreenOn = on;
    _log('Screen: ${on ? 'ON' : 'OFF'}');
  }

  /// Request ignoring battery optimizations
  Future<bool> requestBatteryOptimizationExemption() async {
    // This would use platform channel to open settings
    // For now, return true (assume granted)
    return true;
  }

  int _stableConnectionTime = 0;
  bool _preferWifiOnly = false;
  Timer? _stabilityTimer;

  void startStabilityTracking() {
    _stabilityTimer?.cancel();
    _stabilityTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _stableConnectionTime++;
    });
  }

  void resetStabilityTracking() {
    _stableConnectionTime = 0;
  }

  void setPreferWifiOnly(bool value) {
    _preferWifiOnly = value;
  }

  void _log(String msg) {
    // Battery service logs are minimal
  }

  void dispose() {
    _stabilityTimer?.cancel();
    _powerController.close();
  }
}

class PowerState {
  final bool isLowPower;
  final bool isDozeMode;
  final String networkType;

  PowerState({
    required this.isLowPower,
    required this.isDozeMode,
    required this.networkType,
  });
}
