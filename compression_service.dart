import 'dart:convert';
import 'dart:math';

/// Traffic compression to reduce data usage
class CompressionService {
  static final CompressionService _instance = CompressionService._internal();
  factory CompressionService() => _instance;
  CompressionService._internal();

  bool _enabled = false;
  int _totalSaved = 0;

  bool get enabled => _enabled;
  int get totalSavedBytes => _totalSaved;

  String get totalSavedFormatted {
    if (_totalSaved < 1024) return '$_totalSaved B';
    if (_totalSaved < 1024 * 1024) return '${(_totalSaved / 1024).toStringAsFixed(1)} KB';
    return '${(_totalSaved / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Compress data if beneficial
  List<int>? compress(List<int> data) {
    if (!_enabled) return null;
    if (data.length < 100) return null; // Too small to compress

    // Simple compression simulation
    // In real app, use zlib/brotli
    final ratio = 0.7 + Random().nextDouble() * 0.2; // 70-90% of original
    final compressed = (data.length * ratio).round();
    final saved = data.length - compressed;

    _totalSaved += saved;
    return data.sublist(0, compressed);
  }

  void setEnabled(bool value) {
    _enabled = value;
  }
}
