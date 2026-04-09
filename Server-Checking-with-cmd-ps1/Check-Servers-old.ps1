# ============================
# SAFE VIEW-ONLY CONNECTIVITY CHECK
# Uses .NET Ping + TcpClient (no Test-NetConnection / no telnet)
# Summary format: "<server> - WORKING|NOT WORKING|REACHABLE_NO_PING"
# ============================

$Servers = @(
  '10.129.8.51','10.129.8.52','10.129.8.54','10.129.8.55','10.129.8.56',
  '10.129.8.31','10.129.8.27','10.129.8.26','10.129.8.25','10.129.8.23', '10.129.8.43',
  '10.129.8.20','10.129.8.19','10.129.8.16','10.129.8.10','10.129.8.100'
)
# Add/remove ports as needed (e.g., add 443, 1433):
$Ports = @(3389,445,80)

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

$summaryLines = New-Object System.Collections.Generic.List[string]

Write-Host "=========================================================="
Write-Host "  Server Connectivity Check (SAFE / VIEW-ONLY)"
Write-Host ("  Time: {0}" -f (Get-Date))
Write-Host "  Ports tested: $($Ports -join ', ')"
Write-Host "==========================================================`n"

foreach ($s in $Servers) {
    Write-Host "[TARGET] $s"
    Write-Host "  [1/2] Ping testing..."
    $pingOk = Test-Ping -Target $s
    if ($pingOk) { Write-Host "      Ping: SUCCESS" } else { Write-Host "      Ping: FAILED (no ICMP reply)" }

    Write-Host "  [2/2] TCP port tests (.NET TcpClient)..."
    $openAny = $false
    foreach ($p in $Ports) {
        if (Test-Port -Target $s -Port $p) {
            $openAny = $true
            Write-Host ("      > Port {0}: OPEN" -f $p)
        } else {
            Write-Host ("      > Port {0}: CLOSED or FILTERED" -f $p)
        }
    }

    # WORKING if ping success; REACHABLE_NO_PING if any port open; else NOT WORKING
    $status = if ($pingOk) { 'WORKING' } elseif ($openAny) { 'REACHABLE_NO_PING' } else { 'NOT WORKING' }

    Write-Host "  => Status: $status`n"

    # Use string interpolation instead of -f to avoid formatting exceptions
    [void]$summaryLines.Add("$($s) - $($status)")
}

Write-Host "`n=========================================================="
Write-Host "                        SUMMARY"
Write-Host "=========================================================="
$summaryLines | ForEach-Object { Write-Host "  $_" }
Write-Host "=========================================================="
Read-Host "Press Enter to close" | Out-Null