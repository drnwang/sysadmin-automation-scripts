# Sysadmin Automation Scripts [![Security and quality checks](https://github.com/drnwang/sysadmin-automation-scripts/actions/workflows/security-checks.yml/badge.svg)](https://github.com/drnwang/sysadmin-automation-scripts/actions/workflows/security-checks.yml) ![MIT License](https://img.shields.io/badge/license-MIT-blue) ![Languages](https://img.shields.io/badge/language-PowerShell%20%7C%20Bash%20%7C%20Python-yellowgreen)

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
│   ├── active-directory/   # Onboarding, offboarding, password and account audits
│   ├── server-build/       # New server provisioning
│   ├── monitoring/         # Health checks and reporting
│   └── patching/           # SCCM / patch management
├── security/
│   ├── nessus-scan-lab/    # Vulnerability scan lab + results summarizer
│   └── windows-hardening-lab/  # CIS/STIG baseline lab + audit script
├── linux/                  # Bash scripts for Linux admin tasks
├── python/                 # Python utilities
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
