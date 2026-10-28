# Server Build: `Build_Server.ps1`

Outlines a zero-touch build for a new Windows Server: rename, domain join, role installation, Group Policy, and SCCM client install.

## Steps in the script

| Step | What happens |
|---|---|
| 1 | Renames the computer and restarts |
| 2 | Joins the domain (prompts for credentials) and restarts |
| 3 | Installs File Server, DFS Namespace and Replication, Hyper-V, and RSAT AD tools |
| 4 | Runs `gpupdate /force` to apply baseline GPOs already linked in AD |
| 5 | Downloads and installs the SCCM (ConfigMgr) client |

## Run it

```powershell
.\Build_Server.ps1 -Hostname FS01 -Domain corp.example.com
```

## Notes

- Step 1 restarts the server, which stops the script. In practice, run the steps after the restart separately, or use a scheduled task or `RunOnce` entry so the script resumes after each reboot.
- Replace `sccm.corp` and the client source path with your Configuration Manager site's values.
