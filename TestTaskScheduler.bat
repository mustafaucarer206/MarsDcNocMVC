@echo off
:: Simple Task Scheduler Test
echo ========================================== > C:\temp\TaskTest.log
echo Task Scheduler Test - %DATE% %TIME% >> C:\temp\TaskTest.log
echo ========================================== >> C:\temp\TaskTest.log
echo Current User: %USERNAME% >> C:\temp\TaskTest.log
echo Computer: %COMPUTERNAME% >> C:\temp\TaskTest.log
echo Current Directory: %CD% >> C:\temp\TaskTest.log
echo Script Path: %~dp0 >> C:\temp\TaskTest.log
echo Script Full Path: %~f0 >> C:\temp\TaskTest.log
echo PATH Environment: %PATH% >> C:\temp\TaskTest.log
echo ========================================== >> C:\temp\TaskTest.log

:: Test if main script exists
if exist "%~dp0RunCheckDiskCapacity.bat" (
    echo FOUND: RunCheckDiskCapacity.bat >> C:\temp\TaskTest.log
) else (
    echo NOT FOUND: RunCheckDiskCapacity.bat >> C:\temp\TaskTest.log
    echo Script directory contents: >> C:\temp\TaskTest.log
    dir "%~dp0" >> C:\temp\TaskTest.log
)

:: Test if PowerShell script exists
if exist "%~dp0CheckDiskCapacity.ps1" (
    echo FOUND: CheckDiskCapacity.ps1 >> C:\temp\TaskTest.log
) else (
    echo NOT FOUND: CheckDiskCapacity.ps1 >> C:\temp\TaskTest.log
)

echo Test completed at %DATE% %TIME% >> C:\temp\TaskTest.log
echo Check C:\temp\TaskTest.log for results 