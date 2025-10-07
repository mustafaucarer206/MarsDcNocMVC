@echo off
echo ================================================
echo           Check Server Status Script
echo ================================================

cd /d "%~dp0"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "CheckServerStatus.ps1" %*

if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] Script failed with error code: %ERRORLEVEL%
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo [SUCCESS] Server status check completed successfully!
pause 