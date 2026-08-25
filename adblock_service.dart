import 'dart:convert';
import 'package:http/http.dart' as http;

/// DNS-based ad blocking and filtering
class AdBlockService {
  static final AdBlockService _instance = AdBlockService._internal();
  factory AdBlockService() => _instance;
  AdBlockService._internal();

  final Set<String> _blocklist = {};
  bool _enabled = false;
  DateTime _lastUpdate = DateTime(2000);

  /// Default blocklist URLs
  static const List<String> blocklistUrls = [
    'https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts',
    'https://adaway.org/hosts.txt',
    'https://someonewhocares.org/hosts/zero/hosts',
  ];

  bool get enabled => _enabled;
  int get blockedCount => _blocklist.length;

  /// Initialize with cached blocklist
  Future<void> init() async {
    // Load from cache or use minimal default
    _blocklist.addAll(_defaultBlocklist);
  }

  /// Update blocklists from remote
  Future<bool> updateBlocklists() async {
    if (DateTime.now().difference(_lastUpdate).inHours < 24) {
      return true; // Updated recently
    }

    final newBlocks = <String>{};

    for (final url in blocklistUrls) {
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {'User-Agent': 'ShieldVPN/1.0'},
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final lines = response.body.split('\n');
          for (final line in lines) {
            final domain = _parseHostLine(line);
            if (domain != null) newBlocks.add(domain);
          }
        }
      } catch (e) {
        // Skip failed sources
      }
    }

    if (newBlocks.isNotEmpty) {
      _blocklist.clear();
      _blocklist.addAll(newBlocks);
      _lastUpdate = DateTime.now();
      return true;
    }
    return false;
  }

  /// Check if domain should be blocked
  bool shouldBlock(String domain) {
    if (!_enabled) return false;

    // Exact match
    if (_blocklist.contains(domain)) return true;

    // Subdomain match
    final parts = domain.split('.');
    for (var i = 1; i < parts.length; i++) {
      final parent = parts.sublist(i).join('.');
      if (_blocklist.contains(parent)) return true;
    }

    return false;
  }

  /// Get DNS response for blocked domain (redirect to 0.0.0.0)
  String? getBlockedResponse(String domain) {
    if (!shouldBlock(domain)) return null;
    return '0.0.0.0';
  }

  void setEnabled(bool value) {
    _enabled = value;
  }

  String? _parseHostLine(String line) {
    line = line.trim();
    if (line.isEmpty || line.startsWith('#')) return null;

    final parts = line.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final ip = parts[0];
      final domain = parts[1];
      if (ip == '0.0.0.0' || ip == '127.0.0.1') {
        if (domain != 'localhost' && !domain.contains('#')) {
          return domain.toLowerCase();
        }
      }
    }
    return null;
  }

  /// Minimal default blocklist for offline use
  final Set<String> _defaultBlocklist = {
    'doubleclick.net',
    'googleadservices.com',
    'googlesyndication.com',
    'google-analytics.com',
    'facebook.com',
    'fbcdn.net',
    'ads.yahoo.com',
    'advertising.com',
    'adsystem.com',
    'amazon-adsystem.com',
    'app-measurement.com',
    'crashlytics.com',
    'firebaseio.com',
  };
}
