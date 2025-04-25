# 🔐 Get-LoginEvents-MultiServer.ps1

## 📚 Overview

This PowerShell script remotely queries multiple Windows servers for user login events from the Security Event Log.  
It filters out system and service accounts and gathers real user login activity into structured CSV reports.

---

## ⚙️ Features

- Collects Event ID 4624 (successful logons)
- Filters only meaningful logins:
  - LogonTypes 2 (interactive), 3 (network), 10 (remote desktop), 11 (cached interactive)
- Skips virtual/system accounts:
  - `DWM-*`, `UMFD-*`, `NT AUTHORITY\SYSTEM`, etc.
- Runs across multiple servers using background jobs
- Exports two CSVs:
  - `LoginEvents.csv` — login activity
  - `FailedServer.csv` — unreachable servers or errors

---

## 🛠 Requirements

- PowerShell 5.1
- WinRM enabled and trusted across target servers
- Proper credentials to query remote event logs

---

## 📥 Parameters

| Parameter    | Description                                      |
|--------------|--------------------------------------------------|
| `-Servers`   | Array of server names or IPs                     |
| `-StartTime` | Start of the login event time window (DateTime)  |
| `-EndTime`   | End of the login event time window (DateTime)    |

---

## ▶️ Example

```powershell
$servers = @("Server01", "Server02", "Server03")
$start = Get-Date -Year 2025 -Month 4 -Day 1
$end = Get-Date

.\Get-LoginEvents-MultiServer.ps1 -Servers $servers -StartTime $start -EndTime $end
