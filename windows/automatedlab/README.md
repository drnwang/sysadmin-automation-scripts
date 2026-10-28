# Lab as Code with AutomatedLab

Rebuild a complete Windows lab (domain controller, web server, certificate authority, and Windows 11 client) from **one short PowerShell definition**, including unattended Windows installs. Then compare it with building the [server lab](../server-lab/) by hand and with your own scripts.

> **Status:** tutorial ready. Results and screenshots to be added after the lab is run.

| | |
|---|---|
| **Role** | Sysadmin |
| **Time** | A weekend (mostly unattended install time) |
| **Cost** | Free (open source) |
| **Builds on** | [Server lab](../server-lab/) for comparison; a Hyper-V host |
| **Resume keywords** | Infrastructure as code, automation, unattended installation, Hyper-V, PowerShell |

## Why this matters

Senior sysadmins and engineers are expected to automate repeatable work. AutomatedLab is an open-source PowerShell framework used to build test and training labs. Using it shows you understand **infrastructure as code**: the environment is described in a file, so it can be rebuilt, shared, and changed safely. It also gives you a disposable lab for risky experiments.

---

## Part 1: Prepare the Hyper-V host

On your **PC** (the Hyper-V host), in PowerShell as administrator:

1. Install the module:
   ```powershell
   Install-Module AutomatedLab -AllowClobber -Scope AllUsers
   ```
   The first import asks whether to send anonymous telemetry. Answer as you prefer.
2. Create the **LabSources** folder, where AutomatedLab keeps ISOs, tools, and scripts:
   ```powershell
   New-LabSourcesFolder -DriveLetter C
   ```
3. Copy your **Windows Server 2022** and **Windows 11 Enterprise** evaluation ISOs into `C:\LabSources\ISOs`.
4. See which operating systems AutomatedLab found in them, and copy the exact names. You'll need them in Part 2:
   ```powershell
   Get-LabAvailableOperatingSystem -Path C:\LabSources\ISOs | Select-Object OperatingSystemName
   ```

> AutomatedLab uses its own network and domain (`al.lab` below), so it won't interfere with your `lab.local` VMs. Make sure you have enough free RAM for both, or shut the other lab down.

---

## Part 2: Write the lab definition

Create `ALLab.ps1` with the content below. Read each line before running it. The comments explain what it does.

```powershell
# Name the lab and choose Hyper-V
New-LabDefinition -Name 'ALLab' -DefaultVirtualizationEngine HyperV

# A private network for this lab only
Add-LabVirtualNetworkDefinition -Name 'ALLab' -AddressSpace 192.168.70.0/24

# The domain, and the account used during installation (lab-only password)
Add-LabDomainDefinition -Name 'al.lab' -AdminUser 'Install' -AdminPassword 'Lab-Only-Pass1!'
Set-LabInstallationCredential -Username 'Install' -Password 'Lab-Only-Pass1!'

# Defaults shared by every machine (use the exact OS names from Part 1, step 4)
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Network'         = 'ALLab'
    'Add-LabMachineDefinition:DomainName'      = 'al.lab'
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2022 Standard Evaluation (Desktop Experience)'
    'Add-LabMachineDefinition:Memory'          = 2GB
}

# The machines and their roles
Add-LabMachineDefinition -Name 'ALDC1'  -Roles RootDC
Add-LabMachineDefinition -Name 'ALCA1'  -Roles CaRoot
Add-LabMachineDefinition -Name 'ALWEB1' -Roles WebServer
Add-LabMachineDefinition -Name 'ALCL1'  -OperatingSystem 'Windows 11 Enterprise Evaluation'

# Build everything, then show a summary
Install-Lab
Show-LabDeploymentSummary -Detailed
```

> **What the roles do:** `RootDC` creates the forest with DNS, `CaRoot` installs an enterprise root CA (like your [PKI lab](../adcs-pki/)), and `WebServer` installs IIS. AutomatedLab handles the unattended Windows install, the network, the domain join, and the role setup.

---

## Part 3: Build it and time it

```powershell
Measure-Command { .\ALLab.ps1 } | Select-Object TotalMinutes
```

Go do something else. The first run copies and prepares the ISOs, which takes the longest. When it finishes, the summary lists each machine, its IP address, and credentials.

### ✅ Check your work
```powershell
Get-LabVM | Select-Object Name, OperatingSystem, Roles
Invoke-LabCommand -ComputerName ALDC1 -ScriptBlock { Get-ADDomain | Select-Object DNSRoot, DomainMode } -PassThru
Invoke-LabCommand -ComputerName ALWEB1 -ScriptBlock { Get-WindowsFeature Web-Server } -PassThru
```

📸 Screenshots: the deployment summary and the elapsed time

---

## Part 4: Use and extend the lab

### Run commands across machines
`Invoke-LabCommand` runs code on lab machines without signing in to them:
```powershell
Invoke-LabCommand -ComputerName (Get-LabVM) -ScriptBlock { hostname; (Get-Date).ToString() } -PassThru
```

### Snapshot before risky experiments
```powershell
Checkpoint-LabVM -All -SnapshotName 'Clean'
# ...break something on purpose...
Restore-LabVMSnapshot -All -SnapshotName 'Clean'
```

### Add your own configuration
Add a `PostInstallationActivity` or extra `Invoke-LabCommand` calls to apply your own setup, for example the OU structure and groups from [04-New-ADStructure.ps1](../server-lab/scripts/04-New-ADStructure.ps1), adjusted for the `al.lab` domain.

### Change the design
Add a second DC with `-Roles DC`, a file server with `-Roles FileServer`, or a SQL Server role if you supply its ISO. Rebuild and compare.

---

## Part 5: Compare the three ways you've built a lab

Fill in this table from your own experience. It's a strong talking point.

| | Click-ops ([guide](../server-lab/01-clickops-guide.md)) | Your scripts ([guide](../server-lab/02-powershell-guide.md)) | AutomatedLab |
|---|---|---|---|
| Time to build | | | |
| Manual steps | Many | Windows installs only | None after starting |
| Repeatable exactly? | No | Yes | Yes |
| Easy to change the design? | No | Edit the config file | Edit the definition |
| Best for | Learning what each setting does | Your own environment, documented | Fast disposable test labs |

---

## Part 6: Clean up

```powershell
Remove-Lab -Name 'ALLab'
```
This removes the VMs, disks, and the lab network. Your `C:\LabSources` folder stays for next time.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| "Operating system not found" | Use the exact names from `Get-LabAvailableOperatingSystem`; they vary by ISO |
| Install hangs at a machine | Check the VM console in Hyper-V Manager; low host RAM is the usual cause |
| Remoting errors to lab VMs | Run `Enable-LabHostRemoting -Force` on the host, then try again |
| Not enough disk space | ISOs and base disks take tens of GB. Use a drive with plenty of free space for LabSources. |

## How to talk about it in an interview

> *"I've built the same Windows lab three ways: by hand to learn every setting, with my own PowerShell scripts driven by one config file, and with AutomatedLab, where a short definition file deploys a domain controller, CA, web server, and Windows 11 client unattended. I can rebuild a clean environment in about an hour and snapshot it before risky changes, which is how I test things before they touch production."*

## Results

_To be added after the lab is run:_
- [ ] `ALLab.ps1` as you ran it
- [ ] Build time and the completed comparison table
- [ ] Screenshots
