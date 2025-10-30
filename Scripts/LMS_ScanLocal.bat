@echo off
REM ================================================
REM   LMS Local Content Scanner
REM   Her LMS sunucusunda ayri calistirilmalidir
REM ================================================

echo.
echo ================================================
echo    LMS ICERIK TARAMA BASLADI
echo ================================================
echo.

cd /d "%~dp0"

REM PowerShell scriptini calistir
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0LMS_GetActiveContent_Local.ps1"

if %ERRORLEVEL% neq 0 (
    echo.
    echo [HATA] Script basarisiz oldu!
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ================================================
echo    TARAMA TAMAMLANDI!
echo ================================================
echo.
echo JSON dosyasi olusturuldu: active_content_%COMPUTERNAME%.json
echo.
echo Simdi bu dosyayi NOC sunucusuna kopyalayin:
echo   - Network share: \\NOC_SERVER\LMSScans\
echo   - Veya email ile gonderin
echo.
pause

