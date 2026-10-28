# Mock ticket queue

Twenty realistic tickets from the `lab.local` employees. Enter each one through the **customer portal** as the user who reports it (or as an agent with **New Ticket**), then work it like a real queue: set the help topic and priority, reply, escalate when it's not Tier 1 work, fix it in the lab where possible, and close it with a resolution note.

Several tickets can be fixed for real in the lab. They're marked 🔧.

| # | Reported by | Department | Subject | What's really going on | Expected priority | Tier |
|---|---|---|---|---|---|---|
| 1 | Jane Smith (jsmith) | Finance | I'm locked out of my computer | Account locked after 5 bad passwords 🔧 | High | 1 |
| 2 | Marcus Johnson (mjohnson) | Finance | Can't get to the F: drive | Not in GG-Finance-Staff / stale token 🔧 | Normal | 1 |
| 3 | Priya Patel (ppatel) | HR | Can I edit the Finance budget file? | Read-only by design (AGDLP). Needs manager approval, not a fix. | Low | 1 |
| 4 | Dana Lee (dlee) | HR | New hire starting Monday: Alex Kim, HR Generalist | Onboarding request 🔧 (use New-ADUserOnboarding.ps1) | Normal | 1 |
| 5 | Marcus Johnson (mjohnson) | Finance | Jane's last day is Friday | Offboarding request, scheduled 🔧 (Disable-ADUserOffboarding.ps1) | Normal | 2 |
| 6 | Carlos Reyes (creyes) | IT | Intranet site asking for a password | Site not in Local intranet zone 🔧 | Normal | 2 |
| 7 | Jane Smith (jsmith) | Finance | Printer says offline | Spooler stuck on APP01 🔧 | Normal | 1 |
| 8 | Dana Lee (dlee) | HR | Got a new phone, can't approve sign-ins | MFA method re-registration | High | 1 |
| 9 | Priya Patel (ppatel) | HR | Computer is really slow | Triage: Task Manager, disk space, updates pending | Normal | 1 |
| 10 | Marcus Johnson (mjohnson) | Finance | Suspicious email asking me to "verify my payroll" | Phishing report: don't click, report, check if others got it | **Emergency** | 2 |
| 11 | Jane Smith (jsmith) | Finance | Outlook keeps asking for my password | Cached credentials / profile issue | Normal | 1 |
| 12 | Carlos Reyes (creyes) | IT | DC01 disk at 85% | Monitoring alert, investigate log growth 🔧 | High | 2 |
| 13 | Dana Lee (dlee) | HR | Teams microphone not working in meetings | Device permissions / default device | Normal | 1 |
| 14 | Priya Patel (ppatel) | HR | Need Adobe Acrobat installed | Software request, needs approval and license | Low | 1 |
| 15 | Marcus Johnson (mjohnson) | Finance | Accidentally deleted a spreadsheet from the share | Restore from Previous Versions / backup 🔧 | High | 2 |
| 16 | Jane Smith (jsmith) | Finance | Screen locks too fast | Working as designed (15-minute GPO). Explain the security reason. | Low | 1 |
| 17 | Carlos Reyes (creyes) | IT | New laptop won't join the domain | Client DNS pointed at the router, not DC01 🔧 | Normal | 2 |
| 18 | Dana Lee (dlee) | HR | Can't open https://intranet.lab.local, says certificate error | Self-signed cert (until the PKI lab) | Low | 2 |
| 19 | Priya Patel (ppatel) | HR | Password expires tomorrow, I'm on vacation | Proactive reset guidance; Get-PasswordExpiryReport.ps1 🔧 | Normal | 1 |
| 20 | Marcus Johnson (mjohnson) | Finance | Whole Finance team can't reach the share this morning | Outage: APP01 Server service / share down 🔧. Major-incident communication. | **Emergency** | 3 |

## What "good" looks like for each ticket

1. **Acknowledge** within the SLA, in plain language, with what happens next.
2. **Verify identity** before account changes (tickets 1, 8, 19). Never reset a password because an email asked.
3. **Document** what you checked, even when it didn't work. The next tech needs your notes.
4. **Escalate** with a summary, not "see below." Include what you tried and what you need.
5. **Resolve** with the root cause and fix in one or two sentences, then link the KB article if one exists.
6. **Close the loop:** confirm with the user before closing.

## Sample resolution note

> **Ticket #2: Can't get to the F: drive**
> **Cause:** Marcus was added to GG-Finance-Staff this morning, but his sign-in token was issued before the change, so the share still denied access.
> **Fix:** Had him sign out and back in; confirmed with `whoami /groups` that GG-Finance-Staff now appears. F: maps and opens.
> **KB:** [KB-004 Mapped drive missing or access denied](../knowledge-base/KB-004-mapped-drive-missing.md)
