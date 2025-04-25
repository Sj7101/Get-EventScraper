# ================================
# FUNCTION: Get-LoginEvents
# ================================
function Get-LoginEvents {
    param (
        [datetime]$StartTime,
        [datetime]$EndTime
    )

    $logName = 'Security'
    $eventID = 4624

    try {
        $events = Get-WinEvent -FilterHashtable @{
            LogName = $logName
            Id      = $eventID
        } -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to query events: $_"
        return
    }

    $filteredResults = foreach ($event in $events) {
        if ($event.TimeCreated -ge $StartTime -and $event.TimeCreated -le $EndTime) {
            $properties = $event.Properties
            $user = $properties[5].Value
            $domain = $properties[6].Value

            $fullUser = "$domain\$user"

            if ($fullUser -match "^(NT AUTHORITY\\|LOCAL SERVICE\\|NETWORK SERVICE\\|.*\\SYSTEM$)") {
                continue
            }

            [PSCustomObject]@{
                TimeCreated    = $event.TimeCreated
                TargetUser     = $user
                TargetDomain   = $domain
                IPAddress      = $properties[18].Value
                ServerName     = $env:COMPUTERNAME
                EventRecordId  = $event.RecordId
            }
        }
    }

    return $filteredResults
}

# ================================
# MAIN SCRIPT
# ================================

param (
    [Parameter(Mandatory)]
    [string[]]$Servers,

    [Parameter(Mandatory)]
    [datetime]$StartTime,

    [Parameter(Mandatory)]
    [datetime]$EndTime
)

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$OutputCsv = Join-Path $ScriptRoot "LoginEvents.csv"

# Settings
$ThrottleLimit = 30 # Max number of background jobs at once

# Track background jobs
$jobs = @()

foreach ($Server in $Servers) {
    # Wait if too many jobs are running
    while ($jobs.Count -ge $ThrottleLimit) {
        $finished = $jobs | Where-Object { $_.State -match 'Completed|Failed|Stopped' }
        if ($finished) {
            $jobs = $jobs | Where-Object { $_.State -notmatch 'Completed|Failed|Stopped' }
        }
        Start-Sleep -Seconds 1
    }

    # Start a background job per server
    $jobs += Start-Job -ScriptBlock {
        param($ServerName, $Start, $End)

        try {
            $result = Invoke-Command -ComputerName $ServerName -ScriptBlock {
                param($startInside, $endInside)

                function Get-LoginEvents {
                    param (
                        [datetime]$StartTime,
                        [datetime]$EndTime
                    )

                    $logName = 'Security'
                    $eventID = 4624

                    try {
                        $events = Get-WinEvent -FilterHashtable @{
                            LogName = $logName
                            Id      = $eventID
                        } -ErrorAction Stop
                    }
                    catch {
                        return
                    }

                    $filteredResults = foreach ($event in $events) {
                        if ($event.TimeCreated -ge $StartTime -and $event.TimeCreated -le $EndTime) {
                            $properties = $event.Properties
                            $user = $properties[5].Value
                            $domain = $properties[6].Value

                            $fullUser = "$domain\$user"

                            if ($fullUser -match "^(NT AUTHORITY\\|LOCAL SERVICE\\|NETWORK SERVICE\\|.*\\SYSTEM$)") {
                                continue
                            }

                            [PSCustomObject]@{
                                TimeCreated    = $event.TimeCreated
                                TargetUser     = $user
                                TargetDomain   = $domain
                                IPAddress      = $properties[18].Value
                                ServerName     = $env:COMPUTERNAME
                                EventRecordId  = $event.RecordId
                            }
                        }
                    }

                    return $filteredResults
                }

                Get-LoginEvents -StartTime $startInside -EndTime $endInside
            } -ArgumentList $Start, $End -ErrorAction Stop

            return $result
        }
        catch {
            Write-Error "Failed to connect to $ServerName : $_"
            return
        }
    } -ArgumentList $Server, $StartTime, $EndTime
}

# Wait for all jobs to complete
Write-Host "Waiting for all background jobs to complete..."
$jobs | Wait-Job

# Collect results
$AllResults = @()

foreach ($job in $jobs) {
    try {
        $data = Receive-Job -Job $job -ErrorAction Stop
        if ($data) {
            $AllResults += $data
        }
    }
    catch {
        Write-Warning "Could not receive job results: $_"
    }
}

# Cleanup background jobs
$jobs | Remove-Job

# Export results
if ($AllResults.Count -gt 0) {
    $AllResults | Export-Csv -Path $OutputCsv -NoTypeInformation
    Write-Host "Login events successfully exported to $OutputCsv"
}
else {
    Write-Warning "No login events found across any servers."
}