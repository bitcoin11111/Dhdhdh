import 'dart:convert';

/// Multi-hop VPN - chain two servers for extra security
class MultiHopService {
  static final MultiHopService _instance = MultiHopService._internal();
  factory MultiHopService() => _instance;
  MultiHopService._internal();

  bool _enabled = false;
  int? _entryServerId;
  int? _exitServerId;

  bool get enabled => _enabled;

  /// Build multi-hop configuration
  /// Entry server → Exit server → Internet
  String buildMultiHopConfig(String entryConfig, String exitConfig) {
    final entry = jsonDecode(entryConfig);
    final exit = jsonDecode(exitConfig);

    return jsonEncode({
      'mode': 'multihop',
      'entry': entry,
      'exit': exit,
      'routing': {
        'type': 'chain',
        'hops': [
          {'address': entry['address'], 'port': entry['port']},
          {'address': exit['address'], 'port': exit['port']},
        ],
      },
    });
  }

  /// Calculate expected latency increase
  int estimateLatency(int entryPing, int exitPing) {
    // Multi-hop adds roughly 30% overhead
    return ((entryPing + exitPing) * 1.3).round();
  }

  void setEnabled(bool value) {
    _enabled = value;
  }

  void setServers(int entryId, int exitId) {
    _entryServerId = entryId;
    _exitServerId = exitId;
  }
}
