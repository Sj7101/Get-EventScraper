# ================================
# FUNCTION: Get-LoginEventsMultiServer
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

            $xml = [xml]$event.ToXml()
            $data = @{}
            foreach ($d in $xml.Event.EventData.Data) {
                $data[$d.Name] = $d.'#text'
            }

            if ($data.LogonType -in @("2", "3", "10", "11")) {
                $user = $data.TargetUserName
                $domain = $data.TargetDomainName
                $fullUser = "$domain\$user"

                if ($fullUser -match "^(NT AUTHORITY\\|LOCAL SERVICE\\|NETWORK SERVICE\\|.*\\SYSTEM$)") {
                    continue
                }

                if ($user -match "^(DWM-|UMFD-)\d*$") {
                    continue
                }

                [PSCustomObject]@{
                    TimeCreated    = $event.TimeCreated
                    TargetUser     = $user
                    TargetDomain   = $domain
                    IPAddress      = $data.IpAddress
                    ServerName     = $env:COMPUTERNAME
                    EventRecordId  = $event.RecordId
                    LogonType      = $data.LogonType
                }
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
$FailedCsv = Join-Path $ScriptRoot "FailedServer.csv"

$ThrottleLimit = 30
$jobs = @()
$FailedServers = @()

foreach ($Server in $Servers) {
    while ($jobs.Count -ge $ThrottleLimit) {
        $finished = $jobs | Where-Object { $_.State -match 'Completed|Failed|Stopped' }
        if ($finished) {
            $jobs = $jobs | Where-Object { $_.State -notmatch 'Completed|Failed|Stopped' }
        }
        Start-Sleep -Seconds 1
    }

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
                            $xml = [xml]$event.ToXml()
                            $data = @{}
                            foreach ($d in $xml.Event.EventData.Data) {
                                $data[$d.Name] = $d.'#text'
                            }

                            if ($data.LogonType -in @("2", "3", "10", "11")) {
                                $user = $data.TargetUserName
                                $domain = $data.TargetDomainName
                                $fullUser = "$domain\$user"

                                if ($fullUser -match "^(NT AUTHORITY\\|LOCAL SERVICE\\|NETWORK SERVICE\\|.*\\SYSTEM$)") {
                                    continue
                                }

                                if ($user -match "^(DWM-|UMFD-)\d*$") {
                                    continue
                                }

                                [PSCustomObject]@{
                                    TimeCreated    = $event.TimeCreated
                                    TargetUser     = $user
                                    TargetDomain   = $domain
                                    IPAddress      = $data.IpAddress
                                    ServerName     = $env:COMPUTERNAME
                                    EventRecordId  = $event.RecordId
                                    LogonType      = $data.LogonType
                                }
                            }
                        }
                    }

                    return $filteredResults
                }

                Get-LoginEvents -StartTime $startInside -EndTime $endInside
            } -ArgumentList $Start, $End -ErrorAction Stop

            return @{ Server=$ServerName; Success=$true; Data=$result }
        }
        catch {
            return @{ Server=$ServerName; Success=$false; ErrorMessage=$_.Exception.Message }
        }
    } -ArgumentList $Server, $StartTime, $EndTime
}

Write-Host "Waiting for all background jobs to complete..."
$jobs | Wait-Job

$AllResults = @()

foreach ($job in $jobs) {
    try {
        $data = Receive-Job -Job $job -ErrorAction Stop
        if ($data.Success) {
            if ($data.Data) {
                $AllResults += $data.Data
            }
        } else {
            $FailedServers += [PSCustomObject]@{
                ServerName    = $data.Server
                FailureReason = $data.ErrorMessage
            }
        }
    }
    catch {
        $FailedServers += [PSCustomObject]@{
            ServerName    = "Unknown"
            FailureReason = $_.Exception.Message
        }
    }
}

$jobs | Remove-Job

if ($AllResults.Count -gt 0) {
    $AllResults | Export-Csv -Path $OutputCsv -NoTypeInformation
    Write-Host "Login events successfully exported to $OutputCsv"
} else {
    Write-Warning "No login events found across any servers."
}

if ($FailedServers.Count -gt 0) {
    $FailedServers | Export-Csv -Path $FailedCsv -NoTypeInformation
    Write-Host "Failed server list exported to $FailedCsv"
} else {
    Write-Host "No server failures detected."
}