# Running Exchange Server

*Self-study course · Messaging*

Fourteen modules on how Exchange Server works and how to run it, covering recipients, databases, mail flow, client access, DAGs, security, patching, hybrid with Exchange Online, and troubleshooting. It includes a lab build on lab.local and ends each module with a short self-check.

**Total:** about 4½ hours · **Version:** Exchange Server SE · **Lab:** lab.local + EX01

> Each module ends with a self-check. Open each answer to see the explanation.

## Contents

0. [What Exchange is today](#00-what-exchange-is-today) (12 min)
1. [Architecture](#01-architecture) (18 min)
2. [Build a lab Exchange server](#02-build-a-lab-exchange-server) (30 min)
3. [Recipients](#03-recipients) (18 min)
4. [Mailbox and calendar permissions](#04-mailbox-and-calendar-permissions) (14 min)
5. [Databases and storage](#05-databases-and-storage) (18 min)
6. [Mail flow](#06-mail-flow) (24 min)
7. [Message tracking and queues](#07-message-tracking-and-queues) (16 min)
8. [Client access, namespaces, and certificates](#08-client-access-namespaces-and-certificates) (22 min)
9. [High availability: database availability groups](#09-high-availability-database-availability-groups) (20 min)
10. [Security, compliance, and permissions](#10-security-compliance-and-permissions) (22 min)
11. [Patching, monitoring, and backups](#11-patching-monitoring-and-backups) (18 min)
12. [Hybrid and Exchange Online](#12-hybrid-and-exchange-online) (18 min)
13. [Troubleshooting playbook](#13-troubleshooting-playbook) (18 min)

---

## 00 What Exchange is today

*12 min*

*Exchange is still running in many organizations, often in hybrid with Microsoft 365, and the version you're on decides whether it's getting security fixes.*

**Exchange Server** is Microsoft's on-premises email, calendar, and contacts server. Outlook, Outlook on the web (OWA), and phones connect to it. It stores mailboxes in databases, routes mail inside the organization and to the internet, and relies completely on **Active Directory** for accounts, configuration, and address lists.

**Exchange Online** is the same product run by Microsoft as part of Microsoft 365. Most organizations have moved their mailboxes there, but many still keep Exchange servers for:
- **Hybrid:** managing recipients that sync from AD, and relaying mail from on-premises apps and devices (scanners, line-of-business apps).
- **Regulation or policy:** government, defense, and some regulated industries.
- **Disconnected networks** that can't use the cloud.

### Versions and support

| Version | Status (October 2026) |
|---|---|
| Exchange 2013 and earlier | Out of support since 2023. No security fixes. |
| Exchange 2016 and 2019 | Mainstream support ended October 2025. A paid **Extended Security Update** program ran to **October 2026** and isn't being extended. |
| **Exchange Server Subscription Edition (SE)** | Current version, released July 2025. Same code base as Exchange 2019 CU15, sold under a **subscription** license (or covered by qualifying subscriptions). Follows Microsoft's Modern Lifecycle: supported as long as you stay current with updates. |

> [!WARNING]
> **Watch out: Unsupported Exchange is a top target**
>
> Exchange servers face the internet, hold sensitive email, and run with high privileges in AD. Unpatched Exchange servers were mass-exploited in 2021 (ProxyLogon and ProxyShell). An Exchange 2016 or 2019 server that isn't getting updates should be upgraded to SE or retired.

### Upgrading to SE
From Exchange 2019 (CU14 or CU15), SE installs as an **in-place upgrade**, just like a cumulative update. From Exchange 2016, you install new SE servers and move mailboxes to them ("legacy upgrade"), then remove the old servers.

> [!TIP]
> **In your lab**
>
> Module 2 walks through installing an Exchange server, `EX01`, in your lab.local domain. It's the best way to make the rest of this course concrete. Exchange setup runs as a time-limited trial if you don't enter a product key; check Microsoft's current trial terms before you start.

### Check yourself

**1. What's the support status of Exchange 2019 today?**

- a) Fully supported until 2029
- b) Its extended security update program ended in October 2026
- c) It was never supported on-premises

<details><summary>Answer</summary>

**b)** Exchange 2016 and 2019 left mainstream support in October 2025, and the paid ESU program ended in October 2026. Exchange SE is the supported version.

</details>

**2. How do you move from Exchange 2019 CU15 to Exchange SE?**

- a) Run SE setup as an in-place upgrade
- b) Build a new forest
- c) Move every mailbox to the cloud first

<details><summary>Answer</summary>

**a)** SE installs over Exchange 2019 CU14/CU15 like a cumulative update.

</details>

**3. Why do many cloud-first organizations still run an Exchange server?**

- a) Outlook requires one
- b) To manage synced recipients in hybrid and relay mail from on-premises apps
- c) Exchange Online can't send external mail

<details><summary>Answer</summary>

**b)** In hybrid, AD is the source of authority for recipients, and on-premises apps and devices often relay through a local server.

</details>




---

## 01 Architecture

*18 min*

*What's inside an Exchange server and how it uses Active Directory.*

### Server roles
Modern Exchange has just two roles:
- **Mailbox server:** does almost everything. It holds the mailbox databases, the transport services that route mail, and the **Client Access services** that accept connections from Outlook, OWA, phones, and other servers.
- **Edge Transport server** (optional): sits in the perimeter network (DMZ), isn't domain-joined, and handles internet mail with anti-spam agents. It gets recipient data from the Mailbox servers through **EdgeSync**. Many organizations use Exchange Online Protection or a third-party email gateway instead.

### Front end and back end
Inside each Mailbox server are two layers:
- **Client Access services (front end)** in IIS on ports 443, 25, 587, and others. They authenticate the client, work out which server holds the user's active mailbox database, and **proxy** the request there. They store nothing.
- **Back-end services** do the actual work: open the mailbox, render data, store messages.

So a user can connect to *any* Mailbox server, and the request is proxied to wherever their mailbox lives.

### How Exchange uses Active Directory
Exchange stores almost all its configuration in AD:

| Where | What |
|---|---|
| **Schema** | Exchange extends it with hundreds of attributes (`proxyAddresses`, `homeMDB`, `msExch*`) |
| **Configuration partition** → `CN=Microsoft Exchange` | The Exchange organization: servers, databases, connectors, policies, virtual directories |
| **Domain partition** | Recipients are AD objects with Exchange attributes; plus the `Microsoft Exchange Security Groups` OU (Organization Management, Exchange Servers, and others) |

That's why preparing AD (`/PrepareSchema`, `/PrepareAD`) comes first, why Exchange servers need fast access to a **global catalog**, and why AD problems quickly become email problems.

### Key services

| Service | Job |
|---|---|
| **MSExchangeIS** (Information Store) | Hosts the mailbox databases |
| **MSExchangeFrontEndTransport** | Front-end SMTP: accepts and proxies inbound connections |
| **MSExchangeTransport** | The main transport service: categorizes and routes messages |
| **MSExchangeSubmission / MSExchangeDelivery** | Moves mail between transport and mailbox databases |
| **MSExchangeADTopology** | Discovers DCs and global catalogs. If it stops, almost everything stops. |
| **MSExchangeRepl** | Database replication for DAGs |
| **MSExchangeHM** | Managed Availability: built-in health monitoring and self-healing |
| **W3SVC** (IIS) | Hosts OWA, EAC, EWS, ActiveSync, MAPI over HTTP, Autodiscover |

### Management tools
- **Exchange admin center (EAC):** `https://ex01.lab.local/ecp`
- **Exchange Management Shell:** PowerShell with the Exchange cmdlets. Everything in the EAC can be done here, and much can *only* be done here.

### Check yourself

**1. A user connects to Mailbox server A, but their mailbox is on server B. What happens?**

- a) The connection is refused
- b) Server A's front end proxies the request to server B
- c) Server A copies the mailbox locally

<details><summary>Answer</summary>

**b)** Client Access services authenticate the user and proxy to the server hosting the active copy of the mailbox database.

</details>

**2. Where does Exchange store its organization configuration?**

- a) In a SQL database on each server
- b) In Active Directory's configuration partition
- c) In the registry of the first server

<details><summary>Answer</summary>

**b)** Connectors, databases, virtual directories, and policies all live under `CN=Microsoft Exchange` in the configuration partition.

</details>

**3. Which service, if stopped, breaks almost every Exchange function because it finds domain controllers?**

- a) MSExchangeRepl
- b) MSExchangeADTopology
- c) MSExchangeHM

<details><summary>Answer</summary>

**b)** Exchange depends on AD for everything, and ADTopology is how it discovers DCs and GCs.

</details>




---

## 02 Build a lab Exchange server

*30 min*

*A step-by-step install on lab.local. Plan an evening; most of the time is waiting for setup.*

### Plan the VM
- `EX01`: Windows Server 2022 or 2025 (Desktop Experience), 4 vCPU, **at least 12 GB RAM** (Exchange is memory-hungry; 16 GB is more comfortable), 100 GB system disk plus a 50 GB data disk.
- IP `10.10.10.25`, DNS `10.10.10.10` and `10.10.10.11`, joined to `lab.local`, in `OU=Servers,OU=Corp`.

> [!WARNING]
> **Watch out: Lab only**
>
> Don't install Exchange on a domain controller, and don't expose a lab Exchange server to the internet.

### 1. Install prerequisites
Check Microsoft's **Exchange Server prerequisites** page for the current list for your OS. It typically includes:
1. **.NET Framework 4.8** or later (built into recent Windows Server versions)
2. **Visual C++ Redistributable** for Visual Studio 2012 and 2013
3. **IIS URL Rewrite** module
4. **Unified Communications Managed API (UCMA) 4.0** runtime (included on the Exchange ISO in the `UCMARedist` folder)
5. Windows features, installed with PowerShell:
```powershell
Install-WindowsFeature Server-Media-Foundation, NET-Framework-45-Features, RPC-over-HTTP-proxy, RSAT-Clustering, `
  RSAT-Clustering-CmdInterface, RSAT-Clustering-Mgmt, RSAT-Clustering-PowerShell, WAS-Process-Model, Web-Asp-Net45, `
  Web-Basic-Auth, Web-Client-Auth, Web-Digest-Auth, Web-Dir-Browsing, Web-Dyn-Compression, Web-Http-Errors, `
  Web-Http-Logging, Web-Http-Redirect, Web-Http-Tracing, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Metabase, `
  Web-Mgmt-Console, Web-Mgmt-Service, Web-Net-Ext45, Web-Request-Monitor, Web-Server, Web-Stat-Compression, `
  Web-Static-Content, Web-Windows-Auth, Web-WMI, Windows-Identity-Foundation, RSAT-ADDS
```
Restart, then install URL Rewrite, the Visual C++ packages, and UCMA.

### 2. Prepare Active Directory
Sign in as an account in **Schema Admins** and **Enterprise Admins** (in the lab, `LAB\Administrator`). Mount the Exchange ISO (say as `D:`) and run:
```
D:\Setup.exe /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF /PrepareSchema
D:\Setup.exe /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF /PrepareAD /OrganizationName:"LAB"
D:\Setup.exe /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF /PrepareAllDomains
```
Wait for AD replication between steps if you have two DCs (`repadmin /syncall /AdeP`).

### 3. Install the Mailbox role
```
D:\Setup.exe /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF /Mode:Install /Roles:Mailbox
```
It takes 30–60 minutes. Reboot when it finishes.

### 4. Check it
```powershell
Get-ExchangeServer | Format-List Name, Edition, AdminDisplayVersion, ServerRole
Get-MailboxDatabase -Status | Format-Table Name, Server, Mounted, DatabaseSize
Get-ServerComponentState EX01 | Format-Table Component, State
Test-ServiceHealth
```
Sign in to `https://ex01.lab.local/ecp` as `LAB\Administrator`. Accept the self-signed certificate warning for now (Module 8 fixes it).

### 5. Give your lab users mailboxes
```powershell
Get-User -OrganizationalUnit 'OU=Users,OU=Corp,DC=lab,DC=local' -RecipientTypeDetails User |
  ForEach-Object { Enable-Mailbox -Identity $_.Identity }
```
Then sign in to `https://ex01.lab.local/owa` as Jane and send Marcus an email.

> [!TIP]
> **Good practice: Run the Health Checker**
>
> Microsoft's free **HealthChecker.ps1** script (on the Microsoft *CSS-Exchange* GitHub) checks build version, security settings, OS configuration, and known problems, and produces an HTML report. Run it after every install and every update.

### Check yourself

**1. What permissions do you need to run `/PrepareSchema`?**

- a) Domain Admins only
- b) Schema Admins and Enterprise Admins
- c) Local administrator on the Exchange server

<details><summary>Answer</summary>

**b)** Extending the schema needs Schema Admins; preparing the forest-wide configuration needs Enterprise Admins.

</details>

**2. Where should you never install Exchange?**

- a) A virtual machine
- b) A domain controller
- c) Windows Server 2022

<details><summary>Answer</summary>

**b)** Installing Exchange on a DC isn't recommended or supported for production. It complicates security and recovery.

</details>




---

## 03 Recipients

*18 min*

*Everything that can receive or send mail is a recipient, and each type behaves a little differently.*

| Recipient type | What it is | Typical use |
|---|---|---|
| **User mailbox** | A mailbox attached to an AD user who signs in | Every employee |
| **Shared mailbox** | A mailbox whose AD account is disabled; people get access through permissions | `finance@`, `helpdesk@` |
| **Room mailbox** | A bookable meeting room with its own calendar and booking rules | Conference rooms |
| **Equipment mailbox** | A bookable resource that isn't a room | Projectors, pool cars |
| **Linked mailbox** | A mailbox for a user in another (account) forest | Resource-forest designs |
| **Mail user** | An AD user with an *external* email address and no mailbox here | Contractors who sign in to your domain but use their own email |
| **Mail contact** | An address book entry for an external address, with no sign-in | Vendors, partners |
| **Distribution group** | An email list | Announcements |
| **Mail-enabled security group** | A security group that can also receive email | Teams whose list doubles as permissions |
| **Dynamic distribution group** | Membership calculated from a filter when mail is sent | "Everyone in Department = Finance" |
| **Public folders** | Shared folder hierarchy stored in special mailboxes | Legacy shared calendars and contacts |

### Email addresses
A recipient's addresses live in AD's `proxyAddresses` attribute. Uppercase `SMTP:` marks the **primary** (reply) address; lowercase `smtp:` entries are extra addresses that also receive mail.

**Email address policies** generate addresses automatically, for example `%g.%s@lab.local` (first.last). **Accepted domains** list the domains your organization receives mail for. A recipient can't have an address in a domain that isn't accepted.

### Common recipient tasks
```powershell
# Create a new user and mailbox together (prompts for a password)
New-Mailbox -Name 'Ana Ortiz' -UserPrincipalName aortiz@lab.local -OrganizationalUnit 'OU=HR,OU=Users,OU=Corp,DC=lab,DC=local' -Password (Read-Host -AsSecureString)

# Shared and resource mailboxes
New-Mailbox -Shared -Name 'Finance Shared' -Alias finance
New-Mailbox -Room -Name 'Conf Room 1' -Alias confroom1
Set-CalendarProcessing confroom1 -AutomateProcessing AutoAccept -AllowConflicts $false -BookingWindowInDays 180

# Add a second address and change the primary
Set-Mailbox jsmith -EmailAddresses @{Add='jane.smith@lab.local'}

# Groups
New-DistributionGroup -Name 'All Staff' -Alias allstaff -Members jsmith, mjohnson, ppatel
New-DynamicDistributionGroup -Name 'Finance Everyone' -RecipientFilter "(Department -eq 'Finance') -and (RecipientType -eq 'UserMailbox')"

# External recipients
New-MailContact -Name 'Vendor Support' -ExternalEmailAddress support@vendor.example

# Convert a departing user's mailbox to shared
Set-Mailbox jsmith -Type Shared
```

### Quotas and deleted items
- **Mailbox quotas** (warning, prohibit send, prohibit send and receive) are set per database, or per mailbox to override.
- **Deleted item retention:** items emptied from Deleted Items can be recovered by the user (**Recover deleted items**) for 14 days by default.
- **Deleted mailbox retention:** when a mailbox is disabled or removed, it stays **disconnected** in the database for 30 days by default and can be reconnected.

```powershell
Get-MailboxStatistics jsmith | Format-List DisplayName, TotalItemSize, ItemCount, LastLogonTime
Get-MailboxStatistics -Database DB01 | Where-Object DisconnectReason | Format-Table DisplayName, DisconnectReason, DisconnectDate
```

### Check yourself

**1. Which recipient type has a disabled AD account and is accessed through permissions?**

- a) Mail user
- b) Shared mailbox
- c) Linked mailbox

<details><summary>Answer</summary>

**b)** Shared mailboxes have disabled accounts. People open them using Full Access permission.

</details>

**2. In `proxyAddresses`, what does uppercase `SMTP:` mean?**

- a) It's the primary address used for replies
- b) It's an external address
- c) It's a disabled address

<details><summary>Answer</summary>

**a)** Exactly one uppercase `SMTP:` entry is the primary address. Lowercase `smtp:` entries are secondary addresses.

</details>

**3. Which group's membership is calculated each time mail is sent to it?**

- a) Mail-enabled security group
- b) Dynamic distribution group
- c) Distribution group

<details><summary>Answer</summary>

**b)** Dynamic groups use a recipient filter that's evaluated at send time.

</details>




---

## 04 Mailbox and calendar permissions

*14 min*

*Most Exchange help desk tickets are about access: "I need to see the Finance mailbox," "Let my assistant manage my calendar."*

### The three mailbox permissions

| Permission | What it allows | On-premises command |
|---|---|---|
| **Full Access** | Open the mailbox and read everything | `Add-MailboxPermission finance -User jsmith -AccessRights FullAccess -InheritanceType All` |
| **Send As** | Send mail that appears to come directly from the mailbox | `Add-ADPermission finance -User jsmith -ExtendedRights 'Send As'` |
| **Send on Behalf** | Send mail shown as "Jane Smith on behalf of Finance" | `Set-Mailbox finance -GrantSendOnBehalfTo @{Add='jsmith'}` |

> [!WARNING]
> **Watch out: On-premises vs. Exchange Online**
>
> On-premises, **Send As** is an Active Directory permission, so you use `Add-ADPermission`. In Exchange Online, it's `Add-RecipientPermission`. This trips people up when moving between the two.

**Automapping:** granting Full Access adds the mailbox to the user's Outlook automatically. To avoid that (for example, an admin who needs occasional access), use `-AutoMapping $false`.

### Folder and calendar permissions
Individual folders, especially the **Calendar**, have their own permissions, set by the owner in Outlook or by an admin:
```powershell
Get-MailboxFolderPermission mjohnson:\Calendar
Add-MailboxFolderPermission mjohnson:\Calendar -User jsmith -AccessRights Editor -SharingPermissionFlags Delegate
Set-MailboxFolderPermission mjohnson:\Calendar -User Default -AccessRights LimitedDetails
```

| Role | Can do |
|---|---|
| AvailabilityOnly | See free/busy only (default for everyone) |
| LimitedDetails | See free/busy, subject, and location |
| Reviewer | Read items |
| Editor | Read, create, change, and delete items |
| Editor + Delegate | Editor, plus receive meeting requests on the owner's behalf |

### Checking who has access
```powershell
Get-MailboxPermission finance | Where-Object { -not $_.IsInherited -and $_.User -notlike 'NT AUTHORITY\*' }
Get-ADPermission finance | Where-Object ExtendedRights -like '*Send-As*'
Get-Mailbox finance | Select-Object -ExpandProperty GrantSendOnBehalfTo
```

> [!TIP]
> **In your lab**
>
> Give Jane Full Access and Send As to `finance` in your lab. Open OWA as Jane, open the Finance mailbox (**your profile picture → Open another mailbox**), and send a message from `finance@`. Then remove Send As and try again.

### Check yourself

**1. On-premises, how do you grant Send As?**

- a) `Add-MailboxPermission -AccessRights SendAs`
- b) `Add-ADPermission -ExtendedRights 'Send As'`
- c) `Set-Mailbox -GrantSendOnBehalfTo`

<details><summary>Answer</summary>

**b)** Send As on-premises is an AD extended right. Exchange Online uses `Add-RecipientPermission` instead.

</details>

**2. An admin needs occasional access to a mailbox without it appearing in their Outlook. What do you set?**

- a) Full Access with `-AutoMapping $false`
- b) Send on Behalf
- c) Reviewer on the Inbox only

<details><summary>Answer</summary>

**a)** Automapping adds Full Access mailboxes to Outlook automatically. Turning it off keeps the access without the clutter.

</details>




---

## 05 Databases and storage

*18 min*

*Where mail physically lives, and why transaction logs matter so much.*

### The ESE database
Each **mailbox database** is an `.edb` file managed by the **Extensible Storage Engine (ESE)**. Every change is written first to **transaction logs** (1 MB `.log` files) and later to the database. Logs make the database recoverable: after a crash, Exchange replays the logs to bring the database back to a consistent state.

| File | Purpose |
|---|---|
| `DB01.edb` | The database |
| `E00*.log` | Transaction logs (`E00.log` is the current one) |
| `E00.chk` | Checkpoint: how far the logs have been written into the database |

### Logs keep growing until a backup truncates them
Logs are deleted (truncated) only after a **full Exchange-aware backup** (using the VSS writer) completes, or, in a DAG, after the logs are replicated and backed up. If backups stop, logs fill the disk and the database **dismounts**. This is a classic Exchange outage.

**Circular logging** deletes logs automatically after they're written to the database. It saves space but means you can only restore to the last full backup. It's acceptable in a DAG with three or more copies (Exchange Native Data Protection) or in a lab. It's not recommended for a single server in production.

### Sizing and layout
- Keep databases a manageable size (Microsoft's guidance: up to 2 TB in a DAG; much smaller on a standalone server), so restores and reseeds finish in a reasonable time.
- Put databases and logs on volumes formatted with **ReFS** or NTFS with a **64 KB** allocation unit size, separate from the OS.
- Exclude Exchange folders and processes from antivirus scanning, following Microsoft's exclusion list. Scanning database files is a common cause of corruption and slowness.

```powershell
New-MailboxDatabase -Name DB02 -Server EX01 -EdbFilePath 'E:\DB02\DB02.edb' -LogFolderPath 'E:\DB02\Logs'
Mount-Database DB02
Set-MailboxDatabase DB02 -ProhibitSendQuota 9.5GB -IssueWarningQuota 9GB -ProhibitSendReceiveQuota 10GB
New-MoveRequest jsmith -TargetDatabase DB02          # move a mailbox while the user keeps working
Get-MoveRequest | Get-MoveRequestStatistics
Get-MailboxDatabase -Status | Format-Table Name, DatabaseSize, AvailableNewMailboxSpace, LastFullBackup
```

### White space
Deleting mail doesn't shrink the `.edb` file; it leaves **white space** that Exchange reuses for new data. To actually reclaim disk space, create a new database and **move mailboxes** to it, then delete the old one. Offline defragmentation (`eseutil /d`) is rarely worth the downtime.

### Recovery tools
- **Recovery database (RDB):** mount a restored copy of a database alongside production and copy individual mailboxes or items back with `New-MailboxRestoreRequest`.
- **`eseutil /mh`** shows whether a database is in a **Clean Shutdown** or **Dirty Shutdown** state, and which logs it needs.
- **`eseutil /r`** (soft recovery) replays logs into a dirty database. **`eseutil /p`** (hard repair) discards damaged data and should be a last resort.

> [!TIP]
> **In your lab**
>
> In your lab, run `Get-MailboxDatabase -Status | Format-List Name, LastFullBackup, CircularLoggingEnabled`. Back up the database with Windows Server Backup (choose the volume with the database and **VSS full backup**), and watch the transaction log count drop afterward.

### Check yourself

**1. An Exchange database dismounted, and its log volume is full. What's the usual cause?**

- a) Too many mailboxes
- b) Backups stopped, so logs were never truncated
- c) Circular logging was turned on

<details><summary>Answer</summary>

**b)** Logs are only removed after a successful Exchange-aware full backup (or by circular logging). Fix the backups first.

</details>

**2. After deleting 50 GB of mail, the `.edb` file is the same size. Why?**

- a) The space becomes white space reused inside the database
- b) The deletion failed
- c) Logs haven't replayed yet

<details><summary>Answer</summary>

**a)** Databases don't shrink. Move mailboxes to a new database to reclaim disk space.

</details>

**3. How do you restore one user's deleted folder from last week's backup?**

- a) Restore the whole database over production
- b) Mount the backup as a recovery database and run `New-MailboxRestoreRequest`
- c) Use `eseutil /p`

<details><summary>Answer</summary>

**b)** A recovery database lets you copy individual mailboxes or folders back without touching production.

</details>




---

## 06 Mail flow

*24 min*

*How a message gets from one person to another, inside the organization and across the internet.*

### The transport pipeline
1. **Front End Transport** service: accepts SMTP connections (port 25 from other servers, 587 from authenticated clients and apps). It doesn't queue mail; it proxies the connection to a Transport service.
2. **Transport** service (on a Mailbox server): **categorizes** each message (looks up recipients in AD, expands groups, applies **mail flow rules**), then **routes** it, queuing it for the next hop.
3. **Mailbox Transport Delivery** service: delivers the message into the recipient's mailbox database. **Mailbox Transport Submission** picks up messages that users send and hands them to Transport.

### Connectors
- **Receive connectors** accept inbound SMTP. A new server has five by default, including **Default Frontend EX01** (port 25, anonymous internet mail) and **Client Frontend EX01** (port 587, authenticated clients).
- **Send connectors** send mail out of the organization. You create one for the internet (address space `*`), either sending directly using DNS (MX lookups) or through a **smart host** (your email gateway or Exchange Online Protection).

```powershell
Get-ReceiveConnector | Format-Table Name, Bindings, PermissionGroups
New-SendConnector -Name 'Internet' -AddressSpaces '*' -SourceTransportServers EX01 -Internet
Get-AcceptedDomain
New-AcceptedDomain -Name 'company.example' -DomainName company.example -DomainType Authoritative
```

### Relaying for apps and devices
Printers, scanners, and apps often need to send mail. Options:
- **Authenticated submission** on port 587 with a mailbox account (best, if the device supports TLS and modern settings).
- A dedicated **receive connector** that accepts mail only from the device's IP addresses and allows **anonymous relay** to external domains. Lock it to specific IPs; an **open relay** gets your domain blacklisted within hours.

```powershell
New-ReceiveConnector -Name 'Relay - Scanners' -TransportRole FrontendTransport -Usage Custom `
  -Bindings 0.0.0.0:25 -RemoteIPRanges 10.10.10.50 -PermissionGroups AnonymousUsers
Get-ReceiveConnector 'EX01\Relay - Scanners' |
  Add-ADPermission -User 'NT AUTHORITY\ANONYMOUS LOGON' -ExtendedRights 'Ms-Exch-SMTP-Accept-Any-Recipient'
```

### DNS records for email

| Record | Purpose | Example |
|---|---|---|
| **MX** | Where to deliver mail for your domain | `company.example MX 10 mail.company.example` |
| **SPF** (TXT) | Which servers may send mail for your domain | `v=spf1 ip4:203.0.113.10 include:spf.protection.outlook.com -all` |
| **DKIM** (TXT/CNAME) | Public key for verifying message signatures. Exchange Server doesn't sign with DKIM natively; your gateway or Exchange Online does. | `selector1._domainkey` |
| **DMARC** (TXT) | What receivers should do when SPF and DKIM fail, and where to send reports | `v=DMARC1; p=quarantine; rua=mailto:dmarc@company.example` |
| **Autodiscover** | Helps Outlook find its settings (Module 8) | `autodiscover.company.example` |
| **PTR** (reverse DNS) | The sending IP should resolve back to your mail server's name | Set with your ISP |

### Mail flow rules (transport rules)
Rules act on messages in transit: add a disclaimer, warn about external senders, block attachments by type, copy messages to a manager, or encrypt.
```powershell
New-TransportRule -Name 'External sender warning' -FromScope NotInOrganization -SentToScope InOrganization `
  -PrependSubject '[EXTERNAL] '
```

### Anti-malware and anti-spam
Exchange Server includes a basic **anti-malware** filter and, on Edge Transport servers (or when enabled on Mailbox servers), **anti-spam agents** (connection filtering, sender and recipient filtering, content filtering). Most organizations put a dedicated filter in front: **Exchange Online Protection** in hybrid, or a third-party gateway.

### Check yourself

**1. Which receive connector accepts anonymous mail from the internet on port 25 by default?**

- a) Default Frontend
- b) Client Frontend
- c) Default (back end)

<details><summary>Answer</summary>

**a)** "Default Frontend <server>" listens on port 25 for anonymous inbound mail. Client Frontend on 587 is for authenticated submission.

</details>

**2. Which DNS record tells the world where to deliver your email?**

- a) SPF
- b) MX
- c) DMARC

<details><summary>Answer</summary>

**b)** MX records point to the server or gateway that accepts mail for your domain.

</details>

**3. A scanner needs to email external addresses. What's the safest setup if it can't authenticate?**

- a) Allow anonymous relay from any IP
- b) A dedicated receive connector limited to the scanner's IP, with relay permission
- c) Turn off the anti-malware agent

<details><summary>Answer</summary>

**b)** Restrict relay to specific IP addresses. An open relay gets abused and blocklisted quickly.

</details>




---

## 07 Message tracking and queues

*16 min*

*"I sent it and they never got it" is one of the most common Exchange tickets. These tools answer it.*

### Message tracking
Every Transport service logs each message's journey: received, submitted, routed, delivered, failed. Logs are kept for 30 days by default (subject to a size limit).
```powershell
Get-MessageTrackingLog -Sender jsmith@lab.local -Start (Get-Date).AddHours(-4) |
  Sort-Object Timestamp | Format-Table Timestamp, EventId, Source, Recipients, MessageSubject -AutoSize

# Across every server
Get-TransportService | Get-MessageTrackingLog -MessageSubject 'Q3 budget' -Start '2026-10-27' |
  Format-Table Timestamp, ServerHostname, EventId, Recipients
```

| EventId | Means |
|---|---|
| RECEIVE | Transport received the message |
| SUBMIT | Mailbox Transport Submission handed it to Transport |
| AGENTINFO | A transport agent (anti-malware, rules) processed it |
| SEND | Sent to another server or the internet |
| DELIVER | Delivered to a mailbox |
| FAIL | Delivery failed; check the RecipientStatus |
| DEFER | Delivery delayed and will be retried |
| REDIRECT, EXPAND | Redirected, or a group was expanded |

### Queues
When a message can't reach its next hop, it waits in a **queue** and Exchange retries.
```powershell
Get-Queue | Format-Table Identity, DeliveryType, Status, MessageCount, NextHopDomain, LastError
Get-Message -Queue 'EX01\5' | Format-Table FromAddress, Subject, Status, LastError
Retry-Queue -Identity 'EX01\5'
```
A growing queue to one domain usually means DNS or that domain's server is unreachable. A growing queue to **everywhere** usually means your send connector, smart host, or outbound port 25 is blocked.

### Non-delivery reports (NDRs)
When delivery fails, the sender gets an NDR with a status code:

| Code | Usual meaning |
|---|---|
| 5.1.1 | Recipient address doesn't exist |
| 5.1.10 | Recipient not found by SMTP address (often in hybrid or after a migration) |
| 5.2.2 | Recipient's mailbox is full |
| 5.4.1 | Recipient's server rejected relaying; or the domain isn't accepted |
| 5.7.1 | Not authorized: restricted group, blocked sender, or relay denied |
| 4.x.x | Temporary: Exchange is still retrying |

### Back pressure
When a Transport server runs low on resources (disk space for the queue database, memory), it starts **refusing** new messages to protect itself. This is called **back pressure**. Event log entries from `MSExchangeTransport` (event 15004 and related) and the `Get-ExchangeDiagnosticInfo` output tell you which resource is the problem. Free up disk space on the queue volume first.

> [!TIP]
> **In your lab**
>
> In your lab, send a message from Jane to a made-up address, `nobody@lab.local`. Find it with `Get-MessageTrackingLog -EventId FAIL`, then read the NDR in Jane's mailbox. Next, stop the `MSExchangeTransport` service briefly while sending mail, and watch `Get-Queue` in another session after you restart it.

### Check yourself

**1. A user says an email to a partner never arrived. What's your first check?**

- a) Message tracking for that message and recipient
- b) Rebuild the user's Outlook profile
- c) Restart the Transport service

<details><summary>Answer</summary>

**a)** Message tracking shows whether the message was received, sent, delivered, deferred, or failed, and to which next hop.

</details>

**2. Mail to every external domain is queuing. What's the likely cause?**

- a) One recipient's mailbox is full
- b) The send connector, smart host, or outbound port 25 is broken or blocked
- c) Message tracking is turned off

<details><summary>Answer</summary>

**b)** A queue to everywhere points at your own outbound path.

</details>

**3. What does NDR code 5.2.2 usually mean?**

- a) The address doesn't exist
- b) The recipient's mailbox is full
- c) The sender isn't authorized

<details><summary>Answer</summary>

**b)** 5.2.2 means the mailbox is over its quota.

</details>




---

## 08 Client access, namespaces, and certificates

*22 min*

*How Outlook, OWA, and phones find and reach the right server.*

### Protocols

| Protocol | Used by | IIS virtual directory |
|---|---|---|
| **MAPI over HTTP** | Outlook for Windows (default) | `/mapi` |
| **Outlook Anywhere** (RPC over HTTP) | Older Outlook; legacy fallback | `/rpc` |
| **Outlook on the web (OWA)** | Browsers | `/owa` |
| **Exchange admin center (EAC)** | Admins | `/ecp` |
| **Exchange Web Services (EWS)** | Outlook for Mac, free/busy in hybrid, many third-party apps | `/EWS` |
| **Exchange ActiveSync (EAS)** | Phone mail apps | `/Microsoft-Server-ActiveSync` |
| **Autodiscover** | Outlook and phones finding their settings | `/Autodiscover` |
| **Offline Address Book (OAB)** | Outlook's downloaded address book | `/OAB` |
| **POP3 / IMAP4** | Off by default; old clients | Not IIS |

### Namespaces
Users and apps should never see server names. Plan a small set of **names** that point to your servers (or a load balancer):
- `mail.company.example` for OWA, EWS, ActiveSync, MAPI, OAB
- `autodiscover.company.example` for Autodiscover

Then set every virtual directory's **InternalUrl** and **ExternalUrl** to those names.
```powershell
$ns = 'mail.lab.local'
Get-OwaVirtualDirectory -Server EX01 | Set-OwaVirtualDirectory -InternalUrl "https://$ns/owa" -ExternalUrl "https://$ns/owa"
Get-MapiVirtualDirectory -Server EX01 | Set-MapiVirtualDirectory -InternalUrl "https://$ns/mapi" -ExternalUrl "https://$ns/mapi" -IISAuthenticationMethods Ntlm, Negotiate
Get-WebServicesVirtualDirectory -Server EX01 | Set-WebServicesVirtualDirectory -InternalUrl "https://$ns/EWS/Exchange.asmx" -ExternalUrl "https://$ns/EWS/Exchange.asmx"
Get-ClientAccessService EX01 | Set-ClientAccessService -AutoDiscoverServiceInternalUri "https://autodiscover.lab.local/Autodiscover/Autodiscover.xml"
```

### Autodiscover
- **Domain-joined Outlook** finds Exchange by reading the **service connection point (SCP)** that each server publishes in AD (that's `AutoDiscoverServiceInternalUri`).
- **Outside the network** (or not domain-joined), Outlook tries `https://company.example/autodiscover/autodiscover.xml`, then `https://autodiscover.company.example/...`, then a DNS SRV record (`_autodiscover._tcp`).
- Outlook's **Test E-mail AutoConfiguration** tool (Ctrl+right-click the Outlook tray icon) shows exactly which URLs it tried and what it received.

### Certificates
Clients only trust Exchange if its certificate matches the names they connect to and comes from a trusted CA.
- Use **one certificate** with every namespace as a subject alternative name: `mail.company.example`, `autodiscover.company.example`.
- For internet-facing names, use a **public CA**. For a lab, your internal [AD CS](../windows/adcs-pki) works for domain-joined clients.
- Assign it to **IIS** and **SMTP**. Renew it **before** it expires; expired Exchange certificates are a classic Monday-morning outage. In hybrid, the certificate also secures the connection to Exchange Online.
```powershell
Get-ExchangeCertificate | Format-Table Thumbprint, Subject, CertificateDomains, Services, NotAfter
Enable-ExchangeCertificate -Thumbprint <thumbprint> -Services IIS, SMTP
```

### Extended Protection
**Extended Protection for Authentication** binds Windows authentication to the TLS session, which stops a class of credential-relay attacks. It's turned on by default on current Exchange versions. If a load balancer or reverse proxy does **SSL offloading** (decrypting before Exchange), Extended Protection breaks; use SSL bridging instead.

> [!TIP]
> **In your lab**
>
> In your lab: create a DNS A record for `mail.lab.local` and a CNAME for `autodiscover.lab.local` pointing to EX01, request a certificate with both names from your internal CA, assign it, update the virtual directory URLs, and confirm that OWA opens with no certificate warning on CLIENT01.

### Check yourself

**1. How does domain-joined Outlook find its Autodiscover URL?**

- a) From the MX record
- b) From the service connection point published in Active Directory
- c) From the user's email signature

<details><summary>Answer</summary>

**b)** Each Exchange server publishes an SCP object in AD that domain-joined Outlook queries first.

</details>

**2. What must the Exchange certificate include?**

- a) Every namespace clients use, such as mail. and autodiscover.
- b) Every server's NetBIOS name
- c) Only the internal domain name

<details><summary>Answer</summary>

**a)** Clients compare the name they connect to with the certificate's names. Use a SAN certificate covering all namespaces.

</details>

**3. What breaks Extended Protection?**

- a) Enabling MAPI over HTTP
- b) SSL offloading on a load balancer
- c) Using a public CA certificate

<details><summary>Answer</summary>

**b)** Extended Protection ties authentication to the TLS session. If something else terminates TLS, use SSL bridging instead.

</details>




---

## 09 High availability: database availability groups

*20 min*

*How Exchange keeps mail available when a server, a disk, or a whole data center fails.*

### What a DAG is
A **database availability group (DAG)** is a group of up to **16** Mailbox servers that keep **copies** of each other's databases. For each database, one copy is **active** (users connect to it) and the rest are **passive**, kept up to date by shipping transaction logs (continuous replication). If the active copy's server fails, **Active Manager** activates a passive copy on another server, usually within seconds, and the front ends start proxying users there.

DAGs use parts of **Windows Failover Clustering** (for membership and quorum) but don't need shared storage. Each server has its own disks.

### Quorum and the witness
To avoid two halves of a DAG both thinking they're in charge (**split brain**), a majority of voters must agree. With an even number of servers, a **file share witness** (a folder on another server, or an Azure cloud witness) breaks the tie. Put the witness in a third location if you have two data centers.

### Designs
- **Two servers, one site:** protects against a server failure.
- **Two sites:** protects against losing a data center. Activation across sites is usually manual (**datacenter switchover**) to avoid failing over because of a network blip.
- **Three or more copies:** lets you use **Exchange Native Data Protection** (no traditional backups, circular logging on), often with one **lagged copy** that delays log replay by up to 14 days, to recover from logical corruption.

```powershell
New-DatabaseAvailabilityGroup -Name DAG01 -WitnessServer APP01 -WitnessDirectory C:\DAG01Witness
Add-DatabaseAvailabilityGroupServer DAG01 -MailboxServer EX01
Add-DatabaseAvailabilityGroupServer DAG01 -MailboxServer EX02
Add-MailboxDatabaseCopy DB01 -MailboxServer EX02 -ActivationPreference 2

Get-MailboxDatabaseCopyStatus * | Format-Table Name, Status, CopyQueueLength, ReplayQueueLength, ContentIndexState
Test-ReplicationHealth
Move-ActiveMailboxDatabase DB01 -ActivateOnServer EX02      # planned switchover
Update-MailboxDatabaseCopy DB01\EX02 -DeleteExistingFiles   # reseed a failed copy
```

### Healthy copy states

| Field | Healthy value |
|---|---|
| Status | **Mounted** (active) or **Healthy** (passive) |
| CopyQueueLength | Near 0 (logs not yet copied) |
| ReplayQueueLength | Near 0 (logs copied but not yet replayed), except lagged copies |
| ContentIndexState | Healthy (search index) |

### Patching a DAG member
Put the server into **maintenance mode** first so databases move off cleanly and the server doesn't take new work:
```powershell
Set-ServerComponentState EX01 -Component HubTransport -State Draining -Requester Maintenance
Redirect-Message -Server EX01 -Target EX02.lab.local
Suspend-ClusterNode EX01
Set-MailboxServer EX01 -DatabaseCopyActivationDisabledAndMoveNow $true
Set-MailboxServer EX01 -DatabaseCopyAutoActivationPolicy Blocked
Set-ServerComponentState EX01 -Component ServerWideOffline -State Inactive -Requester Maintenance
# ...install the update, reboot, then reverse each step
```
Microsoft's `StartDagServerMaintenance.ps1` and `StopDagServerMaintenance.ps1` scripts (in Exchange's `Scripts` folder) do the DAG parts for you.

> [!TIP]
> **In your lab**
>
> A DAG lab needs a second Exchange server (`EX02`), so it's an advanced extension. Even with one server, run `Get-ServerComponentState EX01` and practice putting it into maintenance mode and back.

### Check yourself

**1. What's the maximum number of servers in a DAG?**

- a) 4
- b) 16
- c) 32

<details><summary>Answer</summary>

**b)** A DAG can have up to 16 Mailbox servers.

</details>

**2. Why does a DAG with two servers need a witness?**

- a) To break ties so one side can keep quorum
- b) To store a third database copy
- c) To run Autodiscover

<details><summary>Answer</summary>

**a)** With an even number of voters, the witness provides the deciding vote and prevents split brain.

</details>

**3. What is a lagged copy for?**

- a) Faster failover
- b) Recovering from logical corruption by keeping older data
- c) Load balancing users

<details><summary>Answer</summary>

**b)** A lagged copy delays replaying logs, so you can recover data from before corruption or a mass deletion.

</details>




---

## 10 Security, compliance, and permissions

*22 min*

*Exchange has deep access to AD and holds the organization's email. Securing it is a core part of the job.*

### Role-based access control (RBAC)
Exchange permissions come from **management roles** (sets of cmdlets and parameters) assigned to **role groups**. Members get exactly the cmdlets their roles allow, in both the EAC and the shell.

| Role group | Can |
|---|---|
| **Organization Management** | Everything. Treat like Domain Admins. |
| **Recipient Management** | Create and manage mailboxes, groups, contacts, and moves |
| **View-Only Organization Management** | Read all configuration, change nothing |
| **Help Desk** | View and change limited user settings, reset passwords where allowed |
| **Discovery Management** | Search mailboxes for legal holds and investigations |
| **Compliance Management** | Retention and compliance settings |

**Role assignment policies** control what *end users* can change about their own mailbox (like their own distribution groups).

```powershell
Add-RoleGroupMember 'Recipient Management' -Member creyes
Get-ManagementRoleAssignment -RoleAssignee creyes | Format-Table Role, RoleAssigneeName
```

> [!WARNING]
> **Watch out: Exchange's power in AD**
>
> By default, Exchange's own security groups (like **Exchange Windows Permissions**) hold powerful rights over the domain. Attacks in the past turned an Exchange compromise into a Domain Admin compromise. Current versions reduce these rights, and **AD split permissions** can separate Exchange admins from AD account management. Keep Exchange as patched and protected as a domain controller.

### Auditing
- **Admin audit logging** records every change made by admins in the shell or EAC: `Search-AdminAuditLog -StartDate (Get-Date).AddDays(-7)`.
- **Mailbox audit logging** records actions like mailbox access by delegates and admins, message deletions, and Send As. It's on by default for owners, delegates, and admins in current versions.

### Retention and legal hold
- **Messaging records management (MRM):** **retention tags** (for example, "delete after 2 years" or "archive after 1 year") grouped into a **retention policy** applied to mailboxes. The **Managed Folder Assistant** applies them on a schedule.
- **Archive mailboxes** (**In-Place Archive**) give users a second mailbox for older mail.
- **Litigation hold** preserves everything in a mailbox, including deleted and edited items, until removed: `Set-Mailbox jsmith -LitigationHoldEnabled $true`.
- **Journaling** sends a copy of messages to an archive system for regulatory needs.

### Hardening checklist
1. Install every **cumulative update** and **security update** promptly. Subscribe to the Exchange Team Blog.
2. Run **HealthChecker.ps1** after every change and fix what it flags.
3. Leave the **Emergency Mitigation service** on; Microsoft uses it to push temporary protections for new attacks.
4. Keep **AMSI** integration on so your antivirus can inspect requests.
5. Publish only what's needed to the internet (typically OWA, ActiveSync, Autodiscover, EWS, MAPI, through a reverse proxy or WAF). Never publish `/ecp` or PowerShell externally.
6. Require **TLS 1.2** and disable older protocols and ciphers.
7. Use **modern authentication** (OAuth) and MFA where supported, through hybrid modern auth or AD FS.
8. Review RBAC role group membership regularly.

### Check yourself

**1. Which role group should a help desk tech who creates mailboxes be in?**

- a) Organization Management
- b) Recipient Management
- c) Discovery Management

<details><summary>Answer</summary>

**b)** Recipient Management covers mailboxes, groups, contacts, and moves without organization-wide configuration rights.

</details>

**2. What preserves everything in a mailbox, including deleted items, for an investigation?**

- a) Litigation hold
- b) A retention tag
- c) Circular logging

<details><summary>Answer</summary>

**a)** Litigation hold keeps all content until the hold is removed, regardless of what the user deletes.

</details>

**3. Which virtual directory should never be published to the internet?**

- a) `/owa`
- b) `/ecp`
- c) `/Microsoft-Server-ActiveSync`

<details><summary>Answer</summary>

**b)** The admin center (`/ecp`) and remote PowerShell should be reachable only from the internal admin network.

</details>




---

## 11 Patching, monitoring, and backups

*18 min*

*The routine that keeps Exchange healthy month after month.*

### Updates
- **Cumulative updates (CUs)** are full builds of Exchange, released periodically. Install them as an upgrade: `Setup.exe /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF /Mode:Upgrade`. Some CUs need `/PrepareSchema` and `/PrepareAD` first; the release notes say so.
- **Security updates (SUs)** are smaller patches released for a specific CU when needed, often on Patch Tuesday.
- Support requires being on a **recent CU**. Falling behind means no security updates.

> [!TIP]
> **Good practice: Before you patch**
>
> 1. Read the release notes and the Exchange Team Blog post for known issues.
> 2. Run HealthChecker.ps1 to know your starting state.
> 3. Back up, and check you have a good full backup.
> 4. Put DAG members into maintenance mode (Module 9) and patch one at a time.
> 5. Run setup **from an elevated prompt**. SUs installed without elevation can leave OWA and EAC broken.
> 6. Afterwards: run HealthChecker.ps1 again, test OWA, Outlook, mail flow, and ActiveSync.

### Version numbers
`Get-ExchangeServer | Format-Table Name, AdminDisplayVersion` shows the build. Microsoft's **Exchange Server build numbers and release dates** page maps each build to its CU and SU. Look it up whenever you inherit a server.

### Monitoring
- **Managed Availability** (MSExchangeHM) runs probes against every component and can restart services or take a component offline when it fails. `Get-ServerHealth EX01 | Where-Object AlertValue -ne Healthy` shows what it thinks is wrong.
- Watch from outside too: certificate expiry, queue length, database copy health, disk space on database and log volumes, and the services in Module 1. Your [PRTG lab](../infrastructure/monitoring-prtg) can watch OWA's URL and certificate.

```powershell
Test-ServiceHealth
Get-ServerHealth EX01 | Where-Object AlertValue -ne 'Healthy' | Format-Table HealthSetName, Name, AlertValue
Get-Queue | Where-Object MessageCount -gt 50
Get-ExchangeCertificate | Where-Object NotAfter -lt (Get-Date).AddDays(30)
```

### Backups
- Use backup software that's **Exchange-aware** (uses the Exchange VSS writer), so it truncates logs and produces restorable databases.
- Test restores by mounting a backup as a **recovery database** and restoring a mailbox to a test folder.
- Back up the server configuration too, but rebuilding is usually faster: Exchange servers can be recovered with `Setup.exe /Mode:RecoverServer` on a new machine with the same name, because the configuration lives in AD.

### Check yourself

**1. What usually must run before some cumulative updates?**

- a) `eseutil /d`
- b) `/PrepareSchema` and `/PrepareAD`
- c) A full DAG reseed

<details><summary>Answer</summary>

**b)** CUs that add schema or AD changes require the prepare steps; the release notes say when.

</details>

**2. What's the danger of installing a security update from a non-elevated prompt?**

- a) OWA and the EAC can be left broken
- b) The update installs twice
- c) Nothing; it's fine

<details><summary>Answer</summary>

**a)** Exchange SUs must be installed elevated. Partial installs commonly break web services.

</details>

**3. A server is lost but AD is intact. What's the fastest way to rebuild it?**

- a) Reinstall Exchange with a new name
- b) Build a machine with the same name and run Setup with `/Mode:RecoverServer`
- c) Restore the whole forest

<details><summary>Answer</summary>

**b)** Exchange configuration lives in AD, so RecoverServer rebuilds the server from it. Then restore or reseed databases.

</details>




---

## 12 Hybrid and Exchange Online

*18 min*

*How on-premises Exchange and Microsoft 365 work together, and how mailboxes move to the cloud.*

### What hybrid gives you
**Exchange hybrid** connects an on-premises Exchange organization to Exchange Online so they behave like one:
- A **shared address book** and mail routing between both sides
- **Free/busy** calendar sharing across both
- **Mailbox moves** in either direction with no new Outlook profile
- **Centralized mail flow** (optional), routing internet mail through on-premises

Users sync from AD to Entra ID with **Entra Connect** (your [hybrid identity tutorial](../m365/hybrid-identity)), and the **Hybrid Configuration Wizard (HCW)** sets up the connectors, certificates, organization relationship, and OAuth between the two.

### Classic vs. Modern hybrid
- **Classic (full) hybrid:** Exchange Online connects inbound to your on-premises servers for moves and free/busy, so they must be published to the internet.
- **Modern hybrid** uses the **Hybrid Agent**, which makes an *outbound* connection, so you don't publish EWS for migration traffic. Some features (like certain cross-premises permissions) work differently.

### Migration options

| Method | When |
|---|---|
| **Hybrid remote move** | Larger or long migrations; users move in batches with almost no disruption |
| **Cutover migration** | Small organizations (Microsoft's limit is 2,000 mailboxes, recommended for far fewer) moving everyone at once |
| **Staged migration** | Exchange 2003/2007 only (historic) |
| **IMAP migration** | From non-Exchange systems; mail only |
| **Third-party tools** | Tenant-to-tenant and complex scenarios |

### Recipient management after the move
When users sync from AD, **AD is the source of authority**, so Exchange attributes (addresses, aliases) must be managed on-premises. You used to have to keep a running Exchange server just for that. Now, once every mailbox is in the cloud, you can **shut down the last Exchange server** and manage recipients with the **Exchange Management Tools** installed on a management machine (the *Exchange Recipient Management* PowerShell snap-in), as long as you don't still need hybrid mail flow or on-premises relay.

### Key differences in Exchange Online

| Task | On-premises | Exchange Online |
|---|---|---|
| Send As | `Add-ADPermission` | `Add-RecipientPermission` |
| Connect PowerShell | Exchange Management Shell | `Connect-ExchangeOnline` |
| Message tracking | `Get-MessageTrackingLog` | `Get-MessageTraceV2` / Message trace in the EAC |
| Spam and malware | Your gateway / agents | Exchange Online Protection, Defender for Office 365 |
| Patching | You | Microsoft |
| Backups | You | Native data protection; many organizations add third-party backup |

> [!TIP]
> **In your lab**
>
> You can't easily run a full hybrid in a lab (it needs a public domain and certificate), but you can learn the cloud side in your [Microsoft 365 admin lab](../m365/m365-admin) and compare each task above with your EX01 server.

### Check yourself

**1. What tool sets up the connectors and trust between on-premises Exchange and Exchange Online?**

- a) Entra Connect
- b) The Hybrid Configuration Wizard
- c) HealthChecker.ps1

<details><summary>Answer</summary>

**b)** Entra Connect syncs identities. The HCW configures the Exchange side of hybrid.

</details>

**2. All mailboxes are in Exchange Online, and users sync from AD. How can you manage their email addresses without a running Exchange server?**

- a) Use the Exchange Management Tools' recipient management snap-in
- b) Edit them directly in Exchange Online
- c) You can't; a server is always required

<details><summary>Answer</summary>

**a)** Once no server is needed for mail flow, the management tools let you edit Exchange attributes in AD without a running Exchange server.

</details>




---

## 13 Troubleshooting playbook

*18 min*

*A quick reference for the problems you'll actually be called about.*

| Symptom | Likely causes | Where to look |
|---|---|---|
| Outlook keeps asking for a password | Autodiscover pointing to the wrong place, an expired or mismatched certificate, MAPI virtual directory authentication settings, a stale cached credential | **Test E-mail AutoConfiguration**; `Get-ExchangeCertificate`; Credential Manager on the PC |
| Outlook stuck "Disconnected" / "Trying to connect" | Server or service down, DNS for `mail.` wrong, certificate problem | `Test-ServiceHealth`, `Get-ServerComponentState`, browse to `https://mail.../mapi/healthcheck.htm` |
| OWA shows an error after patching | SU installed without elevation, or a broken OWA virtual directory | Re-run the update elevated; HealthChecker.ps1 |
| Mail not arriving from outside | MX record, firewall on port 25, receive connector, the gateway in front | Message tracking (did it ever arrive?), `Get-ReceiveConnector`, test with an external tool |
| Mail not leaving | Send connector, smart host credentials, ISP blocking port 25, being on a blocklist | `Get-Queue`, `LastError`, check blocklists for your IP |
| Mail delayed internally | Transport back pressure, queue database disk full | `Get-Queue`, Application log (MSExchangeTransport), free disk |
| Database dismounted | Log disk full (backups failed), disk errors, dirty shutdown | `Get-MailboxDatabase -Status`, Application log, `eseutil /mh` |
| Free/busy not showing for some users | Autodiscover/EWS issues; in hybrid, the organization relationship or OAuth | `Test-OAuthConnectivity`, `Get-OrganizationRelationship` |
| Shared mailbox not showing in Outlook | Automapping takes time, or was turned off | `Get-MailboxPermission`, re-grant with automapping, or add manually |
| Phone stopped syncing | ActiveSync device quarantined or blocked, password changed, certificate | `Get-MobileDevice -Mailbox jsmith`, `Get-MobileDeviceStatistics` |
| "Your mailbox is full" | Quota reached | `Get-MailboxStatistics`, raise quota or enable archive |

### Useful logs and tools
- **Event Viewer → Application:** sources starting with `MSExchange`
- **IIS logs** (`C:\inetpub\logs\LogFiles\W3SVC1`): every client request with its HTTP status
- **Protocol logs** for SMTP connectors (turn on per connector with `-ProtocolLoggingLevel Verbose`)
- **Microsoft Remote Connectivity Analyzer** (testconnectivity.microsoft.com): tests Autodiscover, ActiveSync, SMTP, and more from the internet
- **CSS-Exchange scripts** on Microsoft's GitHub: HealthChecker, SetupAssist (setup failures), and others

> [!TIP]
> **Good practice: A habit that saves hours**
>
> When something breaks, first ask: **what changed?** A certificate renewal, a CU, a firewall change, a DNS change, or an AD change explains most Exchange outages.

### Check yourself

**1. Outlook prompts for a password repeatedly after a certificate renewal. What do you check first?**

- a) The mailbox quota
- b) Whether the new certificate covers all namespaces and is assigned to IIS
- c) The DAG witness

<details><summary>Answer</summary>

**b)** Credential prompts after a certificate change usually mean a name mismatch or the old certificate still bound to IIS.

</details>

**2. Which free Microsoft tool tests Exchange from the internet?**

- a) Remote Connectivity Analyzer
- b) ADSI Edit
- c) dcdiag

<details><summary>Answer</summary>

**a)** testconnectivity.microsoft.com runs external tests of Autodiscover, ActiveSync, SMTP, and more.

</details>




---

*Written in plain language from Microsoft's Exchange documentation, current as of October 2026. Exchange support dates and licensing change. Check Microsoft Learn and the Exchange Team Blog before planning upgrades.*
