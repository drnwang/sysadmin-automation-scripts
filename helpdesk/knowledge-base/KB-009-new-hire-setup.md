# KB-009: New hire setup checklist (SOP)

| | |
|---|---|
| **Applies to** | New employees in `lab.local` and Microsoft 365 |
| **Audience** | Technicians |
| **Time to complete** | About 1 hour of work, spread across the week before day one |
| **Last tested** | _Not yet tested_ |

## Trigger
An onboarding ticket from **HR or the hiring manager** with: name, title, department, manager, start date, and location. **No ticket, no account.** Accounts created from a hallway conversation are a security risk.

## One week before the start date

### Accounts
- [ ] Create the AD account in the right department OU. Use the [onboarding script](../../windows/active-directory/) or ADUC.
  - Username follows the standard (first initial + last name), with title, department, and manager filled in.
- [ ] Add to the **role group** for their job (for example `GG-Finance-Staff`). Grant only what the ticket lists.
  > Copying another employee's groups is fast but risky: it copies years of extra access. Use role groups instead.
- [ ] Assign the Microsoft 365 license.
- [ ] Add to distribution lists and Teams that the manager requested.

### Device
- [ ] Assign a laptop and record the asset tag and serial number against the user in the asset system ([asset inventory lab](../asset-inventory/)).
- [ ] Set it up: Autopilot enrollment or domain join, then confirm updates, encryption (BitLocker), and standard apps.
- [ ] Sign in once with a test account to confirm Group Policy applied (`gpresult /r`).

## Day one (with the employee)
- [ ] **Verify identity** in person or on a video call.
- [ ] Give the temporary password through a secure channel, and have them change it at first sign-in.
- [ ] Set up **MFA** with Microsoft Authenticator ([KB-002](./KB-002-mfa-new-phone.md), Part A).
- [ ] Test together:
  - [ ] Signs in to the laptop
  - [ ] Outlook and Teams open
  - [ ] Department drive maps and opens ([KB-004](./KB-004-mapped-drive-missing.md))
  - [ ] Prints a test page ([KB-005](./KB-005-printer-offline.md))
  - [ ] Opens the intranet
  - [ ] Connects to the VPN, if they'll work remotely ([KB-003](./KB-003-vpn-wont-connect.md))
- [ ] Show them **how to contact the help desk** and how to report phishing ([KB-008](./KB-008-report-phishing.md)).

## Day three
- [ ] Follow up: "Is everything working? Anything you still need access to?"
- [ ] Close the ticket with a summary: account, groups, license, device asset tag.

## Related
- [KB-010: Employee departure checklist](./KB-010-departure-checklist.md)
