# ============================================================================
# GestureMouse - Build & UIAccess Signing Script
# ============================================================================
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 1. Tự động kiểm tra và nâng quyền Administrator nếu chưa có
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[*] Đang yêu cầu quyền Administrator để cài đặt chứng chỉ..." -ForegroundColor Yellow
    try {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    } catch {
        Write-Host "[X] Yêu cầu quyền Administrator bị từ chối hoặc bị hủy." -ForegroundColor Red
        Read-Host "Nhấn Enter để đóng..."
    }
    exit
}

try {
    $ScriptDir = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    Set-Location $ScriptDir

    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host "       GESTURE MOUSE - QUY TRÌNH BIÊN DỊCH & KÝ SỐ TỰ ĐỘNG (UIAccess)       " -ForegroundColor Cyan
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host ""

    $ahk2Exe = "C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"
    $ahkV2 = "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
    $mainScript = Join-Path $ScriptDir "Main.ahk"
    $customBase = Join-Path $ScriptDir "bin\CustomClass.bin"
    $outputExe = Join-Path $ScriptDir "bin\GestureMouse.exe"
    $signScript = Join-Path $ScriptDir "tools\SignUIAccess.ahk"

    # 2. Kiểm tra các công cụ
    if (-not (Test-Path $ahk2Exe)) {
        throw "Không tìm thấy trình biên dịch Ahk2Exe tại: $ahk2Exe. Vui lòng cài đặt AutoHotkey Compiler."
    }
    if (-not (Test-Path $ahkV2)) {
        throw "Không tìm thấy AutoHotkey v2 tại: $ahkV2. Cần có AutoHotkey v2 để chạy bộ công cụ ký số."
    }
    if (-not (Test-Path $customBase)) {
        throw "Không tìm thấy Base binary tùy biến tại: $customBase."
    }
    if (-not (Test-Path $signScript)) {
        throw "Không tìm thấy công cụ ký số tại: $signScript."
    }

    # 3. Tắt tiến trình cũ nếu đang chạy
    Write-Host "[*] Đang kiểm tra và tắt tiến trình GestureMouse cũ nếu đang chạy..." -ForegroundColor Gray
    Get-Process "GestureMouse", "GestureMouse2" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Milliseconds 500

    # 4. Biên dịch bằng Ahk2Exe
    Write-Host ""
    Write-Host "[1/2] Đang biên dịch Main.ahk thành $outputExe..." -ForegroundColor Yellow
    $proc = Start-Process -FilePath $ahk2Exe -ArgumentList "/in `"$mainScript`" /base `"$customBase`" /out `"$outputExe`"" -Wait -PassThru -NoNewWindow
    if ($proc.ExitCode -ne 0) {
        throw "Biên dịch Ahk2Exe thất bại với mã lỗi $($proc.ExitCode)"
    }
    Write-Host "[+] Biên dịch thành công!" -ForegroundColor Green

    # 5. Kích hoạt UIAccess & Ký số
    Write-Host ""
    Write-Host "[2/2] Đang kích hoạt UIAccess và ký số tự động..." -ForegroundColor Yellow
    $procSign = Start-Process -FilePath $ahkV2 -ArgumentList "`"$signScript`" `"$outputExe`"" -Wait -PassThru -NoNewWindow
    if ($procSign.ExitCode -ne 0) {
        throw "Kích hoạt UIAccess hoặc ký số thất bại!"
    }

    Write-Host ""
    Write-Host "============================================================================" -ForegroundColor Green
    Write-Host "[V] THÀNH CÔNG: Đã tạo file thực thi hoàn chỉnh nhất tại:" -ForegroundColor Green
    Write-Host "    $outputExe" -ForegroundColor White
    Write-Host "============================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "LƯU Ý: Để UIAccess có tác dụng (cuộn Task Manager không UAC), file exe phải nằm trong Program Files." -ForegroundColor Yellow
    Write-Host ""

    $choice = Read-Host "Bạn có muốn tự động cài đặt/cập nhật file vào C:\Program Files\GestureMouse\ ngay không? (Y/N)"
    if ($choice -match "^[yY]") {
        $destDir = "C:\Program Files\GestureMouse"
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        Copy-Item $outputExe (Join-Path $destDir "GestureMouse.exe") -Force
        Write-Host ""
        Write-Host "[+] Đã cài đặt thành công vào: $destDir\GestureMouse.exe" -ForegroundColor Green
        Write-Host "[+] Ứng dụng đã sẵn sàng chạy với quyền UIAccess!" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "Nhấn phím Enter để đóng cửa sổ..." -ForegroundColor Gray
    Read-Host
} catch {
    Write-Host ""
    Write-Host "[X] ĐÃ CÓ LỖI XẢY RA:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Read-Host "Nhấn phím Enter để đóng cửa sổ..."
    exit 1
}