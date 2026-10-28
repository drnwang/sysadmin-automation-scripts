# File Services: DFS Namespaces, DFS Replication, and FSRM

Give users **one path** for shared folders no matter which server holds them (`\\lab.local\Shares\Finance`), **replicate** the data to a second file server so a server failure doesn't stop work, and **control** what gets stored with quotas and file screens. Along the way you'll build and manage your first **Server Core** machine.

> **Status:** tutorial ready. Results and screenshots to be added after the lab is run.

| | |
|---|---|
| **Role** | Sysadmin |
| **Time** | 3–4 hours |
| **Cost** | Free |
| **Builds on** | [Server lab](../server-lab/) (APP01 and the Finance share) |
| **Resume keywords** | DFS-N, DFS-R, FSRM, file server management, Server Core, NTFS and share permissions |

## Why this matters

File shares are still everywhere. Admins are expected to know how to make them highly available, migrate them without changing paths, and stop them filling up with personal music and videos. DFS also solves a classic problem: when a file server is replaced, users and scripts keep the same path.

---

## Part 1: Build FS02 on Server Core

Server Core has **no desktop**. It's smaller, needs fewer patches, and has less to attack, which is why many organizations prefer it for infrastructure roles. You manage it remotely.

| Setting | Value |
|---|---|
| VM name | `FS02` |
| CPU / RAM / disk | 2 / 2 GB / 40 GB |
| Edition | **Windows Server 2022 Standard Evaluation** (the one **without** "Desktop Experience") |
| IP address | `10.10.10.21/24`, gateway `10.10.10.1`, DNS `10.10.10.10` and `10.10.10.11` |

1. Install Windows, set the Administrator password. You land at a command prompt, and **SConfig** opens.
2. In **SConfig**, use the numbered menu:
   - **8 Network settings** → set the static IP and DNS servers.
   - **9 Date and time** → your time zone.
   - **7 Remote Desktop** → enable (optional).
   - **2 Computer name** → `FS02` → restart.
   - **1 Domain/workgroup** → join `lab.local` with `LAB\adm-nwang` → restart.
3. On DC01, in ADUC, move **FS02** from Corp\Computers to **Corp\Servers**.

### Manage FS02 from APP01
On **APP01**: **Server Manager → Manage → Add Servers** → find `FS02` → add it. You can now install roles on FS02, view its events, and open its management consoles from APP01. Also try:
```powershell
Enter-PSSession -ComputerName FS02
hostname
exit
```

### ✅ Check your work
FS02 appears in Server Manager on APP01 with a green **Online** status.

---

## Part 2: Install the file services roles

On both APP01 and FS02 (run from APP01):
```powershell
Install-WindowsFeature FS-DFS-Namespace, FS-DFS-Replication, FS-Resource-Manager -IncludeManagementTools
Install-WindowsFeature FS-DFS-Namespace, FS-DFS-Replication, FS-Resource-Manager -ComputerName FS02
```
Or in Server Manager: **Add Roles and Features** → choose the server → **File and Storage Services → File and iSCSI Services** → **DFS Namespaces**, **DFS Replication**, **File Server Resource Manager**.

---

## Part 3: Create the DFS namespace

A **namespace** is a virtual folder tree. Users see `\\lab.local\Shares\Finance`, and DFS sends them to whichever real server holds the data.

On APP01, open **DFS Management** (Tools menu):
1. **Namespaces → New Namespace** → server **APP01** → name **Shares**.
2. Edit settings: the wizard creates a share for the namespace root. Accept the defaults.
3. Type: **Domain-based namespace**, ✅ **Enable Windows Server 2008 mode** → `\\lab.local\Shares` → **Create**.
4. Add redundancy for the namespace itself: right-click `\\lab.local\Shares` → **Add Namespace Server** → **FS02**.
5. Right-click the namespace → **New Folder** → name **Finance** → **Add** target `\\APP01\Finance`.

**PowerShell equivalent** (once the root share exists on APP01):
```powershell
New-DfsnRoot   -Path '\\lab.local\Shares' -TargetPath '\\APP01\Shares' -Type DomainV2
New-DfsnFolder -Path '\\lab.local\Shares\Finance' -TargetPath '\\APP01\Finance'
```

### ✅ Check your work
On CLIENT01 as `jsmith`, open `\\lab.local\Shares\Finance`. It shows the same files as `\\APP01\Finance`.

---

## Part 4: Replicate the Finance folder to FS02

### 4.1 Create the matching share on FS02
DFS Replication copies files **and their NTFS permissions**, but not the share itself. Create the folder and share on FS02 from APP01:
```powershell
Invoke-Command -ComputerName FS02 -ScriptBlock {
    New-Item -ItemType Directory -Path 'C:\Shares\Finance' -Force | Out-Null
    New-SmbShare -Name 'Finance' -Path 'C:\Shares\Finance' -FullAccess 'BUILTIN\Administrators' `
        -ChangeAccess 'NT AUTHORITY\Authenticated Users' -FolderEnumerationMode AccessBased
}
```

### 4.2 Add the second target and replicate
1. In DFS Management, right-click the **Finance** folder → **Add Folder Target** → `\\FS02\Finance` → **OK**.
2. DFS asks: *Do you want to create a replication group?* → **Yes**. The wizard:

| Page | Setting |
|---|---|
| Replication eligibility | Both APP01 and FS02 listed |
| Primary member | **APP01** (its files win during the first sync) |
| Topology | **Full mesh** |
| Schedule and bandwidth | **Replicate continuously**, full bandwidth |

3. **Create**. Initial replication starts within a few minutes.

### ✅ Check your work
1. Create `test-from-app01.txt` in `\\APP01\Finance`. Within seconds it appears in `\\FS02\Finance`.
2. Create one on FS02 and confirm it appears on APP01.
3. Right-click the replication group → **Create Diagnostic Report** → **Health report**. It should show no errors or backlog.

> **DFS-R is not a backup.** Deleting a file deletes it on **both** servers within seconds. Keep backups (see the [backup lab](../backup-dr/)). Also, if two people edit the same file on different servers at once, the last save wins, and the other copy goes to a hidden *ConflictAndDeleted* folder.

---

## Part 5: Point users at the namespace and test failover

1. Update the **F:** drive mapping (Group Policy Preferences, [server lab 6.5](../server-lab/01-clickops-guide.md#65-bonus-map-the-finance-drive-for-finance-staff)) to `\\lab.local\Shares\Finance`.
2. On CLIENT01 as Jane, sign out and back in, then open **F:**.
3. **Failover test:** shut down **APP01**. On CLIENT01, close and reopen F:. It now serves the files from **FS02**. Clients cache which server they used for a few minutes, so it can take a moment to switch.

On the folder's **Properties → DFS** tab (in Explorer), you can see which target the client is using.

📸 Screenshots: DFS Management, the health report, the DFS tab showing FS02 during the failover test

---

## Part 6: Quotas, file screens, and reports (FSRM)

**File Server Resource Manager** controls how much is stored and what kind of files are allowed. FSRM settings aren't replicated, so apply them on **both** APP01 and FS02.

### 6.1 Quota
**Click-ops:** **File Server Resource Manager → Quota Management → Quotas → Create Quota** → path `C:\Shares\Finance` → custom properties: limit **5 GB**, **Hard quota** → add a **threshold at 85%** that writes a **warning to the event log**.

**PowerShell:**
```powershell
$action    = New-FsrmAction -Type Event -EventType Warning -Body 'Finance share is above 85% of its 5 GB quota.'
$threshold = New-FsrmQuotaThreshold -Percentage 85 -Action $action
New-FsrmQuota -Path 'C:\Shares\Finance' -Size 5GB -Threshold $threshold -Description 'Finance share limit'
```

### 6.2 File screen
Block executables and media files from the share. They're a malware risk and waste space.

**Click-ops:** **File Screening Management → File Screens → Create File Screen** → path `C:\Shares\Finance` → custom properties: **Active screening** → file groups **Executable Files** and **Audio and Video Files**.

**PowerShell:**
```powershell
New-FsrmFileScreen -Path 'C:\Shares\Finance' -IncludeGroup 'Executable Files', 'Audio and Video Files' -Active
```

### 6.3 Storage reports
**Storage Reports Management → Generate Reports Now** → `C:\Shares` → **Large Files**, **Duplicate Files**, **Files by Owner** → view the HTML reports.

### ✅ Check your work
- As Jane, copy any `.exe` or `.mp3` into F:. Windows says **access denied**: the screen blocked it.
- `Get-FsrmQuota -Path 'C:\Shares\Finance'` shows the 5 GB limit and current usage.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `\\lab.local\Shares` doesn't open | DNS and DC reachability: `nslookup lab.local`; namespace servers online? |
| Files don't replicate | Health report; check **DFS Replication** event log on both servers (Event IDs 4012, 2213 indicate stopped replication) |
| Initial sync never finishes | Large data or a missing share on FS02. Check the health report backlog. |
| Failover doesn't happen | The client is still using its cached referral. Wait a few minutes, or reopen the folder. |
| Allowed file type is blocked | Edit the file screen's file groups, or add an **exception** for a specific subfolder |

## How to talk about it in an interview

> *"I built a domain-based DFS namespace so users map one path regardless of which server holds the data, replicated the Finance folder to a second file server running Server Core, and shut down the primary to prove failover. I added FSRM quotas with threshold alerts and file screens to block executables and media, and I know DFS-R isn't a backup, since deletions replicate too."*

## Results

_To be added after the lab is run:_
- [ ] Screenshots: SConfig, DFS Management, the health report, failover, the file screen blocking a file
- [ ] Storage report highlights
