Get-LoginEvents-MultiServer.ps1
Overview
This PowerShell script queries multiple Windows servers remotely to collect user login events from the Security Event Log. It filters out system and service accounts and exports real user login events into a consolidated CSV file.

The script:

Searches for successful login events (Event ID 4624) between a user-defined start and end time.

Excludes system accounts such as NT AUTHORITY\SYSTEM, LOCAL SERVICE, and NETWORK SERVICE.

Gathers results from multiple servers simultaneously using background jobs.

Exports the collected data into a file named LoginEvents.csv in the same directory as the script.

Requirements
Windows PowerShell 5.1.

WinRM (Windows Remote Management) must be enabled and configured on all target servers.

User account must have permission to read the Security Event Log on the remote servers.

Parameters

Parameter	Description
-Servers	An array of server names to query. Example: @("Server1", "Server2")
-StartTime	The start of the time window to search for login events. Must be a [datetime].
-EndTime	The end of the time window to search for login events. Must be a [datetime].
Example Usage
powershell
Copy
Edit
$servers = @("Server01", "Server02", "Server03")
$start = Get-Date -Year 2025 -Month 4 -Day 1
$end = Get-Date

.\Get-LoginEvents-MultiServer.ps1 -Servers $servers -StartTime $start -EndTime $end
This will retrieve login events from April 1, 2025 to the current date across the specified servers and export them into LoginEvents.csv.

Output
The script generates a CSV file (LoginEvents.csv) with the following columns:

TimeCreated

TargetUser

TargetDomain

IPAddress

ServerName

EventRecordId

Filtering Logic
The script automatically filters out the following:

Logins from the NT AUTHORITY domain (e.g., SYSTEM, LOCAL SERVICE, NETWORK SERVICE).

Any username ending in SYSTEM.

This ensures only real user login events are captured.

Performance and Job Management
The script uses Start-Job to create background jobs for each server.

It enforces a ThrottleLimit (default 30) to avoid overloading the system by limiting the number of concurrent background jobs.

After all jobs finish, the results are collected and exported together.

Error Handling
If a server connection fails, the script logs a warning and continues processing other servers.

Only successful results are included in the final export.

Jobs are properly cleaned up after execution.

Notes
Ensure proper firewall rules and WinRM policies are in place for remote execution.

It is recommended to test on a small batch of servers first before scaling up to hundreds or thousands.

Throttle limit can be adjusted based on the available system resources.

License
This script is free to use, modify, and distribute.
Attribution is appreciated but not required.

