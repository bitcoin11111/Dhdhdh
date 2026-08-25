import 'package:flutter/material.dart';

import '../services/geo_service.dart';
import '../services/storage_service.dart';

class GeoBypassScreen extends StatefulWidget {
  const GeoBypassScreen({super.key});

  @override
  State<GeoBypassScreen> createState() => _GeoBypassScreenState();
}

class _GeoBypassScreenState extends State<GeoBypassScreen> {
  final GeoService _geo = GeoService();
  final StorageService _storage = StorageService();
  List<String> _enabled = [];

  @override
  void initState() {
    super.initState();
    _enabled = List<String>.from(_storage.getSettings().enabledGeoServices);
  }

  void _toggle(String id) {
    setState(() {
      if (_enabled.contains(id)) {
        _enabled.remove(id);
      } else {
        _enabled.add(id);
      }
    });

    final settings = _storage.getSettings();
    settings.enabledGeoServices = _enabled;
    _storage.saveSettings(settings);
  }

  @override
  Widget build(BuildContext context) {
    final services = _geo.getServices();

    return Scaffold(
      appBar: AppBar(title: const Text('Обход блокировок')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          final isEnabled = _enabled.contains(service.name.toLowerCase());

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(
                color: isEnabled ? Colors.green : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(12),
              color: isEnabled ? Colors.green.withOpacity(0.05) : null,
            ),
            child: Row(
              children: [
                Text(service.icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Регионы: ${service.regions.join(', ')}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                      Text(
                        '${service.domains.length} доменов',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isEnabled,
                  onChanged: (_) => _toggle(service.name.toLowerCase()),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
