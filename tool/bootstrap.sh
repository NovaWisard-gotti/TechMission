#!/usr/bin/env bash
# Genera las carpetas de plataforma (android/ios) y descarga dependencias.
# El repositorio solo versiona el codigo Dart, los assets y la configuracion:
# las carpetas nativas se regeneran para evitar conflictos entre versiones
# de Flutter y para mantener el repositorio limpio.
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Generando plataformas nativas"
flutter create --project-name it_management_simulator --org pe.edu.emaf --platforms=android,ios .

echo "==> Descargando dependencias"
flutter pub get

echo "==> Analisis estatico"
flutter analyze

echo "==> Pruebas"
flutter test

echo ""
echo "Listo. Para ejecutar en un dispositivo:  flutter run"
echo "Para generar el APK:                     flutter build apk --release"
