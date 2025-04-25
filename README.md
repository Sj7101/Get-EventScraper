📄 Updated Professional README.md (with light Unicode formatting)
markdown
Copy
Edit
# 📄 Get-LoginEvents-MultiServer.ps1

## 📚 Overview
This PowerShell script remotely queries multiple Windows servers for user login events from the Security Event Log.  
It filters out system and service accounts, and consolidates real user login events into a single CSV file.

The script:
- Retrieves **successful login events** (Event ID 4624) between a user-defined start and end time.
- **Excludes** system accounts such as `NT AUTHORITY\SYSTEM`, `LOCAL SERVICE`, and `NETWORK SERVICE`.
- Runs server checks in **parallel background jobs** for better performance.
- Exports results into a file called **`LoginEvents.csv`** in the script's folder.

---

## ⚙️ Requirements
- Windows PowerShell **5.1**.
- **WinRM** (Windows Remote Management) enabled on all target servers.
- Proper permissions to access the **Security Event Log** on remote servers.
- Ability to run `Invoke-Command` remotely.

---

## 🛠 Parameters

| Parameter | Description |
|:---|:---|
| `-Servers` | An array of server names. Example: `@("Server1", "Server2")` |
| `-StartTime` | Start of the search window. Must be a `[datetime]`. |
| `-EndTime` | End of the search window. Must be a `[datetime]`. |

---

## ▶️ Example Usage

```powershell
$servers = @("Server01", "Server02", "Server03")
$start = Get-Date -Year 2025 -Month 4 -Day 1
$end = Get-Date

.\Get-LoginEvents-MultiServer.ps1 -Servers $servers -StartTime $start -EndTime $end
This command retrieves login events between April 1, 2025 and today across the specified servers.

📦 Output
The script generates a CSV file named LoginEvents.csv containing:

TimeCreated

TargetUser

TargetDomain

IPAddress

ServerName

EventRecordId

🧹 Filtering Rules
The script excludes the following accounts to focus on real user logins:

Accounts from the domain NT AUTHORITY (e.g., SYSTEM, LOCAL SERVICE, NETWORK SERVICE).

Any account where the username ends with SYSTEM.

🚀 Performance
Runs each server scan as a background job using Start-Job.

Enforces a ThrottleLimit (default: 30) to control concurrent jobs.

Waits for all background jobs to complete before exporting the results.

You can adjust the $ThrottleLimit in the script if needed based on your system performance.

⚠️ Error Handling
Servers that fail to connect will log a warning and continue.

Only successful query results are included in the final CSV.

All background jobs are properly cleaned up at the end of the script.

📝 Notes
Ensure WinRM and firewall rules allow remote PowerShell sessions.

User running the script must have rights to read event logs remotely.

If querying a large number of servers (hundreds or thousands), consider tuning ThrottleLimit to prevent resource exhaustion.