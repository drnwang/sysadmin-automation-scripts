# Nessus Vulnerability Scan Lab

A home lab that walks through the full vulnerability management cycle: **discover → scan → analyze → prioritize → remediate → verify → report**. It uses Tenable Nessus Essentials (free) against deliberately vulnerable and unpatched lab machines.

> **Status:** lab guide and tooling are ready. Results, screenshots, and the findings report will be added after the scans are run. See [Results](#results).

---

## What this project demonstrates

- Setting up and running **Tenable Nessus** scans
- The difference between **credentialed and non-credentialed** scans, and how to confirm credentials worked (plugin 19506)
- **Risk-based prioritization:** CISA KEV status and exploit availability, not just CVSS
- **Remediation and verification:** fixing findings, then rescanning to prove they're closed
- Writing a **findings report** for both technical teams and leadership
- **Automation:** a Python tool that turns a Nessus CSV export into a prioritized summary

---

## Lab setup

All machines run on an isolated **host-only network** in VirtualBox, so nothing vulnerable is reachable from the internet.

| Machine | Role | Notes |
|---|---|---|
| Windows Server 2022 (evaluation) | Target, and the domain controller from the [AD toolkit lab](../../windows/active-directory/) | Free 180-day evaluation from Microsoft |
| Metasploitable 2 | Deliberately vulnerable Linux target | Free from Rapid7. **Never connect it to a real network.** |
| Scanner host | Runs Nessus Essentials | Your PC, or a small Linux VM on the same host-only network |

### Steps

1. **Create a host-only network** in VirtualBox and attach every lab VM to it.
2. **Install Nessus Essentials:** register for a free activation code at tenable.com, install Nessus, and let the plugins download. Essentials scans up to 16 IP addresses.
3. **Run discovery:** a *Host Discovery* scan of the lab subnet to confirm which machines are live.
4. **Run a non-credentialed scan:** a *Basic Network Scan* of all targets with no credentials. This is what an attacker on the network would see.
5. **Run a credentialed scan:** the same scan with **Windows (SMB)** credentials for the server and **SSH** credentials for Metasploitable. Check plugin **19506** to confirm "Credentialed checks : yes."
6. **Compare** the two scans and record how many more findings the credentialed scan found.
7. **Export results:** Report → CSV, then run the summary tool:
   ```bash
   python3 nessus_summary.py scan.csv --kev known_exploited_vulnerabilities.json --out summary.md
   ```
   The KEV JSON comes from CISA's Known Exploited Vulnerabilities catalog page.
8. **Remediate** the top findings on the Windows server: apply updates, disable SMBv1 and TLS 1.0/1.1, and fix configuration issues.
9. **Rescan** to verify the fixes, and record before-and-after counts.
10. **Write the findings report** using [`report-template.md`](./report-template.md).

---

## The summary tool: `nessus_summary.py`

Reads a Nessus CSV export and produces a Markdown report with:

- findings by severity and by host
- whether each host's **credentialed scan worked** (from plugin 19506)
- a **remediation priority list** ordered by: in CISA KEV → public exploit available → severity → number of hosts

```bash
python3 nessus_summary.py sample-data/sample-scan.csv --kev sample-data/sample-kev.json
```

The files in [`sample-data/`](./sample-data/) are **made-up example data** (every finding name starts with "EXAMPLE:") for trying the tool out. They aren't real scan results. Standard library only; Python 3.8+.

---

## Results

_To be added after the lab is run:_

- [ ] Screenshots: Nessus dashboard, scan configuration, credential check (plugin 19506)
- [ ] Non-credentialed vs. credentialed comparison
- [ ] Prioritized summary from `nessus_summary.py`
- [ ] Remediation steps taken
- [ ] Before-and-after rescan results
- [ ] Findings report
