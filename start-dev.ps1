<#
.SYNOPSIS
    Kịch bản 1-click tự động chạy môi trường Dev:
    - Mở Docker Desktop (hoặc ứng dụng bạn chỉ định)
    - Chờ Docker Daemon sẵn sàng
    - Khởi động Database & Django Backend qua Docker Compose
    - Mở Frontend Dev Server (npm run dev)
    - Mở trình duyệt và TỰ ĐỘNG ĐĂNG NHẬP vào UI
#>

param(
    [string]$DockerShortcut = "C:\Users\DELL\Desktop\Visual Studio Code.lnk",
    [string]$DevEmail = "hoang.dinh.khang@example.com",
    [string]$DevPassword = "testpass123",
    [switch]$AutoLogin
)

$ErrorActionPreference = "Continue"
$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "   🚀 PARKING MANAGEMENT - START DEV AUTO" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. Khởi chạy Docker Desktop
Write-Host "`n[1/4] Kiểm tra và khởi động Docker Desktop..." -ForegroundColor Yellow
$dockerProcess = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue

if (-not $dockerProcess) {
    if (Test-Path "C:\Program Files\Docker\Docker\Docker Desktop.exe") {
        Write-Host "-> Đang mở Docker Desktop..." -ForegroundColor Gray
        Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    } elseif (Test-Path $DockerShortcut) {
        Write-Host "-> Đang mở qua shortcut: $DockerShortcut" -ForegroundColor Gray
        Start-Process $DockerShortcut
    } else {
        Write-Host "-> Đang khởi động Docker service..." -ForegroundColor Gray
        Start-Process "docker" -ArgumentList "version" -ErrorAction SilentlyContinue
    }
} else {
    Write-Host "-> Docker Desktop đã đang chạy." -ForegroundColor Green
}

# Chờ Docker Engine sẵn sàng
Write-Host "-> Đang kiểm tra kết nối tới Docker Engine..." -ForegroundColor Gray
$dockerReady = $false
for ($i = 0; $i -lt 30; $i++) {
    $null = & docker info 2>&1
    if ($LASTEXITCODE -eq 0) {
        $dockerReady = $true
        break
    }
    Write-Host "." -NoNewline -ForegroundColor DarkGray
    Start-Sleep -Seconds 2
}
Write-Host ""

if ($dockerReady) {
    Write-Host "-> Docker Engine đã sẵn sàng!" -ForegroundColor Green
} else {
    Write-Host "[!] Docker Engine phản hồi chậm, tiếp tục thực thi các bước tiếp theo..." -ForegroundColor Magenta
}

# 2. Khởi động DB và Backend
Write-Host "`n[2/4] Khởi động Database & Backend qua Docker Compose..." -ForegroundColor Yellow
$backendDir = Join-Path $RootDir "parking_management_backend"
Push-Location $backendDir
try {
    docker compose up -d db web
} finally {
    Pop-Location
}

# 3. Khởi động Frontend Dev Server
Write-Host "`n[3/4] Mở Frontend Server (Vite)..." -ForegroundColor Yellow
$frontendDir = Join-Path $RootDir "parking_management_frontend"
$feCommand = "Set-Location '$frontendDir'; npm run dev -- --host 127.0.0.1"
Start-Process powershell -ArgumentList "-NoExit", "-Command", $feCommand

# 4. Mở trình duyệt & Tự động login
Write-Host "`n[4/4] Đang mở trình duyệt vào trang ứng dụng..." -ForegroundColor Yellow

$encodedEmail = [System.Uri]::EscapeDataString($DevEmail)
$encodedPass = [System.Uri]::EscapeDataString($DevPassword)

if ($DevPassword) {
    # Tự động điền và đăng nhập
    $targetUrl = "http://127.0.0.1:5173/login?account=$encodedEmail&password=$encodedPass&autologin=1"
} else {
    # Tự động điền email sẵn, chờ nhập mật khẩu
    $targetUrl = "http://127.0.0.1:5173/login?account=$encodedEmail"
}

Start-Sleep -Seconds 2
Start-Process $targetUrl

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "  Môi trường đã sẵn sàng!" -ForegroundColor Green
Write-Host "  Frontend URL: http://127.0.0.1:5173/login" -ForegroundColor White
Write-Host "  Backend API:  http://127.0.0.1:8000/api/health/" -ForegroundColor White
Write-Host "==================================================" -ForegroundColor Cyan
