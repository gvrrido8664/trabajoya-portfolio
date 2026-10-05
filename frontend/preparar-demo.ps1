$ErrorActionPreference = 'Stop'
$projectDir = $PSScriptRoot
foreach ($name in @('.env.development', '.env.production')) {
  $target = Join-Path $projectDir $name
  if (Test-Path -LiteralPath $target) { throw "$name ya existe; conserva tu configuración o retírala manualmente." }
}
foreach ($name in @('.env.development', '.env.production')) {
  Copy-Item -LiteralPath (Join-Path $projectDir '.env.example') -Destination (Join-Path $projectDir $name)
}
Write-Host 'Entorno local preparado. Ejecuta flutter pub get y flutter run -d chrome --web-port 3000.'
