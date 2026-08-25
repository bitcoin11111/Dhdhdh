#!/bin/bash
set -e

echo "🛡️ ShieldVPN Build Script"
echo "=========================="

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter не установлен"
    echo "   https://docs.flutter.dev/get-started/install"
    exit 1
fi

echo "✅ Flutter $(flutter --version | head -1)"

# Get dependencies
echo ""
echo "📦 Установка зависимостей..."
flutter pub get

# Generate Hive adapters
echo ""
echo "🔧 Генерация адаптеров..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# Build release APK
echo ""
echo "📱 Сборка APK..."
flutter build apk --release

echo ""
echo "✅ Готово!"
echo "APK: build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "Установка:"
echo "  flutter install"
echo ""
echo "Или скопируй APK на устройство:"
echo "  adb install build/app/outputs/flutter-apk/app-release.apk"
