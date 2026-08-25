import 'dart:async';
import 'package:flutter/material.dart';

import '../models/server.dart';
import '../services/vpn_service.dart';
import '../services/ping_service.dart';
import '../services/storage_service.dart';
import 'servers_screen.dart';
import 'subscriptions_screen.dart';
import 'settings_screen.dart';
import 'tester_screen.dart';
import 'logs_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VPNService _vpn = VPNService();
  final PingService _ping = PingService();
  final StorageService _storage = StorageService();

  Server? _selectedServer;
  Server? _bestServer;
  List<Server> _servers = [];
  bool _connected = false;
  bool _connecting = false;
  bool _fallbackMode = false;
  int _sessionTime = 0;
  String _statusText = 'Не подключено';
  Timer? _sessionTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupListeners();
  }

  void _loadData() {
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

  void _setupListeners() {
    _vpn.connectionStream.listen((connected) {
      setState(() {
        _connected = connected;
        _connecting = false;
        if (connected) {
          _startSessionTimer();
          _startPingChecker();
        } else {
          _sessionTimer?.cancel();
          _ping.stop();
        }
      });
    });

    _vpn.statusStream.listen((status) {
      setState(() {
        _fallbackMode = status == VPNStatus.fallback;
        _connecting = status == VPNStatus.connecting;
        _statusText = _getStatusText(status);
      });
    });

    _ping.bestServerStream.listen((server) {
      setState(() => _bestServer = server);
    });

    _ping.fallbackStream.listen((server) {
      _performFallback(server);
    });
  }

  String _getStatusText(VPNStatus status) {
    switch (status) {
      case VPNStatus.disconnected: return 'Не подключено';
      case VPNStatus.connecting: return 'Подключение...';
      case VPNStatus.connected: return 'Подключено';
      case VPNStatus.fallback: return 'Переключение...';
      case VPNStatus.unstable: return 'Нестабильно';
      default: return 'Неизвестно';
    }
  }

  Future<void> _toggleVPN() async {
    if (_connecting) return;

    if (_connected) {
      await _vpn.disconnect();
      setState(() {
        _connected = false;
        _sessionTime = 0;
      });
    } else {
      if (_selectedServer == null) {
        final settings = _storage.getSettings();
        if (settings.autoSwitch && _bestServer != null) {
          _selectedServer = _bestServer;
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ServersScreen()));
          return;
        }
      }

      setState(() => _connecting = true);
      final success = await _vpn.connect(
        _selectedServer!.configJson,
        _selectedServer!.protocol,
      );

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка подключения')),
        );
      }
    }
  }

  Future<void> _performFallback(Server newServer) async {
    final success = await _vpn.fallback(newServer.configJson, newServer.protocol);
    if (success) {
      setState(() {
        _selectedServer = newServer;
        _storage.getSettings().selectedServerId = newServer.id;
        _storage.saveSettings(_storage.getSettings());
      });
    }
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _sessionTime++),
    );
  }

  void _startPingChecker() {
    final settings = _storage.getSettings();
    _ping.start(
      servers: _servers,
      interval: settings.checkInterval,
      currentServer: _selectedServer,
      autoSwitch: settings.autoSwitch,
      fallbackEnabled: settings.fallbackEnabled,
    );
  }

  void _openServers() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ServersScreen()),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final settings = _storage.getSettings();
    final autoSwitch = settings.autoSwitch;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ShieldVPN'),
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubscriptionsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection Ring
            _ConnectionRing(
              isConnected: _connected,
              isConnecting: _connecting,
              isFallback: _fallbackMode,
              onPressed: _toggleVPN,
            ),
            const SizedBox(height: 20),
            // Status
            Center(
              child: Column(
                children: [
                  Text(
                    _statusText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: _connected ? Colors.green : null,
                    ),
                  ),
                  if (autoSwitch)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'AUTO',
                          style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatBox(
                  value: _selectedServer != null ? '${_selectedServer!.ping}ms' : '--',
                  label: 'Пинг',
                ),
                _StatBox(
                  value: _connected ? _formatTime(_sessionTime) : '00:00',
                  label: 'Время',
                ),
                _StatBox(
                  value: '${_servers.where((s) => s.alive).length}',
                  label: 'Онлайн',
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Current Server
            _CurrentServerCard(
              server: _selectedServer,
              bestServer: _bestServer,
              onTap: _openServers,
            ),
            const SizedBox(height: 20),
            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TesterScreen()),
                    ),
                    icon: const Icon(Icons.speed),
                    label: const Text('Тест'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LogsScreen()),
                    ),
                    icon: const Icon(Icons.article),
                    label: const Text('Логи'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.shield), label: 'VPN'),
          BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Серверы'),
          BottomNavigationBarItem(icon: Icon(Icons.link), label: 'Подписки'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ещё'),
        ],
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) _openServers();
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubscriptionsScreen()),
            );
          }
          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          }
        },
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _ConnectionRing extends StatelessWidget {
  final bool isConnected;
  final bool isConnecting;
  final bool isFallback;
  final VoidCallback onPressed;

  const _ConnectionRing({
    required this.isConnected,
    required this.isConnecting,
    required this.isFallback,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = Colors.grey.shade300;
    Color buttonColor = Colors.grey.shade100;
    String text = 'Вкл';
    IconData icon = Icons.power_settings_new;

    if (isFallback) {
      borderColor = Colors.blue;
      buttonColor = Colors.blue;
      text = '...';
    } else if (isConnected) {
      borderColor = Colors.green;
      buttonColor = Colors.green;
      text = 'Выкл';
      icon = Icons.shield;
    } else if (isConnecting) {
      borderColor = Colors.orange;
      buttonColor = Colors.orange;
      text = '...';
    }

    return Center(
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 3),
          boxShadow: isConnected
            ? [BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)]
            : null,
        ),
        child: Center(
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(20),
              backgroundColor: buttonColor,
              foregroundColor: isConnected || isFallback ? Colors.white : Colors.black87,
              minimumSize: const Size(120, 120),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 32),
                const SizedBox(height: 4),
                Text(text, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;

  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class _CurrentServerCard extends StatelessWidget {
  final Server? server;
  final Server? bestServer;
  final VoidCallback onTap;

  const _CurrentServerCard({
    this.server,
    this.bestServer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
            color: server != null ? Colors.green : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(12),
          color: server != null ? Colors.green.withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            Text(server?.flag ?? '🌍', style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    server != null ? '${server!.name} — ${server!.city}' : 'Нет сервера',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    server != null
                      ? '${server!.protocol} · ${server!.subName}'
                      : 'Нажмите для выбора',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (server != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: server!.ping < 50
                    ? Colors.green.withOpacity(0.1)
                    : server!.ping < 100
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${server!.ping}ms',
                  style: TextStyle(
                    fontSize: 12,
                    color: server!.ping < 50
                      ? Colors.green
                      : server!.ping < 100
                        ? Colors.orange
                        : Colors.red,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
