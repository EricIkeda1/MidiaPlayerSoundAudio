$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw 'Instale o Flutter e adicione flutter/bin ao PATH. Consulte README.md.'
}
if (-not (Test-Path 'android/gradlew.bat')) {
  flutter create --platforms=android,ios,web --org app.musica --project-name musica --no-pub .
  if ($LASTEXITCODE -ne 0) { throw 'Falha ao preparar o projeto nativo.' }
}
dart tool/configure.dart
if ($LASTEXITCODE -ne 0) { throw 'Falha ao configurar o projeto nativo.' }
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'Falha ao instalar dependências.' }
flutter run @args
