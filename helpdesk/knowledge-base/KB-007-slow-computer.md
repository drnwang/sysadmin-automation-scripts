# KB-007: Computer is slow

| | |
|---|---|
| **Applies to** | Windows 10/11 workstations |
| **Audience** | Technicians |
| **Time to fix** | 15–30 minutes |
| **Last tested** | _Not yet tested_ |

## Symptoms
"My computer is slow" can mean many things. Narrow it down first.

## Before you start: ask four questions
1. **Since when?** Sudden changes point to an update, new software, or malware.
2. **Everything slow, or one app?** One app usually means that app.
3. **All the time, or at certain times?** For example only at sign-in, or only in the afternoon.
4. **When did you last restart?** Many "slow computer" tickets are a computer that hasn't restarted in weeks.

## Fix
Connect with remote support or sit with the user, then work top to bottom.

### 1. Restart check
**Task Manager → Performance → CPU** shows **Up time**. Several days or more? Restart, which also finishes pending updates. Then retest.

### 2. What's using the resources
**Task Manager → Processes** → sort by **CPU**, then **Memory**, then **Disk**.

| You see | Likely cause | Action |
|---|---|---|
| Memory above 90% | Too many apps or browser tabs, or not enough RAM | Close extras; note RAM size for a possible upgrade |
| Disk at 100% for minutes | Updates or search indexing, or a failing or slow drive | Wait for updates; check drive health (step 5) |
| One unknown process using high CPU | Possible malware | Step 4, and don't end it until you've noted its name |

### 3. Startup apps and disk space
- **Task Manager → Startup apps:** disable non-essential items, for example updaters and chat apps that aren't needed at sign-in.
- **Settings → System → Storage:** if the C: drive is more than 90% full, run **Storage Sense** or **Disk Cleanup** (`cleanmgr`).

### 4. Malware check
**Windows Security → Virus & threat protection → Quick scan**. Anything found means a security incident: escalate, don't just delete it.

### 5. Hardware warnings
**Event Viewer → Windows Logs → System**: look for **Disk** event IDs **7**, **51**, or **153**, which point to a failing drive.

### Remote checks in PowerShell
```powershell
$pc = 'CLIENT01'
Get-CimInstance -ComputerName $pc Win32_OperatingSystem |
    Select-Object CSName, LastBootUpTime, @{ n = 'FreeMemGB'; e = { [math]::Round($_.FreePhysicalMemory / 1MB, 1) } }
Get-CimInstance -ComputerName $pc Win32_LogicalDisk -Filter "DriveType=3" |
    Select-Object DeviceID, @{ n = 'FreeGB'; e = { [math]::Round($_.FreeSpace / 1GB, 1) } }, @{ n = 'SizeGB'; e = { [math]::Round($_.Size / 1GB, 1) } }
```

## Escalate when
- Defender finds malware, or you see an unknown process you can't identify → **Security**.
- Disk errors in Event Viewer → **Systems** for a hardware replacement (back up the user's data first).
- The computer meets minimum specs, but the user's work genuinely needs more → manager, for a hardware request.

## Related
- [KB-005: Printer offline or jobs stuck](./KB-005-printer-offline.md)
- [KB-008: Report a suspicious email](./KB-008-report-phishing.md)
