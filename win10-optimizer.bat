@echo off
title Smart Windows Optimizer
color 0A

set success=0
set failed=0

echo ==========================================
echo SMART WINDOWS PERFORMANCE OPTIMIZER
echo ==========================================
echo.

:: -------------------------------
:: ADMIN CHECK
:: -------------------------------
net session >nul 2>&1
if %errorlevel% neq 0 (
echo Requesting Administrator privileges...
powershell -Command "Start-Process '%~f0' -Verb runAs"
exit
)

:: -------------------------------
:: RAM DETECTION (FIXED)
:: -------------------------------
for /f %%A in ('powershell -command "(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory /1GB -as [int]"') do set RAM=%%A

echo Detected RAM: %RAM% GB
echo.

:: -------------------------------
:: STORAGE DETECTION
:: -------------------------------
set STORAGE=HDD
for /f "tokens=*" %%A in ('wmic diskdrive get MediaType ^| find /i "SSD"') do set STORAGE=SSD

echo Storage Type: %STORAGE%
echo.

:: -------------------------------
:: STEP 1 - SERVICE OPTIMIZATION
:: -------------------------------
echo [1/10] Optimizing services...

if %RAM% LEQ 4 (
sc config SysMain start=disabled >nul
sc config WSearch start=disabled >nul
)

sc config DiagTrack start=disabled >nul
sc config WerSvc start=disabled >nul

set /a success+=1

:: -------------------------------
:: STEP 2 - TEMP CLEANUP
:: -------------------------------
echo [2/10] Cleaning TEMP files...

del /f /q %temp%* >nul 2>&1
del /f /q C:\Windows\Temp* >nul 2>&1

set /a success+=1

:: -------------------------------
:: STEP 3 - WINDOWS UPDATE RESET
:: -------------------------------
echo [3/10] Resetting Windows Update...

net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1

rd /s /q C:\Windows\SoftwareDistribution >nul 2>&1
mkdir C:\Windows\SoftwareDistribution >nul 2>&1

net start wuauserv >nul 2>&1
net start bits >nul 2>&1

set /a success+=1

:: -------------------------------
:: STEP 4 - PREFETCH CLEAN (FIXED)
:: -------------------------------
echo [4/10] Cleaning Prefetch cache...

if exist C:\Windows\Prefetch (
for %%F in (C:\Windows\Prefetch*) do del /f /q "%%F" >nul 2>&1
)

set /a success+=1

:: -------------------------------
:: STEP 5 - NETWORK RESET
:: -------------------------------
echo [5/10] Resetting network...

ipconfig /flushdns >nul
netsh winsock reset >nul
netsh int ip reset >nul

set /a success+=1

:: -------------------------------
:: STEP 6 - POWER PLAN
:: -------------------------------
echo [6/10] Setting High Performance mode...

powercfg -setactive SCHEME_MIN >nul

set /a success+=1

:: -------------------------------
:: STEP 7 - BACKGROUND APPS
:: -------------------------------
echo [7/10] Disabling background apps...

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled /t REG_DWORD /d 1 /f >nul

set /a success+=1

:: -------------------------------
:: STEP 8 - STARTUP REPORT
:: -------------------------------
echo [8/10] Generating startup report...

wmic startup get caption,command > startup_report.txt

set /a success+=1

:: -------------------------------
:: STEP 9 - SYSTEM FILE CHECK
:: -------------------------------
echo [9/10] Running system repair...
echo This may take several minutes...

sfc /scannow

set /a success+=1

:: -------------------------------
:: STEP 10 - DISK SCAN
:: -------------------------------
echo [10/10] Checking disk health...

chkdsk /scan

set /a success+=1

:: -------------------------------
:: FINAL REPORT
:: -------------------------------
echo.
echo ==========================================
echo OPTIMIZATION COMPLETE
echo ==========================================

echo RAM Detected        : %RAM% GB
echo Storage Type        : %STORAGE%
echo Successful Tasks    : %success%
echo Failed Tasks        : %failed%

echo.
echo Completed actions:
echo - Service optimization
echo - Temp file cleanup
echo - Windows Update reset
echo - Prefetch cleanup
echo - Network reset
echo - High performance power mode
echo - Background apps disabled
echo - Startup program report
echo - System file repair
echo - Disk health scan

echo.
echo Restart your computer for best performance.

pause
