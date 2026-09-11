#!/usr/bin/env bash
# Genera las carpetas de plataforma (android/ios) y descarga dependencias.
# El repositorio solo versiona el codigo Dart, los assets y la configuracion:
# las carpetas nativas se regeneran para evitar conflictos entre versiones
# de Flutter y para mantener el repositorio limpio.
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Generando plataformas nativas"
flutter create --project-name techmission --org pe.edu.emaf --platforms=android,ios .

echo "==> Nombre de la app en Android"
sed -i 's/android:label="techmission"/android:label="TechMission"/' android/app/src/main/AndroidManifest.xml

echo "==> Descargando dependencias"
flutter pub get

echo "==> Generando icono de la app"
dart run flutter_launcher_icons

echo "==> Analisis estatico"
flutter analyze

echo "==> Pruebas"
flutter test

echo ""
echo "Listo. Para ejecutar en un dispositivo:  flutter run"
echo "Para generar el APK:                     flutter build apk --release"
