# ============================================================================
# GestureMouse - Build & UIAccess Signing Script
# ============================================================================
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8
try { & chcp 65001 | Out-Null } catch {}

# 1. Tu dong kiem tra va nang quyen Administrator neu chua co
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[*] Dang yeu cau quyen Administrator de cai dat chung chi..." -ForegroundColor Yellow
    try {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; & '$PSCommandPath'`"" -Verb RunAs
    } catch {
        Write-Host "[X] Yeu cau quyen Administrator bi tu choi hoac bi huy." -ForegroundColor Red
        Read-Host "Nhan Enter de dong..."
    }
    exit
}

try {
    $ScriptDir = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    Set-Location $ScriptDir

    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host "       GESTURE MOUSE - QUY TRINH BIEN DICH VA KY SO TU DONG (UIAccess)      " -ForegroundColor Cyan
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host ""

    $ahk2Exe = "C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"
    $ahkV2 = "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
    $mainScript = Join-Path $ScriptDir "Main.ahk"
    $customBase = Join-Path $ScriptDir "bin\CustomClass.bin"
    $outputExe = Join-Path $ScriptDir "bin\GestureMouse.exe"
    $signScript = Join-Path $ScriptDir "tools\SignUIAccess.ahk"

    # 2. Kiem tra cac cong cu
    if (-not (Test-Path $ahk2Exe)) {
        throw "Khong tim thay trinh bien dich Ahk2Exe tai: $ahk2Exe. Vui long cai dat AutoHotkey Compiler."
    }
    if (-not (Test-Path $ahkV2)) {
        throw "Khong tim thay AutoHotkey v2 tai: $ahkV2. Can co AutoHotkey v2 de chay bo cong cu ky so."
    }
    if (-not (Test-Path $customBase)) {
        throw "Khong tim thay Base binary tuy bien tai: $customBase."
    }
    if (-not (Test-Path $signScript)) {
        throw "Khong tim thay cong cu ky so tai: $signScript."
    }

    # 3. Tat tien trinh cu neu dang chay de tranh khoa file
    Write-Host "[*] Dang kiem tra va tat tien trinh GestureMouse cu neu dang chay..." -ForegroundColor Gray
    Get-Process "GestureMouse", "GestureMouse2" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Milliseconds 500

    # 4. Kiem tra va dam bao encoding UTF-8 with BOM cho tat ca file .ahk
    Write-Host ""
    Write-Host "[*] Dang kiem tra va dam bao encoding UTF-8 with BOM cho tat ca file .ahk..." -ForegroundColor Cyan
    $ahkFiles = Get-ChildItem -Path $ScriptDir -Recurse -Filter "*.ahk" | Where-Object { $_.FullName -notmatch '\\(\.git|\.history|\.lh)\\' }
    $utf8Bom = New-Object System.Text.UTF8Encoding($true)
    $bomConverted = 0
    foreach ($file in $ahkFiles) {
        $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
        $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
        if (-not $hasBom) {
            $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
            [System.IO.File]::WriteAllText($file.FullName, $content, $utf8Bom)
            Write-Host "    [+] Da ap BOM: $($file.Name)" -ForegroundColor Green
            $bomConverted++
        }
    }
    if ($bomConverted -eq 0) {
        Write-Host "    [V] Tat ca file .ahk deu da o chuan UTF-8 with BOM." -ForegroundColor Gray
    } else {
        Write-Host "    [V] Da cap nhat BOM cho $bomConverted file .ahk!" -ForegroundColor Green
    }

    # 5. Bien dich bang Ahk2Exe
    Write-Host ""
    Write-Host "[1/2] Dang bien dich Main.ahk thanh $outputExe..." -ForegroundColor Yellow
    $proc = Start-Process -FilePath $ahk2Exe -ArgumentList "/in `"$mainScript`" /base `"$customBase`" /out `"$outputExe`"" -Wait -PassThru -NoNewWindow
    if ($proc.ExitCode -ne 0) {
        throw "Bien dich Ahk2Exe that bai voi ma loi $($proc.ExitCode)"
    }
    Write-Host "[+] Bien dich thanh cong: $outputExe" -ForegroundColor Green

    # 6. Kich hoat UIAccess & Ky so
    Write-Host ""
    Write-Host "[2/2] Dang kich hoat UIAccess va ky so tu dong..." -ForegroundColor Yellow
    $procSign = Start-Process -FilePath $ahkV2 -ArgumentList "`"$signScript`" `"$outputExe`"" -Wait -PassThru -NoNewWindow
    if ($procSign.ExitCode -ne 0) {
        throw "Kich hoat UIAccess hoac ky so that bai!"
    }

    Write-Host ""
    Write-Host "============================================================================" -ForegroundColor Green
    Write-Host "[V] THANH CONG: Da tao file thuc thi hoan chinh nhat tai:" -ForegroundColor Green
    Write-Host "    $outputExe" -ForegroundColor White
    Write-Host "============================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "LUU Y: De UIAccess co tac dung (cuon Task Manager khong UAC), file exe phai nam trong Program Files." -ForegroundColor Yellow
    Write-Host ""

    $choice = Read-Host "Ban co muon cai dat/cap nhat file vao C:\Program Files\GestureMouse\ ngay khong? (Y/N)"
    if ($choice -match "^[yY]") {
        $destDir = "C:\Program Files\GestureMouse"
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        $installedExe = Join-Path $destDir "GestureMouse.exe"
        Copy-Item $outputExe $installedExe -Force
        Write-Host ""
        Write-Host "[+] Da cai dat thanh cong vao: $installedExe" -ForegroundColor Green

        # 1. Tao Shortcut trong Start Menu (de tim kiem trong Windows Start de dang)
        try {
            $wshShell = New-Object -ComObject WScript.Shell
            $startMenuDir = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\GestureMouse"
            if (-not (Test-Path $startMenuDir)) {
                New-Item -ItemType Directory -Path $startMenuDir -Force | Out-Null
            }
            $shortcut = $wshShell.CreateShortcut("$startMenuDir\GestureMouse.lnk")
            $shortcut.TargetPath = $installedExe
            $shortcut.WorkingDirectory = $destDir
            $shortcut.Description = "GestureMouse - Ung dung ho tro cu chi chuot"
            $shortcut.Save()

            # Tao shortcut Go cai dat (Uninstall) trong Start Menu
            $uninstShortcut = $wshShell.CreateShortcut("$startMenuDir\Uninstall GestureMouse.lnk")
            $uninstShortcut.TargetPath = $installedExe
            $uninstShortcut.Arguments = "/uninstall"
            $uninstShortcut.WorkingDirectory = $destDir
            $uninstShortcut.Description = "Go cai dat GestureMouse khoi he thong"
            $uninstShortcut.IconLocation = "$env:SystemRoot\System32\shell32.dll,32"
            $uninstShortcut.Save()

            # Tao shortcut Go cai dat (Uninstall) ngay trong thu muc Program Files
            $uninstProg = $wshShell.CreateShortcut("$destDir\Uninstall GestureMouse.lnk")
            $uninstProg.TargetPath = $installedExe
            $uninstProg.Arguments = "/uninstall"
            $uninstProg.WorkingDirectory = $destDir
            $uninstProg.Description = "Go cai dat GestureMouse khoi he thong"
            $uninstProg.IconLocation = "$env:SystemRoot\System32\shell32.dll,32"
            $uninstProg.Save()

            Write-Host "[+] Da them GestureMouse va Shortcut Go cai dat vao Start Menu & Program Files!" -ForegroundColor Green
        } catch {
            Write-Host "[!] Khong the tao shortcut Start Menu: $($_.Exception.Message)" -ForegroundColor Yellow
        }

        # 2. Tùy chọn them vao Startup (Khoi dong cung Windows)
        $startChoice = Read-Host "Ban co muon GestureMouse tu dong khoi dong cung Windows khong? (Y/N)"
        if ($startChoice -match "^[yY]") {
            try {
                $runKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
                Set-ItemProperty -Path $runKey -Name "GestureMouse" -Value "`"$installedExe`"" -Force
                Write-Host "[+] Da them vao danh sach khoi dong cung Windows (Startup)!" -ForegroundColor Green
            } catch {
                Write-Host "[!] Khong the ghi vao Startup: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }

        # 3. Tu dong chay file exe len ngay lap tuc
        Write-Host ""
        Write-Host "[*] Dang khoi chay GestureMouse..." -ForegroundColor Cyan
        Start-Process -FilePath $installedExe
        Write-Host "[+] GestureMouse da duoc khoi chay thanh cong voi dac quyen UIAccess!" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "Nhan phim Enter de dong cua so..." -ForegroundColor Gray
    Read-Host
} catch {
    Write-Host ""
    Write-Host "[X] DA CO LOI XAY RA:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Read-Host "Nhan phim Enter de dong cua so..."
    exit 1
}