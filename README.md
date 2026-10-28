# Sysadmin Automation Scripts ![MIT License](https://img.shields.io/badge/license-MIT-blue) ![Languages](https://img.shields.io/badge/language-PowerShell%20%7C%20Bash%20%7C%20Python-yellowgreen)

Practical scripts for everyday system administration tasks on Windows Server, Active Directory, SCCM, and Linux, organized by area. Each folder has its own README explaining what the script does and how to run it.

Built by **Nathaniel Wang**, a Windows systems administrator with 10+ years supporting federal and enterprise environments.

---

## 📂 What's inside

| Area | Script | What it does |
|---|---|---|
| **Active Directory** | [`New-ADUserOnboarding.ps1`](./windows/active-directory/) | Creates new-hire accounts from a CSV, with temporary passwords and group memberships |
| | [`Disable-ADUserOffboarding.ps1`](./windows/active-directory/) | Disables departing users, resets passwords, removes groups, and logs what was removed |
| | [`Get-PasswordExpiryReport.ps1`](./windows/active-directory/) | Lists users whose passwords expire within N days |
| | [`user_audit.ps1`](./windows/active-directory/) | Finds users inactive for 90+ days or who have never logged on |
| **Server build** | [`windows/server-build/Build_Server.ps1`](./windows/server-build/) | Renames, domain-joins, and configures a new Windows Server, then installs the SCCM client |
| **Monitoring** | [`windows/monitoring/HealthCheck.ps1`](./windows/monitoring/) | Emails a daily CPU, memory, disk, and event-log health report |
| **Patching** | [`windows/patching/New-MonthlyPatchADR.ps1`](./windows/patching/) | Creates an SCCM Automatic Deployment Rule for monthly security updates |
| **Security** | [`security/nessus-scan-lab/`](./security/nessus-scan-lab/) | Nessus home lab guide, findings report template, and a Python tool that prioritizes scan results by CISA KEV, exploit, and severity |
| **Linux** | [`linux/check_disk.sh`](./linux/) | Flags file systems above 80% disk usage |
| **Python** | [`python/system_info.py`](./python/) | Prints OS, architecture, and CPU count |

---

## 📁 Repository layout

```
sysadmin-automation-scripts/
├── windows/
│   ├── active-directory/   # Onboarding, offboarding, password and account audits
│   ├── server-build/       # New server provisioning
│   ├── monitoring/         # Health checks and reporting
│   └── patching/           # SCCM / patch management
├── security/
│   └── nessus-scan-lab/    # Vulnerability scan lab + results summarizer
├── linux/                  # Bash scripts for Linux admin tasks
├── python/                 # Python utilities
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
