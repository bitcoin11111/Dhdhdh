import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/subscription.dart';
import '../models/server.dart';
import '../services/storage_service.dart';
import '../services/subscription_service.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final StorageService _storage = StorageService();
  final SubscriptionService _subService = SubscriptionService();

  List<Subscription> _subs = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSubs();
  }

  void _loadSubs() {
    _subs = _storage.getSubscriptions();
    setState(() {});
  }

  Future<void> _addSubscription(String name, String url) async {
    setState(() => _loading = true);

    final sub = Subscription(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      url: url,
      lastUpdate: 'только что',
      active: true,
    );

    try {
      final servers = await _subService.parseSubscription(sub);
      sub.serverCount = servers.length;

      await _storage.saveSubscription(sub);
      await _storage.saveServers([..._storage.getServers(), ...servers]);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Добавлено ${servers.length} серверов')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }

    setState(() => _loading = false);
    _loadSubs();
  }

  Future<void> _deleteSub(int id) async {
    await _storage.deleteSubscription(id);
    // Remove associated servers
    final servers = _storage.getServers().where((s) => s.subId != id).toList();
    await _storage.clearServers();
    await _storage.saveServers(servers);
    _loadSubs();
  }

  Future<void> _updateSub(Subscription sub) async {
    setState(() => _loading = true);
    try {
      final servers = await _subService.parseSubscription(sub);
      sub.serverCount = servers.length;
      sub.lastUpdate = 'только что';

      await _storage.saveSubscription(sub);
      // Remove old servers from this sub and add new
      final existing = _storage.getServers().where((s) => s.subId != sub.id).toList();
      await _storage.clearServers();
      await _storage.saveServers([...existing, ...servers]);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Обновлено: ${servers.length} серверов')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка обновления: $e')),
      );
    }
    setState(() => _loading = false);
    _loadSubs();
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить подписку'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Название',
                hintText: 'Premium Access',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL подписки',
                hintText: 'https://... или vless://...',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _scanQR(urlCtrl),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Сканировать QR'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && urlCtrl.text.isNotEmpty) {
                Navigator.pop(context);
                _addSubscription(nameCtrl.text, urlCtrl.text);
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _scanQR(TextEditingController controller) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Сканировать QR')),
          body: MobileScanner(
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  controller.text = barcode.rawValue!;
                  Navigator.pop(context);
                  _showAddDialog();
                  break;
                }
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Подписки'),
        actions: [
          IconButton(
            icon: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.add),
            onPressed: _loading ? null : _showAddDialog,
          ),
        ],
      ),
      body: _subs.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.link, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Нет подписок',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Добавьте подписку по URL или QR-коду',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _subs.length,
            itemBuilder: (context, index) {
              final sub = _subs[index];
              return _SubCard(
                sub: sub,
                onDelete: () => _deleteSub(sub.id),
                onUpdate: () => _updateSub(sub),
              );
            },
          ),
    );
  }
}

class _SubCard extends StatelessWidget {
  final Subscription sub;
  final VoidCallback onDelete;
  final VoidCallback onUpdate;

  const _SubCard({
    required this.sub,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.link, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      sub.url,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _SubStat(icon: Icons.public, text: '${sub.serverCount} серверов'),
              const SizedBox(width: 16),
              _SubStat(icon: Icons.access_time, text: sub.lastUpdate),
              const Spacer(),
              TextButton.icon(
                onPressed: onUpdate,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Обновить', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubStat extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SubStat({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}
