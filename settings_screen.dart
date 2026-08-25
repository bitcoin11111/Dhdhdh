import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../models/app_settings.dart';
import 'split_tunnel_screen.dart';
import 'geo_bypass_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = _storage.getSettings();
  }

  void _save() {
    _storage.saveSettings(_settings);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle('Автоматика'),
          _ToggleTile(
            title: 'Авто-выбор сервера',
            subtitle: 'Проверяет пинг и выбирает лучший',
            value: _settings.autoSwitch,
            onChanged: (v) { _settings.autoSwitch = v; _save(); },
          ),
          _ToggleTile(
            title: 'Fallback (авто-переключение)',
            subtitle: 'Мгновенно переключает при падении',
            value: _settings.fallbackEnabled,
            onChanged: (v) { _settings.fallbackEnabled = v; _save(); },
          ),
          _ToggleTile(
            title: 'Проверка при старте',
            subtitle: 'Тест серверов при запуске',
            value: _settings.checkOnStartup,
            onChanged: (v) { _settings.checkOnStartup = v; _save(); },
          ),
          _IntervalTile(
            value: _settings.checkInterval,
            onChanged: (v) { _settings.checkInterval = v; _save(); },
          ),

          _SectionTitle('Экономия батареи'),
          _ToggleTile(
            title: 'Адаптивный интервал',
            subtitle: 'Реже проверять при стабильном соединении',
            value: _settings.adaptiveInterval,
            onChanged: (v) { _settings.adaptiveInterval = v; _save(); },
          ),
          _ToggleTile(
            title: 'Только на WiFi',
            subtitle: 'Не проверять пинги на мобильных данных',
            value: _settings.preferWifiChecks,
            onChanged: (v) { _settings.preferWifiChecks = v; _save(); },
          ),
          _ToggleTile(
            title: 'Ночной режим',
            subtitle: 'Снижать активность ночью (23:00 - 07:00)',
            value: _settings.nightMode,
            onChanged: (v) { _settings.nightMode = v; _save(); },
          ),

          _SectionTitle('Функции'),
          _ToggleTile(
            title: 'Split Tunneling',
            subtitle: 'Выбор приложений для VPN',
            value: _settings.splitTunneling,
            onChanged: (v) { _settings.splitTunneling = v; _save(); },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Настроить приложения', style: TextStyle(fontSize: 15)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SplitTunnelScreen()),
            ),
          ),
          _ToggleTile(
            title: 'AdBlock',
            subtitle: 'Блокировка рекламы через DNS',
            value: _settings.adBlockEnabled,
            onChanged: (v) { _settings.adBlockEnabled = v; _save(); },
          ),
          _ToggleTile(
            title: 'Обход блокировок',
            subtitle: 'Netflix, Spotify, TikTok и др.',
            value: _settings.enabledGeoServices.isNotEmpty,
            onChanged: (v) {},
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Настроить сервисы', style: TextStyle(fontSize: 15)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GeoBypassScreen()),
            ),
          ),
          _ToggleTile(
            title: 'Сжатие трафика',
            subtitle: 'Уменьшить расход данных',
            value: _settings.compression,
            onChanged: (v) { _settings.compression = v; _save(); },
          ),
          _ToggleTile(
            title: 'Multi-hop (двойной VPN)',
            subtitle: 'Двойное шифрование для безопасности',
            value: _settings.multiHop,
            onChanged: (v) { _settings.multiHop = v; _save(); },
          ),

          _SectionTitle('Защита'),
          _ToggleTile(
            title: 'Kill Switch',
            subtitle: 'Блокировать трафик при разрыве',
            value: _settings.killSwitch,
            onChanged: (v) { _settings.killSwitch = v; _save(); },
          ),
          _ToggleTile(
            title: 'Always-on VPN',
            subtitle: 'Переподключаться автоматически',
            value: _settings.alwaysOn,
            onChanged: (v) { _settings.alwaysOn = v; _save(); },
          ),
          _ToggleTile(
            title: 'IPv6',
            subtitle: 'Разрешить IPv6 трафик',
            value: _settings.ipv6Enabled,
            onChanged: (v) { _settings.ipv6Enabled = v; _save(); },
          ),

          _SectionTitle('Сеть'),
          _TextTile(
            title: 'Удалённый DNS',
            value: _settings.remoteDNS,
            onTap: () => _editText('Удалённый DNS', (v) => _settings.remoteDNS = v),
          ),
          _TextTile(
            title: 'Локальный DNS',
            value: _settings.localDNS,
            onTap: () => _editText('Локальный DNS', (v) => _settings.localDNS = v),
          ),

          _SectionTitle('О приложении'),
          _InfoTile(title: 'Версия', value: '1.0.0 (build 42)'),
          _InfoTile(title: 'Xray-core', value: 'v25.3.3'),
          _InfoTile(title: 'Батарея', value: 'Оптимизировано'),
        ],
      ),
    );
  }

  void _editText(String title, Function(String) onSave) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctrl, decoration: InputDecoration(hintText: title)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              onSave(ctrl.text);
              _save();
              Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
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
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
      child: Text(
        text,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

class _IntervalTile extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _IntervalTile({required this.value, required this.onChanged});

  String _label(int sec) {
    if (sec < 60) return '$sec секунд';
    return '${sec ~/ 60} минут';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Интервал проверки', style: TextStyle(fontSize: 15)),
      subtitle: Text(_label(value), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(title: const Text('30 секунд (агрессивно)'), onTap: () { onChanged(30); Navigator.pop(context); }),
                ListTile(title: const Text('60 секунд (рекомендуется)'), onTap: () { onChanged(60); Navigator.pop(context); }),
                ListTile(title: const Text('5 минут (экономно)'), onTap: () { onChanged(300); Navigator.pop(context); }),
                ListTile(title: const Text('10 минут (минимум)'), onTap: () { onChanged(600); Navigator.pop(context); }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TextTile extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;

  const _TextTile({required this.title, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: Text(value, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String value;

  const _InfoTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: Text(value, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
    );
  }
}
