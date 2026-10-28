# Lab scripts

Numbered PowerShell scripts that build the on-premises Windows Server lab. Run them in order. The **[PowerShell guide](../02-powershell-guide.md)** explains where to run each one, what it does, and how to check the result.

| Script | Run on | Builds |
|---|---|---|
| `lab-config.psd1` | (settings) | Every name, IP address, and OU used by the scripts |
| `users.csv` | (data) | The lab's six employees |
| `00-New-LabVMs.ps1` | Hyper-V host | Lab switch, NAT, and the three VMs |
| `01-Initialize-Server.ps1` | DC01, APP01 | Static IP, DNS, time zone, RDP, computer name |
| `02-Install-DomainController.ps1` | DC01 | AD DS and the `lab.local` forest |
| `03-Configure-DnsDhcp.ps1` | DC01 | Reverse zone, forwarders, DHCP scope and options |
| `04-New-ADStructure.ps1` | DC01 | OUs, AGDLP groups, users, admin account, gMSA |
| `05-New-GroupPolicy.ps1` | DC01 | Password policy, Central Store, baseline and user GPOs |
| `06-Join-Domain.ps1` | APP01, CLIENT01 | Domain join straight into the right OU |
| `07-Deploy-AppServer.ps1` | APP01 | IIS intranet under a gMSA with HTTPS, Finance file share |
| `08-Test-Lab.ps1` | CLIENT01 | 15 read-only health checks |
