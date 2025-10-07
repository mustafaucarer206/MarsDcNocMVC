@echo off
:: Alternative CMD Test for Task Scheduler
C:\Windows\System32\cmd.exe /c "echo Task Scheduler CMD Test - %DATE% %TIME% > C:\temp\CMDTest.log"
C:\Windows\System32\cmd.exe /c "echo Current User: %USERNAME% >> C:\temp\CMDTest.log"
C:\Windows\System32\cmd.exe /c "echo Computer: %COMPUTERNAME% >> C:\temp\CMDTest.log"
C:\Windows\System32\cmd.exe /c "echo Working Directory: %CD% >> C:\temp\CMDTest.log"
C:\Windows\System32\cmd.exe /c "echo Script Path: %~dp0 >> C:\temp\CMDTest.log"

:: Test file existence
if exist "C:\Users\mustafa.ucarer\Desktop\MarsDcNocMVC\CheckDiskCapacity.ps1" (
    C:\Windows\System32\cmd.exe /c "echo FOUND: CheckDiskCapacity.ps1 >> C:\temp\CMDTest.log"
) else (
    C:\Windows\System32\cmd.exe /c "echo NOT FOUND: CheckDiskCapacity.ps1 >> C:\temp\CMDTest.log"
)

C:\Windows\System32\cmd.exe /c "echo Test completed >> C:\temp\CMDTest.log" 