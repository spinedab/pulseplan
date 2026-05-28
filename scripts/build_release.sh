#!/bin/bash
#
# PulsePlan - Build Release Script
# Ejecuta builds de producción para las plataformas principales
#

set -e

echo "=== PulsePlan Release Build ==="
echo ""

# Limpieza
flutter clean
flutter pub get

echo "→ Running analysis..."
flutter analyze

echo "→ Running tests..."
flutter test

echo "→ Building Android Release APK..."
flutter build apk --release

echo "→ Building Web Release..."
flutter build web --release

echo ""
echo "✅ Builds completados exitosamente."
echo ""
echo "Artefactos generados:"
echo "  - Android: build/app/outputs/flutter-apk/app-release.apk"
echo "  - Web:     build/web/"
echo ""
echo "Versión: $(grep 'version:' pubspec.yaml | head -1 | awk '{print $2}')"