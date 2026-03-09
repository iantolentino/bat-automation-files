# ============================
# SAFE VIEW-ONLY CONNECTIVITY CHECK
# Uses .NET Ping + TcpClient (no Test-NetConnection / no telnet)
# Summary format: "<timestamp> - <server> - WORKING|NOT WORKING|REACHABLE_NO_PING"
# ============================

$Servers = @(
  '10.129.8.51','10.129.8.52','10.129.8.54','10.129.8.55','10.129.8.56',
  '10.129.8.31','10.129.8.27','10.129.8.26','10.129.8.25','10.129.8.23', '10.129.8.43',
  '10.129.8.20','10.129.8.19','10.129.8.16','10.129.8.10','10.129.8.100'
)
# Add/remove ports as needed (e.g., add 443, 1433):
$Ports = @(3389,445,80)

# Configuration
$PingTimeout = 1000      # milliseconds
$PortTimeout = 1200      # milliseconds
$MaxParallel = 5         # Maximum parallel checks (to avoid overwhelming network)

# ---- Helpers (no external cmdlets required) ----
function Test-Ping {
    param([string]$Target, [int]$Timeout=1000)
    try {
        $p = New-Object System.Net.NetworkInformation.Ping
        $reply = $p.Send($Target, $Timeout)
        return ($reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success)
    } catch {
        return $false
    }
}

function Test-Port {
    param([string]$Target, [int]$Port, [int]$Timeout=1200)
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $iar = $client.BeginConnect($Target, $Port, $null, $null)
        if (-not $iar.AsyncWaitHandle.WaitOne($Timeout)) {
            $client.Close()
            return $false
        }
        $client.EndConnect($iar)
        $client.Close()
        return $true
    } catch {
        return $false
    }
}

# Function to format timestamp
function Get-FormattedTimestamp {
    return (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}

# Function to export results to file
function Export-Results {
    param(
        [string[]]$SummaryLines,
        [string]$LogPath
    )
    
    $header = @"
==========================================================
CONNECTIVITY CHECK REPORT
Generated: $(Get-FormattedTimestamp)
Ports tested: $($Ports -join ', ')
Total servers: $($Servers.Count)
==========================================================

"@
    
    $header | Out-File -FilePath $LogPath -Encoding UTF8
    $SummaryLines | ForEach-Object { $_ | Out-File -FilePath $LogPath -Encoding UTF8 -Append }
    
    Write-Host "`n[INFO] Results exported to: $LogPath" -ForegroundColor Cyan
}

# Initialize collections
$summaryLines = New-Object System.Collections.Generic.List[string]
$failedServers = New-Object System.Collections.Generic.List[string]
$workingServers = New-Object System.Collections.Generic.List[string]
$partialServers = New-Object System.Collections.Generic.List[string]

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Server Connectivity Check (SAFE / VIEW-ONLY)" -ForegroundColor White
Write-Host ("  Start Time: {0}" -f (Get-FormattedTimestamp)) -ForegroundColor Yellow
Write-Host "  Ports tested: $($Ports -join ', ')" -ForegroundColor Yellow
Write-Host "  Total servers: $($Servers.Count)" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$progress = 0
$total = $Servers.Count

foreach ($s in $Servers) {
    $progress++
    $percentDone = [math]::Round(($progress / $total) * 100, 1)
    
    Write-Host "──────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "[$percentDone%] [TARGET] $s" -ForegroundColor Magenta
    Write-Host "  [1/2] Ping testing..."
    
    $pingOk = Test-Ping -Target $s -Timeout $PingTimeout
    if ($pingOk) { 
        Write-Host "      ✓ Ping: SUCCESS" -ForegroundColor Green
    } else { 
        Write-Host "      ✗ Ping: FAILED (no ICMP reply)" -ForegroundColor Red
    }

    Write-Host "  [2/2] TCP port tests (.NET TcpClient)..."
    $openPorts = @()
    $closedPorts = @()
    
    foreach ($p in $Ports) {
        if (Test-Port -Target $s -Port $p -Timeout $PortTimeout) {
            $openPorts += $p
            Write-Host ("      ✓ Port {0}: OPEN" -f $p) -ForegroundColor Green
        } else {
            $closedPorts += $p
            Write-Host ("      ✗ Port {0}: CLOSED or FILTERED" -f $p) -ForegroundColor Red
        }
    }

    # Determine status
    $openAny = $openPorts.Count -gt 0
    $status = if ($pingOk) { 
        $workingServers.Add($s)
        'WORKING' 
    } elseif ($openAny) { 
        $partialServers.Add($s)
        'REACHABLE_NO_PING' 
    } else { 
        $failedServers.Add($s)
        'NOT WORKING' 
    }

    # Color-coded status output
    $statusColor = switch ($status) {
        'WORKING' { 'Green' }
        'REACHABLE_NO_PING' { 'Yellow' }
        'NOT WORKING' { 'Red' }
    }
    
    Write-Host "  => Status: $status" -ForegroundColor $statusColor
    if ($openPorts.Count -gt 0) {
        Write-Host "     Open ports: $($openPorts -join ', ')" -ForegroundColor Cyan
    }
    Write-Host ""

    # Add to summary with timestamp
    [void]$summaryLines.Add("$(Get-FormattedTimestamp) - $s - $status")
}

# Generate summary report
Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "                        SUMMARY" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Generated: $(Get-FormattedTimestamp)" -ForegroundColor Yellow
Write-Host ""

$summaryLines | ForEach-Object { 
    $parts = $_ -split ' - '
    $statusColor = switch ($parts[2]) {
        'WORKING' { 'Green' }
        'REACHABLE_NO_PING' { 'Yellow' }
        'NOT WORKING' { 'Red' }
    }
    Write-Host "  $_" -ForegroundColor $statusColor
}

Write-Host ""
Write-Host "──────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "Statistics:" -ForegroundColor White
Write-Host "  ✓ WORKING: $($workingServers.Count)" -ForegroundColor Green
Write-Host "  ⚠ REACHABLE_NO_PING: $($partialServers.Count)" -ForegroundColor Yellow
Write-Host "  ✗ NOT WORKING: $($failedServers.Count)" -ForegroundColor Red
Write-Host "  Total: $total" -ForegroundColor White
Write-Host "──────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "==========================================================" -ForegroundColor Cyan

# Offer to export results
Write-Host ""
$exportChoice = Read-Host "Export results to file? (Y/N, default: N)"
if ($exportChoice -eq 'Y' -or $exportChoice -eq 'y') {
    $logPath = "Connectivity_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    Export-Results -SummaryLines $summaryLines -LogPath $logPath
}

Write-Host ""
Read-Host "Press Enter to close" | Out-Null
