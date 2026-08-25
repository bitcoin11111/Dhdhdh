import 'package:flutter/material.dart';

import '../services/split_tunnel_service.dart';

class SplitTunnelScreen extends StatefulWidget {
  const SplitTunnelScreen({super.key});

  @override
  State<SplitTunnelScreen> createState() => _SplitTunnelScreenState();
}

class _SplitTunnelScreenState extends State<SplitTunnelScreen> {
  final SplitTunnelService _service = SplitTunnelService();
  List<AppRouteRule> _rules = [];

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  void _loadRules() {
    _rules = _service.getRules();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Split Tunneling')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Split Tunneling',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  'Выберите, какие приложения работают через VPN, а какие напрямую',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle('Через VPN'),
          ..._rules.where((r) => r.mode == 'vpn').map((r) => _AppRuleTile(
            rule: r,
            onToggle: () => _service.addAppToDirect(r.package, r.name),
          )),
          const SizedBox(height: 20),
          _SectionTitle('Напрямую (обход VPN)'),
          ..._rules.where((r) => r.mode == 'direct').map((r) => _AppRuleTile(
            rule: r,
            onToggle: () => _service.addAppToVPN(r.package, r.name),
          )),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
      ),
    );
  }
}

class _AppRuleTile extends StatelessWidget {
  final AppRouteRule rule;
  final VoidCallback onToggle;

  const _AppRuleTile({required this.rule, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: rule.mode == 'vpn' 
            ? Colors.green.withOpacity(0.1) 
            : Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          rule.mode == 'vpn' ? Icons.vpn_lock : Icons.public,
          color: rule.mode == 'vpn' ? Colors.green : Colors.orange,
        ),
      ),
      title: Text(rule.name),
      subtitle: Text(rule.package, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      trailing: Switch(
        value: rule.mode == 'vpn',
        onChanged: (_) => onToggle(),
      ),
    );
  }
}
