$ErrorActionPreference = 'Stop'

$websiteDir = $PSScriptRoot
$projectDir = Split-Path -Parent $websiteDir
$apkSource = Join-Path $projectDir 'build\app\outputs\flutter-apk\app-release.apk'
$downloadDir = Join-Path $websiteDir 'public\downloads'
$apkDestination = Join-Path $downloadDir 'amazon-track.apk'
$vercelHobbyLimit = 100MB

Write-Host '1/4 Gerando APK release universal...'
Push-Location $projectDir
try {
    flutter build apk --release
}
finally {
    Pop-Location
}

if (-not (Test-Path $apkSource)) {
    throw "O APK release não foi encontrado em: $apkSource"
}

$apkSize = (Get-Item $apkSource).Length
if ($apkSize -gt $vercelHobbyLimit) {
    $sizeMb = [Math]::Round($apkSize / 1MB, 2)
    throw "O APK release tem $sizeMb MiB e excede o limite de 100 MB da Vercel Hobby."
}

Write-Host '2/4 Substituindo o APK disponível no site...'
New-Item -ItemType Directory -Path $downloadDir -Force | Out-Null
Copy-Item $apkSource $apkDestination -Force

Write-Host '3/4 Instalando dependências do site...'
Push-Location $websiteDir
try {
    npm install

    Write-Host '4/4 Gerando build Vite...'
    npm run build
}
finally {
    Pop-Location
}

$sizeMb = [Math]::Round((Get-Item $apkDestination).Length / 1MB, 2)
Write-Host "Concluído: APK release de $sizeMb MiB incluído em public/downloads/amazon-track.apk"
