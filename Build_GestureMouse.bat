@echo off
chcp 65001 >nul
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\Build.ps1"
if %errorlevel% neq 0 (
    echo.
    echo [!] Cua so dong lenh tam dung de ban doc thong bao loi tren.
    pause
)
