@echo off

:: Create log file for Task Scheduler debugging
set LOGFILE="%~dp0TaskScheduler_Debug.log"
echo ================================================ > %LOGFILE%
echo Task Scheduler Debug Log - %DATE% %TIME% >> %LOGFILE%
echo ================================================ >> %LOGFILE%
echo User Context: %USERNAME% >> %LOGFILE%
echo Computer Name: %COMPUTERNAME% >> %LOGFILE%
echo Current Directory: %CD% >> %LOGFILE%
echo Script Path: %~dp0 >> %LOGFILE%
echo Command Line: %0 %* >> %LOGFILE%
echo ================================================ >> %LOGFILE%

echo ================================================
echo         Check Disk Capacity Script
echo ================================================

:: Force working directory to script location
cd /d "%~dp0"
echo Working Directory: %CD%
echo Script Location: %~dp0
echo Working Directory: %CD% >> %LOGFILE%

:: Use full path to PowerShell and script for Task Scheduler compatibility
echo Calling PowerShell with full paths...
echo PowerShell Command: %SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0CheckDiskCapacity.ps1" >> %LOGFILE%

%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0CheckDiskCapacity.ps1" %* >> %LOGFILE% 2>&1

set EXITCODE=%ERRORLEVEL%
echo PowerShell Exit Code: %EXITCODE% >> %LOGFILE%

if %EXITCODE% neq 0 (
    echo.
    echo [ERROR] Script failed with error code: %EXITCODE%
    echo [ERROR] Script failed with error code: %EXITCODE% >> %LOGFILE%
    echo Task completed with ERROR at %DATE% %TIME% >> %LOGFILE%
    exit /b %EXITCODE%
)

echo.
echo [SUCCESS] Disk capacity check completed successfully!
echo [SUCCESS] Disk capacity check completed successfully! >> %LOGFILE%
echo Task completed SUCCESSFULLY at %DATE% %TIME% >> %LOGFILE% 