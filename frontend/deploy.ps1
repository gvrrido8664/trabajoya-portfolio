# Build de Flutter web + commit + push. Vercel sirve build/web automaticamente.
# Uso:  .\deploy.ps1            (mensaje por defecto)
#       .\deploy.ps1 "mi msg"   (mensaje de commit propio)
param([string]$Message = "deploy web")

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

# Ejecutar chequeo de tokens
Write-Host "Verificando deriva de diseño..."
.\tools\check_tokens.ps1
if ($LASTEXITCODE -ne 0) { throw "Deriva de diseño detectada. Corrige los errores antes de desplegar." }

flutter build web --release --dart-define=ENV=production
if ($LASTEXITCODE -ne 0) { throw "flutter build fallo" }

git add -A
# Commitea solo si hay cambios staged
git diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
    git commit -m $Message
    # Publica a produccion (rama main) sin importar en que rama estes
    git push origin HEAD:main
    Write-Host "Deploy pusheado. Vercel publicara en ~1 min: https://trabajoya-app.vercel.app"
} else {
    Write-Host "Sin cambios en build/web; nada que desplegar."
}
