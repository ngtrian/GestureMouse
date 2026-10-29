@echo off
chcp 65001 >nul
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8; & '%~dp0tools\Build.ps1' }"
if %errorlevel% neq 0 (
    echo.
    echo [!] Cua so dong lenh tam dung de ban doc thong bao tren.
    pause
)
