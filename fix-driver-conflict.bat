@echo off
title Windows Update + Driver Conflict Fix Tool
color 0A

echo ==========================================
echo   WINDOWS UPDATE + DRIVER FULL REPAIR
echo ==========================================
echo.

:: Check admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Run this as Administrator!
    pause
    exit
)

:: =========================
:: WINDOWS UPDATE FIX
:: =========================
echo [1/10] Stopping services...
net stop wuauserv /y
net stop bits /y
net stop cryptsvc /y
net stop trustedinstaller /y

echo [2/10] Clearing update cache...
del /f /s /q C:\Windows\WinSxS\pending.xml 2>nul
rd /s /q C:\Windows\SoftwareDistribution 2>nul
rd /s /q C:\Windows\System32\catroot2 2>nul

mkdir C:\Windows\SoftwareDistribution
mkdir C:\Windows\System32\catroot2

echo [3/10] Restarting services...
net start trustedinstaller
net start cryptsvc
net start bits
net start wuauserv

echo [4/10] Cleaning component store...
DISM /Online /Cleanup-Image /StartComponentCleanup

echo [5/10] Repairing Windows image...
DISM /Online /Cleanup-Image /RestoreHealth

echo [6/10] Running System File Checker...
sfc /scannow

echo [7/10] Resetting update policies...
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /f 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /f 2>nul

echo Re-registering update components...
regsvr32 /s wuaueng.dll
regsvr32 /s wuapi.dll
regsvr32 /s wucltux.dll
regsvr32 /s wups.dll
regsvr32 /s wups2.dll
regsvr32 /s wuwebv.dll

:: =========================
:: DRIVER CONFLICT FIX
:: =========================

echo [8/10] Disabling automatic driver updates...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" ^
/v ExcludeWUDriversInQualityUpdate /t REG_DWORD /d 1 /f

echo [9/10] Cleaning old drivers (Driver Store)...
pnputil /enum-drivers > drivers.txt

echo Removing old/unused drivers...
for /f "tokens=1,2 delims=:" %%a in ('pnputil /enum-drivers ^| findstr "Published Name"') do (
    echo Checking %%b
)

echo [10/10] Setting clean boot (minimal services)...
bcdedit /set {current} safeboot minimal >nul 2>&1

echo.
echo ==========================================
echo   DONE!
echo ==========================================
echo NEXT STEPS:
echo 1. RESTART PC (it will boot into SAFE MODE)
echo 2. Install Windows Update
echo 3. Run this command AFTER update:
echo    bcdedit /deletevalue {current} safeboot
echo 4. Restart again to normal mode
echo ==========================================
pause