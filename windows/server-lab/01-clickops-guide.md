# 🖱️ Click-Ops Guide: Build the Lab Through the GUI

This tutorial builds the whole lab with Server Manager and the standard admin consoles, the way most admins first learn it. Each part explains **what** you're doing, **why** it matters, and ends with a **✅ Check your work** step so you never build on a broken foundation.

Before you start, read the [lab overview](./README.md) for the plan: names, IP addresses, OUs, and groups. This guide uses those exact values.

> **Conventions**
> - `Start → Run` means press **Win + R** and type the command.
> - 📸 marks a good moment to take a screenshot for your portfolio.
> - 💾 marks a good moment to take a VM **checkpoint** (snapshot) you can roll back to.

---

## Contents

1. [Download ISOs and create the VMs](#part-1-download-isos-and-create-the-vms)
2. [Install Windows Server and prepare DC01](#part-2-install-windows-server-and-prepare-dc01)
3. [Install Active Directory and promote DC01](#part-3-install-active-directory-and-promote-dc01)
4. [Configure DNS and DHCP](#part-4-configure-dns-and-dhcp)
5. [Build the OUs, groups, and users](#part-5-build-the-ous-groups-and-users)
6. [Password policy and Group Policy](#part-6-password-policy-and-group-policy)
7. [Prepare APP01 and join the domain](#part-7-prepare-app01-and-join-the-domain)
8. [Build the application server](#part-8-build-the-application-server)
9. [Join CLIENT01 and test as an employee](#part-9-join-client01-and-test-as-an-employee)
10. [Verify, back up, and troubleshoot](#part-10-verify-back-up-and-troubleshoot)

---

## Part 1: Download ISOs and create the VMs

### 1.1 Download the evaluation ISOs

From the **Microsoft Evaluation Center** (search "Microsoft Evaluation Center"), download:

- **Windows Server 2022** ISO (180-day evaluation)
- **Windows 11 Enterprise** ISO (90-day evaluation)

Save both to `C:\ISO\`.

> Windows Server 2025 is also available and works almost identically. This guide uses 2022 because it's what most employers still run.

### 1.2 Create the lab network

The lab needs its own network so DC01's DHCP server doesn't hand out addresses on your home network, while still reaching the internet for updates.

<details open>
<summary><b>Option A: Hyper-V</b> (Windows 10/11 Pro or Enterprise)</summary>

1. Turn on Hyper-V: `Start → Run → optionalfeatures`, check **Hyper-V**, restart.
2. Open **Hyper-V Manager** → **Virtual Switch Manager** (right pane).
3. **New virtual network switch** → **Internal** → **Create Virtual Switch**.
4. Name it `LabSwitch` → **OK**.
5. Give your PC the gateway address on that switch: `Start → Run → ncpa.cpl` → right-click **vEthernet (LabSwitch)** → **Properties** → **Internet Protocol Version 4** → **Use the following IP address**:
   - IP address `10.10.10.1`, subnet mask `255.255.255.0`, no gateway → **OK**.
6. Create the NAT. Hyper-V has no GUI for this, so open **PowerShell as administrator** and run this one line:
   ```powershell
   New-NetNat -Name LabNAT -InternalIPInterfaceAddressPrefix 10.10.10.0/24
   ```
</details>

<details>
<summary><b>Option B: VirtualBox</b> (any Windows, macOS, or Linux PC)</summary>

1. **File → Tools → Network Manager → NAT Networks → Create**.
2. Name `LabNet`, IPv4 prefix `10.10.10.0/24`. **Uncheck "Enable DHCP"**: DC01 will be the DHCP server.
3. **Apply**. VirtualBox uses `10.10.10.1` as the gateway automatically, matching the plan.
</details>

**Why internal + NAT?** An *external* switch would put DC01's DHCP server on your home network and could hand out addresses to your family's devices. NAT keeps the lab isolated but online.

### 1.3 Create the three VMs

Create **DC01**, **APP01**, and **CLIENT01** with the sizes in the [plan](./README.md#machines).

<details open>
<summary><b>Hyper-V</b></summary>

For each VM: **New → Virtual Machine**.

| Wizard page | Setting |
|---|---|
| Name and location | `DC01` (then `APP01`, `CLIENT01`) |
| Generation | **Generation 2** |
| Memory | `4096` MB, **uncheck** "Use Dynamic Memory" |
| Networking | `LabSwitch` |
| Virtual hard disk | Create: 60 GB (64 GB for CLIENT01) |
| Installation options | Install from a bootable image file → choose the ISO |

Then open the VM's **Settings**:
- **Processor** → 2 virtual processors.
- **Security** → check **Enable Trusted Platform Module** (required for CLIENT01's Windows 11, harmless on servers).
- **Checkpoints** → uncheck **Use automatic checkpoints**.
</details>

<details>
<summary><b>VirtualBox</b></summary>

For each VM: **Machine → New**.

| Setting | Value |
|---|---|
| Name | `DC01` / `APP01` / `CLIENT01` |
| ISO image | The Server ISO (CLIENT01: the Windows 11 ISO) |
| Skip Unattended Installation | ✅ **Check it** (you'll install manually) |
| Memory / CPUs | 4096 MB / 2 |
| Disk | 60 GB (64 GB for CLIENT01) |

Then **Settings → Network → Adapter 1 → Attached to: NAT Network → LabNet**.
</details>

### ✅ Check your work
- Three VMs exist, each with 2 CPUs, 4 GB RAM, and an ISO attached.
- Hyper-V: `ipconfig` on your PC shows `10.10.10.1` on vEthernet (LabSwitch).

---

## Part 2: Install Windows Server and prepare DC01

### 2.1 Install Windows Server

1. Start **DC01** and connect to its console. Press a key when you see *Press any key to boot from CD or DVD*.
2. Choose language → **Install now**.
3. Select **Windows Server 2022 Standard Evaluation (Desktop Experience)**.
   > ⚠️ The option *without* "Desktop Experience" is Server Core: no GUI. You want the GUI for this track.
4. Accept the license → **Custom: Install Microsoft Server Operating System only** → select the disk → **Next**.
5. After it restarts, set the **Administrator** password.
6. Sign in. In Hyper-V, use **Action → Ctrl+Alt+Delete**. In VirtualBox, press **Right Ctrl + Del**.

**Server Manager** opens automatically. That's your home base for this lab.

### 2.2 Set the static IP address

A domain controller **must** have an address that never changes, because every machine in the domain finds it by IP through DNS.

1. Server Manager → **Local Server** → click the link next to **Ethernet** (or `Start → Run → ncpa.cpl`).
2. Right-click the adapter → **Properties** → **Internet Protocol Version 4 (TCP/IPv4)** → **Properties**.
3. Enter:

   | Field | Value |
   |---|---|
   | IP address | `10.10.10.10` |
   | Subnet mask | `255.255.255.0` |
   | Default gateway | `10.10.10.1` |
   | Preferred DNS | `1.1.1.1` |
   | Alternate DNS | `8.8.8.8` |

4. **OK** → **Close**.

> **Why public DNS for now?** DC01 isn't a DNS server yet, and it needs internet name resolution to download updates. You'll point it at itself in Part 4.

### 2.3 Name, time zone, Remote Desktop, updates

In **Server Manager → Local Server**, click each blue link:

| Setting | What to do |
|---|---|
| **Time zone** | Set yours, for example *(UTC-05:00) Eastern Time*. Kerberos fails if clocks drift more than 5 minutes apart, and DC01 becomes the domain's time source. |
| **Remote Desktop** | **Allow remote connections** and keep **Network Level Authentication** checked. |
| **Windows Update** | Install all updates. This can take a while. |
| **Computer name** | **Change** → `DC01` → **OK** → restart when prompted. Do this last, since it requires a restart. |

> ⚠️ **Rename before promoting to a DC.** Renaming a domain controller afterward is possible but painful.

### ✅ Check your work
Open **Command Prompt** and run:
```cmd
hostname
ipconfig /all
ping 10.10.10.1
nslookup www.microsoft.com
```
You should see `DC01`, IP `10.10.10.10`, replies from the gateway, and an answer from DNS.

💾 **Checkpoint:** `DC01 - clean install`

---

## Part 3: Install Active Directory and promote DC01

This is the moment DC01 becomes the heart of the network. **Active Directory Domain Services (AD DS)** stores every user, computer, and group, and handles sign-in (Kerberos) for the whole domain.

### 3.1 Install the AD DS role

1. **Server Manager → Manage → Add Roles and Features**.
2. **Role-based or feature-based installation** → select **DC01**.
3. Check **Active Directory Domain Services** → **Add Features** → **Next** through to **Install**.

Installing the role only copies the files. Nothing changes until you promote the server.

### 3.2 Promote DC01 to a domain controller

1. When installation finishes, click the **yellow flag** in Server Manager → **Promote this server to a domain controller**.
2. Walk through the wizard:

| Page | Setting | Why |
|---|---|---|
| Deployment Configuration | **Add a new forest**, root domain `lab.local` | This is the first DC, so it creates a brand-new forest |
| Domain Controller Options | Functional level **Windows Server 2016** (forest and domain); ✅ **DNS server**; ✅ Global Catalog (required for the first DC); set the **DSRM password** | AD relies on DNS. DSRM is the emergency password for restoring AD. Store it safely. |
| DNS Options | Ignore the *"delegation can't be created"* warning | Normal for a new forest: there's no parent zone to delegate from |
| Additional Options | NetBIOS name `LAB` | The short name users type as `LAB\username` |
| Paths | Keep the defaults | Database, logs, and SYSVOL |
| Review Options | Click **View script** 👀 | Shows the PowerShell this wizard runs. Compare it with `02-Install-DomainController.ps1`. |
| Prerequisites Check | Warnings are normal; errors are not | |

3. **Install**. DC01 restarts automatically.

### 3.3 Sign in to the domain

Sign in as **`LAB\Administrator`** (same password as before). Notice the sign-in screen now says *Sign in to: LAB*.

### ✅ Check your work
1. Server Manager now shows **AD DS** and **DNS** in the left pane.
2. `Start → Run → dsa.msc` opens **Active Directory Users and Computers**, and you see `lab.local`.
3. In **Command Prompt (Admin)**:
   ```cmd
   nltest /dsgetdc:lab.local
   dcdiag /q
   ```
   `nltest` names DC01. `dcdiag /q` prints **nothing** when everything passes. Any output is a problem to read.

📸 Screenshot: ADUC showing `lab.local`
💾 **Checkpoint:** `DC01 - domain controller`

---

## Part 4: Configure DNS and DHCP

### 4.1 Point DC01 at itself for DNS

During promotion, Windows set DC01's DNS to `127.0.0.1`. Best practice is to use its real IP instead:

1. `ncpa.cpl` → adapter → **Properties** → **IPv4** → Preferred DNS `10.10.10.10`, clear the alternate → **OK**.

> In a real domain with two DCs, each DC points first at its **partner** and second at itself, so a DC that's booting doesn't depend on itself.

### 4.2 Create the reverse lookup zone

A **reverse zone** answers "what name has IP 10.10.10.20?" Troubleshooting tools, logs, and some security tools rely on it.

1. `Start → Run → dnsmgmt.msc` → expand **DC01** → right-click **Reverse Lookup Zones** → **New Zone**.
2. **Primary zone**, ✅ *Store the zone in Active Directory*.
3. Replication: **To all DNS servers running on domain controllers in this domain: lab.local**.
4. **IPv4 Reverse Lookup Zone** → Network ID `10.10.10`.
5. Dynamic updates: **Allow only secure dynamic updates** (only domain members can register records).
6. **Finish**.

Then register DC01's own reverse (PTR) record. In **Command Prompt (Admin)**:
```cmd
ipconfig /registerdns
```

### 4.3 Add forwarders

DC01 only knows about `lab.local`. **Forwarders** tell it where to send everything else, like `microsoft.com`.

1. In DNS Manager, right-click **DC01** → **Properties** → **Forwarders** tab → **Edit**.
2. Add `1.1.1.1` and `8.8.8.8` → **OK** → **OK**.

### ✅ Check your work (DNS)
```cmd
nslookup dc01.lab.local
nslookup 10.10.10.10
nslookup www.microsoft.com
```
All three should answer. The second one proves the reverse zone works. If it doesn't, wait a minute, then refresh the zone in DNS Manager.

### 4.4 Install DHCP

**DHCP** hands out IP addresses, the gateway, and the DNS server to workstations automatically.

1. **Add Roles and Features** → **DHCP Server** → **Add Features** → **Install**.
2. Click the **yellow flag** → **Complete DHCP configuration** → **Commit**. This creates the DHCP security groups and **authorizes** the server in AD.
   > **Why authorize?** In a domain, an unauthorized DHCP server refuses to hand out addresses. This stops a rogue DHCP server from hijacking clients.

### 4.5 Create the scope

1. `Start → Run → dhcpmgmt.msc` → expand **dc01.lab.local** → right-click **IPv4** → **New Scope**.

| Wizard page | Setting |
|---|---|
| Name | `Lab clients` |
| IP range | Start `10.10.10.100`, end `10.10.10.200`, length `24` |
| Exclusions | None (the servers' static IPs are outside the range) |
| Lease duration | 8 days |
| Configure options now? | **Yes** |
| Router (default gateway) | `10.10.10.1` → **Add** |
| Domain name and DNS servers | Parent domain `lab.local`, DNS server `10.10.10.10` (remove any others) |
| WINS | Skip |
| Activate scope | **Yes** |

2. Make DHCP register clients in DNS: right-click **IPv4** → **Properties** → **DNS** tab:
   - ✅ *Always dynamically update DNS records*
   - ✅ *Discard A and PTR records when lease is deleted*

### ✅ Check your work (DHCP)
In the DHCP console, **IPv4** and the scope show **green check marks**, and **Scope Options** lists 003 Router, 006 DNS Servers, and 015 DNS Domain Name.

💾 **Checkpoint:** `DC01 - DNS and DHCP`

---

## Part 5: Build the OUs, groups, and users

### 5.1 Turn on Advanced Features

`dsa.msc` → **View → Advanced Features**. This shows the *Protect object from accidental deletion* option and the hidden system containers.

### 5.2 Create the OU structure

**Why not just use the built-in Users and Computers folders?** They're *containers*, not OUs, so you **can't link Group Policy to them**. Real environments put everything in OUs.

1. Right-click **lab.local** → **New → Organizational Unit** → `Corp`, ✅ Protect from accidental deletion.
2. Right-click **Corp** → create: `Admins`, `Users`, `Computers`, `Servers`, `Groups`, `Service Accounts`.
3. Right-click **Corp\Users** → create: `Finance`, `HR`, `IT`.

### 5.3 Redirect the default containers

When a computer joins the domain through the GUI, it lands in the built-in **Computers** container, where your GPOs can't reach it. Redirect new objects into your OUs. There's no GUI for this, so run in **Command Prompt (Admin)**:
```cmd
redircmp "OU=Computers,OU=Corp,DC=lab,DC=local"
redirusr "OU=Users,OU=Corp,DC=lab,DC=local"
```

### 5.4 Create the groups (AGDLP)

In **Corp\Groups**, right-click → **New → Group** for each:

| Group name | Group scope | Group type |
|---|---|---|
| `GG-Finance-Staff` | Global | Security |
| `GG-HR-Staff` | Global | Security |
| `GG-IT-Staff` | Global | Security |
| `GG-Intranet-Servers` | Global | Security |
| `DL-FinanceShare-Modify` | **Domain local** | Security |
| `DL-FinanceShare-Read` | **Domain local** | Security |

Then nest the role groups into the resource groups:
- Open **DL-FinanceShare-Modify** → **Members** → **Add** → `GG-Finance-Staff`.
- Open **DL-FinanceShare-Read** → **Members** → **Add** → `GG-HR-Staff`.

> **AGDLP in one sentence:** people go in role groups, role groups go in resource groups, and only resource groups get permissions. When Jane moves from Finance to HR, you change *one* membership.

### 5.5 Create the users

For each person below, right-click their department OU → **New → User**:

| Name | Logon name | OU | Group |
|---|---|---|---|
| Nathaniel Wang | `nwang` | IT | GG-IT-Staff |
| Carlos Reyes | `creyes` | IT | GG-IT-Staff |
| Jane Smith | `jsmith` | Finance | GG-Finance-Staff |
| Marcus Johnson | `mjohnson` | Finance | GG-Finance-Staff |
| Priya Patel | `ppatel` | HR | GG-HR-Staff |
| Dana Lee | `dlee` | HR | GG-HR-Staff |

- Set a temporary password, ✅ **User must change password at next logon**.
- Then right-click the user → **Add to a group** → their `GG-` group.
- Open each user's **Properties → Organization** and fill in **Job Title** and **Department**. Real help desks rely on these fields.

> 💡 **Time saver:** fill in one user completely, then right-click → **Copy**. The copy keeps the groups and department. This is how many help desks onboard people.

### 5.6 Create your admin account

1. In **Corp\Admins** → **New → User** → `Nathaniel Wang (Admin)`, logon `adm-nwang`, strong password, *don't* require a change.
2. Right-click → **Add to a group** → `Domain Admins`.
3. **Sign out** and sign back in as **`LAB\adm-nwang`**. Use this account for the rest of the lab.

> **Why two accounts?** You read email and browse as `nwang`. If that account gets phished, the attacker *doesn't* get Domain Admin. This separation is called **tiering**, and it's one of the most effective AD security practices.

### 5.7 Create the intranet service account (gMSA)

A **Group Managed Service Account** runs a service (here, the intranet website) with a password that **AD generates and rotates automatically**. Nobody knows it, nobody types it, and it never expires and breaks the app. There's no GUI for creating one, so open **PowerShell as administrator** on DC01:

```powershell
# One-time per domain. Backdating makes it usable immediately: LAB ONLY.
Add-KdsRootKey -EffectiveTime ((Get-Date).AddHours(-10))

New-ADServiceAccount -Name gmsa-intranet -DNSHostName gmsa-intranet.lab.local `
    -PrincipalsAllowedToRetrieveManagedPassword GG-Intranet-Servers `
    -Path "OU=Service Accounts,OU=Corp,DC=lab,DC=local"
```

Only computers in **GG-Intranet-Servers** can use it. APP01 joins that group in Part 8.

### ✅ Check your work
- ADUC shows the full `Corp` tree with users in their department OUs.
- Open **DL-FinanceShare-Modify → Members**: it lists `GG-Finance-Staff`.
- Refresh **Corp\Service Accounts**: `gmsa-intranet` is there.

📸 Screenshot: the expanded OU tree in ADUC

---

## Part 6: Password policy and Group Policy

`Start → Run → gpmc.msc` opens **Group Policy Management**.

### 6.1 Domain password and lockout policy

Domain password policy lives in the **Default Domain Policy**, linked at the domain root.

1. Expand **Forest → Domains → lab.local** → right-click **Default Domain Policy** → **Edit**.
2. **Computer Configuration → Policies → Windows Settings → Security Settings → Account Policies**:

| Policy | Setting |
|---|---|
| **Password Policy** → Enforce password history | 24 |
| Maximum password age | 365 days |
| Minimum password age | 1 day |
| Minimum password length | 14 |
| Password must meet complexity requirements | Enabled |
| **Account Lockout Policy** → Account lockout threshold | 5 invalid attempts |
| Account lockout duration | 15 minutes |
| Reset account lockout counter after | 15 minutes |

### 6.2 Create the ADMX Central Store

Group Policy settings come from **ADMX templates**. A Central Store makes every admin's editor use the same templates. In **File Explorer**, copy the folder:

- From: `C:\Windows\PolicyDefinitions`
- To: `\\lab.local\SYSVOL\lab.local\Policies\`

### 6.3 Computer security baseline GPO

1. Right-click **Corp\Computers** → **Create a GPO in this domain, and Link it here** → `Corp - Computer Security Baseline`.
2. Right-click it → **Edit**, then set:

| Path (under Computer Configuration → Policies → Administrative Templates) | Setting | Why |
|---|---|---|
| Network → DNS Client → **Turn off multicast name resolution** | Enabled | Disables LLMNR, which attackers abuse to capture password hashes |
| Windows Components → Remote Desktop Services → Remote Desktop Session Host → Security → **Require user authentication for remote connections by using Network Level Authentication** | Enabled | Users must authenticate before an RDP session starts |
| Windows Components → Windows PowerShell → **Turn on PowerShell Script Block Logging** | Enabled | Records what PowerShell runs (Event ID 4104), which is critical for investigations |
| Windows Components → Internet Explorer → Internet Control Panel → Security Page → **Site to Zone Assignment List** | Enabled → **Show** → value name `intranet.lab.local`, value `1` | Puts the intranet in the *Local intranet* zone, so browsers sign users in automatically instead of prompting |

3. Link the same GPO to servers: right-click **Corp\Servers** → **Link an Existing GPO** → `Corp - Computer Security Baseline`.

### 6.4 User settings GPO

1. Right-click **Corp\Users** → **Create a GPO… and Link it here** → `Corp - User Settings` → **Edit**.
2. **User Configuration → Policies → Administrative Templates → Control Panel → Personalization**:
   - **Enable screen saver** → Enabled
   - **Password protect the screen saver** → Enabled
   - **Screen saver timeout** → Enabled, `900` seconds

### 6.5 Bonus: map the Finance drive for Finance staff

This uses **Group Policy Preferences**, a GUI-only feature with no built-in PowerShell cmdlets.

1. Edit `Corp - User Settings` → **User Configuration → Preferences → Windows Settings → Drive Maps** → **New → Mapped Drive**.
2. Action **Update**, Location `\\APP01\Finance`, Label `Finance`, Drive letter **F:**.
3. **Common** tab → ✅ **Item-level targeting** → **Targeting… → New Item → Security Group** → `LAB\GG-Finance-Staff`.

### ✅ Check your work
In GPMC, click **Corp\Computers** → **Linked Group Policy Objects** tab: the baseline is listed. Click the GPO → **Settings** tab to see a readable report of everything you set.

📸 Screenshot: the GPO Settings report
💾 **Checkpoint:** `DC01 - AD built`

---

## Part 7: Prepare APP01 and join the domain

### 7.1 Install and prepare

Repeat **Part 2** on **APP01**, with these differences:

| Setting | APP01 value |
|---|---|
| IP address | `10.10.10.20` |
| Preferred DNS | **`10.10.10.10`** (DC01). No alternate. |
| Computer name | `APP01` |

> ⚠️ **DNS must point at DC01.** Joining a domain starts with a DNS lookup for the domain controller. With public DNS, the join fails with *"An Active Directory Domain Controller for the domain could not be contacted."* This is the most common domain-join mistake.

### 7.2 Join the domain

1. **Server Manager → Local Server** → click **WORKGROUP** → **Change**.
2. **Member of: Domain** → `lab.local` → **OK**.
3. Enter **`LAB\adm-nwang`** and its password → *Welcome to the lab.local domain* → restart.

### 7.3 Move APP01 to the Servers OU

The GUI join put APP01 in **Corp\Computers** (thanks to `redircmp`). Servers belong in **Corp\Servers**:

1. On DC01, open **ADUC** → **Corp\Computers** → right-click **APP01** → **Move** → **Corp\Servers**.

> The PowerShell track joins straight into the right OU with `Add-Computer -OUPath`. That's one advantage of scripting.

### ✅ Check your work
Sign in to APP01 as **`LAB\adm-nwang`**. In **Command Prompt (Admin)**:
```cmd
whoami
nltest /sc_query:lab.local
gpupdate /force
gpresult /r /scope computer
```
`nltest` reports a healthy secure channel, and `gpresult` lists **Corp - Computer Security Baseline**.

💾 **Checkpoint:** `APP01 - domain joined`

---

## Part 8: Build the application server

APP01 will host two things a real company runs: an internal **website** (IIS) running under the gMSA with Windows sign-in, and a **department file share** secured with AGDLP groups.

### 8.1 Let APP01 use the gMSA

1. On **DC01**, ADUC → **Corp\Groups** → **GG-Intranet-Servers** → **Members** → **Add** → **Object Types** → ✅ **Computers** → `APP01` → **OK**.
2. **Restart APP01** so its Kerberos ticket includes the new group membership.

### 8.2 Create the intranet DNS name

Users should browse to a friendly name, not a server name. If the site moves to a new server later, you only change DNS.

1. On DC01, DNS Manager → **Forward Lookup Zones → lab.local** → right-click → **New Alias (CNAME)**.
2. Alias name `intranet`, target FQDN `app01.lab.local` → **OK**.

### 8.3 Install IIS and tools on APP01

**Add Roles and Features** on APP01:

| Page | Select |
|---|---|
| Server Roles | **Web Server (IIS)** → Add Features |
| Role Services → Security | ✅ **Windows Authentication** |
| Role Services → Application Development | ✅ **ASP.NET 4.8** (accept added features) |
| Role Services → Management Tools | ✅ IIS Management Console (already checked) |
| Features → Remote Server Administration Tools → Role Administration Tools → AD DS and AD LDS Tools | ✅ **Active Directory module for Windows PowerShell** |

### 8.4 Install the gMSA on APP01

There's no GUI for this step. In **PowerShell as administrator** on APP01:
```powershell
Install-ADServiceAccount -Identity gmsa-intranet
Test-ADServiceAccount -Identity gmsa-intranet   # must return True
```
If it returns **False**, APP01 hasn't picked up the group membership yet. Restart it and try again.

### 8.5 Create the site content

1. Create the folder `C:\inetpub\intranet`.
2. In Notepad, save this as `C:\inetpub\intranet\index.html` (set *Save as type* to **All Files**):
   ```html
   <!DOCTYPE html>
   <html><head><title>LAB Intranet</title></head>
   <body style="font-family: Segoe UI; max-width: 640px; margin: 48px auto;">
     <h1>Welcome to the LAB intranet</h1>
     <p>Served by APP01, running as LAB\gmsa-intranet$.</p>
   </body></html>
   ```
3. Give the gMSA read access: right-click the folder → **Properties → Security → Edit → Add** → **Object Types** → ✅ **Service Accounts** → `gmsa-intranet` → **Read & execute** → **OK**.

### 8.6 Configure IIS

Open **IIS Manager** (`Start → Run → inetmgr`).

**Application pool** (the process that runs the site):
1. **Application Pools → Add Application Pool** → name `IntranetPool`, .NET CLR v4.0, Integrated → **OK**.
2. Select it → **Advanced Settings** → **Identity** → **…** → **Custom account → Set**:
   - User name: `LAB\gmsa-intranet$` (note the **$**)
   - Password: **leave blank**. AD manages it.

**Website:**
1. Right-click **Sites → Add Website**:

| Field | Value |
|---|---|
| Site name | `Intranet` |
| Application pool | `IntranetPool` (click **Select**) |
| Physical path | `C:\inetpub\intranet` |
| Binding | http, port 80, host name `intranet.lab.local` |

2. Select **Intranet** → **Authentication**: **Anonymous Authentication → Disable**, **Windows Authentication → Enable**.

**HTTPS:** IIS Manager's *Create Self-Signed Certificate* always uses the server's own name (`APP01`), which would cause a name-mismatch warning. Create one for the right name with this PowerShell line instead:
```powershell
New-SelfSignedCertificate -DnsName intranet.lab.local -CertStoreLocation Cert:\LocalMachine\My -FriendlyName "LAB intranet (self-signed)"
```
Then **Intranet → Bindings → Add**: type **https**, host name `intranet.lab.local`, ✅ **Require Server Name Indication**, SSL certificate **LAB intranet (self-signed)** → **OK**.

> In a real company, an internal certificate authority (AD Certificate Services) issues this certificate, so browsers trust it without warnings.

### 8.7 Create the Finance share

**NTFS permissions** (what users can do with the files):
1. Create `C:\Shares\Finance` → **Properties → Security → Advanced**.
2. **Disable inheritance** → **Remove all inherited permissions from this object**.
3. **Add** these entries (*This folder, subfolders and files*):

| Principal | Permission |
|---|---|
| SYSTEM | Full control |
| Administrators | Full control |
| LAB\DL-FinanceShare-Modify | Modify |
| LAB\DL-FinanceShare-Read | Read & execute |

**Share** (how users reach it over the network):
1. **Server Manager → File and Storage Services → Shares → Tasks → New Share** → **SMB Share - Quick**.
2. Path `C:\Shares\Finance`, share name `Finance`.
3. **Other Settings** → ✅ **Enable access-based enumeration** (users only *see* folders they can open).
4. **Permissions** → keep the NTFS permissions you set. For share permissions, use **Customize permissions → Share** tab: remove *Everyone*, add **Authenticated Users: Change** and **Administrators: Full Control**.

> **Common practice:** keep share permissions broad (Authenticated Users) and control access with NTFS. Two layers of fine-grained permissions are hard to troubleshoot, and the more restrictive one always wins.

### ✅ Check your work
- IIS Manager shows **Intranet** started, with http and https bindings.
- Do the real test from **CLIENT01** in Part 9. Browsing to `intranet.lab.local` *on APP01 itself* often fails with 401 because of Windows' loopback check. That's expected.

📸 Screenshots: the app pool identity dialog, the site bindings, the Finance folder's Advanced Security Settings
💾 **Checkpoint:** `APP01 - app server`

---

## Part 9: Join CLIENT01 and test as an employee

### 9.1 Install Windows 11

1. Boot CLIENT01 from the Windows 11 Enterprise ISO and install.
2. During setup, choose **Sign-in options → Domain join instead** to create a local account (no Microsoft account needed).

### 9.2 Check that DHCP works

Don't set a static IP. Open **Command Prompt**:
```cmd
ipconfig /all
```
You should see an address between `10.10.10.100` and `.200`, gateway `10.10.10.1`, DNS server `10.10.10.10`, and DNS suffix `lab.local`. That's your DHCP scope working. In the DHCP console on DC01, **Address Leases** now lists CLIENT01.

### 9.3 Join the domain

1. **Settings → System → About → Domain or workgroup → Change**.
2. **Member of: Domain** → `lab.local` → credentials **`LAB\adm-nwang`** → restart.

CLIENT01 lands in **Corp\Computers** automatically, so the baseline GPO applies with no extra steps.

### 9.4 Test as Jane from Finance

1. At the sign-in screen, choose **Other user** → `LAB\jsmith` → temporary password → set a new one.

   > If Windows refuses the new password, remember the 14-character minimum from Part 6.
2. Run these checks:

| Test | How | Expected |
|---|---|---|
| Group Policy | `gpresult /r` | Computer: *Corp - Computer Security Baseline*; User: *Corp - User Settings* |
| Intranet | Edge → `https://intranet.lab.local` → *Advanced → Continue* past the self-signed warning | The welcome page, **with no password prompt** |
| File share | Explorer → `\\APP01\Finance` (or the **F:** drive, if you did 6.5) | Can create and edit files |
| Screen lock | Wait 15 minutes | Screen locks |

### 9.5 Test as someone outside Finance

Sign out, then sign in as **`LAB\ppatel`** (HR) and **`LAB\creyes`** (IT):

| User | `\\APP01\Finance` |
|---|---|
| ppatel (HR) | Can open and read files, but **can't** save changes |
| creyes (IT) | **Access denied** |

That's AGDLP working: HR is in `GG-HR-Staff` → `DL-FinanceShare-Read`, and IT isn't in either resource group.

📸 Screenshots: the intranet page, the access-denied message, `gpresult`

---

## Part 10: Verify, back up, and troubleshoot

### 10.1 Health checks

On **DC01** (Command Prompt as admin):

| Command | What it tells you |
|---|---|
| `dcdiag /q` | Prints nothing if the DC passes all tests |
| `dcdiag /test:dns` | Detailed DNS health |
| `repadmin /replsummary` | Replication status (matters once you add a second DC) |
| `nltest /dsgetdc:lab.local` | Which DC clients find |

**Event Viewer → Applications and Services Logs** → check **Directory Service**, **DNS Server**, and **DFS Replication** (SYSVOL) for errors.

Then run the lab's automated test from CLIENT01. It's read-only, so it's safe for the click-ops track too:
```powershell
.\scripts\08-Test-Lab.ps1
```

### 10.2 Back up Active Directory

VM checkpoints are **not** AD backups. In a domain with more than one DC, restoring a DC from a snapshot can corrupt replication (a "USN rollback"). Use a **system state backup**:

1. Add a second virtual disk to DC01 (for example 20 GB) and format it as `E:` in **Disk Management**.
2. **Add Roles and Features → Features → Windows Server Backup**.
3. `Start → Run → wbadmin.msc` → **Backup Once → Different options → Custom → Add Items → System state** → destination **E:**.

### 10.3 Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| *"A domain controller for the domain could not be contacted"* when joining | The computer's DNS isn't `10.10.10.10` | Set DNS to DC01 and retry. Check with `nslookup lab.local`. |
| Sign-in fails with time or clock errors | Clock skew of more than 5 minutes | `w32tm /resync` on the client; check DC01's time zone |
| Client gets a `169.254.x.x` address | No DHCP lease | Is the scope active and the server authorized? In VirtualBox, is DHCP **off** on the NAT network? |
| GPO doesn't apply | Computer or user is in the wrong OU, or policy hasn't refreshed | `gpresult /r`, check the OU in ADUC, `gpupdate /force` |
| `Test-ADServiceAccount` returns False | APP01 isn't in GG-Intranet-Servers, or hasn't refreshed its ticket | Check membership, then restart APP01 |
| Intranet prompts for a password | Site isn't in the Local intranet zone | Check the Site to Zone setting (6.3), then `gpupdate /force` on the client |
| Intranet returns 503 | App pool stopped (often a typo in the gMSA name or a missing **$**) | Check the identity in Advanced Settings; start the pool; look in Event Viewer → System |
| Share says access denied for a user who should have access | The user's sign-in token predates a group change | Sign out and back in; check with `whoami /groups` |

---

## 🎉 Done

You've built a working company network by hand. Next:
- Rebuild it in about an hour with the **[PowerShell guide](./02-powershell-guide.md)**.
- Harden it with the **[Windows hardening lab](../../security/windows-hardening-lab/)**.
- Scan it with the **[Nessus lab](../../security/nessus-scan-lab/)**.
