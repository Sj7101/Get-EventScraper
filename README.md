📄 Get-LoginEvents-MultiServer.ps1
📚 Overview
This PowerShell script remotely queries multiple Windows servers for user login events from the Security Event Log.
It filters out system and service accounts, consolidates real user login events, and exports clean reports into two separate CSV files.

The script:

Retrieves successful login events (Event ID 4624) between a user-defined start and end time.

Excludes system accounts such as NT AUTHORITY\SYSTEM, LOCAL SERVICE, and NETWORK SERVICE.

Runs server checks in parallel background jobs for better performance.

Exports results into two CSV files: successful logins and failed server queries.

⚙️ Requirements
Windows PowerShell 5.1

WinRM (Windows Remote Management) enabled on all target servers

Permissions to access the Security Event Log on remote servers

Ability to run Invoke-Command remotely

🛠 Parameters

Parameter	Description
-Servers	An array of server names. Example: @("Server1", "Server2")
-StartTime	Start of the search window. Must be a [datetime].
-EndTime	End of the search window. Must be a [datetime].
▶️ Example Usage
powershell
Copy
Edit
$servers = @("Server01", "Server02", "Server03")
$start = Get-Date -Year 2025 -Month 4 -Day 1
$end = Get-Date

.\Get-LoginEvents-MultiServer.ps1 -Servers $servers -StartTime $start -EndTime $end
This command retrieves login events between April 1, 2025 and today across the specified servers.

📦 Output Files
After the script completes, two CSV files are created in the same folder as the script:


File	Description
LoginEvents.csv	Contains all successfully retrieved login event data.
FailedServer.csv	Contains servers that could not be queried, with reason.
LoginEvents.csv Fields
TimeCreated

TargetUser

TargetDomain

IPAddress

ServerName

EventRecordId

FailedServer.csv Fields
ServerName

FailureReason

🧹 Filtering Logic
The script excludes the following accounts to focus on real user logins:

Accounts under the NT AUTHORITY domain (SYSTEM, LOCAL SERVICE, NETWORK SERVICE)

Any account where the username ends with SYSTEM

🚀 Performance
Runs each server scan as a background job using Start-Job

Enforces a ThrottleLimit (default: 30) to control concurrent background jobs

Waits for all jobs to complete before exporting results

Cleans up background jobs after collection

⚠️ Error Handling
If a server fails (connection error, timeout, RPC issue), it is recorded in FailedServer.csv with a reason

The script continues processing other servers even if some fail

Proper job cleanup after execution

📝 Notes
Ensure WinRM is enabled and firewall rules permit remote PowerShell sessions

The user running the script must have read access to the remote Event Logs

For very large server lists, adjust the $ThrottleLimit value to manage resource load

✅ License
This script is free to use, modify, and distribute.
Attribution is appreciated but not required.

Summary
This script:

Collects successful login events across multiple servers

Filters out system accounts

Runs parallel server queries for faster performance

Produces two clean CSV reports: one for successful logins, and one for failures