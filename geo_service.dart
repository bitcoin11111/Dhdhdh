import 'dart:convert';

/// Geo-unblocking for streaming services
class GeoBypassService {
  static final GeoBypassService _instance = GeoBypassService._internal();
  factory GeoBypassService() => _instance;
  GeoBypassService._internal();

  final Map<String, StreamingService> _services = {
    'netflix': StreamingService(
      name: 'Netflix',
      domains: [
        'netflix.com',
        'nflxvideo.net',
        'nflxext.com',
        'nflxso.net',
      ],
      regions: ['US', 'GB', 'JP'],
      icon: '🎬',
    ),
    'spotify': StreamingService(
      name: 'Spotify',
      domains: [
        'spotify.com',
        'spotifycdn.com',
        'scdn.co',
      ],
      regions: ['US', 'GB', 'DE'],
      icon: '🎵',
    ),
    'tiktok': StreamingService(
      name: 'TikTok',
      domains: [
        'tiktok.com',
        'tiktokcdn.com',
        'musical.ly',
      ],
      regions: ['US', 'SG'],
      icon: '📱',
    ),
    'youtube': StreamingService(
      name: 'YouTube Premium',
      domains: [
        'youtube.com',
        'googlevideo.com',
        'ytimg.com',
      ],
      regions: ['US', 'GB'],
      icon: '▶️',
    ),
    'disney': StreamingService(
      name: 'Disney+',
      domains: [
        'disneyplus.com',
        'bamgrid.com',
        'disney.com',
      ],
      regions: ['US', 'GB', 'NL'],
      icon: '✨',
    ),
    'instagram': StreamingService(
      name: 'Instagram',
      domains: [
        'instagram.com',
        'cdninstagram.com',
      ],
      regions: ['US', 'EU'],
      icon: '📸',
    ),
  };

  /// Get all supported services
  List<StreamingService> getServices() => _services.values.toList();

  /// Get domains that need routing through VPN for a service
  List<String> getDomainsForService(String serviceId) {
    return _services[serviceId]?.domains ?? [];
  }

  /// Generate routing rules for selected services
  String generateRoutingRules(List<String> enabledServices) {
    final rules = <Map<String, dynamic>>[];

    for (final serviceId in enabledServices) {
      final service = _services[serviceId];
      if (service == null) continue;

      for (final domain in service.domains) {
        rules.add({
          'domain': domain,
          'action': 'proxy',
          'service': service.name,
        });
      }
    }

    return jsonEncode(rules);
  }

  /// Check if domain belongs to a streaming service
  String? detectService(String domain) {
    for (final entry in _services.entries) {
      for (final d in entry.value.domains) {
        if (domain == d || domain.endsWith('.$d')) {
          return entry.key;
        }
      }
    }
    return null;
  }
}

class StreamingService {
  final String name;
  final List<String> domains;
  final List<String> regions;
  final String icon;

  StreamingService({
    required this.name,
    required this.domains,
    required this.regions,
    required this.icon,
  });
}
