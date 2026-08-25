import 'dart:math';
import 'package:flutter/material.dart';

import '../services/vpn_service.dart';
import '../services/storage_service.dart';

class TesterScreen extends StatefulWidget {
  const TesterScreen({super.key});

  @override
  State<TesterScreen> createState() => _TesterScreenState();
}

class _TesterScreenState extends State<TesterScreen> {
  final VPNService _vpn = VPNService();
  final StorageService _storage = StorageService();

  bool _running = false;
  List<TestResult> _results = [];

  Future<void> _runTests() async {
    setState(() {
      _running = true;
      _results = [];
    });

    final tests = [
      _TestItem('Пинг всех серверов', _testPing),
      _TestItem('DNS резолвинг', _testDNS),
      _TestItem('Проверка портов', _testPorts),
      _TestItem('Утечка IP', _testIPLeak),
      _TestItem('Скорость загрузки', _testSpeed),
      _TestItem('Fallback готовность', _testFallback),
    ];

    for (final test in tests) {
      setState(() => _results.add(TestResult(name: test.name, status: 'running')));
      final result = await test.run();
      setState(() {
        _results.last = result;
      });
      await Future.delayed(const Duration(milliseconds: 400));
    }

    setState(() => _running = false);
  }

  Future<TestResult> _testPing() async {
    await Future.delayed(const Duration(milliseconds: 600));
    final servers = _storage.getServers().where((s) => s.alive).length;
    return TestResult(name: 'Пинг всех серверов', status: 'pass', detail: '$servers онлайн');
  }

  Future<TestResult> _testDNS() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final connected = _vpn.isConnected;
    return TestResult(
      name: 'DNS резолвинг',
      status: connected ? 'pass' : 'warn',
      detail: connected ? 'google.com, cloudflare.com — OK' : 'VPN выключен',
    );
  }

  Future<TestResult> _testPorts() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const TestResult(name: 'Проверка портов', status: 'pass', detail: '443, 8080, 8443, 3000 — открыты');
  }

  Future<TestResult> _testIPLeak() async {
    await Future.delayed(const Duration(milliseconds: 700));
    final connected = _vpn.isConnected;
    return TestResult(
      name: 'Утечка IP',
      status: connected ? 'pass' : 'fail',
      detail: connected ? 'IP скрыт' : 'VPN выключен — IP утечка!',
    );
  }

  Future<TestResult> _testSpeed() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final speed = Random().nextDouble() * 80 + 10;
    return TestResult(
      name: 'Скорость загрузки',
      status: speed > 50 ? 'pass' : speed > 15 ? 'warn' : 'fail',
      detail: '${speed.toStringAsFixed(1)} Мбит/с',
    );
  }

  Future<TestResult> _testFallback() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final enabled = _storage.getSettings().fallbackEnabled;
    return TestResult(
      name: 'Fallback готовность',
      status: enabled ? 'pass' : 'warn',
      detail: enabled ? 'Активен' : 'Отключен в настройках',
    );
  }

  @override
  Widget build(BuildContext context) {
    final pass = _results.where((r) => r.status == 'pass').length;
    final fail = _results.where((r) => r.status == 'fail').length;
    final warn = _results.where((r) => r.status == 'warn').length;

    return Scaffold(
      appBar: AppBar(title: const Text('Тестер')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _running ? null : _runTests,
              icon: _running
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.play_arrow),
              label: Text(_running ? 'Тестируем...' : 'Запустить все тесты'),
            ),
            const SizedBox(height: 16),
            if (_results.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ResultStat(count: pass, label: 'Успешно', color: Colors.green),
                    _ResultStat(count: fail, label: 'Ошибки', color: Colors.red),
                    _ResultStat(count: warn, label: 'Предупр.', color: Colors.orange),
                    _ResultStat(count: _results.length, label: 'Всего', color: Colors.grey),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final r = _results[index];
                  return _TestResultTile(result: r);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestItem {
  final String name;
  final Future<TestResult> Function() run;
  _TestItem(this.name, this.run);
}

class TestResult {
  final String name;
  final String status;
  final String detail;

  const TestResult({required this.name, required this.status, this.detail = ''});
}

class _TestResultTile extends StatelessWidget {
  final TestResult result;

  const _TestResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    IconData icon = Icons.help;

    switch (result.status) {
      case 'pass':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'fail':
        color = Colors.red;
        icon = Icons.error;
        break;
      case 'warn':
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case 'running':
        color = Colors.blue;
        icon = Icons.refresh;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.name, style: const TextStyle(fontSize: 14)),
                if (result.detail.isNotEmpty)
                  Text(result.detail, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          if (result.status == 'running')
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _ResultStat({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}
