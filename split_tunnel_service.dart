import 'dart:convert';
import 'package:hive/hive.dart';

/// Split tunneling - route specific apps through VPN or direct
class SplitTunnelService {
  static final SplitTunnelService _instance = SplitTunnelService._internal();
  factory SplitTunnelService() => _instance;
  SplitTunnelService._internal();

  late Box<Map> _appsBox;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _appsBox = await Hive.openBox<Map>('split_tunnel_apps');
    _initialized = true;
  }

  /// Get list of apps with routing rules
  List<AppRouteRule> getRules() {
    return _appsBox.values.map((v) => AppRouteRule.fromJson(Map<String, dynamic>.from(v))).toList();
  }

  /// Add app to VPN route (proxy through VPN)
  Future<void> addAppToVPN(String packageName, String appName) async {
    await _appsBox.put(packageName, {
      'package': packageName,
      'name': appName,
      'mode': 'vpn',
    });
  }

  /// Add app to direct route (bypass VPN)
  Future<void> addAppToDirect(String packageName, String appName) async {
    await _appsBox.put(packageName, {
      'package': packageName,
      'name': appName,
      'mode': 'direct',
    });
  }

  /// Remove app from rules
  Future<void> removeApp(String packageName) async {
    await _appsBox.delete(packageName);
  }

  /// Check if app should use VPN
  bool shouldUseVPN(String packageName) {
    final rule = _appsBox.get(packageName);
    if (rule == null) return true; // Default: through VPN
    return rule['mode'] == 'vpn';
  }

  /// Get routing config for VPN service
  String getRoutingConfig() {
    final rules = getRules();
    final vpnApps = rules.where((r) => r.mode == 'vpn').map((r) => r.package).toList();
    final directApps = rules.where((r) => r.mode == 'direct').map((r) => r.package).toList();

    return jsonEncode({
      'vpn_apps': vpnApps,
      'direct_apps': directApps,
    });
  }

  void dispose() {
    _appsBox.close();
  }
}

class AppRouteRule {
  final String package;
  final String name;
  final String mode; // 'vpn' or 'direct'

  AppRouteRule({required this.package, required this.name, required this.mode});

  factory AppRouteRule.fromJson(Map<String, dynamic> json) => AppRouteRule(
    package: json['package'],
    name: json['name'],
    mode: json['mode'],
  );

  Map<String, dynamic> toJson() => {
    'package': package,
    'name': name,
    'mode': mode,
  };
}
