@echo off
echo ====================================================
echo   MARS DC NOC - DCP ONLINE FOLDER TRACKER
echo ====================================================
echo.
echo Baslatma Zamani: %date% %time%
echo.

cd /d "%~dp0"

powershell.exe -ExecutionPolicy Bypass -File "DcpOnlineFolderTracker.ps1" -DebugMode

echo.
echo ====================================================
echo   DCP ONLINE FOLDER TRACKER TAMAMLANDI
echo ====================================================
echo Bitis Zamani: %date% %time%
echo.
pause 