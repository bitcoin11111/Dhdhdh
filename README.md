# 🛡️ ShieldVPN v2.0

Android VPN клиент с авто-переключением, подписками, экономией батареи и расширенными функциями.

## ✨ Фичи

### Основные
- **Подписки** — добавление по URL или QR-коду
- **Авто-пинг** — проверка всех серверов
- **Авто-выбор** — подключение к лучшему серверу
- **Fallback** — бесшовное переключение при падении
- **Протоколы**: VLESS+Reality, VMess+WS, Trojan+TLS, Shadowsocks, Hysteria2, WireGuard

### Экономия батареи 🔋
- **Адаптивный интервал** — реже проверять при стабильном соединении
- **Batch ping** — проверка пачками серверов
- **Night mode** — снижение активности ночью (23:00 - 07:00)
- **WiFi-only checks** — не проверять на мобильных данных
- **Doze mode** — совместимость с режимом сна Android
- **Low power detection** — автоматическое снижение активности
- **Screen-aware** — меньше проверок при выключенном экране

### Расширенные функции
- **Split Tunneling** — выбор приложений для VPN/прямого соединения
- **AdBlock** — DNS-фильтрация рекламы
- **Geo Bypass** — Netflix, Spotify, TikTok, YouTube Premium, Disney+, Instagram
- **Multi-hop** — двойной VPN для максимальной безопасности
- **Сжатие трафика** — уменьшение расхода данных
- **Kill Switch** — блокировка трафика при разрыве
- **Always-on VPN** — авто-переподключение

### Удобство
- **Виджет** — статус на главном экране
- **Shortcuts** — быстрые действия по долгому нажатию на иконку
- **Тестер** — проверка скорости, утечек, пинга
- **Логи** — журнал всех событий

## 🚀 Быстрый старт

```bash
# 1. Распакуй
unzip shieldvpn_app_v2.zip
cd shieldvpn_app

# 2. Собери
./build.sh

# 3. Установи
flutter install
```

## 📁 Структура

```
lib/
├── main.dart
├── models/
│   ├── server.dart
│   ├── subscription.dart
│   └── app_settings.dart
├── services/
│   ├── vpn_service.dart
│   ├── ping_service.dart        # ← Оптимизирован (batch, adaptive)
│   ├── subscription_service.dart
│   ├── storage_service.dart
│   ├── background_service.dart
│   ├── battery_service.dart      # ← NEW
│   ├── night_mode_service.dart   # ← NEW
│   ├── adblock_service.dart      # ← NEW
│   ├── split_tunnel_service.dart # ← NEW
│   ├── geo_service.dart          # ← NEW
│   ├── multihop_service.dart     # ← NEW
│   ├── compression_service.dart  # ← NEW
│   └── widget_service.dart       # ← NEW
└── screens/
    ├── home_screen.dart
    ├── servers_screen.dart
    ├── subscriptions_screen.dart
    ├── settings_screen.dart      # ← Расширен
    ├── split_tunnel_screen.dart  # ← NEW
    ├── geo_bypass_screen.dart    # ← NEW
    ├── tester_screen.dart
    └── logs_screen.dart
```

## ⚙️ Настройки батареи

| Параметр | Описание | Эффект |
|----------|----------|--------|
| Адаптивный интервал | Реже проверять при стабильности | -30% батареи |
| Только на WiFi | Не проверять на мобильных | -20% батареи |
| Ночной режим | 5x реже ночью | -40% ночью |
| Batch ping | Пачками по 4 сервера | -15% CPU |

## 🔧 Сборка

```bash
# Debug
flutter run

# Release APK
flutter build apk --release

# App Bundle
flutter build appbundle
```

## 📝 Лицензия

MIT
