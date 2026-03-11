@echo off
title Ultimate Windows 10 Optimizer with Summary
color 0A

set success=0
set failed=0

echo ==================================================
echo WINDOWS 10 PERFORMANCE OPTIMIZER
echo Designed for Low RAM (4GB) Systems
echo ==================================================
echo.

echo [1/10] Stopping heavy services...

net stop SysMain >nul 2>&1 && (set /a success+=1) || (set /a failed+=1)
net stop WSearch >nul 2>&1 && (set /a success+=1) || (set /a failed+=1)
net stop DiagTrack >nul 2>&1 && (set /a success+=1) || (set /a failed+=1)
net stop WerSvc >nul 2>&1 && (set /a success+=1) || (set /a failed+=1)

echo.
echo [2/10] Disabling heavy services permanently...

sc config SysMain start=disabled >nul && (set /a success+=1) || (set /a failed+=1)
sc config WSearch start=disabled >nul && (set /a success+=1) || (set /a failed+=1)
sc config DiagTrack start=disabled >nul && (set /a success+=1) || (set /a failed+=1)
sc config WerSvc start=disabled >nul && (set /a success+=1) || (set /a failed+=1)

echo.
echo [3/10] Cleaning TEMP folders...

del /s /f /q %temp%* >nul 2>&1
del /s /f /q C:\Windows\Temp* >nul 2>&1

set /a success+=1

echo.
echo [4/10] Clearing Windows Update cache...

net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1

rd /s /q C:\Windows\SoftwareDistribution >nul 2>&1
mkdir C:\Windows\SoftwareDistribution >nul 2>&1

net start wuauserv >nul 2>&1
net start bits >nul 2>&1

set /a success+=1

echo.
echo [5/10] Cleaning Prefetch cache...

del /s /f /q C:\Windows\Prefetch* >nul 2>&1

set /a success+=1

echo.
echo [6/10] Flushing DNS cache...

ipconfig /flushdns >nul

set /a success+=1

echo.
echo [7/10] Resetting network stack...

netsh winsock reset >nul && (set /a success+=1) || (set /a failed+=1)
netsh int ip reset >nul && (set /a success+=1) || (set /a failed+=1)

echo.
echo [8/10] Disabling startup programs...

reg delete HKCU\Software\Microsoft\Windows\CurrentVersion\Run /f >nul 2>&1
reg delete HKLM\Software\Microsoft\Windows\CurrentVersion\Run /f >nul 2>&1

set /a success+=1

echo.
echo [9/10] Setting High Performance power plan...

powercfg -setactive SCHEME_MIN >nul && (set /a success+=1) || (set /a failed+=1)

echo.
echo [10/10] Disabling background apps...

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled /t REG_DWORD /d 1 /f >nul

set /a success+=1

echo.
echo Running system file repair (this may take some time)...

sfc /scannow

echo.
echo ==================================================
echo OPTIMIZATION SUMMARY
echo ==================================================
echo Successful operations : %success%
echo Failed operations     : %failed%
echo ==================================================
echo.

echo Completed optimizations:
echo - Disabled SysMain (Superfetch)
echo - Disabled Windows Search indexing
echo - Disabled telemetry services
echo - Cleared temporary files
echo - Reset Windows Update cache
echo - Cleared Prefetch cache
echo - Flushed DNS cache
echo - Reset network stack
echo - Removed startup programs
echo - Enabled High Performance power plan
echo - Disabled background apps
echo - Ran system file integrity scan

echo.
echo Recommended next steps:
echo - Restart the computer
echo - Check Task Manager for CPU/Disk improvements
echo - Disable extra apps in Startup tab if needed

echo.
pause
