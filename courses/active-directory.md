# Inside Active Directory

*Self-study course · Windows identity*

Sixteen modules on how Active Directory works and how to run it, from forests and domain controllers to Kerberos, Group Policy, replication, recovery, and security. Each module ties back to your lab.local tutorials and ends with a short self-check.

**Total:** about 5 hours · **Lab:** lab.local (DC01, DC02, APP01, CLIENT01) · **Level:** Beginner to advanced

> Each module ends with a self-check. Open each answer to see the explanation.

## Contents

0. [What Active Directory is](#00-what-active-directory-is) (10 min)
1. [Logical structure: forests, domains, OUs](#01-logical-structure-forests-domains-ous) (18 min)
2. [Physical structure: DCs, sites, and replication](#02-physical-structure-dcs-sites-and-replication) (22 min)
3. [DNS and finding a domain controller](#03-dns-and-finding-a-domain-controller) (16 min)
4. [Objects, attributes, and names](#04-objects-attributes-and-names) (18 min)
5. [Groups and access](#05-groups-and-access) (20 min)
6. [Authentication: Kerberos and NTLM](#06-authentication-kerberos-and-ntlm) (24 min)
7. [Group Policy](#07-group-policy) (26 min)
8. [Accounts, passwords, and service accounts](#08-accounts-passwords-and-service-accounts) (20 min)
9. [Delegation, permissions, and LAPS](#09-delegation-permissions-and-laps) (18 min)
10. [FSMO roles](#10-fsmo-roles) (14 min)
11. [The admin toolkit](#11-the-admin-toolkit) (16 min)
12. [Health checks and troubleshooting](#12-health-checks-and-troubleshooting) (24 min)
13. [Backup and recovery](#13-backup-and-recovery) (20 min)
14. [Securing Active Directory](#14-securing-active-directory) (24 min)
15. [Today's AD: Windows Server 2025 and hybrid](#15-todays-ad-windows-server-2025-and-hybrid) (14 min)

---

## 00 What Active Directory is

*10 min*

*Everything else in this course is a detail of one idea: a shared, trusted list of who and what exists, and who may do what.*

**Active Directory Domain Services (AD DS)** is Microsoft's directory service. A *directory* is a database of objects (people, computers, groups, printers) and their attributes (name, password hash, phone number, group memberships). AD stores that database on servers called **domain controllers (DCs)** and gives every Windows machine in the organization a way to:

- **Authenticate:** prove who someone is (sign-in), using Kerberos or NTLM.
- **Authorize:** decide what they may access, using group memberships and permissions.
- **Manage:** push settings to users and computers centrally with Group Policy.
- **Find things:** look up users, computers, and services with LDAP queries and DNS.

Without AD, each computer keeps its own local accounts. With 500 PCs, a new hire would need 500 accounts. With AD, they get one account that works everywhere, and one change (disable the account) removes access everywhere.

### The pieces you'll hear about

| Term | Plain meaning |
|---|---|
| **Domain** | A boundary of administration and replication with its own name, like `lab.local` |
| **Domain controller** | A server holding a writable (or read-only) copy of the domain's database |
| **Forest** | The top-level container: one or more domains sharing one schema and configuration |
| **OU (organizational unit)** | A folder inside a domain for organizing objects and applying policy |
| **Group Policy** | Settings delivered from DCs to users and computers |
| **Schema** | The rulebook defining what kinds of objects and attributes can exist |
| **LDAP** | The protocol used to read and write the directory |
| **Kerberos** | The default sign-in (authentication) protocol |

### AD DS vs. Microsoft Entra ID
**Microsoft Entra ID** (formerly Azure AD) is Microsoft's *cloud* identity service for Microsoft 365 and web apps. Despite the old name, it isn't AD in the cloud: it has no OUs, no Group Policy, no Kerberos for your file servers, and no domain controllers you manage. Most organizations run **both** and sync them with Entra Connect (your [hybrid identity tutorial](../m365/hybrid-identity)).

Other "Active Directory" roles share the brand but do different jobs: **AD CS** (certificates), **AD FS** (federation and single sign-on to web apps), **AD LDS** (a lightweight standalone directory for apps), and **AD RMS** (document protection, now largely replaced by Microsoft Purview).

> [!TIP]
> **In your lab**
>
> Your `lab.local` forest has one domain, one or two DCs (DC01, DC02), and an OU tree under `OU=Corp`. Everything in this course can be tried there.

### Check yourself

**1. What is the main difference between authentication and authorization?**

- a) They mean the same thing
- b) Authentication proves who you are; authorization decides what you may access
- c) Authorization happens first, then authentication

<details><summary>Answer</summary>

**b)** Sign-in (authentication) comes first. Access decisions (authorization) are then made from the groups and permissions attached to that identity.

</details>

**2. Which of these does Microsoft Entra ID **not** provide?**

- a) Cloud sign-in for Microsoft 365
- b) Conditional Access
- c) Group Policy and OUs

<details><summary>Answer</summary>

**c)** Entra ID is a cloud identity service. Group Policy and OUs exist only in on-premises AD DS.

</details>

**3. What is a domain controller?**

- a) A server that holds a copy of the directory database and handles sign-ins
- b) A workstation used by domain admins
- c) A firewall that protects the domain

<details><summary>Answer</summary>

**a)** DCs store the directory, answer LDAP queries, issue Kerberos tickets, and deliver Group Policy.

</details>




---

## 01 Logical structure: forests, domains, OUs

*18 min*

*How AD is organized on paper, independent of where the servers physically sit.*

### Forest
The **forest** is the outermost boundary. Every domain in a forest shares:
- one **schema** (the object and attribute definitions),
- one **configuration** partition (sites, services, the list of domains),
- one **global catalog** (a searchable index of every object in the forest),
- automatic, two-way, transitive **trusts** between all its domains.

The first domain created is the **forest root domain**. Its name becomes the forest's name, and it holds the forest-wide admin groups, **Enterprise Admins** and **Schema Admins**.

> [!NOTE]
> **How it works: The forest is the security boundary**
>
> Microsoft treats the **forest**, not the domain, as the true security boundary. An admin of any domain in a forest can, with enough effort, take over the others. If two business units must be fully isolated, they need separate forests.

### Domains and trees
A **domain** is a partition of the directory with its own name, its own Domain Admins, its own password policy (by default), and its own replication of domain data. A **tree** is a set of domains in a contiguous DNS namespace: `corp.com`, `eu.corp.com`, `us.corp.com`. A forest can contain several trees (`corp.com` and `acquired.net`).

Most organizations today run **a single domain in a single forest**. Extra domains add cost and complexity, and the reasons people once had for them (different password policies, replication traffic) now have other solutions.

### Organizational units (OUs)
An **OU** is a container inside a domain. OUs exist for two reasons:
1. **Delegation:** give the help desk permission to reset passwords in `OU=Users`, without making them Domain Admins.
2. **Group Policy:** link a GPO to an OU, and it applies to the users or computers inside it.

OUs are *not* security groups. You can't grant a folder permission to an OU. Design the OU tree around **how you manage things** (by object type, then location or department), not around the org chart.

```
lab.local
└── Corp
    ├── Admins            (privileged accounts, separate policies)
    ├── Users
    │   ├── Finance
    │   ├── HR
    │   └── IT
    ├── Computers         (workstations)
    ├── Servers
    ├── Groups
    └── Service Accounts
```

> [!WARNING]
> **Watch out: Default containers aren't OUs**
>
> `CN=Users` and `CN=Computers` are *containers*, not OUs, so you can't link GPOs to them. New computers land in `CN=Computers` by default. Redirect them to a real OU with `redircmp` (computers) and `redirusr` (users), as your server lab does.

### Naming contexts (directory partitions)
The database on each DC is split into partitions that replicate with different scopes:

| Partition | Contains | Replicates to |
|---|---|---|
| **Schema** | Class and attribute definitions | Every DC in the forest |
| **Configuration** | Sites, subnets, services, the domain list | Every DC in the forest |
| **Domain** | Users, computers, groups, OUs, GPO links | Every DC in that domain |
| **Application** (for example `DomainDnsZones`, `ForestDnsZones`) | AD-integrated DNS zones | The DCs you choose (usually DNS servers) |

### The global catalog (GC)
A **global catalog server** is a DC that also holds a *partial, read-only* copy of every object from every domain in the forest, with a subset of commonly searched attributes. It's used to find objects anywhere in the forest, to resolve **universal group** memberships at sign-in, and to resolve **UPN** sign-ins (`jsmith@lab.local`). In a single-domain forest, make every DC a GC; there's no downside.

### Trusts
A **trust** lets users from one domain be granted access in another.

| Trust | Typical use |
|---|---|
| Parent-child, tree-root | Created automatically inside a forest (two-way, transitive) |
| **Forest trust** | Between two forests, for example after an acquisition |
| **External trust** | To one specific domain in another forest (non-transitive) |
| **Shortcut trust** | Speeds up authentication between two deep domains in the same forest |
| **Realm trust** | To a non-Windows Kerberos realm (MIT Kerberos) |

**Direction** describes who trusts whom. If domain A *trusts* domain B, users in B can be given access to resources in A. Access flows the opposite way from trust. **Selective authentication** on a forest trust makes you explicitly allow which users may authenticate to which servers.

### Functional levels
Domain and forest **functional levels** turn on features that need every DC to be at a minimum version. You raise them after the last old DC is gone. Windows Server 2025 introduced a new level (internally *level 10*), required for its optional 32k database page size. New forests now require at least the Windows Server 2016 level.

> [!TIP]
> **In your lab**
>
> On DC01, run:
> ```powershell
> Get-ADForest | Select-Object Name, ForestMode, SchemaMaster, GlobalCatalogs
> Get-ADDomain | Select-Object DNSRoot, NetBIOSName, DomainMode, PDCEmulator
> Get-ADOrganizationalUnit -Filter * | Select-Object DistinguishedName
> ```

### Check yourself

**1. What is the real security boundary in Active Directory?**

- a) The OU
- b) The domain
- c) The forest

<details><summary>Answer</summary>

**c)** Any domain admin in a forest can eventually compromise the rest of it. Only a separate forest gives true isolation.

</details>

**2. Why can't you link a GPO to `CN=Computers`?**

- a) It's a container, not an OU
- b) It's reserved for domain controllers
- c) GPOs can only link to the domain root

<details><summary>Answer</summary>

**a)** Only sites, domains, and OUs accept GPO links. Redirect new computers to a real OU with `redircmp`.

</details>

**3. Domain A trusts domain B. Which users can be given access to resources in A?**

- a) Users in A only
- b) Users in B
- c) Nobody until a second trust is created

<details><summary>Answer</summary>

**b)** Access flows opposite to the trust: the trusting domain (A) accepts identities from the trusted domain (B).

</details>

**4. What does a global catalog hold?**

- a) A full writable copy of every domain
- b) A partial, read-only copy of every object in the forest
- c) Only DNS records

<details><summary>Answer</summary>

**b)** The GC indexes every object in the forest with a subset of attributes, which is enough for forest-wide searches and universal group lookups.

</details>




---

## 02 Physical structure: DCs, sites, and replication

*22 min*

*Where the copies of the database live, and how a change on one DC reaches all the others.*

### Multi-master replication
Every writable DC accepts changes. You can reset a password on DC02 while someone else edits a user on DC01, and both changes spread to every DC. This is **multi-master replication**. It's why AD keeps working when one DC is down, and why the second DC in your lab matters.

### How a DC knows what's new
- Each DC numbers its own changes with an ever-increasing **USN** (update sequence number).
- Each DC remembers, for each partner, the highest USN it has already received (the **high-watermark** vector) and, for every DC in the domain, the newest change it has seen (the **up-to-dateness vector**). That's how it avoids receiving the same change twice.
- Each attribute change carries a **version number**, timestamp, and originating DC. If two DCs change the same attribute at the same time, the higher version wins, then the later timestamp. This is **conflict resolution**, and it works per *attribute*, not per object.
- Replication is **pull-based**: a DC is notified that changes exist, then requests them.

### Sites, subnets, and site links
A **site** represents a well-connected network location (an office, a data center). You define:
- **Subnets**, each assigned to a site, so clients and DCs know which site they're in.
- **Site links** connecting sites, with a **cost** (lower is preferred), a **replication interval**, and a schedule.

Sites control three things:
1. **Replication:** inside a site, changes go out almost immediately (DCs notify partners about **15 seconds** after a change). Between sites, replication follows the site link schedule (default **every 180 minutes**, minimum 15), compressed.
2. **Authentication:** clients find a DC in their own site first (the DC locator, Module 3).
3. **Service location:** DFS, Exchange, and other apps use sites to pick nearby servers.

> [!WARNING]
> **Watch out: Missing subnets**
>
> If a client's subnet isn't defined, it doesn't know its site and may authenticate against a DC on the other side of the country. DCs log event 5807 in the Netlogon log listing clients from unknown subnets. Define every subnet.

### The KCC and bridgeheads
The **Knowledge Consistency Checker (KCC)** runs on every DC and builds the replication topology automatically: a ring (plus shortcuts) inside each site, and **bridgehead servers** that carry replication between sites. You rarely create connections by hand; you fix the site and subnet design, and the KCC does the rest.

### Urgent replication
Some changes replicate between sites immediately, ignoring the schedule: **account lockouts**, changes to the account lockout policy, and RID master changes. Password changes are sent urgently to the **PDC emulator** (Module 10).

### SYSVOL
The `SYSVOL` share on every DC holds Group Policy files and logon scripts. It replicates separately from the AD database, using **DFS Replication (DFSR)**. The old FRS engine is deprecated, and new DCs can't join a domain still using it.

### Read-only domain controllers (RODCs)
An **RODC** holds a read-only copy of the database and, by default, **no passwords**. It's meant for branch offices with poor physical security. Its **Password Replication Policy** decides which accounts' passwords it may cache. If the RODC is stolen, you reset only those accounts.

### Tombstones and lingering objects
When an object is deleted, it isn't erased right away. It becomes a **tombstone** (or, with the Recycle Bin, a recoverable *deleted object*) so the deletion can replicate. Tombstones are purged after the **tombstone lifetime**, 180 days in modern forests. A DC that has been offline longer than that may reintroduce deleted objects (**lingering objects**) and must not be reconnected; demote it and rebuild instead.

> [!TIP]
> **In your lab**
>
> After building [DC02](../windows/second-dc):
> ```powershell
> repadmin /replsummary            # failures and largest deltas per DC
> repadmin /showrepl dc02          # each partition, partner, and last result
> repadmin /syncall /AdeP          # force replication of all partitions
> Get-ADReplicationSite -Filter * ; Get-ADReplicationSubnet -Filter *
> ```
> Create a user on DC01, then check DC02 a minute later with `Get-ADUser -Server dc02`.

### Check yourself

**1. Two admins change the same user's phone number on different DCs at the same moment. How does AD decide?**

- a) The DC with the lower name wins
- b) Higher version number wins, then the later timestamp
- c) The change is rejected and logged

<details><summary>Answer</summary>

**b)** Conflict resolution is per attribute: version number first, then timestamp, then the originating DC's GUID as a tiebreaker.

</details>

**2. What happens when a client's IP subnet isn't defined in Sites and Services?**

- a) It can't sign in
- b) It doesn't know its site and may use a distant DC
- c) It falls back to NTLM

<details><summary>Answer</summary>

**b)** Without a subnet mapping, the DC locator can't choose a local DC. Netlogon logs these clients (event 5807).

</details>

**3. A DC has been offline for eight months. What should you do?**

- a) Power it on and force replication
- b) Don't reconnect it; remove its metadata and rebuild it
- c) Raise the tombstone lifetime and reconnect

<details><summary>Answer</summary>

**b)** Beyond the 180-day tombstone lifetime it can reintroduce deleted objects. Clean up its metadata and build a new DC.

</details>




---

## 03 DNS and finding a domain controller

*16 min*

*Most "AD problems" are DNS problems. This module explains why.*

AD depends on DNS to tell clients where DCs are. When a DC is promoted, its **Netlogon** service registers **SRV records** describing the services it offers. Those records live under the `_msdcs` zone and the `_sites` subtree.

| Record | Means |
|---|---|
| `_ldap._tcp.dc._msdcs.lab.local` | Every DC in the domain |
| `_ldap._tcp.Default-First-Site-Name._sites.dc._msdcs.lab.local` | DCs in a specific site |
| `_kerberos._tcp.lab.local` | Kerberos KDCs |
| `_gc._tcp.lab.local` | Global catalog servers |
| `_ldap._tcp.pdc._msdcs.lab.local` | The PDC emulator |
| `<DSA-GUID>._msdcs.lab.local` (CNAME) | Used by DCs to find replication partners |

### The DC locator, step by step
1. A client needs a DC for `lab.local`. It asks DNS for `_ldap._tcp.dc._msdcs.lab.local` (or the site-specific name if it knows its site).
2. DNS returns a list of DCs with priority and weight.
3. The client sends a small LDAP "ping" (a UDP query) to several of them and uses the first to answer.
4. The DC tells the client which **site** it's in, based on the client's IP. If the client is in a different site from that DC, it repeats the lookup for DCs in its own site.
5. The client caches the result and uses that DC until it stops responding.

### DNS design rules for AD
- **Clients and member servers must use only AD DNS servers.** Never put a public resolver (like 8.8.8.8) as a client's secondary DNS: it can't answer SRV queries for your domain, and clients randomly fail to find DCs.
- DCs forward internet lookups using **forwarders** (or root hints).
- Use **AD-integrated zones**: the zone is stored in AD, replicates with it, and supports **secure dynamic updates** (only the computer that owns a record can update it).
- Each DC points to **another DC first** and itself second (`127.0.0.1` last), so a DC doesn't depend only on itself at boot.
- Turn on **scavenging** carefully to remove stale dynamic records.

> [!TIP]
> **Good practice: When something "can't find the domain"**
>
> Check DNS before anything else:
> ```powershell
> Resolve-DnsName -Type SRV _ldap._tcp.dc._msdcs.lab.local
> nltest /dsgetdc:lab.local          # which DC this machine would use, and its site
> ipconfig /all                      # are the DNS servers only your DCs?
> dcdiag /test:dns /v                # on a DC: full DNS health check
> ```
> If SRV records are missing, restart Netlogon on the DC (`Restart-Service Netlogon`) to re-register them.

### Single-label and `.local` names
Never name a domain with a single label (`LAB` with no suffix). `.local` names like `lab.local` work but aren't routable on the internet and clash with multicast DNS on some systems. For new production domains, Microsoft recommends a subdomain of a domain you own, such as `ad.company.com`.

### Check yourself

**1. A workstation's DNS settings are DC01 and 8.8.8.8. What's the problem?**

- a) None; it's a good fallback
- b) When it asks 8.8.8.8, it can't find your domain's SRV records, so sign-ins and GPOs fail randomly
- c) 8.8.8.8 will block Kerberos

<details><summary>Answer</summary>

**b)** Domain members must use only AD DNS servers. DCs handle internet lookups through forwarders.

</details>

**2. Which service registers a DC's SRV records?**

- a) DNS Client
- b) Netlogon
- c) Kerberos

<details><summary>Answer</summary>

**b)** Netlogon registers and refreshes the DC's records. Restarting it re-registers missing ones.

</details>

**3. What does `nltest /dsgetdc:lab.local` show?**

- a) Which DC the machine finds, its site, and the DC's flags (GC, PDC, and so on)
- b) The domain's password policy
- c) All DNS records in the zone

<details><summary>Answer</summary>

**a)** It runs the DC locator from that machine and prints the result, which is one of the most useful first checks.

</details>




---

## 04 Objects, attributes, and names

*18 min*

*Every object has several names. Knowing which one a tool wants saves a lot of confusion.*

### Common object classes

| Class | Examples |
|---|---|
| `user` | People, service accounts (`svc-prtg`), admin accounts (`adm-nwang`) |
| `computer` | Workstations, servers, DCs. A computer *is* a security principal with its own password. |
| `group` | Security and distribution groups |
| `organizationalUnit` | OUs |
| `contact` | An external email address in the address book, with no sign-in |
| `msDS-GroupManagedServiceAccount` | gMSAs, such as `gmsa-intranet` |
| `groupPolicyContainer` | The AD half of a GPO |

### One user, many names

| Name | Example | Used by |
|---|---|---|
| **Distinguished name (DN)** | `CN=Jane Smith,OU=Finance,OU=Users,OU=Corp,DC=lab,DC=local` | LDAP, PowerShell `-Identity`, scripts. Changes when the object moves. |
| **sAMAccountName** | `jsmith` | Pre-Windows 2000 sign-in: `LAB\jsmith`. Max 20 characters. |
| **userPrincipalName (UPN)** | `jsmith@lab.local` | Modern sign-in, Microsoft 365 |
| **Display name / CN** | `Jane Smith` | Address book, ADUC |
| **objectGUID** | `5c1a…` | A permanent ID that never changes, even if renamed or moved |
| **objectSid** | `S-1-5-21-<domain>-1105` | Security: permissions and tokens reference the SID |

### SIDs and RIDs
A **security identifier (SID)** uniquely identifies a security principal (user, group, computer). It's made of the **domain SID** plus a **relative ID (RID)**. Each DC gets blocks of 500 RIDs from the **RID master** to hand out. Well-known RIDs include **500** (built-in Administrator), **512** (Domain Admins), **513** (Domain Users), and **519** (Enterprise Admins).

Permissions on files and folders store **SIDs**, not names. That's why a deleted and re-created "jsmith" doesn't get back Jane's old access: it has a new SID. (It's also why the Recycle Bin, which restores the same SID, matters.)

### Attributes worth knowing

| Attribute | What it holds |
|---|---|
| `memberOf` / `member` | Group memberships (back link / forward link) |
| `userAccountControl` | Flags: disabled, password never expires, smart card required, and more |
| `pwdLastSet`, `badPwdCount`, `lockoutTime` | Password and lockout state |
| `lastLogonTimestamp` | Approximate last sign-in, replicated (can lag by up to about 14 days) |
| `lastLogon` | Exact last sign-in, but **per DC** and not replicated |
| `servicePrincipalName` | Services this account runs, for Kerberos (Module 6) |
| `manager`, `department`, `title` | Org data, often synced to Microsoft 365 |

### Querying the directory
LDAP filters use prefix notation: `(&(objectClass=user)(department=Finance))`. PowerShell accepts either its own filter syntax or LDAP:
```powershell
Get-ADUser -Filter "Department -eq 'Finance'" -Properties Title, LastLogonDate
Get-ADUser -LDAPFilter '(&(objectCategory=person)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=2))'   # disabled users
Search-ADAccount -AccountInactive -TimeSpan 90.00:00:00 -UsersOnly
Get-ADObject -Filter * -SearchBase 'OU=Corp,DC=lab,DC=local' | Group-Object ObjectClass
```

> [!TIP]
> **Good practice: Use `-Properties` sparingly**
>
> `Get-ADUser` returns only a few attributes unless you ask. `-Properties *` works, but it's slow across thousands of users. Ask for just what you need.

### The schema
The schema defines each **class** (which attributes it must and may have) and each **attribute** (its data type, whether it's indexed, whether it's in the GC). Applications such as Exchange **extend** the schema. Schema changes are forest-wide and can't be undone (only deactivated), so they need Schema Admins and are done rarely and deliberately.

### Check yourself

**1. Jane's account was deleted and an identical "jsmith" was created. Why can't she open her old folders?**

- a) The password is different
- b) The new account has a new SID, and permissions store SIDs
- c) The folders were deleted with the account

<details><summary>Answer</summary>

**b)** Permissions reference SIDs. Restoring the original object from the Recycle Bin brings back the original SID.

</details>

**2. Which attribute replicates and is good for finding stale accounts?**

- a) `lastLogon`
- b) `lastLogonTimestamp`
- c) `pwdLastSet`

<details><summary>Answer</summary>

**b)** `lastLogonTimestamp` replicates (with up to about 14 days of lag), so one query works. `lastLogon` is exact but stored separately on each DC.

</details>

**3. Which name changes when you move a user to a different OU?**

- a) The distinguished name
- b) The UPN
- c) The objectGUID

<details><summary>Answer</summary>

**a)** The DN encodes the object's location. The GUID and SID never change.

</details>




---

## 05 Groups and access

*20 min*

*Groups are how AD turns "who you are" into "what you can reach." Good group design keeps access understandable for years.*

### Types
- **Security groups** can be given permissions and appear in sign-in tokens.
- **Distribution groups** are email lists only (used by Exchange). They can't grant access.

### Scopes

| Scope | Can contain | Can be granted access to | Typical use |
|---|---|---|---|
| **Global** | Users and global groups from the **same domain** | Resources in any domain in the forest or trusting forests | Grouping *people* by role: `GG-Finance-Staff` |
| **Domain local** | Users and groups from **any trusted domain**, plus other domain local groups from the same domain | Resources **in its own domain only** | Representing *a permission on a resource*: `DL-FinanceShare-Modify` |
| **Universal** | Users and groups from any domain in the forest | Anything in the forest | Multi-domain forests; stored in the global catalog |

### AGDLP
The classic, scalable pattern: **A**ccounts go into **G**lobal groups, which go into **D**omain **L**ocal groups, which get **P**ermissions.

```
jsmith ─┐
mjohnson┴─► GG-Finance-Staff ──► DL-FinanceShare-Modify ──► Modify on \\APP01\Finance
                                 DL-FinancePrinter-Print ──► Print on Finance-Printer
```

Why bother with two layers?
- When someone joins Finance, you add them to **one** group, and they get every Finance resource.
- When an auditor asks "who can modify the Finance share?", you look at **one** group, and you can see which roles reach it.
- Resources never reference individual users, so permissions don't need changing when people come and go.

In a single domain, **AGUDLP** (adding universal groups in the middle) isn't needed.

### Tokens: when group changes take effect
At sign-in, the DC builds an **access token** listing the user's SID and the SIDs of **every group** they belong to, directly or through nesting. Windows checks that token against resource permissions.

The token is built **only at sign-in** (or when a new Kerberos ticket is issued). If you add Jane to a group, she needs to **sign out and back in** (or run `klist purge` and reconnect) before the new access works. This is one of the most common help desk calls.

> [!WARNING]
> **Watch out: Token bloat**
>
> Users in hundreds of groups get large Kerberos tickets. Past a certain size, sign-ins and web apps fail in strange ways (HTTP 400 "header too long", failed authentication). A token can hold roughly 1,000 group SIDs at most. Keep nesting deliberate, and clean up unused groups.

### Privileged built-in groups
Membership in these should be small, monitored, and reviewed:

| Group | Power |
|---|---|
| **Enterprise Admins** | Full control of the entire forest |
| **Schema Admins** | Change the schema. Keep it **empty** except while making a change. |
| **Domain Admins** | Full control of the domain and admin on every member computer |
| **Administrators** (built-in) | Full control of DCs and the domain |
| **Account Operators, Server Operators, Backup Operators, Print Operators** | Legacy groups with dangerous rights, including signing in to DCs. Keep them empty. |
| **DnsAdmins** | Can configure DNS on DCs, which can lead to code running on DCs |
| **Group Policy Creator Owners** | Can create GPOs |
| **Protected Users** | A *defensive* group: members get stronger protections (Module 14) |

### Seeing effective access
```powershell
Get-ADPrincipalGroupMembership jsmith | Select-Object Name
Get-ADGroupMember 'DL-FinanceShare-Modify' -Recursive | Select-Object SamAccountName
whoami /groups        # on the user's machine: the groups in the current token
```
For file shares, the **Effective Access** tab (folder **Properties → Security → Advanced**) shows what a specific user can actually do.

> [!TIP]
> **In your lab**
>
> Your server lab built `GG-Finance-Staff` → `DL-FinanceShare-Modify` → `\\APP01\Finance`. Add Priya to `GG-Finance-Staff`, try the share without signing out, then sign out and in again. Compare `whoami /groups` before and after.

### Check yourself

**1. In AGDLP, what should be granted the NTFS permission on the Finance share?**

- a) Each user in Finance
- b) The global group GG-Finance-Staff
- c) The domain local group DL-FinanceShare-Modify

<details><summary>Answer</summary>

**c)** Permissions go on domain local groups. Global groups (people by role) are nested inside them.

</details>

**2. You added a user to a group, but they still get "Access denied." What's the most likely fix?**

- a) Have them sign out and back in so a new token is built
- b) Wait 24 hours for replication
- c) Reboot the file server

<details><summary>Answer</summary>

**a)** Group membership is read into the token at sign-in. A new sign-in (or a new Kerberos ticket) picks up the change.

</details>

**3. Which group should normally be empty?**

- a) Domain Users
- b) Schema Admins
- c) Protected Users

<details><summary>Answer</summary>

**b)** Add someone to Schema Admins only for the duration of a planned schema change, then remove them.

</details>




---

## 06 Authentication: Kerberos and NTLM

*24 min*

*What actually happens when someone types their password, and why time, DNS, and names matter so much.*

### Kerberos: the default
Kerberos is a ticket system. The **Key Distribution Center (KDC)**, a service on every DC, issues tickets so a user can prove their identity to services without sending a password over the network.

1. **Sign-in (AS exchange).** The client proves it knows the user's password by encrypting a timestamp with a key derived from it (**pre-authentication**). The KDC checks it and returns a **TGT** (ticket-granting ticket), encrypted with the secret of the special `krbtgt` account. The TGT lasts **10 hours** by default.
2. **Asking for a service (TGS exchange).** When the user opens `\\APP01\Finance`, the client sends its TGT to the KDC and asks for a **service ticket** for `cifs/APP01.lab.local`. The KDC finds the account that owns that **SPN** (service principal name), here the APP01 computer account, and returns a ticket encrypted with *that account's* secret.
3. **Using the service (AP exchange).** The client presents the service ticket to APP01. APP01 decrypts it with its own secret, reads the user's identity and group SIDs inside, and builds an access token. APP01 never contacts the DC for this.

> [!NOTE]
> **How it works: Why the details matter**
>
> - **Time:** tickets and pre-authentication include timestamps. If a client's clock is more than **5 minutes** off from the DC, Kerberos fails. Time flows from the **PDC emulator** to the other DCs to members.
> - **Names:** service tickets are requested by **name**. Connecting by IP address (`\\10.10.10.20\Finance`) can't match an SPN, so Windows falls back to NTLM.
> - **SPNs:** each SPN must belong to exactly **one** account. A duplicate SPN breaks Kerberos for that service.
> - **DNS:** the client must find a KDC through SRV records (Module 3).

### Service principal names
An SPN looks like `service/host:port`, for example `HTTP/intranet.lab.local` or `MSSQLSvc/sql01.lab.local:1433`. Computer accounts register their own common SPNs. When a service runs under a domain user or gMSA, the SPN must be added to *that* account.

```powershell
setspn -L APP01                     # SPNs on the APP01 computer account
setspn -Q HTTP/intranet.lab.local   # which account owns this SPN
setspn -X                           # find duplicates
klist                               # tickets in your current session
klist purge                         # throw them away (forces fresh tickets and group lookups)
```

### Delegation
Sometimes a service must act **as the user** toward another service (a web app reading a database as the signed-in user). That's **Kerberos delegation**:
- **Unconstrained:** the server can impersonate the user to *anything*. Dangerous; avoid it.
- **Constrained:** the server can impersonate users only to listed SPNs.
- **Resource-based constrained:** the *target* service decides who may delegate to it. The modern choice.

### NTLM: the fallback
**NTLM** is an older challenge-response protocol used when Kerberos can't be (IP addresses, workgroup machines, some old apps). The server sends a random challenge, the client answers with a value computed from the password hash, and the server checks it with a DC. NTLM has no mutual authentication and is vulnerable to relay and pass-the-hash attacks. Microsoft is phasing it out. Audit where it's still used before blocking it (Module 14).

### LDAP binds, signing, and LDAPS
Applications that authenticate users with LDAP should use **LDAP signing**, **LDAPS** (port 636, with a certificate from your [PKI](../windows/adcs-pki)), and **channel binding**. Windows Server 2025 requires signing and sealing by default for new deployments. Never let an app do a **simple bind** over plain LDAP (389): the password crosses the network in clear text.

### The ports AD uses

| Port | Protocol | Purpose |
|---|---|---|
| 53 | TCP/UDP | DNS |
| 88 | TCP/UDP | Kerberos |
| 123 | UDP | Time (NTP) |
| 135 + 49152–65535 | TCP | RPC endpoint mapper and dynamic RPC (replication, management) |
| 389 / 636 | TCP/UDP / TCP | LDAP / LDAPS |
| 3268 / 3269 | TCP | Global catalog / GC over TLS |
| 445 | TCP | SMB (SYSVOL, NETLOGON, Group Policy) |
| 464 | TCP/UDP | Kerberos password change |
| 9389 | TCP | AD Web Services (used by the PowerShell module and ADAC) |

> [!TIP]
> **In your lab**
>
> On CLIENT01, signed in as Jane: run `klist purge`, open `\\APP01\Finance`, then run `klist`. You'll see a `krbtgt/LAB.LOCAL` TGT and a `cifs/APP01.lab.local` service ticket. Now open `\\10.10.10.20\Finance` and run `klist` again: no new ticket, because that connection used NTLM.

### Check yourself

**1. A laptop's clock is 9 minutes fast. What breaks?**

- a) Kerberos authentication
- b) Only DNS
- c) Nothing; Windows corrects it at sign-in

<details><summary>Answer</summary>

**a)** Kerberos allows 5 minutes of skew by default. Fix the time source (domain members sync from DCs; the PDC emulator syncs from an external source).

</details>

**2. Which secret encrypts a service ticket for `cifs/APP01.lab.local`?**

- a) The user's password
- b) The krbtgt account's password
- c) The APP01 computer account's secret

<details><summary>Answer</summary>

**c)** Each service ticket is encrypted for the account that owns the SPN, so only that service can read it.

</details>

**3. Why does connecting to a share by IP address usually use NTLM?**

- a) IP connections are encrypted differently
- b) Kerberos needs a service name to match an SPN
- c) SMB doesn't support Kerberos

<details><summary>Answer</summary>

**b)** Without a matching SPN, the KDC can't issue a ticket, so Windows falls back to NTLM.

</details>




---

## 07 Group Policy

*26 min*

*The tool that turns a domain from a list of accounts into managed computers.*

### What a GPO is
A **Group Policy Object** has two halves:
- the **Group Policy Container (GPC)** in AD (`CN=Policies,CN=System`), holding its version and links, and
- the **Group Policy Template (GPT)** in `SYSVOL\lab.local\Policies\{GUID}`, holding the actual settings files.

Both halves must replicate for a GPO to apply correctly. Each has two sections: **Computer Configuration** (applies at startup and to the machine) and **User Configuration** (applies at sign-in and to the user).

### Where it applies, and in what order: LSDOU
GPOs link to **sites**, **domains**, and **OUs**. They're processed in this order, and **the last one applied wins** when settings conflict:

1. **L**ocal policy on the computer
2. **S**ite GPOs
3. **D**omain GPOs (like the Default Domain Policy)
4. **O**U GPOs, from the top OU down to the OU that holds the object

Within one container, link order **1** has the highest priority (it's applied last).

### Changing the normal flow

| Option | Effect |
|---|---|
| **Enforced** (on a link) | That GPO's settings win over lower GPOs and ignore Block Inheritance |
| **Block Inheritance** (on an OU) | GPOs from above don't apply, except Enforced ones |
| **Security filtering** | Only users or computers with **Read** and **Apply group policy** get it. Default: Authenticated Users. |
| **WMI filtering** | Apply only where a WMI query is true, for example only laptops or only Windows 11 |
| **Loopback processing** | Apply *user* settings based on the *computer's* OU. Used for kiosks, RDS servers, and labs. **Replace** or **Merge** mode. |
| **Link disabled / GPO status** | Turn off a link, or just the user or computer half |

> [!WARNING]
> **Watch out: Security filtering needs computer read access**
>
> Since a 2016 security update, the **computer** account must be able to read a GPO, even for user settings. If you remove Authenticated Users from security filtering, add **Domain Computers** with **Read** (not Apply) on the Delegation tab, or the GPO silently stops applying.

### Policies vs. preferences
- **Policies** (Administrative Templates, Security Settings) are enforced and revert if the GPO is removed. Users can't change them.
- **Preferences** (Computer/User Configuration → Preferences) set an initial value the user *can* change, and they stay ("tattoo") unless set to remove. They do things policies can't: map drives, create shortcuts, set registry values, edit local groups, deploy printers. **Item-level targeting** applies each item only where conditions match (group membership, OS, IP range).

### Refresh timing
- Computer settings apply at **startup**, user settings at **sign-in**.
- Background refresh runs every **90 minutes**, with a random offset of up to 30 minutes. DCs refresh every 5 minutes.
- Some settings apply **only** at startup or sign-in, not during background refresh: software installation, folder redirection, and (by default) drive maps with some actions. That's why "it worked after a reboot" is so common.
- `gpupdate /force` reapplies everything now. Use `/target:computer` or `/target:user` to limit it.

### Common GPOs in real environments
- Password, lockout, and Kerberos policy (domain level only, Module 8)
- Security baselines (your [hardening lab](../security/windows-hardening-lab))
- Windows Update / WSUS targeting ([WSUS lab](../windows/wsus-patching))
- Drive maps and printers ([printer lab](../windows/printer-deployment))
- Firewall rules, BitLocker, Windows LAPS, screen lock, Edge and Office settings
- Restricted local administrators

### Troubleshooting a GPO that isn't applying
```powershell
gpresult /r                                  # summary: applied and filtered-out GPOs, and why
gpresult /h C:\Temp\gp.html                  # full report: every setting and the winning GPO
Get-GPResultantSetOfPolicy -ReportType Html -Path C:\Temp\rsop.html -Computer CLIENT01 -User LAB\jsmith
Get-GPO -All | Select-Object DisplayName, GpoStatus, ModificationTime
```
Work through it in order:
1. Is the object in the OU you think it is?
2. Is the link enabled, and is the GPO's user/computer half enabled?
3. Does **security filtering** include the user or computer (and does Domain Computers have Read)?
4. Is a **WMI filter** excluding it, or a higher-priority GPO overriding the setting?
5. Is it the right half? A computer setting won't apply because a *user* is in the OU.
6. Look in **Event Viewer → Applications and Services Logs → Microsoft → Windows → GroupPolicy → Operational**.
7. On the DCs, are the GPC and GPT versions consistent? (The Group Policy Management Console's **Status** tab on the domain checks replication of every GPO.)

> [!TIP]
> **Good practice: Back up GPOs**
>
> ```powershell
> Backup-GPO -All -Path \\APP01\Backups\GPO
> ```
> Do this before big changes. `Restore-GPO` brings one back, and `Import-GPO` copies settings into a new GPO (handy between lab and production).

### Check yourself

**1. A domain GPO sets the wallpaper to blue and an OU GPO sets it to red. Which applies to users in that OU?**

- a) Blue, because domain policies are stronger
- b) Red, because the OU GPO is applied last
- c) Neither; conflicts cancel out

<details><summary>Answer</summary>

**b)** LSDOU: the OU GPO processes last and wins, unless the domain GPO's link is Enforced.

</details>

**2. You security-filtered a user GPO to GG-Finance-Staff and removed Authenticated Users. Now it doesn't apply. What's missing?**

- a) Read permission for Domain Computers
- b) A WMI filter
- c) Loopback processing

<details><summary>Answer</summary>

**a)** Computers must be able to read every GPO. Add Domain Computers with Read only on the Delegation tab.

</details>

**3. Which is a **preference**, not a policy?**

- a) Minimum password length
- b) A mapped drive
- c) A firewall rule

<details><summary>Answer</summary>

**b)** Drive maps, shortcuts, printers, and registry items live under Preferences and can use item-level targeting.

</details>

**4. Which command shows which GPOs applied and which were filtered out?**

- a) `gpupdate /force`
- b) `gpresult /r`
- c) `repadmin /showrepl`

<details><summary>Answer</summary>

**b)** `gpresult /r` (or `/h` for an HTML report) shows applied and denied GPOs and the reason.

</details>




---

## 08 Accounts, passwords, and service accounts

*20 min*

*The account lifecycle is the daily work of AD: create, change, lock, disable, remove.*

### Password and lockout policy
The domain's password and lockout policy comes from **one GPO linked at the domain root** (normally the Default Domain Policy). Password settings in GPOs linked to OUs **don't** affect domain accounts.

| Setting | What to know |
|---|---|
| Minimum length | Length matters more than complexity. Current NIST guidance favors long passphrases (15+ characters) and checking against breached-password lists over forced complexity. |
| Maximum age | NIST no longer recommends forced periodic changes unless there's evidence of compromise. Many organizations still require them for compliance. |
| History | Prevents reuse (24 is the usual value) |
| Lockout threshold | Locks an account after N bad attempts. Too low, and attackers can lock everyone out on purpose. 10 is a common balance. |
| Lockout duration / reset counter | How long it stays locked, and when the bad count resets |

### Fine-grained password policies (PSOs)
To give admins or service accounts a different policy (say, 20 characters), create a **Password Settings Object** in the **Password Settings Container** and apply it to a group. When several apply, the lowest **precedence** number wins.
```powershell
New-ADFineGrainedPasswordPolicy -Name 'PSO-Admins' -Precedence 10 -MinPasswordLength 20 `
  -ComplexityEnabled $true -LockoutThreshold 5 -LockoutDuration '00:30:00' -LockoutObservationWindow '00:30:00' `
  -MaxPasswordAge '365.00:00:00' -MinPasswordAge '1.00:00:00' -PasswordHistoryCount 24
Add-ADFineGrainedPasswordPolicySubject 'PSO-Admins' -Subjects 'Domain Admins'
Get-ADUserResultantPasswordPolicy adm-nwang
```

### Finding why an account keeps locking
1. On the **PDC emulator**, search the Security log for **event 4740** (account locked out). It names the **caller computer** where the bad attempts came from.
2. On that computer, look for stale credentials: a mapped drive with an old password, Credential Manager entries, a phone syncing email, a scheduled task or service running as the user, or an old RDP session.
3. **Events 4771** (Kerberos pre-authentication failed) and **4625** (failed sign-in) show each bad attempt.
```powershell
Get-WinEvent -ComputerName (Get-ADDomain).PDCEmulator -FilterHashtable @{LogName='Security'; Id=4740} -MaxEvents 20 |
  Select-Object TimeCreated, @{n='User';e={$_.Properties[0].Value}}, @{n='From';e={$_.Properties[1].Value}}
Get-ADUser jsmith -Properties LockedOut, BadLogonCount, LastBadPasswordAttempt
Unlock-ADAccount jsmith
```

### Account lifecycle
- **Onboarding:** create from a template or script (your [AD toolkit](../windows/active-directory)), set a temporary password with "change at next sign-in," add to role groups, fill in manager and department.
- **Changes:** moving departments means *removing* old role groups as well as adding new ones. Forgotten removals are how people accumulate access ("privilege creep").
- **Offboarding:** disable (don't delete) immediately, reset the password, remove from groups, move to a Disabled OU, and record the date in the description. Delete after your retention period.
- **Hygiene:** regularly find inactive users and computers, accounts with "password never expires," and empty or unused groups.

### Computer accounts
A domain-joined computer has its own account and password, changed automatically every **30 days**. If a machine's copy and AD's copy get out of sync (an old snapshot restored, a reimage with the same name), you see **"The trust relationship between this workstation and the primary domain failed."**

```powershell
Test-ComputerSecureChannel -Verbose          # on the workstation
Test-ComputerSecureChannel -Repair -Credential LAB\adm-nwang
Reset-ComputerMachinePassword -Credential LAB\adm-nwang
```
Rejoining the domain also works, but repairing keeps the computer's existing account, groups, and GPO targeting.

### Service accounts
Services that run as a normal user account with a password that never changes are a classic weakness. Better options:

| Type | What it is |
|---|---|
| **Virtual account / Network Service** | Built-in local identities. On the network they appear as the computer account. Fine for many services. |
| **sMSA** (standalone managed service account) | Password managed by AD, usable on one computer only. Superseded by gMSA. |
| **gMSA** (group managed service account) | Password managed by AD (rotated every 30 days, 240 characters), usable on a set of computers you allow. Your `gmsa-intranet` IIS pool uses one. |
| **dMSA** (delegated managed service account, Windows Server 2025) | Replaces an existing service account: the old account's password is disabled and the service moves to managed keys with minimal app changes. |

```powershell
Get-ADServiceAccount gmsa-intranet -Properties PrincipalsAllowedToRetrieveManagedPassword
Test-ADServiceAccount gmsa-intranet          # on APP01: can this machine use it?
```
gMSAs need a **KDS root key** in the forest, created once with `Add-KdsRootKey`.

> [!TIP]
> **In your lab**
>
> In your lab, lock out Jane on purpose (enter a wrong password 10+ times on CLIENT01), then find the 4740 event on the PDC emulator and unlock her with PowerShell. Then break CLIENT01's secure channel by restoring an old checkpoint, and repair it with `Test-ComputerSecureChannel -Repair`.

### Check yourself

**1. Where must the domain password policy GPO be linked to affect domain accounts?**

- a) The domain root
- b) The Users OU
- c) The Domain Controllers OU

<details><summary>Answer</summary>

**a)** Only the domain-level policy controls domain account passwords. Use fine-grained password policies for exceptions.

</details>

**2. Which event, on which server, tells you where a lockout came from?**

- a) 4624 on any DC
- b) 4740 on the PDC emulator
- c) 4720 on the user's computer

<details><summary>Answer</summary>

**b)** Lockouts are processed urgently at the PDC emulator, and event 4740 there lists the caller computer.

</details>

**3. What's the main advantage of a gMSA over a regular service account?**

- a) It can sign in interactively
- b) AD manages and rotates its long password automatically
- c) It doesn't need any permissions

<details><summary>Answer</summary>

**b)** gMSA passwords are 240 characters, rotated every 30 days, and retrievable only by computers you allow.

</details>




---

## 09 Delegation, permissions, and LAPS

*18 min*

*How to let people do their jobs in AD without making everyone a Domain Admin.*

### Every object has an ACL
Like files, every AD object has a security descriptor with **ACEs** (access control entries): who may read, write, create children, reset passwords, and so on. Permissions set on an OU are **inherited** by objects inside it. You can see them on the **Security** tab in ADUC (turn on **View → Advanced Features**).

### Delegating with the wizard
Right-click an OU → **Delegate Control** lets you give a group common rights, such as:
- Reset user passwords and force password change at next sign-in
- Create, delete, and manage user accounts
- Modify group membership
- Join computers to the domain (in the Computers OU)

Always delegate to a **group** (`GG-HelpDesk-PasswordReset`), never to individual users. To see what's been delegated:
```powershell
(Get-Acl "AD:OU=Users,OU=Corp,DC=lab,DC=local").Access |
  Where-Object IdentityReference -like 'LAB\GG-*' | Select-Object IdentityReference, ActiveDirectoryRights, ObjectType
dsacls "OU=Users,OU=Corp,DC=lab,DC=local"
```

> [!TIP]
> **Good practice: Help desk unlock and reset**
>
> A typical help desk delegation: on `OU=Users`, for *Descendant User objects*: **Reset password**, **Read/Write lockoutTime** (unlock), and **Read/Write pwdLastSet** (force change at next sign-in).

### AdminSDHolder
Accounts that are (or were) in protected groups like Domain Admins get their permissions **overwritten every 60 minutes** from a template object called **AdminSDHolder**, and their `adminCount` attribute is set to 1. This stops someone delegating control over an admin account by accident. Side effects: delegated help desk rights don't work on those accounts, and inheritance is turned off on them. That's intended: admins shouldn't be managed by the help desk.

### Joining computers
By default, **any authenticated user can join up to 10 computers** to the domain (`ms-DS-MachineAccountQuota`). Most organizations set this to **0** and delegate join rights on the Computers OU to a specific group, or pre-create computer accounts.
```powershell
Set-ADDomain -Identity lab.local -Replace @{'ms-DS-MachineAccountQuota'='0'}
```

### The tiered admin model
Microsoft's guidance separates admin accounts by what they control, so a compromised workstation can't lead to a compromised domain:

| Tier | Controls | Rule |
|---|---|---|
| **Tier 0** | Identity: DCs, AD, AD CS, Entra Connect, PKI | Tier 0 accounts sign in **only** to Tier 0 systems |
| **Tier 1** | Servers and applications | Never sign in to workstations |
| **Tier 2** | Workstations and users | Help desk and desktop support |

In practice, that means separate accounts for each person: `nwang` for email, `adm-nwang` for server administration. Microsoft's newer **Enterprise Access Model** expands this idea, but the core rule is the same: **never use a highly privileged account on a less trusted machine**, because its credentials can be stolen from memory there.

### Windows LAPS
Every computer has a built-in local Administrator. If all of them share one password, stealing it from one PC unlocks every PC. **Windows LAPS** (built into Windows since April 2023 updates) gives each computer a unique, random local admin password, rotates it on a schedule, and stores it in AD (encrypted, with read access you control) or in Entra ID.
```powershell
Update-LapsADSchema                                         # once per forest
Set-LapsADComputerSelfPermission -Identity 'OU=Computers,OU=Corp,DC=lab,DC=local'
# then configure the LAPS GPO: Computer Configuration > Administrative Templates > System > LAPS
Get-LapsADPassword -Identity CLIENT01 -AsPlainText
Reset-LapsPassword                                          # on the client: rotate now
```

> [!TIP]
> **In your lab**
>
> Create `GG-HelpDesk` in your lab, add Carlos (`creyes`), and delegate password reset and unlock on `OU=Users,OU=Corp` only. Sign in as Carlos with RSAT and confirm he can reset Jane's password but not `adm-nwang`'s. Then deploy Windows LAPS to `OU=Computers` and read CLIENT01's password.

### Check yourself

**1. You delegated password resets to the help desk, but they can't reset a former Domain Admin's account. Why?**

- a) AdminSDHolder overwrote that account's permissions
- b) Former admins can never have their passwords reset
- c) Delegation only works on new accounts

<details><summary>Answer</summary>

**a)** Accounts with `adminCount=1` get the AdminSDHolder ACL every hour. That's by design.

</details>

**2. By default, how many computers can any domain user join?**

- a) None
- b) Ten
- c) Unlimited

<details><summary>Answer</summary>

**b)** `ms-DS-MachineAccountQuota` defaults to 10. Most organizations set it to 0 and delegate join rights instead.

</details>

**3. What problem does Windows LAPS solve?**

- a) Expired user passwords
- b) The same local Administrator password on every computer
- c) Kerberos clock skew

<details><summary>Answer</summary>

**b)** LAPS gives each computer a unique, rotating local admin password stored securely in AD or Entra ID.

</details>




---

## 10 FSMO roles

*14 min*

*Most AD work happens on any DC, but five jobs must be done by exactly one DC at a time.*

| Role | Scope | Job | If it's down |
|---|---|---|---|
| **Schema master** | Forest | Only DC that can change the schema | No schema changes (rarely noticed) |
| **Domain naming master** | Forest | Adds and removes domains in the forest | Can't add or remove domains |
| **RID master** | Domain | Hands out blocks of 500 RIDs to DCs so new SIDs are unique | DCs can still create objects until their RID pool runs out |
| **PDC emulator** | Domain | Time source for the domain, password change and lockout authority, default target for GPO editing, legacy DC for old clients | **Noticed quickly:** time drifts, lockouts and password changes behave oddly |
| **Infrastructure master** | Domain | Updates references to objects in other domains | Only matters in multi-domain forests where not every DC is a GC |

### Checking, moving, and seizing
```powershell
netdom query fsmo
Get-ADDomain | Select-Object PDCEmulator, RIDMaster, InfrastructureMaster
Get-ADForest | Select-Object SchemaMaster, DomainNamingMaster

# Transfer (the old holder is online): a clean handover
Move-ADDirectoryServerOperationMasterRole -Identity DC02 -OperationMasterRole PDCEmulator, RIDMaster

# Seize (the old holder is gone for good): add -Force
Move-ADDirectoryServerOperationMasterRole -Identity DC02 -OperationMasterRole SchemaMaster -Force
```

> [!WARNING]
> **Watch out: After seizing a role**
>
> A DC whose roles were seized must **never** come back online as it was. It would believe it still holds the roles. Remove its metadata (Active Directory Users and Computers → Domain Controllers → delete it, or `ntdsutil` metadata cleanup), then rebuild it if needed.

### Time hierarchy
The PDC emulator of the forest root domain should sync from a reliable external source. Every other DC syncs from the domain hierarchy, and members sync from DCs. When you move the PDC emulator role, move the external time configuration with it.
```powershell
w32tm /config /manualpeerlist:"time.windows.com,0x8 pool.ntp.org,0x8" /syncfromflags:manual /reliable:yes /update   # on the PDC emulator
w32tm /query /status ; w32tm /query /source
```

> [!TIP]
> **In your lab**
>
> In your [second DC tutorial](../windows/second-dc), you transfer the PDC emulator to DC02 and back. Watch `w32tm /query /source` on DC01 before and after.

### Check yourself

**1. Which FSMO role failure do users notice first?**

- a) Schema master
- b) Infrastructure master
- c) PDC emulator

<details><summary>Answer</summary>

**c)** The PDC emulator handles time, lockouts, and password-change forwarding, so problems show up quickly.

</details>

**2. The DC holding the RID master burned down. What do you do?**

- a) Seize the role onto a healthy DC and clean up the dead DC's metadata
- b) Transfer the role normally
- c) Nothing; RIDs aren't needed

<details><summary>Answer</summary>

**a)** Transfers need the old holder online. Seize with `-Force`, and the old DC must never return.

</details>

**3. Which DC should sync time from an external NTP source?**

- a) Every DC
- b) The forest root domain's PDC emulator
- c) The schema master

<details><summary>Answer</summary>

**b)** Only the forest root PDC emulator uses external time. Everything else follows the domain hierarchy.

</details>




---

## 11 The admin toolkit

*16 min*

*Which tool to open for which job.*

### Consoles

| Tool | Use it for |
|---|---|
| **Active Directory Users and Computers** (`dsa.msc`) | Day-to-day users, groups, computers, OUs. Turn on **Advanced Features** to see the Attribute Editor and Security tabs. |
| **Active Directory Administrative Center** (`dsac.exe`) | The Recycle Bin, fine-grained password policies, and a **PowerShell History** pane that shows the commands behind every click |
| **Active Directory Sites and Services** (`dssite.msc`) | Sites, subnets, site links, replication connections, GC setting |
| **Active Directory Domains and Trusts** (`domain.msc`) | Trusts, UPN suffixes, functional levels |
| **Group Policy Management** (`gpmc.msc`) | GPOs, links, filtering, modeling, results |
| **DNS Manager** (`dnsmgmt.msc`) | Zones, records, forwarders, scavenging |
| **ADSI Edit** (`adsiedit.msc`) | Low-level editing of any object or partition. Powerful and unforgiving. |
| **Windows Admin Center** | Browser-based management ([your WAC tutorial](../windows/admin-center)) |

On a workstation, install these as **RSAT** features: **Settings → System → Optional features → Add a feature → RSAT: Active Directory Domain Services and Lightweight Directory Services Tools** (and the Group Policy and DNS tools).

### PowerShell (ActiveDirectory module)

| Task | Cmdlet |
|---|---|
| Find | `Get-ADUser`, `Get-ADComputer`, `Get-ADGroup`, `Get-ADObject`, `Search-ADAccount` |
| Create | `New-ADUser`, `New-ADGroup`, `New-ADOrganizationalUnit`, `New-ADComputer` |
| Change | `Set-ADUser`, `Set-ADAccountPassword`, `Unlock-ADAccount`, `Enable-/Disable-ADAccount`, `Move-ADObject`, `Rename-ADObject` |
| Groups | `Add-ADGroupMember`, `Remove-ADGroupMember`, `Get-ADGroupMember -Recursive`, `Get-ADPrincipalGroupMembership` |
| Domain | `Get-ADDomain`, `Get-ADForest`, `Get-ADDomainController -Filter *` |
| Replication | `Get-ADReplicationPartnerMetadata`, `Get-ADReplicationFailure`, `Sync-ADObject` |
| Recovery | `Get-ADObject -IncludeDeletedObjects`, `Restore-ADObject` |

Add `-WhatIf` to any change to preview it, and `-Server dc02` to target a specific DC.

### Command-line diagnostics

| Command | What it tells you |
|---|---|
| `dcdiag /v /c /e /q` | Health of every DC in the forest (show only errors with `/q`) |
| `repadmin /replsummary`, `/showrepl`, `/queue` | Replication status, partners, and backlog |
| `repadmin /showobjmeta dc01 "<DN>"` | Which DC changed each attribute, and when |
| `nltest /dsgetdc:lab.local`, `/sc_verify:lab.local` | DC locator result; secure channel health |
| `netdom query fsmo` / `netdom query dc` | Role holders; list of DCs |
| `setspn -L / -Q / -X` | SPNs and duplicates |
| `klist` / `klist purge` | Kerberos tickets |
| `gpresult /r` / `/h` | Applied Group Policy |
| `w32tm /query /status` | Time sync |
| `dsquery`, `dsget`, `dsmod` | Older command-line queries, still common in scripts |
| `ntdsutil` | Database maintenance, metadata cleanup, seizing roles, snapshots, IFM media |

> [!TIP]
> **Good practice: Let the console teach you PowerShell**
>
> In ADAC, perform a task by clicking (create a user, reset a password), then open **Windows PowerShell History** at the bottom. It shows the exact cmdlet it ran, which you can copy into a script.

### Check yourself

**1. Which console restores deleted objects from the Recycle Bin with a few clicks?**

- a) ADUC
- b) Active Directory Administrative Center
- c) Sites and Services

<details><summary>Answer</summary>

**b)** ADAC has a Deleted Objects container with a Restore action once the Recycle Bin is enabled.

</details>

**2. Which command shows which DC last changed an object's attribute?**

- a) `dcdiag /test:replications`
- b) `repadmin /showobjmeta`
- c) `nltest /dsgetdc`

<details><summary>Answer</summary>

**b)** Object metadata lists each attribute's version, originating DC, and time of change, which is great for "who changed this?"

</details>

**3. How do you preview what an AD cmdlet would change?**

- a) `-Verbose`
- b) `-WhatIf`
- c) `-Confirm:$false`

<details><summary>Answer</summary>

**b)** `-WhatIf` describes the action without performing it.

</details>




---

## 12 Health checks and troubleshooting

*24 min*

*A routine for keeping AD healthy, and a playbook for the problems you'll see most.*

### A weekly health routine
```powershell
dcdiag /e /q                                   # errors only, every DC
repadmin /replsummary                          # replication failures
Get-ADReplicationFailure -Target lab.local -Scope Domain
Get-Service NTDS, DNS, Netlogon, KDC, DFSR, W32Time -ComputerName dc01, dc02 | Format-Table MachineName, Name, Status
Get-PSDrive C                                  # free space on each DC (the database and logs grow)
w32tm /monitor                                 # time offset of every DC
```
Also review: the **Directory Service**, **DNS Server**, and **DFS Replication** event logs on each DC; backup success; and privileged group membership changes. Your [PRTG lab](../infrastructure/monitoring-prtg) automates much of this.

### Common problems

| Symptom | Usual causes | First steps |
|---|---|---|
| "The trust relationship between this workstation and the primary domain failed" | Computer password out of sync (old snapshot, reimage, long offline) | `Test-ComputerSecureChannel -Repair` |
| Sign-in is slow or fails; "no logon servers available" | DNS pointing elsewhere, DC unreachable, time skew | `nltest /dsgetdc:`, `ipconfig /all`, `w32tm /query /status` |
| New user or password works on one DC but not another | Replication delay or failure | `repadmin /showrepl`, force a sync |
| GPO not applying | Wrong OU, filtering, WMI filter, SYSVOL replication | `gpresult /h`, GroupPolicy Operational log |
| Account keeps locking | Stale saved credentials somewhere | Event 4740 on the PDC emulator (Module 8) |
| "Access denied" right after being added to a group | Old token | Sign out and in, or `klist purge` |
| Kerberos errors in the System log (KDC events, "KRB_AP_ERR_MODIFIED") | Duplicate SPN, wrong DNS (name points to the wrong server), stale computer password | `setspn -X`, check DNS A records |
| Replication error 8606, lingering objects | A DC was offline beyond tombstone lifetime | `repadmin /removelingeringobjects`, or rebuild the DC |
| Replication error 1722 "RPC server is unavailable" | Firewall, DNS, or the partner DC is down | `Test-NetConnection dc02 -Port 135`, check DNS |
| Replication error -2146893022 "target principal name is incorrect" | The DC's computer password or DNS record is wrong | Check DNS records; `netdom resetpwd` on the affected DC |
| SYSVOL not replicating; new GPOs missing on some DCs | DFSR problems, often after a dirty shutdown | DFS Replication event log; `dfsrdiag` |

### Event IDs worth knowing

| ID | Log | Meaning |
|---|---|---|
| 4624 / 4625 | Security | Successful / failed sign-in |
| 4740 | Security | Account locked out |
| 4771 | Security | Kerberos pre-authentication failed (usually a bad password) |
| 4720 / 4726 | Security | User created / deleted |
| 4728 / 4732 / 4756 | Security | Member added to a global / local / universal security group |
| 5136 | Security | Directory object modified (needs Directory Service Changes auditing) |
| 4662 | Security | An operation was performed on an object (used to spot DCSync, Module 14) |
| 1311, 1865 | Directory Service | KCC can't build a complete topology (site or link problems) |
| 2042 | Directory Service | Replication hasn't happened beyond the tombstone lifetime |
| 5807 | System (Netlogon log) | Clients from undefined subnets |
| 4013 | DNS Server | DNS waiting for AD to load at startup (normal briefly; a problem if it persists) |

### Demoting and cleaning up a DC
- **Healthy DC:** `Uninstall-ADDSDomainController` (or Server Manager → remove the AD DS role) cleanly demotes it.
- **Dead DC:** delete it in ADUC (Domain Controllers OU) or Sites and Services, which performs metadata cleanup. Then remove its DNS records (A, SRV, the `_msdcs` CNAME) and seize any FSMO roles it held.

> [!TIP]
> **In your lab**
>
> Make a "break-fix" evening:
> 1. Set CLIENT01's DNS to 8.8.8.8 only. Try to sign in as a new user. Fix it.
> 2. Stop the Netlogon service on DC02 and delete its SRV records. Run `dcdiag /test:dns`. Restart Netlogon.
> 3. Block TCP 135 on DC02's firewall. Run `repadmin /replsummary`. Read the error, then fix it.
> Write each one up as a [knowledge base](../helpdesk/knowledge-base) article.

### Check yourself

**1. Replication shows error 1722, "The RPC server is unavailable." Where do you look first?**

- a) Network reachability, firewall rules for RPC, and DNS for the partner DC
- b) The partner's password policy
- c) Group Policy results

<details><summary>Answer</summary>

**a)** 1722 means the RPC connection itself failed: the partner is down, unreachable, blocked, or resolves to the wrong IP.

</details>

**2. Which event shows a member was added to a global security group?**

- a) 4740
- b) 4728
- c) 4625

<details><summary>Answer</summary>

**b)** 4728 (global), 4732 (domain local), and 4756 (universal) record group membership additions.

</details>

**3. How do you remove a DC that died and will never return?**

- a) `Uninstall-ADDSDomainController` on it
- b) Delete it from ADUC or Sites and Services (metadata cleanup), clean DNS, and seize its roles
- c) Leave it; AD forgets it after 180 days

<details><summary>Answer</summary>

**b)** A dead DC can't demote itself, so remove it from the directory, clear its DNS records, and seize its FSMO roles.

</details>




---

## 13 Backup and recovery

*20 min*

*You'll need these skills on the worst day of the year. Practice them in the lab first.*

### Three kinds of "restore"

| Situation | Tool |
|---|---|
| Someone deleted a user, group, or OU | **AD Recycle Bin** (if enabled), otherwise an authoritative restore |
| Someone made bad changes to existing objects | Restore attributes from a **snapshot** or backup, or an authoritative restore |
| A DC is broken | Build a new DC and let it replicate (fastest), or restore its system state |
| The whole forest is gone (ransomware) | **Forest recovery** from a known-good backup of one DC per domain |

### The AD Recycle Bin
Once enabled (it can't be turned off), deleted objects keep **all** attributes, including group memberships and the SID, for the **deleted object lifetime** (by default the same as the tombstone lifetime, 180 days).
```powershell
Enable-ADOptionalFeature 'Recycle Bin Feature' -Scope ForestOrConfigurationSet -Target lab.local
Get-ADObject -Filter 'Name -like "*Jane*"' -IncludeDeletedObjects | Select-Object Name, ObjectClass, Deleted
Get-ADObject -Filter 'SamAccountName -eq "jsmith"' -IncludeDeletedObjects | Restore-ADObject
```
Restore an OU **before** the objects that were in it (parents first).

### System state backups
A DC's **system state** includes the AD database (`ntds.dit`), SYSVOL, the registry, and boot files. Windows Server Backup can back it up:
```powershell
wbadmin start systemstatebackup -backupTarget:E: -quiet
wbadmin get versions
```
Backups older than the tombstone lifetime **can't** be restored. Back up at least two DCs per domain daily.

### Non-authoritative vs. authoritative restores
- **Non-authoritative:** restore a DC's system state in **Directory Services Restore Mode (DSRM)**. After rebooting, the DC receives every newer change from its partners. Use it to repair one DC.
- **Authoritative:** after a non-authoritative restore, and before rebooting normally, use `ntdsutil` to mark specific objects as authoritative. Their version numbers jump by 100,000 per day since the backup, so they **win** over the copies on other DCs and replicate back out. Use it to bring back deleted objects when there's no Recycle Bin.
```
ntdsutil
activate instance ntds
authoritative restore
restore subtree "OU=Finance,OU=Users,OU=Corp,DC=lab,DC=local"
quit
```

> [!WARNING]
> **Watch out: The DSRM password**
>
> DSRM uses a local administrator password set when the DC was promoted. If nobody recorded it, you can't use it. Reset it now and store it safely:
> ```
> ntdsutil "set dsrm password" "reset password on server null" quit quit
> ```

### Never restore a DC from a VM snapshot (the old way)
Rolling back a DC's virtual machine to an old checkpoint used to cause **USN rollback**: the DC reused USNs its partners had already seen, so its new changes were silently ignored forever. Modern hypervisors that support **VM-GenerationID** (Hyper-V, current VMware) let Windows Server detect the rollback and protect itself. Even so, treat snapshot rollback of a DC as a last resort, never a routine fix.

### AD snapshots for comparing data
`ntdsutil snapshot` creates a point-in-time copy of the database that you can mount read-only (with `dsamain`) and browse with ADUC, to see what an attribute used to be.

### Forest recovery
If every DC is compromised (ransomware is the classic case), you rebuild the forest from a backup taken **before** the attacker got in: restore one DC per domain in an isolated network, clean it, reset privileged passwords and `krbtgt` **twice**, then rebuild the remaining DCs from it. Microsoft publishes a detailed AD Forest Recovery guide. Tested, offline, immutable backups are what make this possible.

> [!TIP]
> **In your lab**
>
> Your [backup and DR tutorial](../windows/backup-dr) walks through the Recycle Bin restore, a system state backup, and a DSRM restore. Try one more: delete an OU of test users, then restore the OU and its users in the right order.

### Check yourself

**1. Someone deleted the Finance OU with 40 users. The Recycle Bin is enabled. What's restored first?**

- a) The OU, then the users inside it
- b) The users, then the OU
- c) Everything restores in one step automatically

<details><summary>Answer</summary>

**a)** Parents must exist before children can be restored. Restore the OU, then its contents (or use a recursive filter).

</details>

**2. When do you need an authoritative restore?**

- a) To repair one corrupted DC
- b) To bring back deleted objects from a backup when there's no Recycle Bin
- c) To add a new DC

<details><summary>Answer</summary>

**b)** Authoritative restore raises the objects' version numbers so the restored copies win over the deletions on other DCs.

</details>

**3. Why must the krbtgt password be reset twice during forest recovery?**

- a) To satisfy password history
- b) AD keeps the current and previous krbtgt keys, so both must be replaced to invalidate forged tickets
- c) The first reset only applies to the PDC

<details><summary>Answer</summary>

**b)** Tickets encrypted with either of the last two keys stay valid. Two resets (with replication between them) retire both.

</details>




---

## 14 Securing Active Directory

*24 min*

*Attackers target AD because it holds the keys to everything. Understanding how attacks work tells you which defenses matter.*

### How attackers usually move
Most domain compromises follow the same path: phish one user, take over their workstation, collect credentials from memory or the network, use them to reach other machines, and keep going until they find a **Domain Admin** session to steal. Then they own everything. The defenses below each break a step in that chain.

### Attack techniques to understand (and defend against)

| Technique | What it abuses | Defense |
|---|---|---|
| **Pass-the-hash** | NTLM accepts the password *hash* as if it were the password | Unique local admin passwords (**LAPS**), tiered admin accounts, restrict NTLM, Credential Guard |
| **Kerberoasting** | Any user can request a service ticket for a user account with an SPN, then crack its password offline | Use **gMSAs**/dMSAs for services; long random passwords on any remaining service accounts; AES only |
| **AS-REP roasting** | Accounts with "Do not require Kerberos preauthentication" | Turn that flag off everywhere |
| **DCSync** | Accounts with "Replicating Directory Changes All" rights can request every password hash from a DC | Only DCs should have that right. Audit it. |
| **Golden ticket** | A stolen `krbtgt` key lets an attacker forge any TGT | Protect Tier 0; reset `krbtgt` periodically (twice, 10+ hours apart) |
| **NTLM relay** | Forwarding an NTLM authentication to another server | SMB signing, LDAP signing and channel binding, EPA on web services, disable NTLM where possible |
| **AD CS template abuse** | Misconfigured certificate templates let users request certificates as someone else | Review templates (no "supply in request" for client auth without approval) |
| **Weak delegation** | Unconstrained delegation on servers | Use constrained or resource-based delegation; mark admins **sensitive and cannot be delegated** |

### High-value defenses
1. **Separate admin accounts** and the **tier model** (Module 9). Domain Admins sign in only to DCs and dedicated admin workstations (**PAWs**).
2. **Small privileged groups.** Know every member of Domain Admins, Enterprise Admins, and Administrators. Review them monthly. Alert on changes (events 4728/4732/4756).
3. **Protected Users** for admin accounts: no NTLM, no DES/RC4, no delegation, no cached credentials, 4-hour TGTs. Test first; it can break things that depend on NTLM.
4. **Windows LAPS** on every workstation and member server.
5. **Kill legacy protocols:** audit and reduce NTLM, require SMB and LDAP signing, disable SMBv1 and RC4. Windows Server 2025 KDCs no longer issue RC4 TGTs.
6. **Credential Guard** on Windows 11 Enterprise (on by default on eligible devices) protects credentials in memory.
7. **Patch DCs first** each month, and don't install anything else on them: no browsing, no email, no extra roles.
8. **Audit:** enable Advanced Audit Policy for account logon, account management, directory service changes, and privilege use. Send DC logs to a SIEM.
9. **Assess:** free tools such as **PingCastle** and **Purple Knight** score your AD's security and list fixes. Microsoft Defender for Identity watches DC traffic for attacks.
10. **Backups that attackers can't reach**, and a practiced recovery plan (Module 13).

```powershell
# Accounts with SPNs (Kerberoasting candidates) that aren't computers
Get-ADUser -Filter 'ServicePrincipalName -like "*"' -Properties ServicePrincipalName, PasswordLastSet
# Accounts that don't require Kerberos pre-authentication
Get-ADUser -Filter 'DoesNotRequirePreAuth -eq $true'
# Computers trusted for unconstrained delegation (DCs are expected)
Get-ADComputer -Filter 'TrustedForDelegation -eq $true'
# Accounts whose passwords never expire
Get-ADUser -Filter 'PasswordNeverExpires -eq $true -and Enabled -eq $true'
```

> [!TIP]
> **In your lab**
>
> Run those four queries in your lab, then download PingCastle on APP01 and run a health check against `lab.local`. Fix three findings, run it again, and compare the scores. It pairs well with your [hardening lab](../security/windows-hardening-lab).

### Check yourself

**1. Why are service accounts with SPNs a target?**

- a) Any user can request a ticket for them and try to crack the password offline
- b) They can't have passwords
- c) They're automatically Domain Admins

<details><summary>Answer</summary>

**a)** That's Kerberoasting. Long random passwords, or better, gMSAs, make cracking impractical.

</details>

**2. What does putting admins in Protected Users do?**

- a) Hides them from the address book
- b) Blocks NTLM, RC4, delegation, and credential caching for them
- c) Gives them more rights

<details><summary>Answer</summary>

**b)** Protected Users hardens how those accounts authenticate. Test it first, because NTLM-dependent tools stop working for them.

</details>

**3. Which right lets an account pull every password hash from a DC?**

- a) Reset password
- b) Replicating Directory Changes All
- c) Read all properties

<details><summary>Answer</summary>

**b)** That's the DCSync right. Only domain controllers should hold it.

</details>




---

## 15 Today's AD: Windows Server 2025 and hybrid

*14 min*

*Where AD is heading, and how it fits with the cloud.*

### Windows Server 2025 changes
- **New functional level** (domain and forest level 10) and an optional **32k database page size**, which raises the limit on values in multivalued attributes (large groups). It requires every DC in the forest to support it.
- **Stronger defaults:** LDAP signing and sealing required for new deployments, confidential attributes only over encrypted connections, random default passwords for new computer accounts, and legacy remote SAM password-change methods blocked.
- **Kerberos:** RC4 TGTs are no longer issued; the encryption types registry value is replaced by Group Policy.
- **dMSA** for migrating classic service accounts to managed keys.
- **Scale:** AD DS can use more than 64 CPU cores (NUMA-aware).
- **DC discovery** no longer uses mailslots (WINS and mailslots are deprecated).

### AD and Entra ID together
Most organizations keep AD for Windows sign-in, file servers, and older apps, and use **Entra ID** for Microsoft 365, SaaS apps, MFA, and Conditional Access. **Entra Connect Sync** or **Entra Cloud Sync** copies users and groups to the cloud, usually with password hash sync.

| Device state | Where it's joined | Typical use |
|---|---|---|
| **AD domain-joined** | AD only | Traditional on-premises PCs |
| **Microsoft Entra hybrid joined** | AD and registered in Entra ID | Existing domain PCs that also need cloud features |
| **Microsoft Entra joined** | Entra ID only, managed by Intune | New laptops deployed with Autopilot. Can still reach on-premises file shares with **Kerberos cloud trust** / Windows Hello for Business. |

The direction for **new devices** is Entra join with Intune. AD remains for servers, legacy apps, and on-premises resources, and it isn't going away soon.

### Where to go next
- Microsoft Learn: **AZ-800 / AZ-801** (Windows Server Hybrid Administrator)
- Microsoft's *Best Practices for Securing Active Directory* and the *Enterprise Access Model*
- Your lab: the [hybrid identity tutorial](../m365/hybrid-identity), then the [Intune lab](../m365/intune-autopilot) for Entra-joined devices

### Check yourself

**1. What is required to use the 32k database page size?**

- a) Any Windows Server 2025 DC
- b) Every DC in the forest supporting it, at the new functional level
- c) An Entra ID P2 license

<details><summary>Answer</summary>

**b)** The 32k page format is forest-wide and needs the Windows Server 2025 functional level.

</details>

**2. A new laptop is joined only to Entra ID and managed by Intune. What's that called?**

- a) Hybrid joined
- b) Microsoft Entra joined
- c) Domain-joined

<details><summary>Answer</summary>

**b)** Entra joined devices have no AD computer account. They can still reach on-premises resources with Kerberos cloud trust.

</details>




---

*Written in plain language from Microsoft's documentation, current as of Windows Server 2025. Check settings against Microsoft Learn before changing production systems.*
