@echo off
echo ====================================================
echo    MARS DC NOC - BACKUP SCRIPT CALISTIRILIYOR
echo ====================================================
echo.
echo Baslatma Zamani: %date% %time%
echo.

cd /d "%~dp0"

powershell.exe -ExecutionPolicy Bypass -File "BackupScript.ps1" -DebugMode

echo.
echo ====================================================
echo    BACKUP SCRIPT TAMAMLANDI
echo ====================================================
echo Bitis Zamani: %date% %time%
echo.
pause 