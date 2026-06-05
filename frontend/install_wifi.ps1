# install_wifi.ps1 — Install APK to phone over WiFi
# Run this script from the frontend directory

$PHONE_IP = "192.168.1.108"
$PHONE_PORT = "5555"
$APK_PATH = "build\app\outputs\flutter-apk\app-release.apk"

Write-Host "=== SkillSwapPro WiFi APK Installer ===" -ForegroundColor Cyan

# Step 1: Kill any existing adb server
Write-Host "[1] Restarting ADB server..." -ForegroundColor Yellow
adb kill-server
Start-Sleep -Seconds 2
adb start-server
Start-Sleep -Seconds 1

# Step 2: Check if USB phone is connected to set TCP mode
$devices = adb devices
if ($devices -match "R5CT51JAHCN") {
    Write-Host "[2] USB phone found — enabling TCP/IP mode..." -ForegroundColor Yellow
    adb -s R5CT51JAHCN tcpip $PHONE_PORT
    Start-Sleep -Seconds 3
} else {
    Write-Host "[2] USB not detected — trying direct WiFi connect..." -ForegroundColor Yellow
}

# Step 3: Connect over WiFi
Write-Host "[3] Connecting to $PHONE_IP`:$PHONE_PORT over WiFi..." -ForegroundColor Yellow
$result = adb connect "${PHONE_IP}:${PHONE_PORT}"
Write-Host "    $result"
Start-Sleep -Seconds 2

# Step 4: Verify connection
$devices = adb devices
Write-Host "[4] Connected devices:" -ForegroundColor Yellow
Write-Host $devices

$devices_str = $devices -join "`n"
if ($devices_str -notlike "*$PHONE_IP*") {
    Write-Host "ERROR: Could not connect wirelessly. Make sure phone and PC are on the same WiFi." -ForegroundColor Red
    exit 1
}

# Step 5: Install APK
Write-Host "[5] Installing APK over WiFi..." -ForegroundColor Yellow
adb -s "${PHONE_IP}:${PHONE_PORT}" install -r $APK_PATH

Write-Host "=== Done! Open SkillSwapPro on your phone ===" -ForegroundColor Green
