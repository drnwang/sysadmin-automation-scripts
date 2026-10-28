# Backup and Disaster Recovery

Protect the lab with layered backups, then **break things on purpose** and restore them: a deleted user, a deleted file, a damaged domain controller, and a whole VM. You'll finish with a recovery runbook, the document a team reaches for during a real outage.

> **Status:** tutorial ready. Results and screenshots to be added after the lab is run.

| | |
|---|---|
| **Role** | Sysadmin |
| **Time** | A weekend |
| **Cost** | Free (Windows Server Backup is built in; Veeam Community Edition is free for up to 10 workloads) |
| **Builds on** | [Server lab](../server-lab/); [second DC lab](../second-dc/) recommended |
| **Resume keywords** | Backup and recovery, AD Recycle Bin, system state, DSRM, Volume Shadow Copy, Veeam, RPO/RTO, runbooks |

## Why this matters

"Tell me about a time you restored something" is one of the most common sysadmin interview questions. Most candidates have never actually done it. This lab gives you four real stories, plus the vocabulary (RPO, RTO, 3-2-1, authoritative restore) that shows you think about recovery before something breaks.

## Key terms first

| Term | Meaning |
|---|---|
| **RPO** (Recovery Point Objective) | How much data you can afford to lose. Nightly backups mean an RPO of up to 24 hours. |
| **RTO** (Recovery Time Objective) | How long you can afford to be down while restoring |
| **3-2-1 rule** | 3 copies of data, on 2 different types of media, with 1 copy offsite (or offline) |
| **System state** | The parts of Windows a DC needs to rebuild AD: the AD database, SYSVOL, registry, and boot files |

---

## Part 1: Restore a deleted user with the AD Recycle Bin

Without the Recycle Bin, a deleted user comes back without its group memberships and attributes. With it, the user comes back exactly as it was.

### 1.1 Turn on the Recycle Bin
> ⚠️ Once turned on, it **can't be turned off**. That's fine, and it's best practice in every domain.

**Click-ops:** **Active Directory Administrative Center** (`dsac.exe`) → select **lab (local)** in the left pane → **Enable Recycle Bin** in the right pane → **OK**. Refresh.

**PowerShell:**
```powershell
Enable-ADOptionalFeature -Identity 'Recycle Bin Feature' -Scope ForestOrConfigurationSet -Target 'lab.local'
```

### 1.2 Delete a user, then bring them back
1. Create a test user with a group membership:
   ```powershell
   New-ADUser -Name 'Test Restore' -SamAccountName trestore -Path 'OU=Finance,OU=Users,OU=Corp,DC=lab,DC=local'
   Add-ADGroupMember -Identity GG-Finance-Staff -Members trestore
   ```
2. Delete it: ADUC → right-click → **Delete** (you'll need to clear *Protect from accidental deletion* if it's set).
3. **Restore it:**
   - **Click-ops:** ADAC → **lab (local) → Deleted Objects** → right-click **Test Restore** → **Restore**.
   - **PowerShell:**
     ```powershell
     Get-ADObject -Filter "samAccountName -eq 'trestore'" -IncludeDeletedObjects | Restore-ADObject
     ```

### ✅ Check your work
```powershell
Get-ADUser trestore -Properties MemberOf | Select-Object Name, DistinguishedName, MemberOf
```
The user is back in the **Finance** OU, **with** its `GG-Finance-Staff` membership.

---

## Part 2: Restore a deleted file with Previous Versions

This is the fix for [mock ticket #15](../../helpdesk/ticketing-osticket/mock-tickets.md) ("I accidentally deleted a spreadsheet from the share"), and users can do it themselves.

### 2.1 Turn on Shadow Copies for the share's drive
On **APP01**: File Explorer → right-click **C:** → **Configure Shadow Copies** → select **C:\\** → **Enable**. Then **Settings → Schedule**: the default is 7:00 AM and 12:00 PM on weekdays. Click **Create Now** for a first copy.

> In production, put file shares on their own data drive (for example `D:`) and enable shadow copies there, not on the system drive.

### 2.2 Delete and restore
1. As `jsmith` on CLIENT01, save `budget.txt` to `\\APP01\Finance`.
2. On APP01, click **Create Now** in the Shadow Copies dialog.
3. As Jane, delete `budget.txt`.
4. In Explorer, right-click the **Finance** folder → **Properties → Previous Versions** → pick the snapshot → **Open** → copy `budget.txt` back.

### ✅ Check your work
Jane recovered her own file without a ticket. Write a short [KB article](../../helpdesk/knowledge-base/) so other users can do the same.

---

## Part 3: Back up domain controller system state

A system state backup is how you rebuild Active Directory on a DC.

1. Give **DC01** a second virtual disk (20 GB). In **Disk Management**, bring it online, initialize it, and create a volume `E:`.
2. Install the feature: **Add Roles and Features → Features → Windows Server Backup** (or `Install-WindowsFeature Windows-Server-Backup`).
3. **Schedule** a nightly backup: `wbadmin.msc` → **Backup Schedule** → **Custom** → **Add Items → System state** → **Once a day, 9:00 PM** → **Back up to a volume** → `E:`.
4. Run one **now** so you have something to restore:
   ```cmd
   wbadmin start systemstatebackup -backupTarget:E: -quiet
   ```

### ✅ Check your work
```cmd
wbadmin get versions -backupTarget:E:
```
Lists your backup with its version identifier (a date and time). You'll need it in Part 4.

---

## Part 4: Restore a domain controller (DSRM)

When a DC's copy of AD is damaged, you restore system state in **Directory Services Restore Mode (DSRM)**. You set the DSRM password when you promoted the DC.

> 💾 **Take a checkpoint of DC01 first** so you can undo the whole exercise.

### 4.1 Non-authoritative restore (the normal case)
The DC goes back to the backup, then **catches up** with newer changes from DC02. Use this when one DC is damaged but the others are healthy.

1. On DC01, set the next boot to DSRM and restart:
   ```cmd
   bcdedit /set safeboot dsrepair
   shutdown /r /t 0
   ```
2. Sign in as **`.\Administrator`** with the **DSRM password** (not the domain admin password).
3. Find the version and restore it:
   ```cmd
   wbadmin get versions -backupTarget:E:
   wbadmin start systemstaterecovery -version:<version-from-the-list> -backupTarget:E: -quiet
   ```
4. Set the DC to boot normally again and restart:
   ```cmd
   bcdedit /deletevalue safeboot
   shutdown /r /t 0
   ```
5. Sign in to the domain and run `repadmin /replsummary`. DC01 replicates recent changes from DC02.

### 4.2 Authoritative restore (the special case)
Imagine someone deleted an entire OU **before** the Recycle Bin was enabled. A normal restore would bring the OU back, but then DC02 (which "knows" it was deleted) would delete it again during replication. An **authoritative** restore marks the restored objects as newer so they win:
```cmd
ntdsutil
activate instance ntds
authoritative restore
restore subtree "OU=Finance,OU=Users,OU=Corp,DC=lab,DC=local"
quit
quit
```
You'd run this in DSRM **after** step 3 and **before** restarting. With the Recycle Bin on (Part 1), you'll rarely need it, but knowing when and why to use it is a strong interview answer.

> ⚠️ **Never restore a DC from a VM snapshot or checkpoint as a backup method.** In a multi-DC domain, rolling a DC back can cause a **USN rollback**, where it silently stops replicating correctly. Modern Hyper-V and VMware use *VM-Generation ID* to guard against this, but system state backups remain the supported method.

---

## Part 5: Whole-VM backups with Veeam Community Edition

1. Download **Veeam Backup & Replication Community Edition** (free; requires a Veeam account).
2. Install it on your **PC** (the Hyper-V host), or on a separate VM with a large backup disk.
3. **Inventory → Add Server → Microsoft Hyper-V** → add your Hyper-V host.
4. **Home → Backup Job → Virtual machine**: include **DC01** and **APP01**. Under **Guest Processing**, enable **application-aware processing** with domain admin credentials. This makes AD-consistent backups.
5. Run the job.
6. Test two restores:
   - **File-level restore**: recover a single file from APP01's backup.
   - **Instant VM Recovery** or a full restore of APP01 under a new name, then delete it.

> Free for up to 10 workloads, which covers the whole lab.

---

## Part 6: Write the recovery runbook

Create `RUNBOOK.md` in this folder with one section per scenario you tested:

```markdown
## Scenario: <for example "Deleted user account">
**Detect:** How would we know? (ticket, monitoring alert)
**RPO / RTO:** <data loss we accept> / <downtime we accept>
**Restore steps:** numbered, copy-paste ready
**Verify:** how to prove it worked
**Time it took in the lab:** <minutes>
**Who to notify:** <roles>
```

Cover at least: deleted user, deleted file, failed DC, failed app server. **Time each restore.** "I restored the app server in 22 minutes" is a great interview line.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| "Enable Recycle Bin" is grayed out | Forest functional level must be Windows Server 2008 R2 or higher (the lab uses 2016) |
| Deleted object isn't in Deleted Objects | It was deleted before the Recycle Bin was enabled. You need an authoritative restore (Part 4.2). |
| Can't sign in to DSRM | Use `.\Administrator` and the **DSRM** password, not a domain account |
| DC stuck booting into DSRM | `bcdedit /deletevalue safeboot`, then restart |
| No Previous Versions tab | Shadow copies aren't enabled on the drive holding the share, or none have been created yet |

## How to talk about it in an interview

> *"I tested four recovery scenarios in my lab: restoring a deleted user with the AD Recycle Bin, so its group memberships came back too; restoring a file with Previous Versions; a non-authoritative system state restore of a domain controller in DSRM; and full VM recovery with Veeam. I documented each in a runbook with RPO and RTO targets, and I timed every restore."*

## Results

_To be added after the lab is run:_
- [ ] Screenshots: Recycle Bin restore, Previous Versions, wbadmin versions, DSRM restore, Veeam job
- [ ] `RUNBOOK.md` with timed restores
