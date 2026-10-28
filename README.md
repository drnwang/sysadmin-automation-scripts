# Sysadmin Automation Scripts [![Security and quality checks](https://github.com/drnwang/sysadmin-automation-scripts/actions/workflows/security-checks.yml/badge.svg)](https://github.com/drnwang/sysadmin-automation-scripts/actions/workflows/security-checks.yml) ![MIT License](https://img.shields.io/badge/license-MIT-blue) ![Languages](https://img.shields.io/badge/language-PowerShell%20%7C%20Bash%20%7C%20Python-yellowgreen)

Practical scripts and hands-on lab tutorials for system administration and help desk work: Windows Server, Active Directory, Microsoft 365, Intune, networking, and Linux. Each folder has its own README explaining what it does and how to run it.

Built by **Nathaniel Wang**, a Windows systems administrator with 10+ years supporting federal and enterprise environments.

---

## 🧪 Lab tutorials

Step-by-step tutorials built on one home lab domain (`lab.local` in Hyper-V). Each has a "Check your work" step for every part, troubleshooting tips, and an interview talking point. Follow them in order with the [**12-week study plan**](./study-plan/).

> **Status:** tutorials ready. Results and screenshots are added to each one as the lab is run.

| Area | Tutorial | What you build |
|---|---|---|
| **Foundation** | [Server lab](./windows/server-lab/) | Domain controller, AD, DNS, DHCP, Group Policy, IIS app server, file share (click-ops and PowerShell) |
| | [Windows Admin Center](./windows/admin-center/) | Browser-based management of every server |
| **Help desk** | [Ticketing system](./helpdesk/ticketing-osticket/) | osTicket service desk with SLAs and 20 mock tickets |
| | [Knowledge base](./helpdesk/knowledge-base/) | 10 KB articles and SOPs for common tickets |
| | [PowerShell toolbox](./helpdesk/powershell-toolbox/) | WinForms GUI for unlocks, resets, remote info, print queues |
| | [Asset inventory](./helpdesk/asset-inventory/) | Snipe-IT with LDAP, plus Lansweeper discovery |
| | [Printer deployment](./windows/printer-deployment/) | Print server and Group Policy printer deployment |
| **Microsoft 365** | [M365 administration](./m365/m365-admin/) | Users, licenses, shared mailboxes, Teams/SharePoint, Conditional Access MFA |
| | [Intune and Autopilot](./m365/intune-autopilot/) | Autopilot, compliance, BitLocker, Win32 apps, compliant-device access |
| | [Hybrid identity](./m365/hybrid-identity/) | Entra Connect Sync, group-based licensing, password writeback |
| **Sysadmin core** | [Second DC](./windows/second-dc/) | Replication, FSMO roles, DHCP failover, DC failure test |
| | [Backup and DR](./windows/backup-dr/) | AD Recycle Bin, system state restore, Veeam, recovery runbook |
| | [WSUS patching](./windows/wsus-patching/) | Pilot and production rings, approvals, compliance reports |
| | [Monitoring](./infrastructure/monitoring-prtg/) | PRTG sensors, alerts, outage tests, uptime reports |
| | [Firewall, VLANs, VPN](./infrastructure/firewall-vlans-vpn/) | pfSense, client and guest VLANs, DHCP relay, WireGuard |
| | [Linux in the domain](./linux/ad-join/) | Ubuntu joined to AD with SSSD, AD-group sudo, nginx |
| **Advanced** | [DFS and FSRM](./windows/dfs-fsrm/) | Server Core file server, DFS namespace and replication, quotas |
| | [Internal PKI](./windows/adcs-pki/) | Enterprise CA, templates, autoenrollment, LDAPS |
| | [AutomatedLab](./windows/automatedlab/) | The whole lab rebuilt from one definition file |
| **Security** | [Nessus scan lab](./security/nessus-scan-lab/) | Vulnerability scanning and prioritization |
| | [Windows hardening](./security/windows-hardening-lab/) | CIS / STIG baseline, measured before and after |

---

## 📚 Self-study courses

Five courses on how the systems behind the labs work, each with self-check questions: [**Active Directory**](./courses/active-directory.md), [**Exchange Server**](./courses/exchange-server.md), [**Mobile devices**](./courses/mobile-devices.md), [**Macs**](./courses/mac-admin.md), and [**Linux administration**](./courses/linux-admin.md). See the [course index](./courses/).

---

## 🛠️ Scripts

| Area | Script | What it does |
|---|---|---|
| **Server lab tutorial** | [`windows/server-lab/`](./windows/server-lab/) | Step-by-step tutorial to build a domain controller, AD, DNS, DHCP, Group Policy, and an IIS application server, in both click-ops and PowerShell versions |
| **Active Directory** | [`New-ADUserOnboarding.ps1`](./windows/active-directory/) | Creates new-hire accounts from a CSV, with temporary passwords and group memberships |
| | [`Disable-ADUserOffboarding.ps1`](./windows/active-directory/) | Disables departing users, resets passwords, removes groups, and logs what was removed |
| | [`Get-PasswordExpiryReport.ps1`](./windows/active-directory/) | Lists users whose passwords expire within N days |
| | [`user_audit.ps1`](./windows/active-directory/) | Finds users inactive for 90+ days or who have never logged on |
| **Server build** | [`windows/server-build/Build_Server.ps1`](./windows/server-build/) | Renames, domain-joins, and configures a new Windows Server, then installs the SCCM client |
| **Monitoring** | [`windows/monitoring/HealthCheck.ps1`](./windows/monitoring/) | Emails a daily CPU, memory, disk, and event-log health report |
| **Patching** | [`windows/patching/New-MonthlyPatchADR.ps1`](./windows/patching/) | Creates an SCCM Automatic Deployment Rule for monthly security updates |
| **Security** | [`security/nessus-scan-lab/`](./security/nessus-scan-lab/) | Nessus home lab guide, findings report template, and a Python tool that prioritizes scan results by CISA KEV, exploit, and severity |
| | [`security/windows-hardening-lab/`](./security/windows-hardening-lab/) | CIS / DISA STIG hardening lab with a read-only PowerShell audit of 15 key settings, run before and after applying a baseline |
| **Linux** | [`linux/check_disk.sh`](./linux/) | Flags file systems above 80% disk usage |
| **Python** | [`python/system_info.py`](./python/) | Prints OS, architecture, and CPU count |

---

## 🔒 Automated security checks (DevSecOps)

Every push and pull request runs a [GitHub Actions pipeline](./.github/workflows/security-checks.yml) with four jobs:

| Job | Tool | What it catches |
|---|---|---|
| PowerShell analysis | **PSScriptAnalyzer** | Insecure patterns (for example, plain-text passwords), unsafe aliases, missing `-WhatIf` support. Errors fail the build. |
| Shell analysis | **ShellCheck** | Quoting bugs, unsafe globbing, and portability problems in Bash scripts |
| Python SAST | **Bandit** | Insecure Python patterns such as shell injection, weak crypto, and unsafe deserialization |
| Secret scanning | **TruffleHog** | API keys, passwords, and tokens committed anywhere in the Git history |

The pipeline already proved useful: its first run flagged two scripts that passed passwords through `ConvertTo-SecureString -AsPlainText`. They now build `SecureString` objects directly. Analyzer settings live in [`PSScriptAnalyzerSettings.psd1`](./PSScriptAnalyzerSettings.psd1).

---

## 📁 Repository layout

```
sysadmin-automation-scripts/
├── windows/
│   ├── server-lab/         # On-prem lab tutorial: DC, AD, DNS, DHCP, GPO, IIS (GUI + PowerShell)
│   ├── admin-center/  printer-deployment/  second-dc/  backup-dr/
│   ├── wsus-patching/  dfs-fsrm/  adcs-pki/  automatedlab/   # Tutorials
│   ├── active-directory/   # Onboarding, offboarding, password and account audits
│   ├── server-build/       # New server provisioning
│   ├── monitoring/         # Health checks and reporting
│   └── patching/           # SCCM / patch management
├── helpdesk/               # Ticketing, knowledge base, PowerShell toolbox, asset inventory
├── m365/                   # Microsoft 365 admin, Intune/Autopilot, hybrid identity
├── infrastructure/         # Monitoring (PRTG), firewall/VLANs/VPN (pfSense)
├── security/
│   ├── nessus-scan-lab/    # Vulnerability scan lab + results summarizer
│   └── windows-hardening-lab/  # CIS/STIG baseline lab + audit script
├── linux/                  # Linux AD join tutorial and Bash scripts
├── python/                 # Python utilities
├── courses/                # Self-study courses: AD, Exchange, mobile, Mac, Linux
├── study-plan/             # 12-week plan pairing free courses with the tutorials
├── .github/workflows/      # CI security pipeline
├── PSScriptAnalyzerSettings.psd1
├── LICENSE
└── README.md
```

---

## 🚀 Getting started

```bash
git clone https://github.com/drnwang/sysadmin-automation-scripts.git
cd sysadmin-automation-scripts
```

**PowerShell** (run as administrator):

```powershell
.\windows\active-directory\user_audit.ps1
```

**Bash:**

```bash
chmod +x linux/check_disk.sh
./linux/check_disk.sh
```

**Python:**

```bash
python3 python/system_info.py
```

> ⚠️ Test scripts in a lab before using them in production, and replace example values (domains, servers, site codes) with your own.

---

## 🔗 More projects

Cloud and infrastructure projects (AWS, Terraform): [**CloudProjects**](https://github.com/drnwang/CloudProjects)

## 📜 License

MIT. See [LICENSE](./LICENSE).
