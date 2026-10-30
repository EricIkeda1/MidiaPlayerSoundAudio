param([ValidateSet('chrome', 'edge')][string]$Navegador = 'chrome')
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw 'Instale o Flutter e adicione flutter/bin ao PATH.'
}
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'Falha ao instalar as dependências.' }
# A porta fixa mantém a mesma origem de armazenamento nas próximas execuções.
flutter run -d $Navegador --web-port=7357
if ($LASTEXITCODE -ne 0) { throw 'Falha ao iniciar o player no navegador.' }
