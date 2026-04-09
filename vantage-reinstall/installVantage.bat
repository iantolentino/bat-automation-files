@echo off
setlocal enableextensions enabledelayedexpansion

:: ================================
:: FORCE ADMIN ELEVATION
:: ================================
>nul 2>&1 "%SYSTEMROOT%\system32\fltmc.exe"
if not "%errorlevel%"=="0" (
    echo Requesting administrative privileges...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: ================================
:: MOVE TO THIS FOLDER
:: ================================
cd /d "%~dp0"
echo Working folder: %CD%

:: ================================
:: CHECK INSTALLER
:: ================================
if not exist "VantageInstaller.exe" (
    echo ERROR: VantageInstaller.exe NOT FOUND in %CD%
    echo Make sure the file is named EXACTLY: VantageInstaller.exe
    pause
    exit /b 1
)

echo Found installer: VantageInstaller.exe
echo Starting installation...

:: ================================
:: RUN LENOVO ENTERPRISE INSTALLER
:: ================================
start /wait "" ".\VantageInstaller.exe" Install -Vantage -SuHelper
set R=%ERRORLEVEL%

echo Installer exit code: %R%

if not "%R%"=="0" (
    echo Installation FAILED with exit code %R%
    echo Check that:
    echo  - You are running as Administrator
    echo  - No previous Vantage components are locked
    echo  - Try reboot then run again
    pause
    exit /b %R%
)

echo =========================================
echo   Lenovo Commercial Vantage INSTALLED
echo   A reboot is recommended.
echo =========================================
pause
exit /b 0