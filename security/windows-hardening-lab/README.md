# Windows Server Hardening Lab (CIS / DISA STIG)

Takes a default Windows Server install, measures it against key hardening settings, applies a security baseline with Group Policy, and proves the improvement with a before-and-after comparison. It's the same work as preparing a server for an audit or an ATO, done in a home lab.

> **Status:** guide and audit script are ready. Before-and-after results will be added after the lab is run. See [Results](#results).

---

## What this project demonstrates

- Reading and applying **CIS Benchmark** and **DISA STIG** requirements
- Deploying a security baseline through **Group Policy**
- **Measuring compliance** before and after, with evidence
- Handling settings that can't be applied, the way an ISSO would: document the reason, the risk, and the mitigation (POA&M style)

---

## The audit script: `Test-WindowsBaseline.ps1`

A **read-only** PowerShell check of 15 high-impact settings. It makes no changes.

| Area | Checks |
|---|---|
| Network | SMBv1 disabled, SMB signing required, TLS 1.0 and 1.1 disabled, LLMNR disabled |
| Authentication | NTLMv2 only, anonymous enumeration blocked, password length ≥ 14, lockout threshold 1–5 |
| Remote access | RDP requires Network Level Authentication |
| Host protection | Firewall on for all profiles, Defender real-time protection, Guest account disabled |
| Logging | PowerShell script block logging, logon auditing (success and failure) |

Each check reports **Pass**, **Fail**, or **Unknown**, with a fix hint for anything that fails.

```powershell
.\Test-WindowsBaseline.ps1 -ReportPath .\baseline-before.csv
```

This is a quick spot check of important settings, not a full CIS or STIG assessment. Use the official tools below for that.

---

## Lab steps

**Setup:** the Windows Server 2022 evaluation VM from the [AD toolkit lab](../../windows/active-directory/), as a domain controller or a member server.

1. **Snapshot the VM** so you can roll back if a setting breaks something.
2. **Measure the starting point:**
   ```powershell
   .\Test-WindowsBaseline.ps1 -ReportPath .\baseline-before.csv
   ```
3. **Get a baseline**, using either or both of these free sources:
   - **Microsoft Security Compliance Toolkit:** Microsoft's security baseline GPOs for Windows Server, plus *Policy Analyzer* to compare settings.
   - **DISA STIG GPO package and SCAP Compliance Checker (SCC):** from DISA's public cyber.mil site. SCC produces a scored STIG report, the same way you checked servers at the Coast Guard.
4. **Import the baseline into Group Policy:** create a GPO, use *Import Settings* from the baseline backup, and link it to the server's OU. Or, on a standalone server, apply it with Microsoft's `LGPO.exe` tool.
5. **Apply and verify:** run `gpupdate /force`, reboot, and confirm with `gpresult /r`.
6. **Measure again:**
   ```powershell
   .\Test-WindowsBaseline.ps1 -ReportPath .\baseline-after.csv
   ```
   If you have SCC, run a STIG scan before and after too.
7. **Test that things still work:** RDP with NLA, domain logons, file shares, and the AD toolkit scripts.
8. **Document exceptions:** for any setting you had to leave off, record the reason, the risk, and the mitigation in a POA&M-style table (below).

---

## Results

_To be added after the lab is run:_

| Measure | Before | After |
|---|---|---|
| `Test-WindowsBaseline.ps1` checks passed | _ of 15 | _ of 15 |
| SCC STIG score (if used) | _% | _% |

- [ ] Screenshots: script output before and after, the GPO in Group Policy Management, `gpresult`
- [ ] SCC report summary (if used)

### Exceptions (POA&M style)

| Setting | Why it wasn't applied | Risk | Mitigation | Target date |
|---|---|---|---|---|
| _example: SMB signing on a legacy file share_ | _breaks an old scanner/printer_ | _relay attacks on that share_ | _isolated VLAN, replace device_ | _date_ |
