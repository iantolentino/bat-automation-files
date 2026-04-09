# ============================
# SAFE VIEW-ONLY CONNECTIVITY CHECK (IMPROVED)
# Uses .NET Ping + TcpClient (no Test-NetConnection / no telnet)
# Output: Console + Dark HTML + CSV
# Dark HTML: CMD-like font, only black/white/red/green/yellow, 2-column layout
# Opens HTML after scan and keeps console open
# ============================

# ----------------------------
# Configuration
# ----------------------------
$Servers = @(
  '10.129.8.51','10.129.8.52','10.129.8.54','10.129.8.55','10.129.8.56',
  '10.129.8.31','10.129.8.27','10.129.8.26','10.129.8.25','10.129.8.23','10.129.8.43',
  '10.129.8.20','10.129.8.19','10.129.8.16','10.129.8.10','10.129.8.100'
)

# Add/remove ports as needed:
$Ports = @(3389,445,80,443,22)

# Timeouts (ms)
$PingTimeout = 1000
$PortTimeout = 1200

# Output folder (script folder). Fallback to current dir if $PSScriptRoot is empty.
$outDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$stamp  = Get-Date -Format 'yyyyMMdd_HHmmss'
$ReportPath = Join-Path $outDir "Connectivity_Report_$stamp.html"
$CSVPath    = Join-Path $outDir "Connectivity_Report_$stamp.csv"


# ----------------------------
# Helper Functions
# ----------------------------
function Test-Ping {
    param([string]$Target, [int]$Timeout = 1000)
    try {
        $p = New-Object System.Net.NetworkInformation.Ping
        $reply = $p.Send($Target, $Timeout)

        return @{
            Success       = ($reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success)
            RoundtripTime = if ($reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) { $reply.RoundtripTime } else { $null }
            Status        = $reply.Status.ToString()
        }
    } catch {
        return @{
            Success       = $false
            RoundtripTime = $null
            Status        = "Error: $($_.Exception.Message)"
        }
    }
}

function Test-Port {
    param([string]$Target, [int]$Port, [int]$Timeout = 1200)

    $start = Get-Date
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $iar = $client.BeginConnect($Target, $Port, $null, $null)

        if (-not $iar.AsyncWaitHandle.WaitOne($Timeout)) {
            $client.Close()
            return @{
                Success      = $false
                ResponseTime = $null
                Error        = "Timeout"
            }
        }

        $client.EndConnect($iar)
        $client.Close()

        $rt = (Get-Date) - $start
        return @{
            Success      = $true
            ResponseTime = [math]::Round($rt.TotalMilliseconds, 2)
            Error        = $null
        }
    } catch {
        return @{
            Success      = $false
            ResponseTime = $null
            Error        = $_.Exception.Message
        }
    }
}

function New-HTMLReport {
    param(
        [array]$Results,
        [int[]]$Ports,
        [string]$OutputPath,
        [datetime]$StartTime,
        [datetime]$EndTime
    )

    # HTML-escape to prevent broken pages / missing servers
    function HtmlEscape([string]$s) {
        if ($null -eq $s) { return "" }
        return [System.Security.SecurityElement]::Escape($s)
    }

    $duration = New-TimeSpan -Start $StartTime -End $EndTime

    # Ensure all results included
    $Results = @($Results) | Where-Object { $_ -ne $null }

    $totalServers = $Results.Count
    $workingCount = ($Results | Where-Object { $_.Status -eq 'WORKING' }).Count
    $partialCount = ($Results | Where-Object { $_.Status -eq 'REACHABLE_NO_PING' }).Count
    $failedCount  = ($Results | Where-Object { $_.Status -eq 'NOT WORKING' }).Count

    $portsText = ($Ports -join ", ")

    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>Server Connectivity Report</title>
<style>
  :root{
    --bg: #000000;   /* black */
    --fg: #ffffff;   /* white */
    --green: #00ff00;
    --yellow:#ffff00;
    --red: #ff0000;
    --line: rgba(255,255,255,0.18);
  }

  * { box-sizing: border-box; }
  html, body { height: 100%; }
  body{
    margin: 0;
    background: var(--bg);
    color: var(--fg);
    font-family: "Cascadia Mono", "Consolas", "Lucida Console", "Courier New", monospace;
    font-size: 12px;
    line-height: 1.25;
  }

  .wrap{
    padding: 14px 16px;
    max-width: 1600px;
    margin: 0 auto;
  }

  .title{
    display:flex;
    justify-content: space-between;
    align-items: baseline;
    gap: 12px;
    border-bottom: 1px solid var(--line);
    padding-bottom: 10px;
    margin-bottom: 10px;
  }

  .title h1{
    margin: 0;
    font-size: 18px;
    letter-spacing: .5px;
  }

  .btns{ display:flex; gap: 8px; flex-wrap: wrap; }
  .btn{
    border: 1px solid var(--line);
    background: transparent;
    color: var(--fg);
    padding: 6px 10px;
    border-radius: 6px;
    cursor: pointer;
    font-family: inherit;
    font-weight: 700;
  }
  .btn:hover{ border-color: rgba(255,255,255,0.45); }

  .meta{
    display:grid;
    grid-template-columns: 1fr 1fr;
    gap: 6px 12px;
    padding: 10px 12px;
    border: 1px solid var(--line);
    border-radius: 10px;
    margin-bottom: 10px;
  }

  .stats{
    display:grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 8px;
    margin-bottom: 12px;
  }

  .stat{
    border: 1px solid var(--line);
    border-radius: 10px;
    padding: 10px 12px;
  }
  .stat .n{
    display:block;
    font-size: 20px;
    font-weight: 900;
    margin-bottom: 2px;
  }
  .stat.ok .n { color: var(--green); }
  .stat.warn .n { color: var(--yellow); }
  .stat.bad .n { color: var(--red); }

  /* ✅ 2-column server list */
  .grid{
    display:grid;
    grid-template-columns: 1fr 1fr 1fr;
    gap: 8px;
  }

  .card{
    border: 1px solid var(--line);
    border-radius: 10px;
    padding: 10px 12px;
    position: relative;
    min-height: 72px;
    overflow: hidden;
  }

  .bar{
    position:absolute;
    left: 0; top: 0; bottom: 0;
    width: 6px;
    background: var(--line);
  }
  .bar.ok{ background: var(--green); }
  .bar.warn{ background: var(--yellow); }
  .bar.bad{ background: var(--red); }

  .row{
    display:flex;
    justify-content: space-between;
    align-items: center;
    gap: 10px;
    margin-bottom: 6px;
  }

  .server{
    font-size: 14px;
    font-weight: 900;
    letter-spacing: .3px;
  }

  .badge{
    display:inline-block;
    padding: 3px 8px;
    border-radius: 999px;
    font-weight: 900;
    border: 1px solid var(--line);
    background: transparent;
    white-space: nowrap;
  }
  .badge.ok{ border-color: rgba(0,255,0,0.8); color: var(--green); }
  .badge.warn{ border-color: rgba(255,255,0,0.8); color: var(--yellow); }
  .badge.bad{ border-color: rgba(255,0,0,0.8); color: var(--red); }

  .k{ color: rgba(255,255,255,0.85); font-weight: 700; }
  .v{ color: var(--fg); font-weight: 800; }

  .ping-ok{ color: var(--green); font-weight: 900; }
  .ping-bad{ color: var(--red); font-weight: 900; }

  .ports{
    margin-top: 6px;
    display:flex;
    flex-wrap: wrap;
    gap: 6px;
  }

  .port{
    border: 1px solid var(--line);
    border-radius: 8px;
    padding: 2px 7px;
    font-weight: 900;
    background: transparent;
  }
  .port.open{ border-color: rgba(0,255,0,0.8); color: var(--green); }
  .port.closed{ border-color: rgba(255,255,255,0.25); color: var(--fg); }

  .note{
    margin-top: 10px;
    color: rgba(255,255,255,0.75);
    border-top: 1px solid var(--line);
    padding-top: 10px;
    font-size: 11px;
  }

  @media (max-width: 1100px){
    .stats{ grid-template-columns: repeat(2, 1fr); }
    .grid{ grid-template-columns: 1fr; }
    .meta{ grid-template-columns: 1fr; }
  }

  @media print{
    body{ background:#fff; color:#000; }
    .btns{ display:none; }
    .card, .stat, .meta{ border: 1px solid #000; }
    .badge, .port{ border: 1px solid #000; }
  }
</style>
</head>
<body>
<div class="wrap">

  <div class="title">
    <h1>SERVER CONNECTIVITY REPORT</h1>
    <div class="btns">
      <button class="btn" onclick="window.print()">PRINT / SAVE PDF</button>
      <button class="btn" onclick="window.scrollTo({top:0,behavior:'smooth'})">TOP</button>
    </div>
  </div>

  <div class="meta">
    <div><b>SCAN START:</b> $(HtmlEscape($StartTime.ToString("yyyy-MM-dd HH:mm:ss")))</div>
    <div><b>SCAN END:</b> $(HtmlEscape($EndTime.ToString("yyyy-MM-dd HH:mm:ss")))</div>
    <div><b>DURATION:</b> $(HtmlEscape(("{0:hh\:mm\:ss}" -f $duration)))</div>
    <div><b>PORTS TESTED:</b> $(HtmlEscape($portsText))</div>
  </div>

  <div class="grid">
"@

    foreach ($r in ($Results | Sort-Object Server)) {
        $server = HtmlEscape([string]$r.Server)
        $status = [string]$r.Status
        if ([string]::IsNullOrWhiteSpace($status)) { $status = "UNKNOWN" }
        $statusEsc = HtmlEscape($status)

        $cls = switch ($status) {
            'WORKING'           { 'ok' }
            'REACHABLE_NO_PING' { 'warn' }
            'NOT WORKING'       { 'bad' }
            default             { 'bad' }
        }

        $pingText = if ($r.PingSuccess) {
            if ($null -ne $r.PingTime) { "SUCCESS ($($r.PingTime)ms)" } else { "SUCCESS" }
        } else {
            "FAILED"
        }

        $pingStatus = if (-not $r.PingSuccess) { HtmlEscape([string]$r.PingStatus) } else { "" }

        $avg = if ($null -ne $r.ResponseTime) { HtmlEscape("$($r.ResponseTime)ms") } else { "N/A" }

        $portBadges = ""
        foreach ($p in $Ports) {
            $pr = $null
            if ($r.PortResults -and $r.PortResults.ContainsKey($p.ToString())) {
                $pr = $r.PortResults[$p.ToString()]
            }

            if ($pr -and $pr.Success) {
                $rt = if ($null -ne $pr.ResponseTime) { "$($pr.ResponseTime)ms" } else { "" }
                $portBadges += "<span class='port open' title='OPEN $rt'>$p</span>"
            } else {
                $err = if ($pr -and $pr.Error) { HtmlEscape([string]$pr.Error) } else { "Closed/Filtered" }
                $portBadges += "<span class='port closed' title='$err'>$p</span>"
            }
        }

        $detailLine = ""
        if (-not $r.PingSuccess -and $pingStatus) {
            $detailLine = "<div><span class='k'>DETAIL:</span> <span class='v'>$pingStatus</span></div>"
        }

        $html += @"
    <div class="card">
      <div class="bar $cls"></div>

      <div class="row">
        <div class="server">$server</div>
        <div class="badge $cls">$statusEsc</div>
      </div>

      <div class="row">
        <div><span class="k">PING:</span>
          <span class="$(if($r.PingSuccess){'ping-ok'}else{'ping-bad'})">$(HtmlEscape($pingText))</span>
        </div>
        <div><span class="k">AVG:</span> <span class="v">$avg</span></div>
      </div>

      $detailLine

      <div class="ports">
        $portBadges
      </div>
    </div>
"@
    }

    $html += @"
  </div>

</div>
</body>
</html>
"@

    $html | Out-File -FilePath $OutputPath -Encoding UTF8
}


# ----------------------------
# Main Execution
# ----------------------------
Clear-Host
$startTime = Get-Date
$sw = [System.Diagnostics.Stopwatch]::StartNew()

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Server Connectivity Check (SAFE / VIEW-ONLY)" -ForegroundColor White
Write-Host ("  Scan Start: {0}" -f $startTime.ToString("yyyy-MM-dd HH:mm:ss")) -ForegroundColor Yellow
Write-Host ("  Ports tested: {0}" -f ($Ports -join ', ')) -ForegroundColor Yellow
Write-Host ("  Total servers: {0}" -f $Servers.Count) -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$results = @()

for ($i = 0; $i -lt $Servers.Count; $i++) {
    $s = $Servers[$i]

    $percent = [math]::Round((($i) / $Servers.Count) * 100, 1)
    Write-Progress -Activity "Testing Servers" -Status "$i of $($Servers.Count) completed" -PercentComplete $percent

    Write-Host "[TARGET] $s" -ForegroundColor White
    Write-Host "  [1/2] Ping testing..." -ForegroundColor Gray

    $ping = Test-Ping -Target $s -Timeout $PingTimeout
    if ($ping.Success) {
        Write-Host ("      Ping: SUCCESS ({0}ms)" -f $ping.RoundtripTime) -ForegroundColor Green
    } else {
        Write-Host ("      Ping: FAILED ({0})" -f $ping.Status) -ForegroundColor Red
    }

    Write-Host "  [2/2] TCP port tests (.NET TcpClient)..." -ForegroundColor Gray

    $portResults = @{}
    $openPorts = New-Object System.Collections.Generic.List[int]
    $sumRt = 0.0
    $rtCount = 0

    foreach ($p in $Ports) {
        $pr = Test-Port -Target $s -Port $p -Timeout $PortTimeout
        $portResults[$p.ToString()] = $pr

        if ($pr.Success) {
            [void]$openPorts.Add($p)
            Write-Host ("      > Port {0}: OPEN ({1}ms)" -f $p, $pr.ResponseTime) -ForegroundColor Green
            if ($pr.ResponseTime -ne $null) { $sumRt += $pr.ResponseTime; $rtCount++ }
        } else {
            Write-Host ("      > Port {0}: CLOSED/FILTERED ({1})" -f $p, $pr.Error) -ForegroundColor DarkYellow
        }
    }

    $avgRt = if ($rtCount -gt 0) { [math]::Round($sumRt / $rtCount, 2) } else { $null }

    # Status logic (same as your old one)
    $status = if ($ping.Success) { 'WORKING' } elseif ($openPorts.Count -gt 0) { 'REACHABLE_NO_PING' } else { 'NOT WORKING' }

    $color = switch ($status) {
        'WORKING'           { 'Green' }
        'REACHABLE_NO_PING' { 'Yellow' }
        default             { 'Red' }
    }

    Write-Host ("  => Status: {0}" -f $status) -ForegroundColor $color
    Write-Host ""

    $results += [PSCustomObject]@{
        Timestamp    = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Server       = $s
        PingSuccess  = $ping.Success
        PingTime     = $ping.RoundtripTime
        PingStatus   = $ping.Status
        OpenPorts    = $openPorts.ToArray()
        PortResults  = $portResults
        Status       = $status
        ResponseTime = $avgRt
    }
}

Write-Progress -Activity "Testing Servers" -Completed

$sw.Stop()
$endTime = Get-Date
$duration = New-TimeSpan -Start $startTime -End $endTime

# Sort results
$results = $results | Sort-Object Server

# Summary counts
$workingCount = ($results | Where-Object { $_.Status -eq 'WORKING' }).Count
$partialCount = ($results | Where-Object { $_.Status -eq 'REACHABLE_NO_PING' }).Count
$failedCount  = ($results | Where-Object { $_.Status -eq 'NOT WORKING' }).Count

# Console Summary
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "                        SUMMARY" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ("Scan End:   {0}" -f $endTime.ToString("yyyy-MM-dd HH:mm:ss")) -ForegroundColor Yellow
Write-Host ("Duration:   {0}" -f ("{0:hh\:mm\:ss}" -f $duration)) -ForegroundColor Yellow
Write-Host ""
Write-Host ("✓ WORKING: {0}" -f $workingCount) -ForegroundColor Green
Write-Host ("⚠ PARTIAL: {0}" -f $partialCount) -ForegroundColor Yellow
Write-Host ("✗ FAILED:  {0}" -f $failedCount)  -ForegroundColor Red
Write-Host ("TOTAL:     {0}" -f $results.Count) -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# Export CSV (flat)
$results | ForEach-Object {
    [PSCustomObject]@{
        Timestamp       = $_.Timestamp
        Server          = $_.Server
        Status          = $_.Status
        PingSuccess     = $_.PingSuccess
        PingTime        = if ($_.PingTime -ne $null) { "$($_.PingTime)ms" } else { "N/A" }
        OpenPorts       = ($_.OpenPorts -join ';')
        AvgResponseTime = if ($_.ResponseTime -ne $null) { "$($_.ResponseTime)ms" } else { "N/A" }
    }
} | Export-Csv -Path $CSVPath -NoTypeInformation -Encoding UTF8

# Generate HTML
New-HTMLReport -Results $results -Ports $Ports -OutputPath $ReportPath -StartTime $startTime -EndTime $endTime

Write-Host "[SUCCESS] Reports generated:" -ForegroundColor Green
Write-Host "  • HTML: $ReportPath" -ForegroundColor Cyan
Write-Host "  • CSV : $CSVPath"    -ForegroundColor Cyan

# Auto-open HTML
Start-Process $ReportPath

# Keep window open
Read-Host "`nPress Enter to close" | Out-Null