import 'package:flutter/material.dart';

import '../models/server.dart';
import '../services/storage_service.dart';
import '../services/ping_service.dart';

class ServersScreen extends StatefulWidget {
  const ServersScreen({super.key});

  @override
  State<ServersScreen> createState() => _ServersScreenState();
}

class _ServersScreenState extends State<ServersScreen> {
  final StorageService _storage = StorageService();
  final PingService _ping = PingService();

  List<Server> _servers = [];
  Server? _selectedServer;
  Server? _bestServer;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _loadServers();
    _ping.bestServerStream.listen((server) {
      if (mounted) setState(() => _bestServer = server);
    });
  }

  void _loadServers() {
    _servers = _storage.getServers();
    final settings = _storage.getSettings();
    if (settings.selectedServerId > 0) {
      _selectedServer = _servers.cast<Server?>().firstWhere(
        (s) => s?.id == settings.selectedServerId,
        orElse: () => null,
      );
    }
    setState(() {});
  }

  Future<void> _refreshPings() async {
    setState(() => _checking = true);
    await _ping.checkNow(_servers);
    _loadServers();
    setState(() => _checking = false);
  }

  void _selectServer(Server server) {
    if (!server.alive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сервер недоступен')),
      );
      return;
    }

    final settings = _storage.getSettings();
    settings.selectedServerId = server.id;
    _storage.saveSettings(settings);

    setState(() => _selectedServer = server);
    Navigator.pop(context, server);
  }

  @override
  Widget build(BuildContext context) {
    final aliveCount = _servers.where((s) => s.alive).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Серверы'),
        actions: [
          IconButton(
            icon: _checking
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.refresh),
            onPressed: _checking ? null : _refreshPings,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _servers.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$aliveCount из ${_servers.length} онлайн',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  if (_bestServer != null)
                    Text(
                      'Лучший: ${_bestServer!.name}',
                      style: const TextStyle(fontSize: 13, color: Colors.green),
                    ),
                ],
              ),
            );
          }

          final server = _servers[index - 1];
          final isSelected = _selectedServer?.id == server.id;
          final isBest = _bestServer?.id == server.id;

          return _ServerListTile(
            server: server,
            isSelected: isSelected,
            isBest: isBest,
            onTap: () => _selectServer(server),
          );
        },
      ),
    );
  }
}

class _ServerListTile extends StatelessWidget {
  final Server server;
  final bool isSelected;
  final bool isBest;
  final VoidCallback onTap;

  const _ServerListTile({
    required this.server,
    required this.isSelected,
    required this.isBest,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = Colors.grey.shade300;
    if (isSelected) borderColor = Colors.green;
    if (isBest && !isSelected) borderColor = Colors.blue;
    if (!server.alive) borderColor = Colors.red.withOpacity(0.5);

    Color pingColor = Colors.grey;
    if (server.alive) {
      if (server.ping < 50) pingColor = Colors.green;
      else if (server.ping < 100) pingColor = Colors.orange;
      else pingColor = Colors.red;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(10),
          color: isSelected ? Colors.green.withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            Text(server.flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${server.name} — ${server.city}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: !server.alive ? Colors.grey : null,
                      decoration: !server.alive ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          server.protocol,
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        server.subName,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isBest && !isSelected)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'BEST',
                  style: TextStyle(fontSize: 9, color: Colors.blue, fontWeight: FontWeight.w600),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: pingColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                server.alive ? '${server.ping}ms' : 'OFF',
                style: TextStyle(fontSize: 12, color: pingColor, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
