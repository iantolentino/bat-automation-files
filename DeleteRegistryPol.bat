
@echo off
setlocal EnableExtensions
title Delete Registry.pol and Run gpupdate

REM Path to Registry.pol
set "POL_FILE=%SystemRoot%\System32\GroupPolicy\Machine\Registry.pol"

REM Delete Registry.pol if exists
if exist "%POL_FILE%" (
  echo Deleting Registry.pol...
  del /f /q "%POL_FILE%"
) else (
  echo Registry.pol not found. Nothing to delete.
)

REM Open folder for user confirmation
start "" explorer.exe "%SystemRoot%\System32\GroupPolicy\Machine"

REM Check if file is deleted
if exist "%POL_FILE%" (
  echo Registry.pol still exists. Aborting gpupdate.
  pause
  exit /b
) else (
  echo Registry.pol deleted successfully.
)

REM Run gpupdate /force
gpupdate /force
echo gpupdate completed.
pause
endlocal
