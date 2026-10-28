# Active Directory Toolkit

PowerShell scripts for the account tasks a help desk or sysadmin team handles every week: onboarding, offboarding, password-expiry outreach, and stale-account audits.

| Script | What it does | Changes AD? |
|---|---|---|
| [`New-ADUserOnboarding.ps1`](./New-ADUserOnboarding.ps1) | Creates new-hire accounts from a CSV or parameters, sets a temporary password, and adds groups | Yes (supports `-WhatIf`) |
| [`Disable-ADUserOffboarding.ps1`](./Disable-ADUserOffboarding.ps1) | Disables a departing user, resets the password, removes groups, and moves the account to a Disabled OU | Yes (supports `-WhatIf`) |
| [`Get-PasswordExpiryReport.ps1`](./Get-PasswordExpiryReport.ps1) | Lists users whose passwords expire within N days | No, read-only |
| [`user_audit.ps1`](./user_audit.ps1) | Lists users inactive for 90+ days or who have never logged on | No, read-only |

**Requirements:** the ActiveDirectory module (RSAT), run as an account with the right AD permissions. Always try changes with `-WhatIf` first.

---

## Onboarding: `New-ADUserOnboarding.ps1`

For each new hire, the script:
1. Builds a username from first initial + last name (`jsmith`) and adds a number if it's taken (`jsmith2`)
2. Creates the account in the right OU with display name, title, department, and manager
3. Sets a random 16-character temporary password and requires a change at first logon
4. Adds the user to their security groups
5. Saves a CSV report with each account's status and temporary password

**From a CSV** (see [`new-hires-example.csv`](./new-hires-example.csv)):

```powershell
.\New-ADUserOnboarding.ps1 -CsvPath .\new-hires.csv -Domain corp.example.com -WhatIf   # preview
.\New-ADUserOnboarding.ps1 -CsvPath .\new-hires.csv -Domain corp.example.com           # run
```

**One user:**

```powershell
.\New-ADUserOnboarding.ps1 -FirstName Jane -LastName Smith -Title "Financial Analyst" -Department Finance `
    -Manager mjohnson -OU "OU=Users,OU=Finance,DC=corp,DC=example,DC=com" `
    -Groups "Finance Staff","VPN Users" -Domain corp.example.com
```

> 🔐 The report contains temporary passwords. Share them through a secure channel and delete the file afterward.

---

## Offboarding: `Disable-ADUserOffboarding.ps1`

For each departing user, the script:
1. Records their group memberships in the report, so access can be restored if HR reverses the decision
2. Disables the account
3. Resets the password to a random value
4. Removes all group memberships (the primary group, Domain Users, stays)
5. Sets the description to `Disabled <date> - <ticket>`
6. Moves the account to the Disabled Users OU

```powershell
.\Disable-ADUserOffboarding.ps1 -Identity jsmith,creyes -Ticket INC0012345 `
    -DisabledOU "OU=Disabled Users,DC=corp,DC=example,DC=com" -WhatIf
```

Microsoft 365 steps (converting the mailbox to shared, removing licenses, transferring OneDrive) are separate.

---

## Password expiry report: `Get-PasswordExpiryReport.ps1`

Finds enabled users whose passwords expire within the next N days, or already have. It uses `msDS-UserPasswordExpiryTimeComputed`, which respects fine-grained password policies. It's handy for contacting remote users before they get locked out.

```powershell
.\Get-PasswordExpiryReport.ps1 -Days 7
.\Get-PasswordExpiryReport.ps1 -Days 14 -SearchBase "OU=Users,DC=corp,DC=example,DC=com" -ReportPath .\expiring.csv
```

---

## Inactive user audit: `user_audit.ps1`

Lists accounts that haven't logged on in 90+ days, or never have. Stale accounts are a common audit finding.

```powershell
.\user_audit.ps1 | Export-Csv .\inactive-users.csv -NoTypeInformation
```

`LastLogonDate` replicates between domain controllers only every 9–14 days by default, so treat results as approximate, and check service accounts before disabling anything.

---

## Testing these scripts

No production domain is needed. A free **Windows Server evaluation** VM (180-day trial) promoted to a domain controller is enough:

```powershell
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
Install-ADDSForest -DomainName lab.local
```

Then create a few test OUs and groups, and run each script with `-WhatIf` before running it for real.
