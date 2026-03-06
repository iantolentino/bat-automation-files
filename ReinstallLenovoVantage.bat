
@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Lenovo Vantage - Cleanup and Install (Admin)

REM ====== Hard-coded Desktop path (files live inside this folder) ======
set "BASE=%USERPROFILE%\Desktop\LenovoVantage_4.27.32.0\Discovery_4.27.32.0"
set "BUNDLE=%BASE%\33880b99e2af47f89fd9c3419314052e.appxbundle"
set "EXE=%BASE%\System-Interface-Foundation-Update-64.exe"

echo.
echo ===========================================================
echo   Lenovo Vantage - Cleanup and Install
echo   Using path:
echo   %BASE%
echo ===========================================================
echo.

REM --------- Auto-elevate to Administrator if needed ----------
>nul 2>&1 net session
if %errorlevel% neq 0 (
  echo [*] Requesting administrative privileges...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
echo [*] Running with administrative privileges.

REM --------- Build the PowerShell script in %TEMP% ----------
set "PSSCRIPT=%TEMP%\__lv_cleanup_install.ps1"

> "%PSSCRIPT%" (
  echo $ErrorActionPreference = 'Stop'
  echo function Write-Section([string]$msg) { Write-Host "`n=== $msg ===" -ForegroundColor Cyan }
  echo function Write-Ok([string]$msg) { Write-Host $msg -ForegroundColor Green }
  echo function Write-Warn([string]$msg) { Write-Warning $msg }
  echo function Write-Info([string]$msg) { Write-Host $msg -ForegroundColor Yellow }

  echo Write-Section "Execution Policy (Process scope)"
  echo $effective = Get-ExecutionPolicy
  echo Write-Host ("Current effective ExecutionPolicy: {0}" -f $effective)
  echo if ($effective -eq 'Restricted') {
  echo   Write-Info "Setting ExecutionPolicy Bypass for this process..."
  echo   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
  echo } else {
  echo   Write-Ok "No change needed."
  echo }

  echo Write-Section "Remove Lenovo Vantage - Current User"
  echo try {
  echo   Get-AppxPackage -Name "*LenovoVantage*" ^| Remove-AppxPackage -ErrorAction SilentlyContinue
  echo   Write-Ok "Removed for current user (or not present)."
  echo } catch { Write-Warn ("Current user removal issue: {0}" -f $_.Exception.Message) }

  echo Write-Section "Remove Lenovo Vantage - All Existing Users"
  echo try {
  echo   Get-AppxPackage -AllUsers -Name "*LenovoVantage*" ^| Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
  echo   Write-Ok "Removed for all users (or not present)."
  echo } catch { Write-Warn ("All users removal issue: {0}" -f $_.Exception.Message) }

  echo Write-Section "Remove Lenovo Vantage - Provisioned (for new users)"
  echo try {
  echo   Get-AppxProvisionedPackage -Online ^| Where-Object { $_.PackageName -like "*LenovoVantage*" } ^| Remove-AppxProvisionedPackage -Online
  echo   Write-Ok "Removed provisioned package (or not present)."
  echo } catch { Write-Warn ("Provisioned removal issue: {0}" -f $_.Exception.Message) }

  echo Write-Section "Install Appxbundle"
  echo $bundle = [IO.Path]::GetFullPath("%BUNDLE%")
  echo if (Test-Path -LiteralPath $bundle) {
  echo   Write-Info ("Installing: {0}" -f $bundle)
  echo   try {
  echo     Add-AppxPackage -Path $bundle
  echo     Write-Ok "Appxbundle installed."
  echo   } catch { Write-Warn ("Appxbundle installation failed: {0}" -f $_.Exception.Message) }
  echo } else {
  echo   Write-Warn ("Appxbundle not found at: {0}" -f $bundle)
  echo }

  echo Write-Section "Run System-Interface-Foundation-Update-64.exe"
  echo $exe = [IO.Path]::GetFullPath("%EXE%")
  echo if (Test-Path -LiteralPath $exe) {
  echo   Write-Info ("Launching: {0}" -f $exe)
  echo   try {
  echo     Start-Process -FilePath $exe -Wait
  echo     Write-Ok "Executable finished."
  echo   } catch { Write-Warn ("Executable failed: {0}" -f $_.Exception.Message) }
  echo } else {
  echo   Write-Warn ("Executable not found at: {0}" -f $exe)
  echo }

  echo Write-Host "`n=== Done ===" -ForegroundColor Green
)

REM --------- Run the PowerShell script with bypass ----------
powershell -NoProfile -ExecutionPolicy Bypass -File "%PSSCRIPT%"
set "RC=%ERRORLEVEL%"

REM --------- Cleanup ----------
del /q "%PSSCRIPT%" >nul 2>&1

echo.
if "%RC%"=="0" (
  echo [*] Completed. Review messages above for any warnings.
) else (
  echo [!] PowerShell reported exit code %RC%. Check messages above for details.
)
echo.
pause
endlocal
