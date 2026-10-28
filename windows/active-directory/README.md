# Inactive User Audit: `user_audit.ps1`

Finds Active Directory user accounts that haven't logged on in **90 days or more**, plus accounts that have **never** logged on. Stale accounts are a common security finding, because unused accounts can be taken over without anyone noticing.

## How it works

1. Loads the `ActiveDirectory` module.
2. Sets a cutoff date 90 days in the past.
3. Pulls every user with their `LastLogonDate`.
4. Keeps users whose last logon is older than the cutoff or empty.
5. Outputs `Name`, `SamAccountName`, and `LastLogonDate`.

## Run it

```powershell
.\user_audit.ps1
```

Export to CSV for review:

```powershell
.\user_audit.ps1 | Export-Csv .\inactive-users.csv -NoTypeInformation
```

## Notes

- `LastLogonDate` replicates between domain controllers only every 9–14 days by default, so treat results as approximate.
- Review the list with account owners before disabling anything. Service accounts often show as "inactive."
