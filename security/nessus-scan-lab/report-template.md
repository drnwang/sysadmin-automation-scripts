# Vulnerability Assessment Report: [Lab / Environment Name]

**Prepared by:** Nathaniel Wang
**Scan dates:** [initial scan date] – [rescan date]
**Tool:** Tenable Nessus Essentials [version]

---

## 1. Executive summary

_Three or four sentences for leadership: overall risk, the most serious issues, what was fixed, and what's left._

> Example: Two hosts were scanned. The initial credentialed scan found [X] critical and [Y] high-severity vulnerabilities, including [N] listed in CISA's Known Exploited Vulnerabilities catalog. After remediation, the rescan showed [results]. [Remaining items] are documented below with target dates.

## 2. Scope and method

| Item | Details |
|---|---|
| Hosts in scope | [IP addresses / hostnames] |
| Scan types | Host discovery; Basic Network Scan, non-credentialed and credentialed |
| Credentials | Windows (SMB) local admin; SSH with sudo |
| Credential check | Plugin 19506 confirmed credentialed checks on [hosts] |
| Out of scope | [anything excluded, and why] |

## 3. Results at a glance

| Severity | Initial scan | After remediation |
|---|---|---|
| Critical | | |
| High | | |
| Medium | | |
| Low | | |

**Credentialed vs. non-credentialed:** the credentialed scan found [N] more findings, mostly [missing patches / configuration issues].

## 4. Priority findings

_Ordered by KEV status → exploit available → severity → hosts affected (output of `nessus_summary.py`)._

| # | Finding | Severity | Hosts | KEV / exploit | Recommended fix | Status |
|---|---|---|---|---|---|---|
| 1 | | | | | | Fixed / Open |
| 2 | | | | | | |
| 3 | | | | | | |

## 5. Remediation performed

| Finding | Action taken | Verified by rescan? |
|---|---|---|
| | | Yes / No |

## 6. Open items (POA&M style)

| Finding | Why it's still open | Mitigation in place | Target date |
|---|---|---|---|
| | | | |

## 7. Lessons learned

- _What surprised you? What took longest? What would you automate next time?_
