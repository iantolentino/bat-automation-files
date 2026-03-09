# ============================
# SAFE VIEW-ONLY CONNECTIVITY CHECK
# Uses .NET Ping + TcpClient with Parallel Processing
# Output: Console + HTML Report
# ============================

# Configuration
$Servers = @(
  '10.129.8.51','10.129.8.52','10.129.8.54','10.129.8.55','10.129.8.56',
  '10.129.8.31','10.129.8.27','10.129.8.26','10.129.8.25','10.129.8.23', '10.129.8.43',
  '10.129.8.20','10.129.8.19','10.129.8.16','10.129.8.10','10.129.8.100'
)
# Add/remove ports as needed (e.g., add 443, 1433):
$Ports = @(3389,445,80,443,22)

# Performance Settings
$PingTimeout = 1000          # milliseconds
$PortTimeout = 1200          # milliseconds
$MaxParallel = 10            # Maximum parallel threads
$ThrottleLimit = 20          # Runspace pool throttle limit

# Output Settings
$ReportPath = "Connectivity_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
$CSVPath = "Connectivity_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"

# ---- Helper Functions ----
function Test-Ping {
    param([string]$Target, [int]$Timeout=1000)
    try {
        $p = New-Object System.Net.NetworkInformation.Ping
        $reply = $p.Send($Target, $Timeout)
        return @{
            Success = ($reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success)
            RoundtripTime = if ($reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) { $reply.RoundtripTime } else { $null }
            Status = $reply.Status.ToString()
        }
    } catch {
        return @{
            Success = $false
            RoundtripTime = $null
            Status = "Error: $_"
        }
    }
}

function Test-Port {
    param([string]$Target, [int]$Port, [int]$Timeout=1200)
    $startTime = Get-Date
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $iar = $client.BeginConnect($Target, $Port, $null, $null)
        if (-not $iar.AsyncWaitHandle.WaitOne($Timeout)) {
            $client.Close()
            return @{
                Success = $false
                ResponseTime = $null
                Error = "Timeout"
            }
        }
        $client.EndConnect($iar)
        $client.Close()
        $responseTime = (Get-Date) - $startTime
        return @{
            Success = $true
            ResponseTime = [math]::Round($responseTime.TotalMilliseconds, 2)
            Error = $null
        }
    } catch {
        return @{
            Success = $false
            ResponseTime = $null
            Error = $_.Exception.Message
        }
    }
}

function Test-Server {
    param([string]$Server, [int[]]$Ports, [int]$PingTimeout, [int]$PortTimeout)
    
    $result = [PSCustomObject]@{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Server = $Server
        PingSuccess = $false
        PingTime = $null
        PingStatus = ""
        OpenPorts = @()
        PortResults = @{}
        Status = ""
        ResponseTime = $null
    }
    
    # Test Ping
    $pingResult = Test-Ping -Target $Server -Timeout $PingTimeout
    $result.PingSuccess = $pingResult.Success
    $result.PingTime = $pingResult.RoundtripTime
    $result.PingStatus = $pingResult.Status
    
    # Test Ports in parallel for this server
    $portTasks = @()
    foreach ($port in $Ports) {
        $portTasks += [PSCustomObject]@{
            Port = $port
            Task = { Test-Port -Target $Server -Port $port -Timeout $PortTimeout }.GetNewClosure()
        }
    }
    
    # Execute port tests
    $openPorts = @()
    $totalResponseTime = 0
    $portCount = 0
    
    foreach ($portTask in $portTasks) {
        $portResult = & $portTask.Task
        $result.PortResults[$portTask.Port.ToString()] = $portResult
        
        if ($portResult.Success) {
            $openPorts += $portTask.Port
            if ($portResult.ResponseTime) {
                $totalResponseTime += $portResult.ResponseTime
                $portCount++
            }
        }
    }
    
    $result.OpenPorts = $openPorts
    
    # Calculate average response time for open ports
    if ($portCount -gt 0) {
        $result.ResponseTime = [math]::Round($totalResponseTime / $portCount, 2)
    }
    
    # Determine overall status
    $result.Status = if ($result.PingSuccess) { 
        'WORKING' 
    } elseif ($openPorts.Count -gt 0) { 
        'REACHABLE_NO_PING' 
    } else { 
        'NOT WORKING' 
    }
    
    return $result
}

function New-HTMLReport {
    param(
        [array]$Results,
        [string]$OutputPath
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $totalServers = $Results.Count
    $workingCount = ($Results | Where-Object { $_.Status -eq 'WORKING' }).Count
    $partialCount = ($Results | Where-Object { $_.Status -eq 'REACHABLE_NO_PING' }).Count
    $failedCount = ($Results | Where-Object { $_.Status -eq 'NOT WORKING' }).Count
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Server Connectivity Report</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
            color: #333;
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background-color: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #2c3e50;
            border-bottom: 3px solid #3498db;
            padding-bottom: 10px;
            margin-top: 0;
        }
        .header-info {
            background-color: #ecf0f1;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .stats-container {
            display: flex;
            justify-content: space-between;
            margin-bottom: 20px;
        }
        .stat-box {
            flex: 1;
            margin: 0 10px;
            padding: 20px;
            border-radius: 5px;
            text-align: center;
            color: white;
            font-weight: bold;
        }
        .stat-box.working { background-color: #27ae60; }
        .stat-box.partial { background-color: #f39c12; }
        .stat-box.failed { background-color: #e74c3c; }
        .stat-box.total { background-color: #3498db; }
        .stat-number {
            font-size: 32px;
            display: block;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        th {
            background-color: #3498db;
            color: white;
            padding: 12px;
            text-align: left;
            cursor: pointer;
        }
        th:hover {
            background-color: #2980b9;
        }
        tr {
            border-bottom: 1px solid #ddd;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        td {
            padding: 12px;
            vertical-align: top;
        }
        .status-badge {
            display: inline-block;
            padding: 5px 10px;
            border-radius: 3px;
            color: white;
            font-weight: bold;
            font-size: 12px;
        }
        .status-working { background-color: #27ae60; }
        .status-partial { background-color: #f39c12; }
        .status-failed { background-color: #e74c3c; }
        .port-badge {
            display: inline-block;
            background-color: #34495e;
            color: white;
            padding: 3px 8px;
            border-radius: 3px;
            margin: 2px;
            font-size: 11px;
        }
        .port-open {
            background-color: #27ae60;
        }
        .port-closed {
            background-color: #7f8c8d;
        }
        .ping-success {
            color: #27ae60;
            font-weight: bold;
        }
        .ping-failed {
            color: #e74c3c;
        }
        .details-toggle {
            background-color: #ecf0f1;
            border: none;
            padding: 5px 10px;
            border-radius: 3px;
            cursor: pointer;
            font-size: 12px;
        }
        .details-toggle:hover {
            background-color: #bdc3c7;
        }
        .port-details {
            display: none;
            margin-top: 10px;
            padding: 10px;
            background-color: #f9f9f9;
            border-left: 3px solid #3498db;
        }
        .footer {
            margin-top: 30px;
            text-align: center;
            color: #7f8c8d;
            font-size: 12px;
        }
        .filter-buttons {
            margin-bottom: 15px;
        }
        .filter-btn {
            padding: 8px 15px;
            margin-right: 5px;
            border: none;
            border-radius: 3px;
            cursor: pointer;
            background-color: #ecf0f1;
        }
        .filter-btn.active {
            background-color: #3498db;
            color: white;
        }
        .search-box {
            padding: 8px;
            margin-bottom: 15px;
            width: 300px;
            border: 1px solid #ddd;
            border-radius: 3px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Server Connectivity Report</h1>
        
        <div class="header-info">
            <strong>Generated:</strong> $timestamp<br>
            <strong>Ports Tested:</strong> $($Ports -join ', ')<br>
            <strong>Total Servers:</strong> $totalServers<br>
            <strong>Scan Duration:</strong> Parallel processing with max $MaxParallel threads
        </div>
        
        <div class="stats-container">
            <div class="stat-box working">
                <span class="stat-number">$workingCount</span>
                WORKING
            </div>
            <div class="stat-box partial">
                <span class="stat-number">$partialCount</span>
                REACHABLE NO PING
            </div>
            <div class="stat-box failed">
                <span class="stat-number">$failedCount</span>
                NOT WORKING
            </div>
            <div class="stat-box total">
                <span class="stat-number">$totalServers</span>
                TOTAL
            </div>
        </div>
        
        <div class="filter-buttons">
            <button class="filter-btn active" onclick="filterTable('all')">All</button>
            <button class="filter-btn" onclick="filterTable('WORKING')">Working</button>
            <button class="filter-btn" onclick="filterTable('REACHABLE_NO_PING')">Partial</button>
            <button class="filter-btn" onclick="filterTable('NOT WORKING')">Failed</button>
            <input type="text" class="search-box" placeholder="Search servers..." onkeyup="searchTable()">
        </div>
        
        <table id="resultsTable">
            <thead>
                <tr>
                    <th onclick="sortTable(0)">Timestamp</th>
                    <th onclick="sortTable(1)">Server</th>
                    <th onclick="sortTable(2)">Ping</th>
                    <th onclick="sortTable(3)">Open Ports</th>
                    <th onclick="sortTable(4)">Status</th>
                    <th>Details</th>
                </tr>
            </thead>
            <tbody>
"@
    
    foreach ($result in $Results) {
        $statusClass = switch ($result.Status) {
            'WORKING' { 'working' }
            'REACHABLE_NO_PING' { 'partial' }
            'NOT WORKING' { 'failed' }
        }
        
        $pingDisplay = if ($result.PingSuccess) {
            "<span class='ping-success'>✓ SUCCESS ($($result.PingTime)ms)</span>"
        } else {
            "<span class='ping-failed'>✗ FAILED</span><br><small>$($result.PingStatus)</small>"
        }
        
        $portBadges = ""
        foreach ($port in $Ports) {
            $portResult = $result.PortResults[$port.ToString()]
            $portClass = if ($portResult.Success) { "port-open" } else { "port-closed" }
            $title = if ($portResult.Success) { 
                "Open - Response: $($portResult.ResponseTime)ms" 
            } else { 
                "Closed/Filtered - $($portResult.Error)" 
            }
            $portBadges += "<span class='port-badge $portClass' title='$title'>$port</span> "
        }
        
        $detailsContent = ""
        foreach ($port in $Ports) {
            $portResult = $result.PortResults[$port.ToString()]
            $detailsContent += "<div><strong>Port $port</strong>: "
            if ($portResult.Success) {
                $detailsContent += "OPEN (Response: $($portResult.ResponseTime)ms)"
            } else {
                $detailsContent += "CLOSED/FILTERED - $($portResult.Error)"
            }
            $detailsContent += "</div>"
        }
        
        $html += @"
                <tr data-status="$($result.Status)">
                    <td>$($result.Timestamp)</td>
                    <td>$($result.Server)</td>
                    <td>$pingDisplay</td>
                    <td>$portBadges</td>
                    <td><span class="status-badge status-$statusClass">$($result.Status)</span></td>
                    <td>
                        <button class="details-toggle" onclick="toggleDetails(this)">Show Details</button>
                        <div class="port-details">
                            $detailsContent
                        </div>
                    </td>
                </tr>
"@
    }
    
    $html += @"
            </tbody>
        </table>
        
        <div class="footer">
            Report generated by Safe Connectivity Check Tool | PowerShell Runspace Parallel Processing
        </div>
    </div>
    
    <script>
        function toggleDetails(button) {
            var details = button.nextElementSibling;
            if (details.style.display === "none" || details.style.display === "") {
                details.style.display = "block";
                button.textContent = "Hide Details";
            } else {
                details.style.display = "none";
                button.textContent = "Show Details";
            }
        }
        
        function filterTable(status) {
            var rows = document.querySelectorAll("#resultsTable tbody tr");
            var buttons = document.querySelectorAll(".filter-btn");
            
            buttons.forEach(function(btn) {
                btn.classList.remove("active");
            });
            event.target.classList.add("active");
            
            rows.forEach(function(row) {
                if (status === "all" || row.getAttribute("data-status") === status) {
                    row.style.display = "";
                } else {
                    row.style.display = "none";
                }
            });
        }
        
        function searchTable() {
            var input = document.querySelector(".search-box");
            var filter = input.value.toUpperCase();
            var rows = document.querySelectorAll("#resultsTable tbody tr");
            
            rows.forEach(function(row) {
                var serverCell = row.cells[1];
                if (serverCell) {
                    var textValue = serverCell.textContent || serverCell.innerText;
                    if (textValue.toUpperCase().indexOf(filter) > -1) {
                        row.style.display = "";
                    } else {
                        row.style.display = "none";
                    }
                }
            });
        }
        
        function sortTable(columnIndex) {
            var table = document.getElementById("resultsTable");
            var tbody = table.tBodies[0];
            var rows = Array.from(tbody.rows);
            var ascending = table.querySelectorAll("th")[columnIndex].getAttribute("data-sort") !== "asc";
            
            rows.sort(function(a, b) {
                var aValue = a.cells[columnIndex].textContent.trim();
                var bValue = b.cells[columnIndex].textContent.trim();
                
                if (!isNaN(parseFloat(aValue)) && !isNaN(parseFloat(bValue))) {
                    return ascending ? parseFloat(aValue) - parseFloat(bValue) : parseFloat(bValue) - parseFloat(aValue);
                }
                
                if (aValue < bValue) return ascending ? -1 : 1;
                if (aValue > bValue) return ascending ? 1 : -1;
                return 0;
            });
            
            rows.forEach(function(row) {
                tbody.appendChild(row);
            });
            
            var headers = table.querySelectorAll("th");
            headers.forEach(function(header) {
                header.removeAttribute("data-sort");
            });
            headers[columnIndex].setAttribute("data-sort", ascending ? "asc" : "desc");
        }
    </script>
</body>
</html>
"@
    
    $html | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "[INFO] HTML report generated: $OutputPath" -ForegroundColor Green
}

function Export-CSVReport {
    param(
        [array]$Results,
        [string]$OutputPath
    )
    
    $csvData = @()
    foreach ($result in $Results) {
        $row = [PSCustomObject]@{
            Timestamp = $result.Timestamp
            Server = $result.Server
            Status = $result.Status
            PingSuccess = $result.PingSuccess
            PingTime = if ($result.PingTime) { "$($result.PingTime)ms" } else { "N/A" }
            OpenPorts = ($result.OpenPorts -join ';')
            AvgResponseTime = if ($result.ResponseTime) { "$($result.ResponseTime)ms" } else { "N/A" }
        }
        $csvData += $row
    }
    
    $csvData | Export-Csv -Path $OutputPath -NoTypeInformation
    Write-Host "[INFO] CSV report generated: $OutputPath" -ForegroundColor Green
}

# ---- Main Execution ----
Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Server Connectivity Check (SAFE / VIEW-ONLY)" -ForegroundColor White
Write-Host "  WITH PARALLEL PROCESSING" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Start Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
Write-Host "Ports tested: $($Ports -join ', ')" -ForegroundColor Yellow
Write-Host "Total servers: $($Servers.Count)" -ForegroundColor Yellow
Write-Host "Max parallel threads: $MaxParallel" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# Create runspace pool
$runspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxParallel)
$runspacePool.Open()
$jobs = @()

# Create progress counter
$syncHash = [hashtable]::Synchronized(@{})
$syncHash.Count = 0
$syncHash.Total = $Servers.Count
$syncHash.Results = @()

# Start parallel processing
foreach ($server in $Servers) {
    $powershell = [powershell]::Create()
    $powershell.RunspacePool = $runspacePool
    
    [void]$powershell.AddScript({
        param($s, $p, $pingTimeout, $portTimeout, $sync)
        
        $result = Test-Server -Server $s -Ports $p -PingTimeout $pingTimeout -PortTimeout $portTimeout
        
        # Update progress
        $sync.Count++
        $percentDone = [math]::Round(($sync.Count / $sync.Total) * 100, 1)
        
        # Add to results
        $sync.Results += $result
        
        # Return for job collection
        return $result
    }).AddParameters($server, $Ports, $PingTimeout, $PortTimeout, $syncHash)
    
    $jobs += @{
        PS = $powershell
        Async = $powershell.BeginInvoke()
        Server = $server
    }
}

# Monitor progress
while ($syncHash.Count -lt $syncHash.Total) {
    $percentDone = [math]::Round(($syncHash.Count / $syncHash.Total) * 100, 1)
    Write-Progress -Activity "Testing Servers" -Status "$($syncHash.Count) of $($syncHash.Total) completed" -PercentComplete $percentDone
    Start-Sleep -Milliseconds 200
}

Write-Progress -Activity "Testing Servers" -Completed

# Collect results
$results = @()
foreach ($job in $jobs) {
    try {
        $result = $job.PS.EndInvoke($job.Async)
        $results += $result
        
        # Display real-time result
        $statusColor = switch ($result.Status) {
            'WORKING' { 'Green' }
            'REACHABLE_NO_PING' { 'Yellow' }
            'NOT WORKING' { 'Red' }
        }
        
        Write-Host "[$($result.Timestamp)] $($result.Server) - " -NoNewline
        Write-Host "$($result.Status)" -ForegroundColor $statusColor
        if ($result.OpenPorts.Count -gt 0) {
            Write-Host "  Open ports: $($result.OpenPorts -join ', ')" -ForegroundColor Cyan
        }
    } catch {
        Write-Host "Error processing job for $($job.Server): $_" -ForegroundColor Red
    } finally {
        $job.PS.Dispose()
    }
}

$runspacePool.Close()
$runspacePool.Dispose()

# Sort results by server
$results = $results | Sort-Object Server

# Generate summary statistics
$workingCount = ($results | Where-Object { $_.Status -eq 'WORKING' }).Count
$partialCount = ($results | Where-Object { $_.Status -eq 'REACHABLE_NO_PING' }).Count
$failedCount = ($results | Where-Object { $_.Status -eq 'NOT WORKING' }).Count

# Display summary
Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "                        SUMMARY" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
Write-Host ""
Write-Host "Statistics:" -ForegroundColor White
Write-Host "  ✓ WORKING: $workingCount" -ForegroundColor Green
Write-Host "  ⚠ REACHABLE_NO_PING: $partialCount" -ForegroundColor Yellow
Write-Host "  ✗ NOT WORKING: $failedCount" -ForegroundColor Red
Write-Host "  Total: $($results.Count)" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Cyan

# Generate reports
Write-Host "`nGenerating reports..." -ForegroundColor Yellow
New-HTMLReport -Results $results -OutputPath $ReportPath
Export-CSVReport -Results $results -OutputPath $CSVPath

Write-Host "`n[SUCCESS] Reports generated:" -ForegroundColor Green
Write-Host "  • HTML: $ReportPath" -ForegroundColor Cyan
Write-Host "  • CSV: $CSVPath" -ForegroundColor Cyan

Write-Host "`nPress Enter to open HTML report or any other key to exit..." -ForegroundColor Yellow
$choice = Read-Host
if ($choice -eq "") {
    Start-Process $ReportPath
}
