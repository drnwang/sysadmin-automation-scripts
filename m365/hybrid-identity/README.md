# Hybrid Identity with Microsoft Entra Connect

Connect the on-premises `lab.local` Active Directory to your Microsoft 365 tenant so each employee has **one account and one password** for both their Windows sign-in and Microsoft 365. You'll prepare AD, install and configure **Entra Connect Sync** with password hash sync and password writeback, then watch changes flow between the two directories.

> **Status:** tutorial ready. Results and screenshots to be added after the lab is run.

| | |
|---|---|
| **Role** | Sysadmin |
| **Time** | 3–4 hours |
| **Cost** | Free (uses the same trial tenant) |
| **Builds on** | [Server lab](../../windows/server-lab/) and [Microsoft 365 admin lab](../m365-admin/) |
| **Resume keywords** | Hybrid identity, Microsoft Entra Connect, password hash sync, password writeback, UPN suffixes, OU filtering, directory synchronization |

## Why this matters

Most organizations with on-premises Active Directory are **hybrid**: AD stays the source of truth, and accounts sync to Microsoft 365. Sysadmins are expected to understand how that sync works, why a user "can't change their name in the cloud," and how to fix sync errors. It's also where your on-premises and cloud skills meet on a resume.

---

## Part 1: Plan

| Decision | Lab choice | Why |
|---|---|---|
| Sync tool | **Entra Connect Sync** on APP01 | The full-featured, widely deployed tool. (Entra **Cloud Sync** is a lighter agent-based alternative worth reading about.) |
| Sign-in method | **Password hash synchronization** | Simplest and most resilient: cloud sign-in works even if on-premises is down |
| What to sync | Only **Corp\Users** and **Corp\Groups** | Never sync service accounts, admins, or built-in objects |
| Password writeback | **On** | Users who reset their password in the cloud can use it on-premises too |

> **Before you start:** delete the cloud-only test users you created in the [Microsoft 365 lab](../m365-admin/) (Jane, Marcus, and the others). If they stay, the synced on-premises accounts with the same names can clash. Keep your admin and break-glass accounts.

---

## Part 2: Prepare Active Directory

### 2.1 Fix the UPN suffix
On-premises users sign in as `jsmith@lab.local`, but `.local` isn't a real internet domain, so Microsoft 365 can't use it. Give users a **routable UPN suffix** that the tenant recognizes. In the lab, use the tenant's own `onmicrosoft.com` domain. In production, you'd use your company's verified domain, like `company.com`.

**Click-ops:** **Active Directory Domains and Trusts** → right-click the top node → **Properties** → **UPN Suffixes** → add `labnwang.onmicrosoft.com`.

**PowerShell:**
```powershell
Get-ADForest | Set-ADForest -UPNSuffixes @{ Add = 'labnwang.onmicrosoft.com' }
```

Then change the users' UPNs, and give them email addresses:
```powershell
$suffix = 'labnwang.onmicrosoft.com'
Get-ADUser -Filter * -SearchBase 'OU=Users,OU=Corp,DC=lab,DC=local' | ForEach-Object {
    Set-ADUser $_ -UserPrincipalName "$($_.SamAccountName)@$suffix" -EmailAddress "$($_.SamAccountName)@$suffix"
}
```

> Users can still sign in to Windows as `LAB\jsmith`. The UPN change affects cloud sign-in names only.

### 2.2 Check for problem objects
Microsoft's free **IdFix** tool (on Microsoft's GitHub) scans AD for attributes that break sync: duplicate addresses, invalid characters, too-long values. Run it against the Corp OU and fix anything it reports.

### ✅ Check your work
```powershell
Get-ADUser -Filter * -SearchBase 'OU=Users,OU=Corp,DC=lab,DC=local' | Select-Object SamAccountName, UserPrincipalName
```
Every user shows `@labnwang.onmicrosoft.com`.

---

## Part 3: Install and configure Entra Connect Sync

1. On **APP01**, download **Microsoft Entra Connect Sync** from the **Entra admin center → Identity → Hybrid management → Microsoft Entra Connect → Connect Sync** (download link).
2. Run the installer → agree → **Customize** (not Express, which syncs everything).
3. Work through the wizard:

| Page | Setting |
|---|---|
| Required components | Defaults |
| User sign-in | **Password Hash Synchronization** |
| Connect to Microsoft Entra ID | Your tenant **Global Administrator** (or Hybrid Identity Administrator) |
| Connect your directories | Forest `lab.local` → **Add Directory** → **Create new AD account** → enter `LAB\Administrator` (Enterprise Admin; the wizard creates a dedicated sync account) |
| Microsoft Entra sign-in configuration | `labnwang.onmicrosoft.com` shows **Verified**; user principal name attribute: `userPrincipalName` |
| Domain and OU filtering | **Sync selected domains and OUs** → check only **Corp → Users** and **Corp → Groups** |
| Identifying users | Defaults |
| Filter users and devices | Synchronize all users and devices (in the selected OUs) |
| Optional features | ✅ **Password hash synchronization**, ✅ **Password writeback** |
| Ready to configure | ✅ **Start the synchronization process when configuration completes** → **Install** |

### ✅ Check your work
1. **Microsoft 365 admin center → Users → Active users**: Jane, Marcus, Priya, Dana, Carlos, and Nathaniel appear with **Sync status: Synced from on-premises**.
2. **Entra admin center → Hybrid management → Microsoft Entra Connect**: Connect Sync shows **Enabled**, with a recent sync time.
3. On APP01:
   ```powershell
   Import-Module ADSync
   Get-ADSyncScheduler | Select-Object SyncCycleEnabled, CurrentlyEffectiveSyncCycleInterval, NextSyncCycleStartTimeInUTC
   ```

📸 Screenshots: OU filtering page, synced users in the admin center

---

## Part 4: Give synced users licenses

Use **group-based licensing** (included with Entra ID P1), so new hires get a license just by being in the right group.

1. **Entra admin center → Groups** → find the synced `GG-Finance-Staff` group → **Licenses → Assignments** → **Microsoft 365 Business Premium**.
2. Repeat for `GG-HR-Staff` and `GG-IT-Staff`.

### ✅ Check your work
Sign in to **office.com** in a private window as `jsmith@labnwang.onmicrosoft.com` with Jane's **on-premises AD password**. It works: one account, one password.

---

## Part 5: Watch changes flow

The sync runs every **30 minutes** by default. Password hashes sync about every **2 minutes**. To skip the wait, run a delta sync on APP01:
```powershell
Start-ADSyncSyncCycle -PolicyType Delta
```

| Test | Do this on-premises | Expected in the cloud |
|---|---|---|
| Attribute change | Change Priya's **Title** in ADUC | Updated title after a sync |
| Password change | Reset Marcus's password in ADUC | New password works at office.com within a couple of minutes |
| New hire | Create a user in `Corp\Users\HR` and add to `GG-HR-Staff` | User appears, licensed automatically |
| Departure | **Disable** Jane in AD | Jane is blocked in Microsoft 365 after a sync |
| Out of scope | Move a test user out of `Corp\Users` | The cloud account is deleted (soft-deleted for 30 days) |

### Source of authority
Open a synced user in the Microsoft 365 admin center and try to change their name or title. You can't: those fields are managed **on-premises**. This explains a classic help desk ticket: "Why can't you just change my name in Teams?" (Answer: change it in AD, and it syncs.)

---

## Part 6: Password writeback and self-service reset

1. **Entra admin center → Protection → Password reset → Properties** → **Self-service password reset enabled: Selected** → `SG-Intune-Pilot-Users` (or create a group with Jane in it).
2. **Password reset → On-premises integration** → ✅ **Enable password write back for synced users**.
3. As Jane, go to **https://aka.ms/sspr** → reset her password with her MFA method.
4. On **CLIENT01**, sign in as `LAB\jsmith` with the **new** password. It works, because it was written back to AD.

> Self-service password reset is one of the biggest ticket reducers there is. Password resets are often the single largest ticket category on a help desk.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| Users don't appear in the cloud | Are they in the selected OUs? Check **Synchronization Service Manager** (`miisclient.exe`) → Operations for errors |
| Sync error: duplicate attribute | Another object (often a leftover cloud user) has the same UPN or email. Delete or fix it, then sync. |
| Users show `@labnwang.onmicrosoft.com` but with odd names | The on-premises UPN didn't match a verified domain when they first synced. Fix the UPN, then sync. |
| Cloud sign-in fails with the AD password | Wait a few minutes for password hash sync; check `Get-ADSyncScheduler` and the Application event log on APP01 |
| Sync errors listed in Entra | **Entra admin center → Hybrid management → Microsoft Entra Connect → Connect Sync → Sync errors** lists each object and the reason |

## How to talk about it in an interview

> *"I set up hybrid identity between on-premises AD and Microsoft 365 with Entra Connect Sync: added a routable UPN suffix, cleaned objects with IdFix, scoped sync to just the user and group OUs, and enabled password hash sync and password writeback. I licensed users through synced groups, so onboarding in AD automatically provisions Microsoft 365, and I tested the full lifecycle, from attribute changes and password resets to disabling a departing user."*

## Results

_To be added after the lab is run:_
- [ ] Screenshots: UPN suffix, OU filtering, synced users, group-based licensing, SSPR writeback test
- [ ] The lifecycle test table, filled in with what you observed
