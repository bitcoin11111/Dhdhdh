import 'package:flutter/services.dart';

/// Home screen widget and app shortcuts
class WidgetService {
  static const platform = MethodChannel('com.shieldvpn.app/widgets');

  /// Update widget with current status
  static Future<void> updateWidget({
    required bool connected,
    required String serverName,
    required String ping,
  }) async {
    try {
      await platform.invokeMethod('updateWidget', {
        'connected': connected,
        'serverName': serverName,
        'ping': ping,
      });
    } catch (e) {
      // Widget not supported or error
    }
  }

  /// Set app shortcuts (long press on icon)
  static Future<void> setShortcuts() async {
    try {
      await platform.invokeMethod('setShortcuts', {
        'shortcuts': [
          {
            'id': 'connect',
            'label': 'Подключить',
            'icon': 'ic_vpn_connect',
          },
          {
            'id': 'disconnect',
            'label': 'Отключить',
            'icon': 'ic_vpn_disconnect',
          },
          {
            'id': 'quick_test',
            'label': 'Быстрый тест',
            'icon': 'ic_speed',
          },
        ],
      });
    } catch (e) {
      // Shortcuts not supported
    }
  }
}
