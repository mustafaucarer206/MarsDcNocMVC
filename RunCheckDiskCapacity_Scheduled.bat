@echo off
:: Check Disk Capacity - Task Scheduler Version
:: Bu dosya Task Scheduler ile otomatik çalıştırılmak için tasarlanmıştır

:: Çalışma dizinini script'in bulunduğu dizin olarak ayarla
cd /d "%~dp0"

:: Log dosyası oluştur (Task Scheduler debugging için)
set LOG_FILE="%~dp0CheckDiskCapacity_TaskScheduler.log"

echo ================================================ >> %LOG_FILE%
echo Task started at: %DATE% %TIME% >> %LOG_FILE%
echo Working Directory: %CD% >> %LOG_FILE%
echo User Context: %USERNAME% >> %LOG_FILE%
echo ================================================ >> %LOG_FILE%

:: PowerShell script'i çalıştır
powershell.exe -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File "%~dp0CheckDiskCapacity.ps1" >> %LOG_FILE% 2>&1

:: Exit code'u logla ve Windows'a aktar
set EXITCODE=%ERRORLEVEL%
echo Exit Code: %EXITCODE% >> %LOG_FILE%
echo Task ended at: %DATE% %TIME% >> %LOG_FILE%
echo ================================================ >> %LOG_FILE%

exit /b %EXITCODE% 