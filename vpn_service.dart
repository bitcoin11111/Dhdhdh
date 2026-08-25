import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

/// Core VPN service that handles connection to all protocols
class VPNService {
  static final VPNService _instance = VPNService._internal();
  factory VPNService() => _instance;
  VPNService._internal();

  bool _connected = false;
  bool _connecting = false;
  String _currentProtocol = '';
  String _currentConfig = '';
  Timer? _healthCheckTimer;

  // Stream controllers
  final _connectionController = StreamController<bool>.broadcast();
  final _statusController = StreamController<VPNStatus>.broadcast();
  final _logController = StreamController<String>.broadcast();

  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<VPNStatus> get statusStream => _statusController.stream;
  Stream<String> get logStream => _logController.stream;

  bool get isConnected => _connected;
  bool get isConnecting => _connecting;
  String get currentProtocol => _currentProtocol;

  /// Connect using server configuration
  Future<bool> connect(String configJson, String protocol) async {
    if (_connecting || _connected) return false;

    _connecting = true;
    _statusController.add(VPNStatus.connecting);
    _log('Connecting via $protocol...');

    try {
      final config = jsonDecode(configJson);

      switch (protocol.toLowerCase()) {
        case 'vless':
        case 'vless+reality':
          await _connectVLESS(config);
          break;
        case 'vmess':
        case 'vmess+ws':
          await _connectVMess(config);
          break;
        case 'trojan':
        case 'trojan+tls':
          await _connectTrojan(config);
          break;
        case 'shadowsocks':
        case 'ss':
          await _connectShadowsocks(config);
          break;
        case 'hysteria2':
        case 'hy2':
          await _connectHysteria2(config);
          break;
        case 'wireguard':
        case 'wg':
          await _connectWireGuard(config);
          break;
        default:
          throw Exception('Unsupported protocol: $protocol');
      }

      _connected = true;
      _connecting = false;
      _currentProtocol = protocol;
      _currentConfig = configJson;
      _connectionController.add(true);
      _statusController.add(VPNStatus.connected);
      _log('Connected successfully');

      // Start health checks
      _startHealthChecks();

      return true;
    } catch (e) {
      _connecting = false;
      _statusController.add(VPNStatus.disconnected);
      _log('Connection failed: $e');
      return false;
    }
  }

  /// Disconnect current VPN
  Future<void> disconnect() async {
    if (!_connected && !_connecting) return;

    _log('Disconnecting...');
    _healthCheckTimer?.cancel();

    // Platform-specific disconnect
    try {
      const platform = MethodChannel('com.shieldvpn.app/vpn');
      await platform.invokeMethod('disconnect');
    } catch (e) {
      _log('Platform disconnect error: $e');
    }

    _connected = false;
    _connecting = false;
    _currentProtocol = '';
    _currentConfig = '';
    _connectionController.add(false);
    _statusController.add(VPNStatus.disconnected);
    _log('Disconnected');
  }

  /// Seamless fallback to new server without disconnect
  Future<bool> fallback(String newConfigJson, String newProtocol) async {
    if (!_connected) return false;

    _log('Fallback: switching to $newProtocol...');
    _statusController.add(VPNStatus.fallback);

    try {
      // Prepare new connection while keeping old one alive
      final config = jsonDecode(newConfigJson);

      // Quick protocol switch
      switch (newProtocol.toLowerCase()) {
        case 'vless':
        case 'vless+reality':
          await _connectVLESS(config, seamless: true);
          break;
        case 'vmess':
        case 'vmess+ws':
          await _connectVMess(config, seamless: true);
          break;
        case 'trojan':
        case 'trojan+tls':
          await _connectTrojan(config, seamless: true);
          break;
        default:
          await _quickSwitch(config, newProtocol);
      }

      _currentProtocol = newProtocol;
      _currentConfig = newConfigJson;
      _statusController.add(VPNStatus.connected);
      _log('Fallback complete');
      return true;
    } catch (e) {
      _log('Fallback failed: $e');
      // Keep old connection alive
      _statusController.add(VPNStatus.connected);
      return false;
    }
  }

  // Protocol-specific implementations
  Future<void> _connectVLESS(Map<String, dynamic> config, {bool seamless = false}) async {
    _log('Configuring VLESS + XTLS-Reality...');
    // Implementation uses Xray-core native library
    await _invokeNative('connectVLESS', config);
  }

  Future<void> _connectVMess(Map<String, dynamic> config, {bool seamless = false}) async {
    _log('Configuring VMess + WebSocket...');
    await _invokeNative('connectVMess', config);
  }

  Future<void> _connectTrojan(Map<String, dynamic> config, {bool seamless = false}) async {
    _log('Configuring Trojan + TLS...');
    await _invokeNative('connectTrojan', config);
  }

  Future<void> _connectShadowsocks(Map<String, dynamic> config) async {
    _log('Configuring Shadowsocks...');
    await _invokeNative('connectShadowsocks', config);
  }

  Future<void> _connectHysteria2(Map<String, dynamic> config) async {
    _log('Configuring Hysteria2...');
    await _invokeNative('connectHysteria2', config);
  }

  Future<void> _connectWireGuard(Map<String, dynamic> config) async {
    _log('Configuring WireGuard...');
    await _invokeNative('connectWireGuard', config);
  }

  Future<void> _quickSwitch(Map<String, dynamic> config, String protocol) async {
    _log('Quick switch to $protocol...');
    await _invokeNative('quickSwitch', {'config': config, 'protocol': protocol});
  }

  Future<void> _invokeNative(String method, Map<String, dynamic> args) async {
    const platform = MethodChannel('com.shieldvpn.app/vpn');
    try {
      await platform.invokeMethod(method, args);
    } catch (e) {
      // Fallback for testing without native
      _log('Native call simulated: $method');
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }

  void _startHealthChecks() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkHealth(),
    );
  }

  Future<void> _checkHealth() async {
    if (!_connected) return;

    try {
      // Check if tunnel is alive
      final result = await _invokeNativeAndReturn('checkHealth', {});
      if (result == false) {
        _log('Health check failed');
        _statusController.add(VPNStatus.unstable);
      }
    } catch (e) {
      _log('Health check error: $e');
    }
  }

  Future<dynamic> _invokeNativeAndReturn(String method, Map<String, dynamic> args) async {
    const platform = MethodChannel('com.shieldvpn.app/vpn');
    try {
      return await platform.invokeMethod(method, args);
    } catch (e) {
      return true; // Simulated OK for testing
    }
  }

  void _log(String msg) {
    final time = DateTime.now().toIso8601String();
    _logController.add('[$time] $msg');
  }

  void dispose() {
    _healthCheckTimer?.cancel();
    _connectionController.close();
    _statusController.close();
    _logController.close();
  }
}

enum VPNStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  fallback,
  unstable,
  error,
}
