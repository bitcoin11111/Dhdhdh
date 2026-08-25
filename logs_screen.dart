import 'package:flutter/material.dart';

import '../services/storage_service.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final StorageService _storage = StorageService();
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    _logs = _storage.getLogs();
    setState(() {});
  }

  Future<void> _clear() async {
    await _storage.clearLogs();
    _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Логи'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clear,
          ),
        ],
      ),
      body: _logs.isEmpty
        ? Center(
            child: Text(
              'Нет логов',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _logs.length,
            itemBuilder: (context, index) {
              final log = _logs[index];
              Color textColor = Colors.grey.shade700;
              if (log.contains('✅') || log.contains('PASS')) textColor = Colors.green;
              if (log.contains('❌') || log.contains('FAIL')) textColor = Colors.red;
              if (log.contains('⚠️') || log.contains('WARN')) textColor = Colors.orange;
              if (log.contains('⚡') || log.contains('FALLBACK')) textColor = Colors.blue;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  log,
                  style: TextStyle(fontSize: 11, color: textColor, fontFamily: 'monospace'),
                ),
              );
            },
          ),
    );
  }
}
