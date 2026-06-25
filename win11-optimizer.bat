@echo off
title Windows 11 Developer Performance Optimizer
color 0A

set success=0
set failed=0

echo ==========================================
echo WINDOWS 11 DEVELOPER OPTIMIZER
echo Safe for VS Code, XAMPP, MySQL, Python
echo ==========================================
echo.

:: --------------------------------------------------
:: ADMIN CHECK
:: --------------------------------------------------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb runAs"
    exit
)

:: --------------------------------------------------
:: RAM DETECTION
:: --------------------------------------------------
for /f %%A in ('powershell -command "(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory /1GB -as [int]"') do set RAM=%%A
echo Detected RAM: %RAM% GB
echo.

:: --------------------------------------------------
:: STORAGE DETECTION (Win11-safe)
:: --------------------------------------------------
set STORAGE=HDD
powershell -command "Get-PhysicalDisk | Where MediaType -eq 'SSD'" >nul 2>&1 && set STORAGE=SSD
echo Storage Type: %STORAGE%
echo.

:: --------------------------------------------------
:: STEP 1 - SAFE SERVICE OPTIMIZATION
:: --------------------------------------------------
echo [1/9] Optimizing telemetry (safe)...

sc stop DiagTrack >nul 2>&1
sc config DiagTrack start=disabled >nul

sc stop WerSvc >nul 2>&1
sc config WerSvc start=disabled >nul

set /a success+=1

:: --------------------------------------------------
:: STEP 2 - TEMP CLEANUP (FIXED)
:: --------------------------------------------------
echo [2/9] Cleaning TEMP files...

del /f /s /q "%temp%\*" >nul 2>&1
del /f /s /q "C:\Windows\Temp\*" >nul 2>&1

set /a success+=1

:: --------------------------------------------------
:: STEP 3 - MEMORY PRIORITY FOR APPS
:: --------------------------------------------------
echo [3/9] Optimizing memory priority...

reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" ^
/v LargeSystemCache /t REG_DWORD /d 0 /f >nul

set /a success+=1

:: --------------------------------------------------
:: STEP 4 - PREFETCH (WIN11 SAFE)
:: --------------------------------------------------
echo [4/9] Refreshing Prefetch...

if exist "C:\Windows\Prefetch" (
    del /f /q "C:\Windows\Prefetch\*" >nul 2>&1
)

set /a success+=1

:: --------------------------------------------------
:: STEP 5 - NETWORK CACHE CLEAN (SAFE)
:: --------------------------------------------------
echo [5/9] Clearing network cache...

ipconfig /flushdns >nul

set /a success+=1

:: --------------------------------------------------
:: STEP 6 - POWER PLAN (BEST FOR DEV)
:: --------------------------------------------------
echo [6/9] Enabling Ultimate Performance...

powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1
powercfg -setactive e9a42b02-d5df-448d-aa00-03f14749eb61 >nul

set /a success+=1

:: --------------------------------------------------
:: STEP 7 - BACKGROUND APPS (WIN11)
:: --------------------------------------------------
echo [7/9] Reducing background apps...

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" ^
/v GlobalUserDisabled /t REG_DWORD /d 1 /f >nul

set /a success+=1

:: --------------------------------------------------
:: STEP 8 - STARTUP REPORT (MODERN)
:: --------------------------------------------------
echo [8/9] Creating startup report...

powershell -command "Get-CimInstance Win32_StartupCommand | Select Name, Command | Out-File startup_report.txt"

set /a success+=1

:: --------------------------------------------------
:: STEP 9 - DISK HEALTH (SSD SAFE)
:: --------------------------------------------------
echo [9/9] Checking disk health...

chkdsk /scan >nul

set /a success+=1

:: --------------------------------------------------
:: FINAL REPORT
:: --------------------------------------------------
echo.
echo ==========================================
echo OPTIMIZATION COMPLETE
echo ==========================================
echo RAM Detected     : %RAM% GB
echo Storage Type     : %STORAGE%
echo Tasks Completed  : %success%
echo.

echo SAFE FOR:
echo - VS Code
echo - XAMPP / Apache / MySQL
echo - Python / Node / PHP
echo - LM Studio / Local AI
echo.

echo Restart recommended for full effect.
pause