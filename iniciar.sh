#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
command -v flutter >/dev/null || { echo 'Instale o Flutter e adicione flutter/bin ao PATH. Consulte README.md.'; exit 1; }
if [ ! -f android/gradlew ]; then
  flutter create --platforms=android,ios,web --org app.musica --project-name musica --no-pub .
fi
dart tool/configure.dart
flutter pub get
flutter run "$@"
