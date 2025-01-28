$serviceName = "PanGPS"  # Replace with your service name (e.g., "PanGPS")
$logPath = "C:\Logs\ServiceMonitor_$(Get-Date -Format 'yyyy-MM-dd').log"  # Define the log file path
$sourceIdentifier = "ServiceMonitor" # Define the identifier as a variable

# Create the log directory if missing
if (-not (Test-Path "C:\Logs")) {
    New-Item -Path "C:\Logs" -ItemType Directory -Force -ErrorAction SilentlyContinue
    Write-host "Created log directory: C:\Logs" -ForegroundColor Yellow
}

# Remove existing event subscription
if (Get-EventSubscriber -SourceIdentifier $sourceIdentifier -ErrorAction SilentlyContinue) {
    Unregister-Event -SourceIdentifier $sourceIdentifier
    Write-Host "Removed existing event subscription: $sourceIdentifier" -ForegroundColor Yellow
}

# Define the WMI event query to detect when the service stops
$query = @"
SELECT * FROM __InstanceModificationEvent
WITHIN 2
WHERE 
    TargetInstance ISA 'Win32_Service' 
    AND TargetInstance.Name = '$serviceName'
    AND TargetInstance.State = 'Stopped'
"@

# Register the event and define the action (restart the service)
Register-WmiEvent -Query $query -SourceIdentifier $sourceIdentifier -Action {
    $serviceName = $event.MessageData.serviceName
    $logPath = $event.MessageData.logPath
    try {
        Start-Service -Name $serviceName -ErrorAction Stop
        "$(Get-Date) - Service $serviceName restarted" | Out-File $logPath -Append
    }
    catch {
        "$(Get-Date) - ERROR: Failed to restart $serviceName - $_" | Out-File $logPath -Append
    }
} -MessageData @{serviceName = $serviceName; logPath = $logPath} | Out-Null

# Keep the script running
Write-Host "Monitoring service $serviceName. Press Ctrl+C to exit..." -ForegroundColor Cyan
while ($true) { Start-Sleep -Seconds 10 }