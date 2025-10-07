@echo off
title DCP Online Folder Tracker
echo Starting DCP Online Folder Tracker...
echo.

:: PowerShell script'i çalıştır
powershell -ExecutionPolicy Bypass -File "%~dp0DcpOnlineFolderTracker.ps1"

:: Exit code'u al
set EXITCODE=%ERRORLEVEL%

echo.
if %EXITCODE%==0 (
    echo ✅ Script completed successfully!
) else (
    echo ❌ Script completed with errors! Exit code: %EXITCODE%
)

echo.
echo Press any key to exit...
pause >nul 