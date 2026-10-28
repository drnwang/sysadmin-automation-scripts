# Monthly Patch Deployment Rule: `New-MonthlyPatchADR.ps1`

Creates a **Configuration Manager (SCCM) Automatic Deployment Rule** that automatically deploys Windows 10 critical and security updates to a workstation collection every month.

## Rule settings

| Setting | Value |
|---|---|
| Name | Win10 Monthly CU |
| Target collection | All Win10 Workstations |
| Product | Windows 10 |
| Update classifications | Critical Updates, Security Updates |
| Schedule | First Tuesday of each month |
| Compliance reporting | Enabled |

## Run it

From a machine with the Configuration Manager console installed:

```powershell
.\New-MonthlyPatchADR.ps1
```

## Notes

- Replace `XYZ:` with your site code.
- Microsoft releases updates on Patch Tuesday, the **second** Tuesday of the month. Many organizations schedule the ADR shortly after it. Adjust `-WeekOrder` to match your patch window.
