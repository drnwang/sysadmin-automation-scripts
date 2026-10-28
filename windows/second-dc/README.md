# Second Domain Controller, Replication, and FSMO Roles

Add **DC02** to `lab.local`, watch Active Directory replicate between the two, move the FSMO roles back and forth, add DHCP failover, then shut DC01 down and prove the company keeps working. Real domains always have at least two domain controllers. This lab shows you understand why, and how to manage them.

> **Status:** tutorial ready. Results and screenshots to be added after the lab is run.

| | |
|---|---|
| **Role** | Sysadmin |
| **Time** | 3–4 hours |
| **Cost** | Free |
| **Builds on** | [Server lab](../server-lab/) |
| **Resume keywords** | AD replication, FSMO roles, redundancy, DNS, DHCP failover, repadmin, dcdiag |

## Why this matters

With one domain controller, a single reboot means nobody can sign in. Interviewers for sysadmin roles routinely ask "What are the FSMO roles?", "How do you check AD replication?", and "What happens if a DC goes down?" After this lab, you'll answer from experience.

---

## Part 1: Build DC02

| Setting | Value |
|---|---|
| VM name | `DC02` |
| CPU / RAM / disk | 2 / 4 GB / 60 GB |
| IP address | `10.10.10.11/24`, gateway `10.10.10.1` |
| DNS (for now) | `10.10.10.10` (DC01). DC02 has to find the domain before it can join it. |

Install Windows Server 2022 (Desktop Experience) and prepare it exactly as in [server lab Part 2](../server-lab/01-clickops-guide.md#part-2-install-windows-server-and-prepare-dc01): static IP, time zone, Remote Desktop, updates, then rename to `DC02`. You don't need to join it to the domain first. Promotion does that.

---

## Part 2: Promote DC02 into the existing domain

### Click-ops
1. **Add Roles and Features** → **Active Directory Domain Services** → Install.
2. Yellow flag → **Promote this server to a domain controller**:

| Page | Setting |
|---|---|
| Deployment Configuration | **Add a domain controller to an existing domain** → `lab.local` → **Change** credentials to `LAB\adm-nwang` |
| Domain Controller Options | ✅ DNS server, ✅ Global Catalog, site **Default-First-Site-Name**, DSRM password |
| Additional Options | **Replicate from: dc01.lab.local** |
| Paths, Review, Prerequisites | Defaults → **Install** |

### PowerShell
```powershell
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

Install-ADDSDomainController -DomainName 'lab.local' -InstallDns `
    -Credential (Get-Credential 'LAB\adm-nwang') `
    -SafeModeAdministratorPassword (Read-Host -AsSecureString 'DSRM password') `
    -ReplicationSourceDC 'dc01.lab.local' -SiteName 'Default-First-Site-Name' -Force
```

DC02 restarts. Sign in as `LAB\adm-nwang`.

---

## Part 3: Verify replication

Run these on DC02 (Command Prompt or PowerShell as admin):

| Command | What you should see |
|---|---|
| `repadmin /replsummary` | Both DCs, **0 fails** |
| `repadmin /showrepl` | Each naming context replicated **successfully** from DC01 |
| `dcdiag /q` | No output (all tests pass) |
| `dcdiag /test:sysvolcheck /test:advertising` | DC02 is advertising as a DC and SYSVOL is ready |
| `dfsrmig /getglobalstate` | **Eliminated**: SYSVOL replicates with DFS-R, the modern method |
| `Get-ChildItem \\dc02\SYSVOL\lab.local\Policies` | The same GPO folders as on DC01 |

### Watch replication happen
1. On **DC01**, create a test user:
   ```powershell
   New-ADUser -Name 'Replication Test' -SamAccountName reptest -Path 'OU=Users,OU=Corp,DC=lab,DC=local'
   ```
2. On **DC02**, check whether it's there yet:
   ```powershell
   Get-ADUser reptest -Server dc02.lab.local
   ```
3. Force replication immediately instead of waiting:
   ```cmd
   repadmin /syncall /AdeP
   ```
   (`A` = all partitions, `d` = show names, `e` = across sites, `P` = push from this DC.)
4. Delete the test user on DC02 and confirm it disappears from DC01.

> Within one site, changes replicate in about **15 seconds**. Between sites, replication follows a schedule, often every 180 minutes by default. Knowing that difference is a common interview point.

---

## Part 4: Update DNS settings everywhere

Each DC should point to its **partner first** and **itself second**, so a DC that's booting doesn't depend on itself.

| Machine | Preferred DNS | Alternate DNS |
|---|---|---|
| DC01 | 10.10.10.11 | 10.10.10.10 |
| DC02 | 10.10.10.10 | 10.10.10.11 |
| APP01 | 10.10.10.10 | 10.10.10.11 |

**Clients (DHCP option 006):** On DC01, **DHCP → Scope Options → 006 DNS Servers** → add `10.10.10.11`. Or:
```powershell
Set-DhcpServerv4OptionValue -ComputerName dc01 -ScopeId 10.10.10.0 -DnsServer 10.10.10.10, 10.10.10.11
```
On CLIENT01: `ipconfig /renew`, then `ipconfig /all` shows both DNS servers.

---

## Part 5: FSMO roles

Most AD changes can happen on any DC, but five tasks must be handled by **one** DC at a time. Those are the **FSMO** (Flexible Single Master Operation) roles:

| Role | Scope | What it does |
|---|---|---|
| **Schema Master** | Forest | Changes to the AD schema (for example when installing Exchange) |
| **Domain Naming Master** | Forest | Adding or removing domains |
| **RID Master** | Domain | Hands out pools of IDs used to create users, groups, and computers |
| **PDC Emulator** | Domain | Domain time source, password-change priority, account lockouts, GPO editing |
| **Infrastructure Master** | Domain | Keeps cross-domain group references up to date |

### See who holds them
```cmd
netdom query fsmo
```
All five are on DC01, because it was the first DC.

### Transfer them to DC02
**PowerShell (fastest):**
```powershell
Move-ADDirectoryServerOperationMasterRole -Identity DC02 `
    -OperationMasterRole PDCEmulator, RIDMaster, InfrastructureMaster, SchemaMaster, DomainNamingMaster
```

**Click-ops (worth knowing where each lives):**

| Roles | Console |
|---|---|
| RID, PDC, Infrastructure | **ADUC** → right-click the domain → **Operations Masters** → tab → **Change** |
| Domain Naming | **Active Directory Domains and Trusts** → right-click → **Operations Master** |
| Schema | Register the snap-in with `regsvr32 schmmgmt.dll`, open **mmc** → add **Active Directory Schema** → right-click → **Operations Master** |

Run `netdom query fsmo` again: everything is on DC02.

### Move the time source with the PDC Emulator
The PDC Emulator is the domain's master clock, so it should sync with an external time source:

On **DC02** (the new PDC):
```cmd
w32tm /config /manualpeerlist:"time.windows.com,0x8" /syncfromflags:manual /reliable:yes /update
w32tm /resync
```
On **DC01** (no longer PDC), switch back to syncing from the domain:
```cmd
w32tm /config /syncfromflags:domhier /update
w32tm /resync
```
Check with `w32tm /query /status` on each.

### Transfer them back
Repeat the transfer with `-Identity DC01`, and swap the two time configurations. Being able to move roles cleanly, in both directions, is the skill.

> **Transfer vs. seize:** *Transfer* is the graceful handover you just did, with both DCs online. *Seize* (`Move-ADDirectoryServerOperationMasterRole ... -Force`, or `ntdsutil`) is only for when the old role holder is **permanently** gone. A seized DC must never come back online with its old roles.

---

## Part 6: DHCP failover (bonus)

DHCP is still only on DC01. Add failover so DC02 can hand out addresses too.

1. On **DC02**: install the DHCP role and authorize it (as in [server lab 4.4](../server-lab/01-clickops-guide.md#44-install-dhcp)).
2. On **DC01**: **DHCP console** → right-click the scope → **Configure Failover** → partner `dc02.lab.local` → mode **Load balance 50/50** → a shared secret → **Finish**.

   Or:
   ```powershell
   Add-DhcpServerv4Failover -ComputerName dc01.lab.local -PartnerServer dc02.lab.local -Name 'DC01-DC02' `
       -ScopeId 10.10.10.0 -LoadBalancePercent 50 -SharedSecret (Read-Host 'Shared secret')
   ```
3. On DC02, the DHCP console now shows the same scope with its options.

---

## Part 7: The real test, shutting down DC01

1. **Shut down DC01.**
2. On **CLIENT01**, sign in as `mjohnson`. Then:
   ```cmd
   echo %LOGONSERVER%
   nslookup dc01.lab.local
   gpupdate /force
   ```
   `%LOGONSERVER%` shows `\\DC02`. DNS still answers through DC02. Group Policy still applies.
3. On CLIENT01, `ipconfig /release` then `ipconfig /renew`. With failover, DC02 gives it an address.
4. Start DC01 again. Run `repadmin /replsummary` after a few minutes to confirm the two DCs caught up.

📸 Screenshots: `netdom query fsmo` before and after, `repadmin /replsummary`, `%LOGONSERVER%` showing DC02

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| Promotion fails: "domain could not be contacted" | DC02's DNS must point at DC01 during promotion |
| `repadmin` shows error 1722 (RPC server unavailable) | Network, firewall, or DNS between the DCs. Test with `Test-NetConnection dc01 -Port 135`. |
| `repadmin` shows error 8606 or "lingering objects" | A DC was offline longer than the tombstone lifetime (180 days). Remove it and rebuild it; don't force replication. |
| Clients still use only DC01 for DNS | Renew DHCP (`ipconfig /renew`), or check option 006 |
| Time drifts across the domain | Check `w32tm /query /source` on each DC: the PDC uses an external source; others use the domain |

## How to talk about it in an interview

> *"I added a second domain controller to my lab, verified replication with repadmin and dcdiag, and transferred all five FSMO roles between the DCs, including moving the external time source along with the PDC Emulator. I set up DHCP failover, then shut down the original DC and confirmed users could still sign in, resolve names, and get Group Policy."*

## Results

_To be added after the lab is run:_
- [ ] Screenshots of replication and FSMO output
- [ ] Notes from the DC01 shutdown test
