# Sysadmin Automation Scripts ![MIT License](https://img.shields.io/badge/license-MIT-blue) ![Python](https://img.shields.io/badge/language-Python%20%7C%20Bash%20%7C%20PowerShell-yellowgreen)

A practical collection of scripts for learning and applying cross-platform automation using **Python**, **Bash**, and **PowerShell**. These tools reflect real-world sysadmin tasks and are designed to help you build confidence in scripting, automation, and administrative workflows.

---

## 🧭 What You'll Learn

* How to retrieve system information with Python
* How to detect disk usage issues using Bash scripting
* How to audit inactive users in Active Directory with PowerShell
* How to navigate and manage cross-platform automation scripts

---

## 📁 Folder Overview

```
├── python_scripts/         # Python-based automation scripts
│   └── hello.py            # Outputs system information
│
├── linux_scripts/          # Bash scripts for Linux admin tasks
│   └── check_disk.sh       # Alerts if disk usage exceeds threshold
│
├── powershell_scripts/     # PowerShell scripts for Windows/AD
│   └── user_audit.ps1      # Finds inactive AD users (90+ days)
│
├── LICENSE                 # MIT license
├── .gitignore              # Python/VScode/env ignores
└── README.md               # Project documentation
```

---

## 🚀 Getting Started

### Clone the Repository

```bash
git clone https://github.com/drnwang/sysadmin-automation-scripts.git
cd sysadmin-automation-scripts
```

### Run the Scripts

#### Python

```bash
cd python_scripts
python3 hello.py
```

#### Bash

```bash
cd linux_scripts
chmod +x check_disk.sh
./check_disk.sh
```

#### PowerShell

```powershell
cd powershell_scripts
.\user_audit.ps1
```

> ⚠️ Run PowerShell as administrator if you're working with Active Directory modules.

---

## 🛠️ Tools & Technologies

* Python 3+
* Bash (Linux/macOS)
* PowerShell (Windows/AD)

---

## ✅ Why Use This Project

* Understand core scripting concepts in a system administration context
* Practice writing and executing scripts in multiple environments
* Build a public portfolio of lightweight, real-world automation tasks
* Lay the groundwork for more advanced DevOps or cloud admin roles

---

## 📜 License

This project is licensed under the MIT License. See `LICENSE` for full terms.

---

## 📆 Project Status

This is an active learning sandbox for practicing automation in Windows and Linux environments.

Scripts are being expanded over time to cover more use cases. You're encouraged to adapt them to your own workflows or training needs.
