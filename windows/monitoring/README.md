# Daily Health Check: `HealthCheck.ps1`

Builds a short daily health report for a Windows server and emails it to the infrastructure team. It's designed to run from Task Scheduler at 06:00.

## What it checks

| Check | How |
|---|---|
| CPU load | `\Processor(_Total)\% Processor Time` performance counter |
| Memory | Whether more than 2 GB of physical memory is free |
| Disk space | Percent used on each file-system drive |
| Errors | Count of Error-level events in the System log over the last 24 hours |

## Run it

```powershell
.\HealthCheck.ps1
```

Schedule it daily:

```powershell
$action  = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-File C:\Scripts\HealthCheck.ps1'
$trigger = New-ScheduledTaskTrigger -Daily -At 6am
Register-ScheduledTask -TaskName 'Daily Health Check' -Action $action -Trigger $trigger -RunLevel Highest
```

## Notes

- Update the SMTP server and addresses (`mail.corp`, `infra@corp`) for your environment.
- `Send-MailMessage` is deprecated by Microsoft but still works on internal relays. For Microsoft 365, sending through Microsoft Graph is the modern replacement.
