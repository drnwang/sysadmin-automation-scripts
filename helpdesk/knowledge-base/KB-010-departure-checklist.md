# KB-010: Employee departure checklist (SOP)

| | |
|---|---|
| **Applies to** | Departing employees in `lab.local` and Microsoft 365 |
| **Audience** | Technicians |
| **Time to complete** | 30–45 minutes |
| **Last tested** | _Not yet tested_ |

## Trigger
An offboarding ticket from **HR** with the employee's name, last day, **exact time access should end**, and who receives their email and files (usually the manager).

> **Involuntary departures:** HR will ask for access to be removed **at a specific moment**, often during the meeting. Coordinate the time in advance and disable the account then, not before and not hours after.

## At the time access ends

### Stop access
- [ ] **Disable the AD account.** Use the [offboarding script](../../windows/active-directory/), which also resets the password, records and removes group memberships, and moves the account to the Disabled Users OU.
- [ ] **Revoke Microsoft 365 sessions:** Entra admin center → user → **Revoke sessions**. Disabling the account doesn't sign out existing sessions right away.
- [ ] **Block sign-in** in Microsoft 365 for cloud-only accounts. Accounts synced from AD (see the [hybrid identity lab](../../m365/hybrid-identity/)) are blocked automatically at the next sync after you disable them in AD.
- [ ] Remove **MFA methods** and any VPN or remote access.

### Preserve data
- [ ] **Convert the mailbox to a shared mailbox** (Microsoft 365 admin center → user → **Mail → Convert to shared mailbox**) and give the manager access.
  > Convert **before** removing the license. Removing the license first can lead to the mailbox being deleted after the retention period.
- [ ] Set an **automatic reply** if HR approves the wording (for example "Jane has left the company. Please contact Marcus Johnson.").
- [ ] Give the manager access to the user's **OneDrive** files before the retention period ends.
- [ ] Remove the **Microsoft 365 license** once the mailbox is shared.

### Recover equipment
- [ ] Collect the laptop, phone, badge, and any tokens.
- [ ] Update the **asset system**: returned, condition, next owner.
- [ ] Wipe or reset the laptop (for example **Autopilot Reset** or a reimage) before reissuing it.

## Afterward
- [ ] Record in the ticket: date and time disabled, groups removed (from the script's report), mailbox shared with, equipment returned.
- [ ] Schedule account **deletion** after the retention period in your policy (often 30–90 days).

## Related
- [KB-009: New hire setup checklist](./KB-009-new-hire-setup.md)
