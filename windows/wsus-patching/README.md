# Patch Management with WSUS

Run patching the way most on-premises Windows shops do: **Windows Server Update Services (WSUS)** downloads updates from Microsoft, you approve them, and Group Policy tells each computer where to get them and when to install. You'll patch workstations first as a **pilot** ring, then servers in **production**, and report compliance.

> **Status:** tutorial ready. Results and screenshots to be added after the lab is run.

| | |
|---|---|
| **Role** | Sysadmin |
| **Time** | 4–6 hours (plus waiting for the first sync) |
| **Cost** | Free |
| **Builds on** | [Server lab](../server-lab/) |
| **Resume keywords** | WSUS, patch management, update rings, Group Policy, client-side targeting, compliance reporting |

## Why this matters

Unpatched systems are the root cause behind a large share of breaches, and patching is a core sysadmin duty. This lab connects to your background (BigFix, SCCM ADRs, ACAS findings) and gives you hands-on WSUS, which many government and enterprise networks still run.

> **Where WSUS is heading:** Microsoft announced in 2024 that WSUS is deprecated: it's still supported and widely used, but gets no new features. Cloud options are Windows Update for Business and Windows Autopatch (managed through Intune) for workstations, and Azure Update Manager for servers. The concepts you learn here (rings, approvals, deadlines, compliance) carry straight over.

---

## Part 1: Install WSUS on APP01

WSUS can store update files locally (lots of disk space) or let computers download them straight from Microsoft while still taking **approvals** from your server. For the lab, give APP01 a dedicated disk:

1. Add a **40 GB** virtual disk to APP01 and create volume `D:` in **Disk Management**.
2. **Add Roles and Features** → **Windows Server Update Services** → accept the added features.
3. Role services: **WID Connectivity** and **WSUS Services** (WID is the built-in Windows Internal Database, so no SQL Server is needed).
4. Content location: `D:\WSUS`.
5. Install, then click **Launch Post-Installation tasks** from the yellow flag.

**PowerShell equivalent:**
```powershell
Install-WindowsFeature UpdateServices -IncludeManagementTools
& 'C:\Program Files\Update Services\Tools\wsusutil.exe' postinstall CONTENT_DIR=D:\WSUS
```

---

## Part 2: Configure what WSUS downloads

Open **Windows Server Update Services** from the Tools menu. The configuration wizard starts:

| Page | Setting | Why |
|---|---|---|
| Upstream server | **Synchronize from Microsoft Update** | This is the top-level WSUS server |
| Proxy | None | |
| Connect | **Start Connecting** (takes several minutes) | Downloads the list of products and categories |
| Languages | **English** only | Every extra language multiplies the download size |
| Products | **Windows 11** and **Microsoft Server operating system-21H2** (that's Windows Server 2022's name in WSUS). Uncheck everything else. | Only what the lab runs |
| Classifications | **Critical Updates**, **Security Updates**, **Definition Updates** | The essentials. Feature upgrades and drivers are out of scope. |
| Sync schedule | **Synchronize automatically**, once a day | |
| Finish | ✅ **Begin initial synchronization** | |

The first sync can take an hour or more. Check progress under **Synchronizations**.

> **The biggest WSUS mistake** is selecting too many products and classifications. The database bloats, the console slows down, and the disk fills. Start narrow.

---

## Part 3: Create update rings (computer groups)

1. In the WSUS console: **Computers → All Computers** → right-click → **Add Computer Group**:
   - `Pilot`: workstations get updates first
   - `Production`: servers get updates after the pilot proves them safe
2. **Options → Computers** → **Use Group Policy or registry settings on computers**.

> This is **client-side targeting**: each computer tells WSUS which group it belongs to, based on Group Policy. You never drag computers between groups by hand.

---

## Part 4: Point computers at WSUS with Group Policy

Create **two** GPOs on DC01, so workstations and servers behave differently.

The settings are under **Computer Configuration → Policies → Administrative Templates → Windows Components → Windows Update** (on newer templates, some are in the **Manage updates offered from Windows Server Update Service** and **Manage end user experience** subfolders).

### 4.1 `Corp - WSUS Workstations (Pilot)`, linked to **Corp\Computers**

| Setting | Value |
|---|---|
| Specify intranet Microsoft update service location | Enabled. Both boxes: `http://app01.lab.local:8530` |
| Enable client-side targeting | Enabled: `Pilot` |
| Configure Automatic Updates | Enabled: **4 – Auto download and schedule the install**, every day, **03:00** |

### 4.2 `Corp - WSUS Servers (Production)`, linked to **Corp\Servers**

| Setting | Value |
|---|---|
| Specify intranet Microsoft update service location | Same as above |
| Enable client-side targeting | Enabled: `Production` |
| Configure Automatic Updates | Enabled: **3 – Auto download and notify for install** |

> **Why different behavior?** Workstations can install and restart overnight. Servers usually restart only in an agreed **maintenance window**, by an admin, so they download automatically but wait for you.

### 4.3 Make the computers check in
On CLIENT01 and APP01:
```cmd
gpupdate /force
reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate
```
The registry should show `WUServer` pointing at `app01.lab.local:8530` and the right `TargetGroup`. Then trigger a scan: **Settings → Windows Update → Check for updates**.

### ✅ Check your work
Within about 15–30 minutes, the WSUS console shows CLIENT01 in **Pilot** and APP01, DC01, and DC02 in **Production**. In PowerShell on APP01:
```powershell
Get-WsusComputer | Select-Object FullDomainName, RequestedTargetGroupName, LastReportedStatusTime
```

---

## Part 5: Approve updates in rings

### 5.1 Approve for Pilot
1. **Updates → Security Updates** → set the filter to **Approval: Unapproved**, **Status: Failed or Needed**.
2. Select the updates → right-click → **Approve** → **Pilot → Approved for Install**. Optionally set a **deadline** (for example 2 days), after which installation is forced.

PowerShell does the same in one line:
```powershell
Get-WsusUpdate -Classification Security -Approval Unapproved -Status FailedOrNeeded |
    Approve-WsusUpdate -Action Install -TargetGroupName 'Pilot'
```

### 5.2 Let the pilot run, then approve Production
In real environments, the pilot runs for a few days while you watch for problems (broken apps, boot issues, help desk tickets). In the lab, confirm CLIENT01 installed the updates and restarted cleanly, then approve the same updates for **Production**. On the servers, install during your "maintenance window" from **Settings → Windows Update**.

### 5.3 Automate the routine part
**Options → Automatic Approvals** → edit the default rule: **Critical Updates** and **Security Updates** → approve for **Pilot**. Production approvals stay manual. That's a common real-world split.

---

## Part 6: Report compliance

1. In the console, select a computer group → set the status filter to **Any** → review the **Status** columns per computer.
2. For graphical reports (**Reports → Update Status Summary**), WSUS needs two free add-ons installed on APP01: **Microsoft Report Viewer 2012 Runtime** and **Microsoft System CLR Types for SQL Server 2012**. The console tells you if they're missing.
3. Quick PowerShell checks:
   ```powershell
   Get-WsusComputer -ComputerUpdateStatus Failed         # computers with failed installs
   Get-WsusComputer -ComputerUpdateStatus Needed         # computers still missing approved updates
   ```

Write a short **patch compliance summary**: which machines are fully patched, which aren't, and why. It's the same report your ACAS and Nessus experience feeds into.

---

## Part 7: Keep WSUS healthy

WSUS slows down over time if you never clean it up. Run the cleanup monthly:

**Click-ops:** **Options → Server Cleanup Wizard** → check every box → **Next**.

**PowerShell:**
```powershell
Invoke-WsusServerCleanup -DeclineSupersededUpdates -CleanupObsoleteUpdates -CleanupUnneededContentFiles -CompressUpdates
```

"Superseded" updates have been replaced by newer ones (for example last month's cumulative update), so declining them is safe and keeps the console fast.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| Computers never appear in WSUS | `gpresult /r` to confirm the GPO applied; check the `WUServer` registry value; check port 8530 with `Test-NetConnection app01 -Port 8530` |
| Computer appears in **Unassigned Computers** | Client-side targeting isn't set, or the group name in the GPO doesn't exactly match the WSUS group |
| Updates show as **Needed** but never install | They aren't approved for that group, or the client is still downloading. Check **Settings → Windows Update**. |
| Console is very slow or times out | Run the cleanup (Part 7); reduce products and classifications |
| Sync fails | APP01 needs internet access; check **Synchronizations** for the error |

## How to talk about it in an interview

> *"I built a WSUS patching setup with two rings: workstations in a pilot group that auto-install overnight, and servers in production that download but wait for a maintenance window. Group Policy handles the targeting, so computers land in the right group automatically. I approved updates to the pilot, then promoted them to production, reported compliance, and ran monthly cleanups. I also know WSUS is deprecated, so the next step is Windows Update for Business or Autopatch through Intune, which uses the same ring concepts."*

## Results

_To be added after the lab is run:_
- [ ] Screenshots: WSUS groups with computers, approvals, GPO settings, compliance view
- [ ] Patch compliance summary
