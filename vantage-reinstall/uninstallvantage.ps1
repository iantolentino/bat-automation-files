<# ========================================================================
  Uninstall-LenovoVantage-Complete.ps1 (Enhanced Version)
  Purpose : Completely remove ALL Lenovo Vantage versions, services,
            provisioned packages, and EVERY residual file across the system.
            Perfect for a clean, offline reinstall.
  ======================================================================== #>

# region ===== Logging =====
$Global:LogFile = "C:\ProgramData\LenovoVantage_Cleanup.log"
New-Item -ItemType Directory -Force -Path (Split-Path $Global:LogFile) | Out-Null
Start-Transcript -Path $Global:LogFile -Force | Out-Null
function Write-Info($msg){ Write-Host "[*] $msg"; }
function Write-Warn($msg){ Write-Warning "$msg"; }
function Try-Run($scriptBlock, $what) {
  try { & $scriptBlock; Write-Info "$what : OK" }
  catch { Write-Warn "$what : $($_.Exception.Message)" }
}
# endregion

Write-Info "=== Lenovo Vantage CLEAN UNINSTALL starting ==="

# region ===== Stop & disable services =====
$svcNames = @('LenovoVantageService','ImControllerService')
foreach ($svc in $svcNames) {
  $sv = Get-Service -Name $svc -ErrorAction SilentlyContinue
  if ($sv) {
    Try-Run { Stop-Service $svc -Force -ErrorAction Stop } "Stop service $svc"
    Try-Run { Set-Service  $svc -StartupType Disabled }     "Disable service $svc"
  }
}
# endregion

# region ===== Remove provisioned Lenovo UWP (preloaded image) =====
Try-Run {
  Get-AppxProvisionedPackage -Online |
    Where-Object { $_.DisplayName -like "*lenovo*" } |
    Remove-AppxProvisionedPackage -Online -ErrorAction Stop | Out-Null
} "Deprovision Lenovo UWP packages"
# endregion

# region ===== Remove Vantage UWP (ALL users) =====
$uwps = Get-AppxPackage -AllUsers E046963* -ErrorAction SilentlyContinue
foreach ($p in $uwps) {
  Try-Run { Remove-AppxPackage -Package $p.PackageFullName -AllUsers -ErrorAction Stop } "Remove UWP: $($p.Name)"
}
# endregion

# region ===== Remove Commercial Vantage UWP leftovers =====
$otherUWPs = Get-AppxPackage -AllUsers | Where-Object { $_.Name -match "Lenovo.*Vantage|CommercialVantage" }
foreach ($p in $otherUWPs) {
  Try-Run { Remove-AppxPackage -Package $p.PackageFullName -AllUsers -ErrorAction Stop } "Remove UWP (other): $($p.Name)"
}
# endregion

# region ===== Remove Lenovo Vantage Service (MSI/Inno) =====
$uninstallHives = @(
  "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
  "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
$targets = foreach ($h in $uninstallHives) {
  Get-ItemProperty $h -ErrorAction SilentlyContinue |
    Where-Object {
      $_.DisplayName -match "Lenovo Vantage" -or
      $_.DisplayName -match "Commercial Vantage" -or
      $_.DisplayName -match "System Interface Foundation"
    }
}

foreach ($app in $targets) {
  $cmd = $app.UninstallString
  if (-not $cmd) { continue }

  if ($cmd -match "msiexec\.exe") {
    Try-Run { Start-Process "cmd.exe" "/c $cmd /qn /norestart" -Wait -WindowStyle Hidden } "MSI uninstall: $($app.DisplayName)"
  }
  elseif ($cmd -match "unins.*\.exe") {
    Try-Run { Start-Process $cmd "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART" -Wait -WindowStyle Hidden } "Inno uninstall: $($app.DisplayName)"
  }
  else {
    Try-Run { Start-Process "cmd.exe" "/c $cmd" -Wait -WindowStyle Hidden } "Generic uninstall: $($app.DisplayName)"
  }
}
# endregion

# region ===== Official System Interface Foundation uninstall =====
$sifUninstaller = "$env:WINDIR\System32\imcontroller.infinstaller.exe"
if (Test-Path $sifUninstaller) {
  Try-Run { Start-Process $sifUninstaller -ArgumentList "-uninstall" -Wait -WindowStyle Hidden } "Remove System Interface Foundation"
}
# endregion

# ============================================================
#   EXPANDED RESIDUAL CLEANUP (NEW IMPROVED SECTION)
# ============================================================

Write-Info "=== Removing residual files, folders, tasks, registry keys, WMI ==="

# region ===== Remove ALL user‑profile AppData leftovers =====
Get-ChildItem "C:\Users" -Directory | ForEach-Object {
    $user = $_.FullName
    $paths = @(
        "$user\AppData\Local\Packages\E046963F.LenovoCompanion_k1h2ywk1493x8",
        "$user\AppData\Local\Lenovo",
        "$user\AppData\Roaming\Lenovo",
        "$user\AppData\Roaming\Vantage",
        "$user\AppData\Local\Vantage"
    )

    foreach ($p in $paths) {
        if (Test-Path $p) {
            Try-Run { Remove-Item $p -Recurse -Force } "Delete residual user data: $p"
        }
    }
}
# endregion

# region ===== System‑wide folders =====
$dirs = @(
  "$env:PROGRAMDATA\Lenovo",
  "$env:PROGRAMDATA\Lenovo\Vantage",
  "$env:PROGRAMDATA\Lenovo\ImController",
  "$env:PROGRAMFILES\Lenovo\VantageService",
  "$env:PROGRAMFILES\Lenovo",
  "${env:ProgramFiles(x86)}\Lenovo\VantageService",
  "${env:ProgramFiles(x86)}\Lenovo",
  "$env:WINDIR\Lenovo"
)
foreach ($d in $dirs) {
  if (Test-Path $d) { Try-Run { Remove-Item $d -Recurse -Force } "Delete system folder: $d" }
}
# endregion

# region ===== Scheduled Tasks removal (enumerate paths) =====
$taskRoots = @("\Lenovo\", "\Lenovo\Vantage\", "\Lenovo\ImController\")
foreach ($tr in $taskRoots) {
    try {
        $tasks = Get-ScheduledTask -TaskPath $tr -ErrorAction SilentlyContinue
        foreach ($t in $tasks) {
            Try-Run {
                Unregister-ScheduledTask -TaskName $t.TaskName -TaskPath $t.TaskPath -Confirm:$false
            } "Delete scheduled task: $($t.TaskPath)$($t.TaskName)"
        }
    } catch {}
}
# endregion

# region ===== Registry cleanup =====
$regKeys = @(
  "HKLM:\SOFTWARE\Lenovo",
  "HKLM:\SOFTWARE\WOW6432Node\Lenovo",
  "HKCU:\SOFTWARE\Lenovo",
  "HKCU:\SOFTWARE\WOW6432Node\Lenovo"
)
foreach ($rk in $regKeys) {
  if (Test-Path $rk) {
    Try-Run { Remove-Item $rk -Recurse -Force } "Delete registry key: $rk"
  }
}
# endregion

# region ===== WMI cleanup (old Vantage versions leave consumers) =====
Try-Run {
  Get-WmiObject -Namespace "root\subscription" -Class __EventConsumer |
    Where-Object { $_.Name -like "*Lenovo*" } |
    Remove-WmiObject
} "WMI consumers"

Try-Run {
  Get-WmiObject -Namespace "root\subscription" -Class __FilterToConsumerBinding |
    Where-Object { $_.Consumer -like "*Lenovo*" } |
    Remove-WmiObject
} "WMI bindings"

Try-Run {
  Get-WmiObject -Namespace "root\subscription" -Class __EventFilter |
    Where-Object { $_.Name -like "*Lenovo*" } |
    Remove-WmiObject
} "WMI filters"
# endregion

# ============================================================

# region ===== Final =====
Write-Info "=== Lenovo Vantage CLEAN UNINSTALL complete ==="
Write-Info "A reboot is strongly recommended."
Stop-Transcript | Out-Null
# endregion