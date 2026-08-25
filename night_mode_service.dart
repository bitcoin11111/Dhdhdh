import 'dart:async';

/// Night mode - quiet hours with reduced activity
class NightModeService {
  static final NightModeService _instance = NightModeService._internal();
  factory NightModeService() => _instance;
  NightModeService._internal();

  bool _enabled = false;
  int _startHour = 23; // 23:00
  int _endHour = 7;    // 07:00
  Timer? _checkTimer;

  bool get enabled => _enabled;
  bool get isNightTime => _checkNightTime();

  /// Check if current time is within night hours
  bool _checkNightTime() {
    if (!_enabled) return false;
    final now = DateTime.now().hour;
    if (_startHour > _endHour) {
      // Overnight range (e.g., 23:00 - 07:00)
      return now >= _startHour || now < _endHour;
    } else {
      return now >= _startHour && now < _endHour;
    }
  }

  /// Get effective check interval considering night mode
  int getEffectiveInterval(int baseInterval) {
    if (!isNightTime) return baseInterval;

    // During night: check much less frequently
    // Base 60s → 300s (5 min)
    // Base 30s → 150s (2.5 min)
    return baseInterval * 5;
  }

  /// Should we suppress notifications?
  bool shouldSuppressNotifications() {
    return isNightTime;
  }

  /// Should we allow fallback during night?
  bool shouldAllowFallback() {
    // During night, only fallback if completely dead
    // Don't switch for performance reasons
    return !isNightTime;
  }

  void setEnabled(bool value) {
    _enabled = value;
    _startTimer();
  }

  void setHours(int start, int end) {
    _startHour = start;
    _endHour = end;
  }

  void _startTimer() {
    _checkTimer?.cancel();
    if (!_enabled) return;

    // Check every 15 minutes if night mode state changed
    _checkTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      // Notify listeners if state changed
    });
  }

  void dispose() {
    _checkTimer?.cancel();
  }
}
