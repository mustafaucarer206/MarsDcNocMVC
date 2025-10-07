@echo off
:: Create Location Based Users - Task Scheduler Version
:: Bu dosya Task Scheduler ile otomatik çalıştırılmak için tasarlanmıştır

:: Çalışma dizinini script'in bulunduğu dizin olarak ayarla
cd /d "%~dp0"

:: PowerShell execution policy geçici olarak bypass yap ve script'i çalıştır
powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0CreateLocationBasedUsers.ps1"

:: Exit code'u Windows'a aktar
exit /b %ERRORLEVEL% 