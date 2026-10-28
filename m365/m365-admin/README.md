# Microsoft 365 Administration

Run a Microsoft 365 tenant the way a small company's IT admin does: users and licenses, groups and shared mailboxes, Teams and OneDrive settings, least-privilege admin roles, and MFA enforced with Conditional Access. Then practice the everyday help desk tasks that come up in cloud environments.

> **Status:** tutorial ready. Results and screenshots to be added after the lab is run.

| | |
|---|---|
| **Role** | Help desk, sysadmin |
| **Time** | A weekend |
| **Cost** | Free trial (about one month). Do the [Intune](../intune-autopilot/) and [hybrid identity](../hybrid-identity/) labs in the same trial. |
| **Builds on** | Nothing required; the [knowledge base](../../helpdesk/knowledge-base/) articles reference this lab |
| **Resume keywords** | Microsoft 365 admin center, Entra ID, Exchange Online, Teams, SharePoint/OneDrive, Conditional Access, MFA, Microsoft Graph PowerShell |

## Why this matters

Almost every help desk and sysadmin job posting you've looked at lists Microsoft 365. Interviewers ask practical questions: "How do you give someone access to a shared mailbox?", "What do you do when someone leaves?", "How do you enforce MFA?" This lab gives you hands-on answers.

> **Plan your trial.** Sign-up may ask for a payment method. Set a calendar reminder a few days before the trial ends to cancel it, and do the three Microsoft 365 labs back to back.

---

## Part 1: Create the tenant

1. Search for **Microsoft 365 Business Premium free trial** on microsoft.com and start the trial.
2. Choose a tenant name, for example `labnwang`. Your domain becomes `labnwang.onmicrosoft.com`. This can't be changed later.
3. Create your first admin account, for example `admin@labnwang.onmicrosoft.com`.

### Create a break-glass account right away
A **break-glass** (emergency access) account is a cloud-only Global Administrator you'll exclude from Conditional Access, so a misconfigured policy can never lock everyone out.

1. **Microsoft 365 admin center → Users → Active users → Add a user**: `breakglass@labnwang.onmicrosoft.com`, a very long random password stored safely offline.
2. Give it the **Global Administrator** role.
3. Don't use it day to day.

---

## Part 2: Learn the admin centers

Microsoft 365 is managed through several portals. Visit each once so you know where things live:

| Admin center | Address | Used for |
|---|---|---|
| Microsoft 365 admin center | admin.microsoft.com | Users, licenses, billing, service health |
| Microsoft Entra admin center | entra.microsoft.com | Identity: users, groups, roles, Conditional Access, sign-in logs |
| Exchange admin center | admin.exchange.microsoft.com | Mailboxes, shared mailboxes, mail flow, message trace |
| Teams admin center | admin.teams.microsoft.com | Teams policies, meetings, external access |
| SharePoint admin center | Linked from the M365 admin center | Sharing settings, OneDrive, sites |
| Intune admin center | intune.microsoft.com | Devices and apps (see the [Intune lab](../intune-autopilot/)) |

---

## Part 3: Users and licenses

### 3.1 Create the lab users
Create the same people as the on-premises lab:

| Name | Username | Department | Job title |
|---|---|---|---|
| Jane Smith | jsmith | Finance | Financial Analyst |
| Marcus Johnson | mjohnson | Finance | Finance Manager |
| Priya Patel | ppatel | HR | HR Generalist |
| Dana Lee | dlee | HR | HR Manager |
| Carlos Reyes | creyes | IT | Help Desk Technician |

**Click-ops:** **Users → Active users → Add a user** → names, username → **Assign product license: Microsoft 365 Business Premium** → **Optional settings**: job title and department → **Finish adding**.

> **Usage location** matters: a license can't be assigned until the user has one. The admin center sets it from the tenant's country.

**PowerShell (Microsoft Graph):**
```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
Connect-MgGraph -Scopes 'User.ReadWrite.All', 'Organization.Read.All'

$domain = 'labnwang.onmicrosoft.com'   # your tenant
$sku    = Get-MgSubscribedSku | Where-Object SkuPartNumber -eq 'SPB'   # SPB = Microsoft 365 Business Premium

$pw = @{ Password = 'Temp-Lab-Pass-2026!'; ForceChangePasswordNextSignIn = $true }
$user = New-MgUser -DisplayName 'Jane Smith' -GivenName 'Jane' -Surname 'Smith' `
    -UserPrincipalName "jsmith@$domain" -MailNickname 'jsmith' -AccountEnabled `
    -Department 'Finance' -JobTitle 'Financial Analyst' -UsageLocation 'US' -PasswordProfile $pw

Set-MgUserLicense -UserId $user.Id -AddLicenses @(@{ SkuId = $sku.SkuId }) -RemoveLicenses @()
```

> If you'll do the [hybrid identity lab](../hybrid-identity/) later, **delete these cloud users first**. Otherwise the synced on-premises users clash with them.

### ✅ Check your work
**Billing → Licenses** shows 5 (plus your admin) of 25 Business Premium licenses assigned.

---

## Part 4: Groups and shared mailboxes

### 4.1 Know the group types

| Type | Gives you | Use for |
|---|---|---|
| **Microsoft 365 group** | Shared mailbox, calendar, files, and an optional Team | Team collaboration |
| **Security group** | Access to apps, files, and policies | Permissions and policy targeting |
| **Distribution list** | Email to many people | Announcements |
| **Shared mailbox** | One mailbox several people use, with no license needed | finance@, helpdesk@ |

### 4.2 Create them
1. **Teams & groups → Active teams & groups → Add a group**:
   - Microsoft 365 group **Finance Team** (owner Marcus, members Jane and Marcus) → ✅ *Create a team for this group*.
   - Distribution list **All Staff** (`allstaff@`) with all five users.
   - Security group **SG-Finance** with Jane and Marcus.
2. **Shared mailbox:** **Teams & groups → Shared mailboxes → Add a shared mailbox** → **Finance Shared**, `finance@` → add Jane and Marcus as members.

**PowerShell (Exchange Online):**
```powershell
Install-Module ExchangeOnlineManagement -Scope CurrentUser
Connect-ExchangeOnline

New-Mailbox -Shared -Name 'Finance Shared' -PrimarySmtpAddress 'finance@labnwang.onmicrosoft.com'
Add-MailboxPermission   -Identity 'finance' -User 'jsmith' -AccessRights FullAccess -InheritanceType All
Add-RecipientPermission -Identity 'finance' -Trustee 'jsmith' -AccessRights SendAs -Confirm:$false
```

> **Full Access** lets someone open the mailbox. **Send As** lets them send email that appears to come from it. **Send on Behalf** shows "Jane on behalf of Finance." Help desks get asked for all three, and they're different.

### ✅ Check your work
Sign in to **outlook.office.com** as Jane. **Finance Shared** appears in her folder list automatically (thanks to Full Access with automapping, which can take up to an hour).

---

## Part 5: Teams, SharePoint, and OneDrive settings

1. **Teams admin center → Users → External access**: allow federation with **specific domains only** (add a partner domain as an example) rather than all external domains.
2. **SharePoint admin center → Policies → Sharing**: set external sharing for SharePoint and OneDrive to **New and existing guests** (not *Anyone*), so anonymous links can't be created.
3. **SharePoint admin center → Settings → OneDrive → Retention**: set deleted users' OneDrive retention to **90 days**, giving managers time to collect files after someone leaves ([KB-010](../../helpdesk/knowledge-base/KB-010-departure-checklist.md)).

---

## Part 6: Least-privilege admin roles

Give Carlos what a help desk tech needs, and nothing more.

1. **Entra admin center → Roles & admins → Helpdesk Administrator → Add assignments** → Carlos.
2. Sign in as Carlos in a private browser window. Reset **Jane's** password: it works. Try to reset **your admin's** password: it fails. Helpdesk Administrators can only reset non-admins and some lower-level admins.

> Most breaches of cloud tenants abuse **over-privileged** accounts. "Who has Global Admin, and why?" is an excellent question to ask in any new job.

---

## Part 7: MFA with Conditional Access

Business Premium includes **Entra ID P1**, so you can use **Conditional Access**: rules like "require MFA for everyone, everywhere."

1. **Turn off security defaults** (they're replaced by your policies): **Entra admin center → Overview → Properties → Manage security defaults → Disabled** → reason: *My organization is using Conditional Access*.
2. **Entra admin center → Protection → Conditional Access → Create new policy**:

| Setting | Value |
|---|---|
| Name | `CA01 - Require MFA for all users` |
| Users | Include **All users**; **Exclude** `breakglass` |
| Target resources | **All resources** (all cloud apps) |
| Grant | **Require multifactor authentication** |
| Enable policy | **Report-only** first |

3. Create a second policy, `CA02 - Block legacy authentication`: All users (exclude break-glass), all resources, **Conditions → Client apps** → *Exchange ActiveSync clients* and *Other clients* → **Block access**. Report-only first.
4. Sign in as Jane a few times, then check **Entra → Sign-in logs → (a sign-in) → Report-only** to see what the policies **would** have done.
5. Switch both policies to **On**. Jane is now prompted to set up Microsoft Authenticator at next sign-in (follow [KB-002](../../helpdesk/knowledge-base/KB-002-mfa-new-phone.md), Part A).

> **Always start in Report-only, and always exclude break-glass.** A Conditional Access mistake can lock out the entire company, including you.

### ✅ Check your work
A sign-in as Jane in a private window requires MFA. **Sign-in logs** show **Conditional Access: Success** with your CA01 policy applied.

📸 Screenshots: the CA policy settings, a sign-in log entry showing the policy result

---

## Part 8: Practice everyday help desk tasks

Do each one, and note where in the portals you did it:

| Task | Where |
|---|---|
| Reset a password and require a change | M365 admin center → Users → user → **Reset password** |
| Block sign-in for a compromised account | User → **Block sign-in**; then Entra → user → **Revoke sessions** |
| Re-register a user's MFA | Entra → user → **Authentication methods → Require re-register MFA** |
| Find out why a sign-in failed | Entra → **Sign-in logs** → filter by user → *Failure reason* |
| Trace a missing email | Exchange admin center → **Mail flow → Message trace** |
| Offboard a user | Convert mailbox to shared, remove license, give manager OneDrive access ([KB-010](../../helpdesk/knowledge-base/KB-010-departure-checklist.md)) |
| Is it us, or Microsoft? | M365 admin center → **Health → Service health** |

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| Can't assign a license | Set the user's **usage location** |
| Shared mailbox doesn't appear in Outlook | Automapping can take up to an hour; or add it manually in Outlook |
| `Connect-MgGraph` permission errors | Sign in as an admin and consent to the requested scopes |
| Locked yourself out with Conditional Access | Sign in with the **break-glass** account and fix the policy |

## How to talk about it in an interview

> *"I administered a Microsoft 365 Business Premium tenant: users and licensing through the portal and Microsoft Graph PowerShell, shared mailboxes with Full Access and Send As, and sharing settings in SharePoint and Teams. I enforced MFA with Conditional Access, starting in report-only mode with a break-glass account excluded, blocked legacy authentication, and used least-privilege roles like Helpdesk Administrator."*

## Results

_To be added after the lab is run:_
- [ ] Screenshots: users and licenses, shared mailbox in Outlook, Conditional Access policies, sign-in log
- [ ] Notes from the help desk task practice
