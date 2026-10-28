# 12-Week Study Plan

A week-by-week plan that pairs free guided courses (to learn the concepts) with the build tutorials in this repo (to practice them in your own lab). Plan on about **8–10 hours a week**: a couple of weeknight sessions for guided learning, and a weekend block for the build project.

> **Status:** plan ready. Tick off weeks as you finish them, and add notes and links to your results.

## How to use it

- **Weeknights:** the guided course for that week (videos, browser labs, games). No setup needed.
- **Weekend:** the build tutorial, in your lab. Take screenshots as you go and fill in the tutorial's **Results** section.
- **Every week:** add one entry to your [knowledge base](../helpdesk/knowledge-base/) or lab notes about something that broke and how you fixed it. Those become interview stories.
- **Need the theory first?** Read the matching module in the [self-study courses](../courses/) (Active Directory, Exchange, mobile, Mac, Linux).
- **Falling behind is fine.** The order matters more than the pace: each phase builds on the one before.

---

## Phase 1: Foundation (Weeks 1–3)

| Week | Weeknights (guided) | Weekend (build) | Done |
|---|---|---|---|
| 1 | **Professor Messer Network+**: OSI model, IP addressing, subnetting, DNS, DHCP | [Server lab](../windows/server-lab/), click-ops version: DC01, AD, DNS, DHCP | ☐ |
| 2 | **TryHackMe**: *Windows Fundamentals 1–3* and *Active Directory Basics* (free rooms) | [Server lab](../windows/server-lab/), PowerShell version, then test the [AD toolkit](../windows/active-directory/) with `-WhatIf` | ☐ |
| 3 | **Under The Wire**: *Century* levels (PowerShell over SSH) | [Windows Admin Center](../windows/admin-center/) and [printer deployment](../windows/printer-deployment/) | ☐ |

## Phase 2: Help desk ready (Weeks 4–6)

| Week | Weeknights (guided) | Weekend (build) | Done |
|---|---|---|---|
| 4 | **Professor Messer A+ Core 2**: the troubleshooting methodology, Windows tools, security basics | [Ticketing system](../helpdesk/ticketing-osticket/) and work the 20 mock tickets | ☐ |
| 5 | **Microsoft Learn MS-102** (Microsoft 365 Administrator) learning path, first modules | [Microsoft 365 admin](../m365/m365-admin/) (start the trial this week) | ☐ |
| 6 | **Microsoft Learn MD-102** (Endpoint Administrator): Intune and Autopilot modules | [Intune and Autopilot](../m365/intune-autopilot/), then [hybrid identity](../m365/hybrid-identity/) before the trial ends | ☐ |

> Weeks 5 and 6 share one Microsoft 365 trial, so keep them back to back. Use spare evenings for the [knowledge base](../helpdesk/knowledge-base/), [asset inventory](../helpdesk/asset-inventory/), and [PowerShell toolbox](../helpdesk/powershell-toolbox/).

## Phase 3: Sysadmin core (Weeks 7–10)

| Week | Weeknights (guided) | Weekend (build) | Done |
|---|---|---|---|
| 7 | **Microsoft Learn AZ-800** (Windows Server Hybrid Administrator): AD DS modules | [Second domain controller](../windows/second-dc/) | ☐ |
| 8 | **AZ-800**: storage and file services modules | [Backup and disaster recovery](../windows/backup-dr/) | ☐ |
| 9 | **Cisco Packet Tracer**: free *Getting Started* course on NetAcad, then build two VLANs with inter-VLAN routing and DHCP | [Patch management with WSUS](../windows/wsus-patching/) | ☐ |
| 10 | **Professor Messer Network+**: VLANs, routing, firewalls, VPNs (review) | [Monitoring with PRTG](../infrastructure/monitoring-prtg/), then [firewall, VLANs, and VPN](../infrastructure/firewall-vlans-vpn/) | ☐ |

> Week 10 is the heaviest. If it runs long, the firewall lab can spill into week 11.

## Phase 4: Senior and specialty (Weeks 11–12)

| Week | Weeknights (guided) | Weekend (build) | Done |
|---|---|---|---|
| 11 | **Linux Upskill Challenge** (one short task a day) and **OverTheWire Bandit** levels 0–15 | [Linux server in the domain](../linux/ad-join/), then [DFS and FSRM](../windows/dfs-fsrm/) | ☐ |
| 12 | **Under The Wire**: *Cyborg* levels (AD queries in PowerShell) | [Internal PKI](../windows/adcs-pki/), [Windows hardening](../security/windows-hardening-lab/), and [AutomatedLab](../windows/automatedlab/) | ☐ |

> The Linux Upskill Challenge runs 20 days, so it continues past week 12. That's fine.

---

## Free resources

| Resource | What it's for | Where |
|---|---|---|
| Professor Messer | A+ and Network+ video courses and notes | professormesser.com |
| Microsoft Learn | Official MS-102, MD-102, AZ-800/801 paths, some with free sandboxes | learn.microsoft.com |
| Cisco Networking Academy | Packet Tracer and the free getting-started course | netacad.com |
| TryHackMe | Browser-based Windows and AD rooms (many free) | tryhackme.com |
| Under The Wire | PowerShell wargames | underthewire.tech |
| Linux Upskill Challenge | A month of daily Linux server tasks | linuxupskillchallenge.org |
| OverTheWire Bandit | Command-line wargame | overthewire.org |

## Certification options (optional)

You already hold Security+. If you want another certification to back up the labs, these line up with the phases above:

| Certification | Matches | Good for |
|---|---|---|
| **MD-102** (Microsoft 365 Certified: Endpoint Administrator Associate) | Phase 2 | Help desk, desktop support |
| **Network+** | Phases 1 and 3 | Closing the networking gap, MSP roles |
| **AZ-800 / AZ-801** (Windows Server Hybrid Administrator Associate) | Phase 3 | Sysadmin roles |

> Exam names, prices, and retirement dates change. Check each vendor's site before you book.
