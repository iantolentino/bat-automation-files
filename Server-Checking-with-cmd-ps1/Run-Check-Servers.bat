@echo off
setlocal
set "SCRIPT=%~dp0Check-Servers.ps1"
if not exist "%SCRIPT%" (
  echo Could not find "%SCRIPT%".
  echo Make sure Check-Servers.ps1 is in the same folder as this BAT.
  echo.
  pause
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
echo.
pause