# Server and Service Monitoring with PRTG

Find out about problems before users do. Install **PRTG Network Monitor** on a small monitoring server, watch every lab server's availability, disk space, critical services, and websites, send alerts when thresholds are crossed, and then break things on purpose to prove the alerts work.

> **Status:** tutorial ready. Results and screenshots to be added after the lab is run.

| | |
|---|---|
| **Role** | Sysadmin, MSP technician |
| **Time** | 4–6 hours |
| **Cost** | Free. PRTG starts as a 30-day trial, then becomes the free edition (up to 100 sensors), which is plenty for this lab. Check Paessler's site for current terms. |
| **Builds on** | [Server lab](../../windows/server-lab/); [second DC](../../windows/second-dc/) and [file server](../../windows/dfs-fsrm/) if you've built them |
| **Resume keywords** | PRTG, monitoring, alerting, WMI, SNMP, thresholds, uptime, incident response |

## Why this matters

Monitoring is how an IT team knows a disk is filling or a service has stopped **before** the phones ring. MSPs especially live in their monitoring dashboards. Interviewers ask, "How would you know a server is down?" and "What would you monitor on a domain controller?" This lab gives you a concrete answer and a dashboard to show.

> **Alternative:** Zabbix is a popular free, open-source option that runs on Linux. The ideas below (devices, items, triggers, actions) carry straight over. See the note at the end.

---

## Part 1: Plan what to monitor

Good monitoring watches what users actually depend on, not just whether a server answers ping.

| Server | Monitor | Why |
|---|---|---|
| All | Ping, CPU, memory, free disk space, uptime | Basic health |
| DC01, DC02 | **DNS** service and a DNS lookup, **Netlogon**, **NTDS**, **KDC** services | Sign-in and name resolution depend on them |
| DC01 | **DHCP Server** service | New devices can't get addresses without it |
| APP01 | **W3SVC** (IIS), an HTTPS check of `https://intranet.lab.local`, **Spooler** | The intranet and printing |
| APP01/FS02 | SMB share reachable, free space on the data volume | File shares |
| All | Pending reboot / last Windows update (optional) | Patch health |

### Thresholds
| Measure | Warning | Down (critical) |
|---|---|---|
| Free disk space | Below 20% | Below 10% |
| CPU | Above 85% for 5 minutes | Above 95% for 10 minutes |
| HTTPS response | Slower than 2 seconds | No response or certificate error |

> Too many alerts is as bad as none: people start ignoring them. Pick thresholds that mean "someone should act."

---

## Part 2: Build the monitoring server and account

### 2.1 VM
Create `MON01`: Windows Server 2022 (Desktop Experience), 2 vCPU, 4 GB RAM, 60 GB disk, on **LabSwitch**, IP `10.10.10.30`, DNS `10.10.10.10` and `10.10.10.11`. Join it to `lab.local` and move it to `OU=Servers,OU=Corp`.

```powershell
New-NetIPAddress -InterfaceAlias 'Ethernet' -IPAddress 10.10.10.30 -PrefixLength 24 -DefaultGateway 10.10.10.1
Set-DnsClientServerAddress -InterfaceAlias 'Ethernet' -ServerAddresses 10.10.10.10, 10.10.10.11
Rename-Computer -NewName MON01 -Restart
# after the restart:
Add-Computer -DomainName lab.local -OUPath 'OU=Servers,OU=Corp,DC=lab,DC=local' -Credential LAB\adm-nwang -Restart
```

> MON01 gets its own VM because PRTG runs its own web server on ports 80 and 443, which would clash with IIS on APP01.

### 2.2 Monitoring service account
PRTG reads performance data over **WMI**, which needs an account with admin rights on the monitored servers. Don't use your own admin account: create a dedicated one.

On DC01:
```powershell
$pw = Read-Host 'Password for svc-prtg' -AsSecureString
New-ADUser -Name 'svc-prtg' -SamAccountName 'svc-prtg' -UserPrincipalName 'svc-prtg@lab.local' `
    -Path 'OU=Service Accounts,OU=Corp,DC=lab,DC=local' -AccountPassword $pw -Enabled $true `
    -PasswordNeverExpires $true -Description 'PRTG WMI monitoring'
New-ADGroup -Name 'GG-Monitoring' -GroupScope Global -Path 'OU=Groups,OU=Corp,DC=lab,DC=local'
Add-ADGroupMember -Identity 'GG-Monitoring' -Members 'svc-prtg'
```

Give the group local admin rights on member servers with a GPO:
1. **Group Policy Management** → create `Servers - Monitoring Admins`, linked to `OU=Servers,OU=Corp`.
2. **Computer Configuration → Preferences → Control Panel Settings → Local Users and Groups → New → Local Group** → Action **Update**, Group name **Administrators (built-in)** → **Add** `LAB\GG-Monitoring`.
3. Run `gpupdate /force` on APP01 and MON01.

Domain controllers have no local groups, so add `GG-Monitoring` to the domain's built-in **Administrators** group for the DCs:
```powershell
Add-ADGroupMember -Identity 'Administrators' -Members 'GG-Monitoring'
```

> **In production**, you'd grant only the WMI and remote DCOM permissions a monitoring account needs, rather than full admin, especially on DCs. Note this as a known lab shortcut.

### ✅ Check your work
On APP01: `net localgroup Administrators` lists `LAB\GG-Monitoring`.

---

## Part 3: Install PRTG and add devices

1. On MON01, download **PRTG Network Monitor** from paessler.com and run the installer with defaults. Enter your email for the trial key.
2. The web interface opens at `https://mon01.lab.local` (accept the self-signed certificate warning for now). Sign in with the default `prtgadmin` account and **change its password immediately** (**Setup → Account Settings → My Account**).
3. Skip or cancel the **auto-discovery** wizard. You'll add devices on purpose, so you know exactly what's monitored.

### 3.1 Set credentials once, at the top
**Devices → Root group → Edit → Settings → Credentials for Windows Systems**: uncheck *Inherit*, enter domain `lab.local`, user `svc-prtg`, and its password. Every device below inherits it.

### 3.2 Create groups and devices
1. Right-click **Local Probe → Add Group**: `Domain Controllers`, `Member Servers`.
2. In each group, **Add Device**: name and IP/DNS name (`dc01.lab.local`, `dc02.lab.local`, `app01.lab.local`, `fs02.lab.local`). For **Sensor Management** choose **Manual (no auto-discovery)**.

### 3.3 Add sensors
For each device, **Add Sensor** and search by name:

| Sensor | Add to | Settings |
|---|---|---|
| **Ping** | All | Default |
| **WMI CPU Load** | All | Default |
| **WMI Memory** | All | Default |
| **WMI Free Disk Space (Multi Disk)** | All | Set the limits from Part 1 |
| **WMI Service** | DCs: DNS, Netlogon, NTDS, Kdc; DC01: DHCPServer; APP01: W3SVC, Spooler | One sensor per service |
| **DNS v2** | DC01, DC02 | Query `intranet.lab.local`, record type A |
| **HTTPS** | APP01 | URL `https://intranet.lab.local` |
| **SSL Certificate** | APP01 | Port 443, common name `intranet.lab.local` (warns before the certificate expires) |

> That's roughly 30–40 sensors, comfortably inside the free edition's 100.

### ✅ Check your work
Every sensor shows **green (Up)** within a few minutes. A red WMI sensor usually means a credential or firewall problem (see Troubleshooting).

📸 Screenshot: the device tree with all sensors green

---

## Part 4: Alerts

### 4.1 Email delivery
**Setup → System Administration → Notification Delivery**:
- **SMTP delivery: Use direct delivery** is fine for a quick test (check your spam folder), or
- **Use one SMTP relay server**: your mail provider's SMTP server with an app password.

### 4.2 Notification template
**Setup → Account Settings → Notification Templates → Add**: name `Email - IT team`, ✅ **Send Email** to your address. Click **Test** (the bell icon) to confirm an email arrives.

### 4.3 Triggers
Set triggers once on the **Root** group so every sensor inherits them: **Root → Notification Triggers**:
- **State trigger:** when sensor state is **Down** for at least **60 seconds**, perform `Email - IT team`. When the condition clears, perform `Email - IT team` (the "recovered" email).
- **State trigger:** when sensor state is **Warning** for at least **10 minutes**, perform `Email - IT team`.

> The "for at least" delay avoids alerts for a one-second blip. The recovery email tells the team the issue is over.

---

## Part 5: Break things and confirm the alerts

Do each test, note how long the alert took to arrive, then fix it.

| Test | Break it | Fix it |
|---|---|---|
| Service down | On APP01: `Stop-Service Spooler` | `Start-Service Spooler` |
| Website down | On APP01: `Stop-WebSite 'Intranet'` (or stop it in IIS Manager) | `Start-WebSite 'Intranet'` |
| Disk filling | On APP01: `fsutil file createnew C:\filler.bin 20000000000` (about 20 GB; adjust so free space drops below your warning level) | `Remove-Item C:\filler.bin` |
| Server unreachable | Shut down DC02 in Hyper-V Manager | Start it again |
| DNS failure | On DC02: `Stop-Service DNS` | `Start-Service DNS` |

> **Treat each test like a real incident:** create a ticket in your [ticketing system](../../helpdesk/ticketing-osticket/) from the alert, note the time detected and the time resolved, and close it with what you did. That's the whole incident loop: detect, respond, resolve, document.

📸 Screenshots: a red sensor, the alert email, the sensor's history graph showing the outage and recovery

---

## Part 6: Dashboards and reports

1. **Maps → Add Map**: a simple status board with each server's overall status and the HTTPS sensor's response time. This is the kind of screen an MSP shows on a wall monitor.
2. **Reports → Add Report**: `Monthly uptime`, covering all devices, template *List of Sensors* with uptime percentages. Run it now to see the output.
3. Write a one-page **monitoring runbook** in the [knowledge base](../../helpdesk/knowledge-base/) style: what each alert means and the first three things to check.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| WMI sensors show "Access denied" | Check that `svc-prtg` is in the target's Administrators (GPO applied? `gpresult /r`); recheck the credentials at the Root group |
| WMI sensors show "RPC server is unavailable" | Windows Firewall on the target: enable the **Windows Management Instrumentation (WMI-In)** rules, or push them by GPO |
| HTTPS sensor shows a certificate error | Expected with a self-signed certificate; use one from your [internal CA](../../windows/adcs-pki/), or set the sensor to ignore certificate errors for now |
| No alert emails | Test the notification template directly; check spam; check **Logs → System Events** for delivery errors |
| Too many alerts | Raise thresholds, lengthen the "for at least" delay, or pause sensors during planned maintenance |

## Zabbix alternative

If you'd rather use open source, install **Zabbix** on an Ubuntu VM (the official packages include a web front end), install the **Zabbix agent 2** on each Windows server, and link the *Windows by Zabbix agent* template. Zabbix's terms: **hosts** (devices), **items** (what's measured), **triggers** (thresholds), and **actions** (alerts). Repeat Part 5 to prove the alerts work.

## How to talk about it in an interview

> *"I set up PRTG to monitor my lab's domain controllers and app server: availability, CPU, memory, disk thresholds, the services that matter like DNS, Netlogon, DHCP, and IIS, plus HTTPS and certificate expiry for the intranet. It ran under a dedicated service account, alerts went out by email with delays to avoid noise, and I tested every alert by stopping services and filling disks, then logged each as a ticket from detection to resolution."*

## Results

_To be added after the lab is run:_
- [ ] Screenshots: device tree, an outage and recovery graph, an alert email, the map
- [ ] Part 5 table with detection and resolution times
- [ ] Monitoring runbook
