# SkillSwap Pro APK Build & Upload Helper
# This script automates compiling the Flutter app and securely copying the APK to your VPS.

$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "   SKILLSWAP PRO: BUILD & UPLOAD APK     " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Verify Flutter environment
if (-not (Get-Command "flutter" -ErrorAction SilentlyContinue)) {
    Write-Error "Flutter SDK not found in path. Please install Flutter and add it to your PATH environment variable."
}

# 2. Build Flutter APK
Write-Host "[1/3] Building Release APK locally..." -ForegroundColor Green
$frontendDir = Join-Path $PSScriptRoot "frontend"

Push-Location $frontendDir
try {
    # Run flutter build
    flutter build apk --release --no-pub
} catch {
    Pop-Location
    Write-Error "Flutter build failed. Please check build logs above."
}
Pop-Location

$apkPath = Join-Path $frontendDir "build/app/outputs/flutter-apk/app-release.apk"
if (-not (Test-Path $apkPath)) {
    Write-Error "APK file was not found after build at: $apkPath"
}

Write-Host "`nAPK successfully built at: $apkPath" -ForegroundColor Cyan
Write-Host ""

# 3. Configure VPS parameters
Write-Host "[2/3] Configuring VPS Connection..." -ForegroundColor Green
$defaultHost = "167.86.100.54"
$defaultUser = "root"
$defaultRemotePath = "/opt/skillprof/backend/gateway-service/shared/skillswap.apk"

# Prompt for Host
$vpsHost = Read-Host "Enter VPS Host IP address [Default: $defaultHost]"
if ([string]::IsNullOrWhiteSpace($vpsHost)) { $vpsHost = $defaultHost }

# Prompt for User
$vpsUser = Read-Host "Enter VPS SSH username [Default: $defaultUser]"
if ([string]::IsNullOrWhiteSpace($vpsUser)) { $vpsUser = $defaultUser }

# Prompt for Private Key Path
$defaultKey = Join-Path $env:USERPROFILE ".ssh\skillprof_vps"
if (-not (Test-Path $defaultKey)) {
    $defaultKey = Join-Path $env:USERPROFILE ".ssh\id_rsa"
}
if (-not (Test-Path $defaultKey)) {
    $defaultKey = ""
}

$sshKeyPath = Read-Host "Enter path to your SSH Private Key file (e.g. C:\Users\YourUser\.ssh\id_rsa)"
if ([string]::IsNullOrWhiteSpace($sshKeyPath)) { 
    if ([string]::IsNullOrWhiteSpace($defaultKey)) {
        Write-Error "SSH Private Key path is required to connect to the VPS."
    }
    $sshKeyPath = $defaultKey 
}

# Clean path quotes if user dragged and dropped the file
$sshKeyPath = $sshKeyPath.Replace("`"", "").Replace("'", "").Trim()

if (-not (Test-Path $sshKeyPath)) {
    Write-Error "Could not find SSH Private Key at: $sshKeyPath"
}

Write-Host ""
Write-Host "[3/3] Uploading APK to VPS at $($vpsHost)..." -ForegroundColor Green

# Use native Windows scp to upload
try {
    Write-Host "Running: scp -i `"$sshKeyPath`" `"$apkPath`" $($vpsUser)@$($vpsHost):$defaultRemotePath" -ForegroundColor DarkGray
    scp -i "$sshKeyPath" "$apkPath" "$($vpsUser)@$($vpsHost):$defaultRemotePath"
    
    Write-Host "Setting file permissions on VPS..." -ForegroundColor DarkGray
    ssh -i "$sshKeyPath" "$($vpsUser)@$($vpsHost)" "chmod 644 $defaultRemotePath"
    
    Write-Host "`n[SUCCESS] APK successfully uploaded and is now live at: http://$($vpsHost):3000/api/download/apk" -ForegroundColor Green
} catch {
    Write-Host "`n[ERROR] Upload failed! Please check:" -ForegroundColor Red
    Write-Host "1. Your SSH private key has correct access permissions to the VPS."
    Write-Host "2. The directory '/opt/skillprof/backend/gateway-service/shared' exists on the VPS."
    Write-Host "   (Note: The directory is created automatically when the latest docker-compose config deploys)."
    Write-Host ""
    Write-Error $_.Exception.Message
}
