#!/usr/bin/env python3
"""
nessus_summary.py - Turn a Nessus CSV export into a prioritized findings summary.

What it does
  * Counts findings by severity and by host
  * Lists the top plugins (findings) by number of affected hosts
  * Flags findings with a public exploit, and (optionally) CVEs in CISA's
    Known Exploited Vulnerabilities (KEV) catalog
  * Checks whether credentialed scanning worked on each host (plugin 19506 output)
  * Writes a Markdown report you can paste into a findings report or README

Usage
  python3 nessus_summary.py scan.csv
  python3 nessus_summary.py scan.csv --kev known_exploited_vulnerabilities.json --out summary.md

Inputs
  scan.csv  - Nessus export: Scan > Report > CSV. Include the default columns.
              Optional columns used if present: "CVSS v3.0 Base Score", "VPR Score",
              "Exploit?" / "Exploit Available", "EPSS Score".
  --kev     - Optional. Download from:
              https://www.cisa.gov/known-exploited-vulnerabilities-catalog (JSON feed)

Standard library only. Python 3.8+.
"""
import argparse
import csv
import json
import re
import sys
from collections import Counter, defaultdict

SEVERITY_ORDER = ["Critical", "High", "Medium", "Low", "None"]
RANK = {s: i for i, s in enumerate(SEVERITY_ORDER)}


def read_findings(path):
    with open(path, newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        if not reader.fieldnames or "Plugin ID" not in reader.fieldnames:
            sys.exit(f"{path} doesn't look like a Nessus CSV export (no 'Plugin ID' column).")
        return list(reader)


def load_kev(path):
    if not path:
        return set()
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    return {v["cveID"].upper() for v in data.get("vulnerabilities", []) if "cveID" in v}


def cves_of(row):
    return {c.strip().upper() for c in re.split(r"[,\s]+", row.get("CVE", "") or "") if c.strip()}


def exploit_available(row):
    for col in ("Exploit?", "Exploit Available", "exploit_available"):
        val = (row.get(col) or "").strip().lower()
        if val in ("true", "yes", "1"):
            return True
    return False


def score(row, col):
    try:
        return float(row.get(col) or "")
    except ValueError:
        return None


def credentialed_status(rows):
    """Plugin 19506 (Nessus Scan Information) reports 'Credentialed checks : yes/no'."""
    status = {}
    for r in rows:
        if r.get("Plugin ID") == "19506":
            out = r.get("Plugin Output", "")
            m = re.search(r"Credentialed checks\s*:\s*(\w+)", out, re.IGNORECASE)
            status[r["Host"]] = m.group(1).lower() if m else "unknown"
    return status


def build_report(rows, kev):
    findings = [r for r in rows if r.get("Risk") in RANK and r["Risk"] != "None"]
    hosts = sorted({r["Host"] for r in rows})
    sev_counts = Counter(r["Risk"] for r in findings)

    per_host = defaultdict(Counter)
    for r in findings:
        per_host[r["Host"]][r["Risk"]] += 1

    # Group by plugin: one line per vulnerability, with the hosts it affects.
    plugins = {}
    for r in findings:
        p = plugins.setdefault(r["Plugin ID"], {
            "name": r.get("Name", ""), "risk": r["Risk"], "hosts": set(), "cves": set(),
            "exploit": False, "cvss3": score(r, "CVSS v3.0 Base Score"),
            "vpr": score(r, "VPR Score"), "solution": (r.get("Solution") or "").strip(),
        })
        p["hosts"].add(r["Host"])
        p["cves"] |= cves_of(r)
        p["exploit"] |= exploit_available(r)
    for p in plugins.values():
        p["kev"] = sorted(p["cves"] & kev)

    # Priority: KEV first, then public exploit, then severity, then number of hosts.
    ordered = sorted(
        plugins.items(),
        key=lambda kv: (not kv[1]["kev"], not kv[1]["exploit"], RANK[kv[1]["risk"]], -len(kv[1]["hosts"])),
    )
    creds = credentialed_status(rows)

    lines = ["# Vulnerability Scan Summary", ""]
    lines.append(f"**Hosts scanned:** {len(hosts)}  ")
    lines.append(f"**Findings (Low and above):** {len(findings)} across {len(plugins)} unique vulnerabilities  ")
    if kev:
        kev_hits = sum(1 for p in plugins.values() if p["kev"])
        lines.append(f"**In CISA KEV:** {kev_hits} vulnerabilities  ")
    lines.append("")

    lines += ["## Findings by severity", "", "| Severity | Count |", "|---|---|"]
    for s in SEVERITY_ORDER[:-1]:
        lines.append(f"| {s} | {sev_counts.get(s, 0)} |")
    lines.append("")

    lines += ["## Findings by host", "",
              "| Host | Critical | High | Medium | Low | Credentialed scan |", "|---|---|---|---|---|---|"]
    for h in hosts:
        c = per_host[h]
        lines.append(f"| {h} | {c['Critical']} | {c['High']} | {c['Medium']} | {c['Low']} | {creds.get(h, 'not reported')} |")
    lines.append("")
    if any(v != "yes" for v in creds.values()) or len(creds) < len(hosts):
        lines += ["> ⚠️ Some hosts weren't scanned with working credentials. Results for those hosts "
                  "will miss most missing-patch findings. Check plugin 19506 and 21745.", ""]

    lines += ["## Remediation priority", "",
              "Ordered by: in CISA KEV → public exploit available → severity → number of hosts affected.", "",
              "| # | Plugin | Vulnerability | Severity | Hosts | Exploit | KEV | Fix |", "|---|---|---|---|---|---|---|---|"]
    for i, (pid, p) in enumerate(ordered[:25], 1):
        fix = p["solution"].replace("\n", " ").replace("|", "/")
        if len(fix) > 90:
            fix = fix[:87] + "..."
        lines.append(
            f"| {i} | {pid} | {p['name'].replace('|', '/')} | {p['risk']} | {len(p['hosts'])} | "
            f"{'Yes' if p['exploit'] else '-'} | {', '.join(p['kev']) or '-'} | {fix} |"
        )
    if len(ordered) > 25:
        lines.append(f"\n_{len(ordered) - 25} more vulnerabilities not shown._")
    lines.append("")
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser(description="Summarize a Nessus CSV export into a prioritized Markdown report.")
    ap.add_argument("csv", help="Nessus CSV export")
    ap.add_argument("--kev", help="CISA KEV catalog JSON file (optional)")
    ap.add_argument("--out", help="Write the report to this file instead of printing it")
    args = ap.parse_args()

    report = build_report(read_findings(args.csv), load_kev(args.kev))
    if args.out:
        with open(args.out, "w", encoding="utf-8") as f:
            f.write(report)
        print(f"Report written to {args.out}")
    else:
        print(report)


if __name__ == "__main__":
    main()
