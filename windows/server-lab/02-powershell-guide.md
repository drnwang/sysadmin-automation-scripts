# ⌨️ PowerShell Guide: Build the Lab with Scripts

This tutorial builds **exactly the same lab** as the [click-ops guide](./01-clickops-guide.md), using the numbered scripts in [`scripts/`](./scripts/). Each part explains what the script does, highlights the commands worth knowing by heart, and ends with **✅ Check your work** commands.

**Why script it?** The click-ops build takes an afternoon and is easy to get slightly wrong. The scripted build takes about an hour, gives the same result every time, and doubles as documentation. That's how admins build environments at scale, and it's what interviewers mean by "automation experience."

> Do the click-ops guide first if you haven't. These scripts make much more sense once you've seen each setting in the GUI.

---

## How the scripts are organized

| Script | Run on | As | Part |
|---|---|---|---|
| [`lab-config.psd1`](./scripts/lab-config.psd1) | (settings file) | | All |
| [`00-New-LabVMs.ps1`](./scripts/00-New-LabVMs.ps1) | Your PC (Hyper-V host) | Your admin account | 1 |
| [`01-Initialize-Server.ps1`](./scripts/01-Initialize-Server.ps1) `-Role DC` | DC01 | Local Administrator | 2 |
| [`02-Install-DomainController.ps1`](./scripts/02-Install-DomainController.ps1) | DC01 | Local Administrator | 3 |
| [`03-Configure-DnsDhcp.ps1`](./scripts/03-Configure-DnsDhcp.ps1) | DC01 | LAB\Administrator | 4 |
| [`04-New-ADStructure.ps1`](./scripts/04-New-ADStructure.ps1) | DC01 | LAB\Administrator | 5 |
| [`05-New-GroupPolicy.ps1`](./scripts/05-New-GroupPolicy.ps1) | DC01 | LAB\adm-nwang | 6 |
| `01-Initialize-Server.ps1 -Role App`, then [`06-Join-Domain.ps1`](./scripts/06-Join-Domain.ps1) `-Type Server` | APP01 | Local Administrator | 7 |
| [`07-Deploy-AppServer.ps1`](./scripts/07-Deploy-AppServer.ps1) | APP01 | LAB\adm-nwang | 8 |
| `06-Join-Domain.ps1 -Type Workstation` | CLIENT01 | Local Administrator | 9 |
| [`08-Test-Lab.ps1`](./scripts/08-Test-Lab.ps1) | CLIENT01 | Any domain user | 10 |

**Every name, IP address, and OU comes from `lab-config.psd1`.** No script has a hard-coded value, so to build a different lab (another domain name or subnet), you change one file.

Every script that changes something is **safe to rerun**: it checks whether each item already exists before creating it.

### Before you start

1. **Use Windows PowerShell 5.1**, the blue *Windows PowerShell* that comes with Windows Server, **as administrator**. Some commands used here (the `GroupPolicy` module, `Test-ComputerSecureChannel`) are built for 5.1.
2. **Get the scripts onto each VM.** The easiest options:
   - **Hyper-V Enhanced Session:** copy the `scripts` folder on your PC and paste it into the VM's desktop.
   - **`Copy-VMFile`** from your PC: enable *Guest services* first, then copy:
     ```powershell
     Enable-VMIntegrationService -VMName DC01 -Name 'Guest Service Interface'
     Get-ChildItem .\scripts | ForEach-Object {
         Copy-VMFile -Name DC01 -SourcePath $_.FullName -DestinationPath "C:\Lab\$($_.Name)" -FileSource Host -CreateFullPath
     }
     ```
3. **Allow the scripts to run** in that PowerShell window only:
   ```powershell
   Set-Location C:\Lab
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   Get-ChildItem *.ps1 | Unblock-File
   ```

---

## Part 1: Create the network and VMs

On **your PC**, in PowerShell as administrator. First run the PC check and download the ISOs ([click-ops 1.0–1.1](./01-clickops-guide.md#10-check-your-pc)). Then edit `lab-config.psd1`: set `HyperV.ServerIso` and `HyperV.ClientIso` to the **real file names** you downloaded (for example `D:\ISO\SERVER_EVAL_x64FRE_en-us.iso`), and point `HyperV.VMPath` at the drive with the most free space. Then:

```powershell
.\00-New-LabVMs.ps1
```

**What it does:**
```powershell
New-VMSwitch -Name LabSwitch -SwitchType Internal                         # private lab network
New-NetIPAddress -InterfaceAlias 'vEthernet (LabSwitch)' -IPAddress 10.10.10.1 -PrefixLength 24
New-NetNat -Name LabNAT -InternalIPInterfaceAddressPrefix 10.10.10.0/24   # internet access via your PC
New-VM -Name DC01 -Generation 2 -MemoryStartupBytes 4GB -NewVHDPath ... -NewVHDSizeBytes 60GB -SwitchName LabSwitch
Enable-VMTPM -VM $vm                                                      # Windows 11 needs TPM 2.0
Set-VMFirmware -VM $vm -FirstBootDevice $dvd                              # boot from the ISO
```

> Using VirtualBox? Do Part 1 of the click-ops guide instead. Everything after Part 1 is identical.

**Install Windows** on DC01 by hand, as in click-ops Part 2.1. (Fully unattended installs with `autounattend.xml` are a great next project.)

### ✅ Check your work
```powershell
Get-VM | Select-Object Name, State, ProcessorCount, @{n='MemoryGB';e={$_.MemoryStartup/1GB}}
Get-NetNat
```

---

## Part 2: Prepare DC01

On **DC01**, as the local Administrator:

```powershell
.\01-Initialize-Server.ps1 -Role DC
```

DC01 restarts as **DC01** when it finishes.

**Commands worth knowing:**
```powershell
New-NetIPAddress -InterfaceIndex $nic.ifIndex -IPAddress 10.10.10.10 -PrefixLength 24 -DefaultGateway 10.10.10.1
Set-DnsClientServerAddress -InterfaceIndex $nic.ifIndex -ServerAddresses 1.1.1.1, 8.8.8.8
Set-TimeZone -Id 'Eastern Standard Time'
Set-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0
Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'
Rename-Computer -NewName DC01 -Restart
```

Install updates before moving on: **Settings → Windows Update**, or use the `PSWindowsUpdate` module if you want to script that too.

### ✅ Check your work
```powershell
hostname
Get-NetIPConfiguration
Test-NetConnection 10.10.10.1
Resolve-DnsName www.microsoft.com
```

---

## Part 3: Promote DC01 to a domain controller

```powershell
.\02-Install-DomainController.ps1
```

You'll be asked for the **DSRM password**. DC01 restarts automatically, then sign in as **`LAB\Administrator`**.

**What it does:**
```powershell
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

$forest = @{
    DomainName = 'lab.local'; DomainNetbiosName = 'LAB'
    ForestMode = 'WinThreshold'; DomainMode = 'WinThreshold'   # Windows Server 2016 level
    InstallDns = $true; SafeModeAdministratorPassword = $dsrm
}
Test-ADDSForestInstallation @forest     # the wizard's "Prerequisites Check"
Install-ADDSForest @forest -Force
```

> **Splatting** (`@forest`) passes a hashtable as parameters. It keeps long commands readable and lets the test and the real install share exactly the same settings.

### ✅ Check your work
```powershell
Get-ADDomain | Select-Object DNSRoot, NetBIOSName, DomainMode
Get-ADDomainController | Select-Object HostName, IPv4Address, IsGlobalCatalog
Get-Service NTDS, DNS, Netlogon, KDC | Select-Object Name, Status
dcdiag /q          # no output means everything passed
```

---

## Part 4: Configure DNS and DHCP

```powershell
.\03-Configure-DnsDhcp.ps1
```

**DNS commands worth knowing:**
```powershell
Set-DnsClientServerAddress -InterfaceIndex $nic.ifIndex -ServerAddresses 10.10.10.10
Add-DnsServerPrimaryZone -NetworkId '10.10.10.0/24' -ReplicationScope Domain -DynamicUpdate Secure
Set-DnsServerForwarder -IPAddress 1.1.1.1, 8.8.8.8
ipconfig /registerdns
```

**DHCP commands worth knowing:**
```powershell
Install-WindowsFeature DHCP -IncludeManagementTools
Add-DhcpServerSecurityGroup                                   # 'DHCP Administrators' and 'DHCP Users'
Add-DhcpServerInDC -DnsName dc01.lab.local -IPAddress 10.10.10.10   # authorize in AD
Add-DhcpServerv4Scope -Name 'Lab clients' -StartRange 10.10.10.100 -EndRange 10.10.10.200 `
    -SubnetMask 255.255.255.0 -LeaseDuration 8.00:00:00 -State Active
Set-DhcpServerv4OptionValue -ScopeId 10.10.10.0 -Router 10.10.10.1 -DnsServer 10.10.10.10 -DnsDomain lab.local
Set-DhcpServerv4DnsSetting -ScopeId 10.10.10.0 -DynamicUpdates Always -DeleteDnsRRonLeaseExpiry $true
```

The script also sets a registry value that clears Server Manager's *"Complete DHCP configuration"* flag. The GUI does that for you when you click **Commit**.

### ✅ Check your work
```powershell
Resolve-DnsName dc01.lab.local
Resolve-DnsName 10.10.10.10            # reverse lookup works
Resolve-DnsName www.microsoft.com      # forwarders work
Get-DnsServerForwarder
Get-DhcpServerInDC
Get-DhcpServerv4Scope
Get-DhcpServerv4OptionValue -ScopeId 10.10.10.0
```

---

## Part 5: Build the OUs, groups, users, and gMSA

```powershell
.\04-New-ADStructure.ps1
```

You'll be asked for an initial password for the lab users (they must change it at first sign-in) and a password for your admin account.

**What it builds:**

| Step | Key command |
|---|---|
| OU tree | `New-ADOrganizationalUnit -Name Finance -Path 'OU=Users,OU=Corp,DC=lab,DC=local' -ProtectedFromAccidentalDeletion $true` |
| Redirect default containers | `redircmp` / `redirusr` |
| Role and resource groups | `New-ADGroup -Name GG-Finance-Staff -GroupScope Global -GroupCategory Security -Path ...` |
| AGDLP nesting | `Add-ADGroupMember -Identity DL-FinanceShare-Modify -Members GG-Finance-Staff` |
| Users from CSV | `Import-Csv users.csv` → `New-ADUser ... -ChangePasswordAtLogon $true` |
| Admin account | `New-ADUser adm-nwang ...` → `Add-ADGroupMember 'Domain Admins'` |
| gMSA | `Add-KdsRootKey` → `New-ADServiceAccount gmsa-intranet -PrincipalsAllowedToRetrieveManagedPassword GG-Intranet-Servers` |

**Pattern worth learning: "create only if missing."**
```powershell
if (-not (Get-ADGroup -Filter "Name -eq 'GG-Finance-Staff'" -ErrorAction SilentlyContinue)) {
    New-ADGroup -Name 'GG-Finance-Staff' -GroupScope Global -GroupCategory Security -Path $groupsOU
}
```
This makes scripts **idempotent**: running them twice gives the same result as running them once. That's what makes automation safe to rerun after a failure halfway through.

**Add more users:** add lines to `users.csv` and rerun the script. Existing users are skipped. For real onboarding, see the [AD toolkit's onboarding script](../active-directory/).

Sign out and sign back in as **`LAB\adm-nwang`**.

### ✅ Check your work
```powershell
Get-ADOrganizationalUnit -Filter * -SearchBase 'OU=Corp,DC=lab,DC=local' | Sort-Object DistinguishedName | Select-Object DistinguishedName
Get-ADUser -Filter * -SearchBase 'OU=Users,OU=Corp,DC=lab,DC=local' -Properties Department, Title | Format-Table Name, SamAccountName, Department, Title
Get-ADGroupMember DL-FinanceShare-Modify -Recursive | Select-Object SamAccountName   # Finance users, through nesting
Get-ADServiceAccount gmsa-intranet -Properties PrincipalsAllowedToRetrieveManagedPassword
```

---

## Part 6: Password policy and Group Policy

```powershell
.\05-New-GroupPolicy.ps1
```

**Commands worth knowing:**
```powershell
Set-ADDefaultDomainPasswordPolicy -Identity lab.local -MinPasswordLength 14 -LockoutThreshold 5 ...

$gpo = New-GPO -Name 'Corp - Computer Security Baseline'
New-GPLink -Guid $gpo.Id -Target 'OU=Computers,OU=Corp,DC=lab,DC=local'

# Every Administrative Template setting is a registry value under ...\Policies\...
Set-GPRegistryValue -Guid $gpo.Id -Key 'HKLM\Software\Policies\Microsoft\Windows NT\DNSClient' `
    -ValueName EnableMulticast -Type DWord -Value 0          # = "Turn off multicast name resolution: Enabled"
```

> **How to find the registry value behind any GUI setting:** set it in the GPO editor, then run `Get-GPOReport -Name '<GPO>' -ReportType Xml` and look for the registry key, or search Microsoft's *Group Policy Settings Reference* spreadsheet.

**Click-ops only:** the bonus Finance drive mapping (Group Policy *Preferences*) has no built-in PowerShell cmdlets. Add it in the GUI (click-ops guide 6.5) if you want it.

### ✅ Check your work
```powershell
Get-ADDefaultDomainPasswordPolicy
Get-GPInheritance -Target 'OU=Computers,OU=Corp,DC=lab,DC=local' | Select-Object -ExpandProperty GpoLinks
Get-GPOReport -Name 'Corp - Computer Security Baseline' -ReportType Html -Path "$env:USERPROFILE\Desktop\baseline.html"
```
Open the HTML report: it's the same view as the GPMC **Settings** tab.

---

## Part 7: Prepare APP01 and join the domain

Install Windows Server on APP01 (click-ops 2.1). Then, as the local Administrator:

```powershell
.\01-Initialize-Server.ps1 -Role App     # IP 10.10.10.20, DNS -> DC01, rename, restart
.\06-Join-Domain.ps1 -Type Server        # after the restart
```

`06-Join-Domain.ps1` first checks that DNS can find the domain controller, which catches the most common join failure with a clear message, then joins **straight into Corp\Servers**:
```powershell
Resolve-DnsName -Name '_ldap._tcp.dc._msdcs.lab.local' -Type SRV     # how computers find a DC
Add-Computer -DomainName lab.local -OUPath 'OU=Servers,OU=Corp,DC=lab,DC=local' -Credential $cred -Restart
```

> **`_ldap._tcp.dc._msdcs.lab.local`** is the DNS record every Windows machine queries to find a domain controller. If it doesn't resolve, nothing domain-related works. Knowing this record is a great interview answer for "how does a client find a DC?"

### ✅ Check your work
Sign in as **`LAB\adm-nwang`**:
```powershell
Test-ComputerSecureChannel -Verbose
Get-ADComputer APP01 | Select-Object DistinguishedName     # should be in OU=Servers
gpupdate /force
gpresult /r /scope computer
```

---

## Part 8: Build the application server

On **APP01**, as **`LAB\adm-nwang`**:

```powershell
.\07-Deploy-AppServer.ps1
```

This is the most interesting script in the lab. It works against **DC01 remotely**, so you never leave APP01.

**Directory and DNS, done remotely with RSAT tools:**
```powershell
Install-WindowsFeature Web-Server, Web-Windows-Auth, Web-Asp-Net45, Web-Mgmt-Console, RSAT-AD-PowerShell, RSAT-DNS-Server
Add-ADGroupMember -Identity GG-Intranet-Servers -Members (Get-ADComputer APP01)
klist -li 0x3e7 purge         # refresh the computer's Kerberos ticket instead of rebooting
Add-DnsServerResourceRecordCName -ComputerName DC01 -ZoneName lab.local -Name intranet -HostNameAlias app01.lab.local
```

> **`klist -li 0x3e7 purge`** clears the tickets of the SYSTEM account (logon ID `0x3e7`), which is the computer itself. The next request gets a fresh ticket with the new group membership. The GUI track simply reboots.

**gMSA and IIS:**
```powershell
Install-ADServiceAccount -Identity gmsa-intranet
Test-ADServiceAccount   -Identity gmsa-intranet          # True = ready

New-WebAppPool -Name IntranetPool
Set-ItemProperty IIS:\AppPools\IntranetPool -Name processModel -Value @{
    identityType = 3; userName = 'LAB\gmsa-intranet$'; password = ''   # 3 = SpecificUser; AD manages the password
}
New-Website -Name Intranet -PhysicalPath C:\inetpub\intranet -ApplicationPool IntranetPool -HostHeader intranet.lab.local -Port 80

Set-WebConfigurationProperty -PSPath IIS:\ -Location Intranet `
    -Filter system.webServer/security/authentication/windowsAuthentication -Name enabled -Value $true
```

**HTTPS:**
```powershell
$cert = New-SelfSignedCertificate -DnsName intranet.lab.local -CertStoreLocation Cert:\LocalMachine\My
New-WebBinding -Name Intranet -Protocol https -Port 443 -HostHeader intranet.lab.local -SslFlags 1   # 1 = SNI
(Get-WebBinding -Name Intranet -Protocol https).AddSslCertificate($cert.Thumbprint, 'My')
```

**File share, using AGDLP:**
```powershell
icacls C:\Shares\Finance /inheritance:r /grant 'SYSTEM:(OI)(CI)F' 'BUILTIN\Administrators:(OI)(CI)F' `
    'LAB\DL-FinanceShare-Modify:(OI)(CI)M' 'LAB\DL-FinanceShare-Read:(OI)(CI)RX'
New-SmbShare -Name Finance -Path C:\Shares\Finance -FullAccess 'BUILTIN\Administrators' `
    -ChangeAccess 'NT AUTHORITY\Authenticated Users' -FolderEnumerationMode AccessBased
```

> **Reading icacls:** `(OI)` = applies to files (object inherit), `(CI)` = applies to subfolders (container inherit), `F` = Full, `M` = Modify, `RX` = Read & execute. `/inheritance:r` removes inherited permissions so only what you grant applies.

If `Test-ADServiceAccount` fails, restart APP01 and run the script again. It picks up where it left off.

### ✅ Check your work
```powershell
Get-Website Intranet | Select-Object Name, State, PhysicalPath
Get-WebBinding -Name Intranet
(Get-ItemProperty IIS:\AppPools\IntranetPool -Name processModel).userName
Get-SmbShare Finance | Select-Object Name, Path, FolderEnumerationMode
Get-SmbShareAccess Finance
(Get-Acl C:\Shares\Finance).Access | Select-Object IdentityReference, FileSystemRights
```

---

## Part 9: Join CLIENT01

Install Windows 11 (click-ops 9.1). Check that DHCP gave it an address:
```powershell
Get-NetIPConfiguration     # 10.10.10.100-200, gateway .1, DNS 10.10.10.10
```

Then join, as the local Administrator:
```powershell
.\06-Join-Domain.ps1 -Type Workstation   # lands in Corp\Computers; the baseline GPO applies
```

Sign in as **`LAB\jsmith`** and run the employee tests from click-ops Part 9.4 and 9.5.

On DC01, confirm DHCP and DNS registered the client:
```powershell
Get-DhcpServerv4Lease -ScopeId 10.10.10.0
Resolve-DnsName client01.lab.local
```

---

## Part 10: Test, back up, and troubleshoot

### Run the full lab test
On CLIENT01, signed in as a domain user:
```powershell
.\08-Test-Lab.ps1
```
It checks DNS (forward, reverse, alias, forwarders), DC locator records, domain membership, the DC's LDAP, Kerberos, DNS, and SMB ports, APP01's HTTP and HTTPS, the intranet with Windows Authentication, and the Finance share. All 15 checks should pass for a Finance user. For HR, the share check passes too (read access); for IT, it fails by design.

### Back up Active Directory (system state)
```powershell
Install-WindowsFeature Windows-Server-Backup
wbadmin start systemstatebackup -backupTarget:E: -quiet
```
(Add and format an `E:` disk first. See click-ops 10.2 for why checkpoints aren't AD backups.)

### Troubleshooting toolkit

| Question | Command |
|---|---|
| Can this machine find a DC? | `Resolve-DnsName _ldap._tcp.dc._msdcs.lab.local -Type SRV` and `nltest /dsgetdc:lab.local` |
| Is the computer's trust with the domain OK? | `Test-ComputerSecureChannel -Repair -Credential LAB\adm-nwang` (repairs if broken) |
| Which GPOs applied, and why not? | `gpresult /h report.html`, then open the report |
| Is the clock in sync? | `w32tm /query /status` and `w32tm /resync` |
| Can I reach a port? | `Test-NetConnection dc01 -Port 389` |
| What groups am I in, right now? | `whoami /groups` (after a group change, sign out and back in) |
| Is the DC healthy? | `dcdiag /q`, `dcdiag /test:dns`, `repadmin /replsummary` |
| Can the server use the gMSA? | `Test-ADServiceAccount gmsa-intranet` |

The **symptom → cause → fix** table in [click-ops Part 10.3](./01-clickops-guide.md#103-troubleshooting) applies here too.

---

## 🎉 Done

You've built a company network twice, by hand and as code. Ideas for what's next:
- **Second domain controller** (`DC02`) with `Install-ADDSDomainController`, then watch replication with `repadmin`
- **AD Certificate Services**, so the intranet gets a trusted certificate instead of a self-signed one
- **Unattended installs** with `autounattend.xml`, so Part 1 needs no clicks either
- Harden it with the **[Windows hardening lab](../../security/windows-hardening-lab/)** and scan it with the **[Nessus lab](../../security/nessus-scan-lab/)**
