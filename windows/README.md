# Windows Administration Scripts

PowerShell scripts for common Windows Server and Active Directory tasks, organized by area.

| Folder | Script | What it does |
|---|---|---|
| [`active-directory/`](./active-directory/) | `New-ADUserOnboarding.ps1` | Creates new-hire accounts from a CSV with temporary passwords and groups |
| | `Disable-ADUserOffboarding.ps1` | Disables, resets, removes groups from, and moves departing users' accounts |
| | `Get-PasswordExpiryReport.ps1` | Lists users whose passwords expire soon |
| | `user_audit.ps1` | Lists AD users who haven't logged on in 90+ days, or never have |
| [`server-lab/`](./server-lab/) | Tutorial + 9 scripts | **Build an on-premises lab** (domain controller, AD, DNS, DHCP, Group Policy, IIS app server, file share) twice: click-ops and PowerShell |
| [`server-build/`](./server-build/) | `Build_Server.ps1` | Renames a new server, joins it to the domain, installs roles, applies GPOs, and installs the SCCM client |
| [`monitoring/`](./monitoring/) | `HealthCheck.ps1` | Daily health report: CPU, memory, disk usage, and critical System log errors, sent by email |
| [`patching/`](./patching/) | `New-MonthlyPatchADR.ps1` | Creates an SCCM Automatic Deployment Rule for monthly Windows security updates |

## Requirements

- Windows PowerShell 5.1 or PowerShell 7
- Run as an administrator
- The ActiveDirectory module (RSAT) for AD scripts, and the Configuration Manager console for SCCM scripts

> ⚠️ Test in a lab before running in production. Replace example names like `corp.example.com`, `sccm.corp`, and `XYZ:` with your environment's values.
