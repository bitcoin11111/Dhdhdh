import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/server.dart';
import '../models/subscription.dart';

/// Service for importing and parsing subscriptions
class SubscriptionService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// Parse subscription URL and extract servers
  Future<List<Server>> parseSubscription(Subscription sub) async {
    try {
      final response = await _dio.get(sub.url);
      final content = response.data.toString();

      // Try base64 decode first
      String decoded;
      try {
        decoded = utf8.decode(base64Decode(content));
      } catch (e) {
        decoded = content;
      }

      final lines = decoded.split('\n').where((l) => l.trim().isNotEmpty).toList();
      final servers = <Server>[];
      int id = DateTime.now().millisecondsSinceEpoch;

      for (final line in lines) {
        final server = _parseLine(line, sub, id++);
        if (server != null) servers.add(server);
      }

      return servers;
    } catch (e) {
      throw Exception('Failed to fetch subscription: $e');
    }
  }

  /// Parse single config line
  Server? _parseLine(String line, Subscription sub, int id) {
    line = line.trim();
    if (line.isEmpty) return null;

    try {
      if (line.startsWith('vless://')) {
        return _parseVLESS(line, sub, id);
      } else if (line.startsWith('vmess://')) {
        return _parseVMess(line, sub, id);
      } else if (line.startsWith('trojan://')) {
        return _parseTrojan(line, sub, id);
      } else if (line.startsWith('ss://')) {
        return _parseShadowsocks(line, sub, id);
      } else if (line.startsWith('hysteria2://') || line.startsWith('hy2://')) {
        return _parseHysteria2(line, sub, id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Server _parseVLESS(String url, Subscription sub, int id) {
    final uri = Uri.parse(url);
    final params = uri.queryParameters;

    return Server(
      id: id,
      flag: _getFlag(uri.host),
      name: _getCountry(uri.host),
      city: _getCity(uri.host),
      protocol: 'VLESS+Reality',
      subId: sub.id,
      subName: sub.name,
      configJson: jsonEncode({
        'protocol': 'vless',
        'id': uri.userInfo,
        'address': uri.host,
        'port': uri.port,
        'flow': params['flow'] ?? 'xtls-rprx-vision',
        'security': params['security'] ?? 'reality',
        'sni': params['sni'] ?? uri.host,
        'fp': params['fp'] ?? 'chrome',
        'pbk': params['pbk'] ?? '',
        'sid': params['sid'] ?? '',
      }),
    );
  }

  Server _parseVMess(String url, Subscription sub, int id) {
    final b64 = url.replaceFirst('vmess://', '');
    final jsonStr = utf8.decode(base64Decode(b64));
    final data = jsonDecode(jsonStr);

    return Server(
      id: id,
      flag: _getFlag(data['add'] ?? ''),
      name: _getCountry(data['add'] ?? ''),
      city: _getCity(data['add'] ?? ''),
      protocol: 'VMess+WS',
      subId: sub.id,
      subName: sub.name,
      configJson: jsonEncode({
        'protocol': 'vmess',
        'id': data['id'],
        'address': data['add'],
        'port': int.parse(data['port'].toString()),
        'aid': data['aid'] ?? 0,
        'security': data['scy'] ?? 'auto',
        'network': data['net'] ?? 'ws',
        'path': data['path'] ?? '/',
        'host': data['host'] ?? data['add'],
      }),
    );
  }

  Server _parseTrojan(String url, Subscription sub, int id) {
    final uri = Uri.parse(url);
    final params = uri.queryParameters;

    return Server(
      id: id,
      flag: _getFlag(uri.host),
      name: _getCountry(uri.host),
      city: _getCity(uri.host),
      protocol: 'Trojan+TLS',
      subId: sub.id,
      subName: sub.name,
      configJson: jsonEncode({
        'protocol': 'trojan',
        'password': uri.userInfo,
        'address': uri.host,
        'port': uri.port,
        'sni': params['sni'] ?? uri.host,
        'allowInsecure': params['allowInsecure'] == '1',
      }),
    );
  }

  Server _parseShadowsocks(String url, Subscription sub, int id) {
    final uri = Uri.parse(url);

    return Server(
      id: id,
      flag: _getFlag(uri.host),
      name: _getCountry(uri.host),
      city: _getCity(uri.host),
      protocol: 'Shadowsocks',
      subId: sub.id,
      subName: sub.name,
      configJson: jsonEncode({
        'protocol': 'shadowsocks',
        'method': 'aes-256-gcm',
        'password': uri.userInfo,
        'address': uri.host,
        'port': uri.port,
      }),
    );
  }

  Server _parseHysteria2(String url, Subscription sub, int id) {
    final uri = Uri.parse(url);

    return Server(
      id: id,
      flag: _getFlag(uri.host),
      name: _getCountry(uri.host),
      city: _getCity(uri.host),
      protocol: 'Hysteria2',
      subId: sub.id,
      subName: sub.name,
      configJson: jsonEncode({
        'protocol': 'hysteria2',
        'password': uri.userInfo,
        'address': uri.host,
        'port': uri.port,
      }),
    );
  }

  String _getFlag(String host) {
    // Simple mapping based on TLD or keywords
    final lower = host.toLowerCase();
    if (lower.contains('nl') || lower.contains('ams')) return '🇳🇱';
    if (lower.contains('de') || lower.contains('fra')) return '🇩🇪';
    if (lower.contains('fi') || lower.contains('hel')) return '🇫🇮';
    if (lower.contains('us') || lower.contains('ny')) return '🇺🇸';
    if (lower.contains('sg') || lower.contains('sin')) return '🇸🇬';
    if (lower.contains('jp') || lower.contains('tok')) return '🇯🇵';
    if (lower.contains('kz') || lower.contains('ala')) return '🇰🇿';
    if (lower.contains('ru') || lower.contains('mos')) return '🇷🇺';
    if (lower.contains('uk') || lower.contains('lon')) return '🇬🇧';
    if (lower.contains('fr') || lower.contains('par')) return '🇫🇷';
    if (lower.contains('ca') || lower.contains('tor')) return '🇨🇦';
    if (lower.contains('au') || lower.contains('syd')) return '🇦🇺';
    return '🌍';
  }

  String _getCountry(String host) {
    final flag = _getFlag(host);
    final map = {
      '🇳🇱': 'Нидерланды', '🇩🇪': 'Германия', '🇫🇮': 'Финляндия',
      '🇺🇸': 'США', '🇸🇬': 'Сингапур', '🇯🇵': 'Япония',
      '🇰🇿': 'Казахстан', '🇷🇺': 'Россия', '🇬🇧': 'Великобритания',
      '🇫🇷': 'Франция', '🇨🇦': 'Канада', '🇦🇺': 'Австралия',
    };
    return map[flag] ?? 'Unknown';
  }

  String _getCity(String host) {
    final lower = host.toLowerCase();
    if (lower.contains('ams')) return 'Amsterdam';
    if (lower.contains('fra')) return 'Frankfurt';
    if (lower.contains('hel')) return 'Helsinki';
    if (lower.contains('ny')) return 'New York';
    if (lower.contains('sin')) return 'Singapore';
    if (lower.contains('tok')) return 'Tokyo';
    if (lower.contains('ala')) return 'Almaty';
    if (lower.contains('mos')) return 'Moscow';
    if (lower.contains('lon')) return 'London';
    if (lower.contains('par')) return 'Paris';
    if (lower.contains('tor')) return 'Toronto';
    if (lower.contains('syd')) return 'Sydney';
    return 'Unknown';
  }
}
