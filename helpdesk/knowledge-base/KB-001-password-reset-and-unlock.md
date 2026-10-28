# KB-001: Reset a password or unlock an account

| | |
|---|---|
| **Applies to** | Active Directory accounts (`LAB\username`) |
| **Audience** | Technicians |
| **Time to fix** | 5 minutes |
| **Last tested** | _Not yet tested_ |

## Symptoms
- *"The referenced account is currently locked out and may not be logged on to."*
- *"The user name or password is incorrect"* after the user is sure they typed it right.
- *"Your password has expired and must be changed."*

## Before you start
**Verify the caller's identity before changing anything.** Never reset a password because an email or chat asked you to. Use your organization's method, for example:
- Call back the phone number on file in AD (**Properties → Telephones**), not a number the caller gives you.
- Confirm with the user's manager.
- Ask a question only the employee would know, if your policy defines one.

Account resets are one of the most common ways attackers get in ("Hi, I'm the new VP and I'm locked out..."). Slowing down here is part of the job.

## Fix: unlock only
Use this when the user remembers their password but is locked out.

**In Active Directory Users and Computers (ADUC):**
1. Right-click the domain → **Find** → type the user's name → **Find Now**.
2. Double-click the user → **Account** tab.
3. Check **Unlock account** → **OK**.

**In PowerShell:**
```powershell
Unlock-ADAccount -Identity jsmith
```

Then ask the user to sign in **now**, while you're on the call.

## Fix: reset the password
1. In ADUC, right-click the user → **Reset Password**.
2. Enter a temporary password that meets policy (14+ characters in `lab.local`).
3. ✅ **User must change password at next logon**.
4. ✅ **Unlock the user's account** (if it's locked).
5. **OK**.
6. Give the temporary password to the user **through a verified channel**, such as reading it over the callback, never in a ticket or email.

**In PowerShell:**
```powershell
Set-ADAccountPassword -Identity jsmith -Reset -NewPassword (Read-Host -AsSecureString 'Temporary password')
Set-ADUser -Identity jsmith -ChangePasswordAtLogon $true
Unlock-ADAccount -Identity jsmith
```

## If the account keeps locking
Something is still trying the **old** password. Find out what:

1. On the domain controller holding the **PDC emulator** role (DC01 in the lab), open **Event Viewer → Windows Logs → Security**.
2. **Filter Current Log** → Event ID **4740** ("A user account was locked out").
3. Open the newest event for the user. **Caller Computer Name** is the device sending the bad password.

```powershell
Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 4740 } -MaxEvents 20 |
    Select-Object TimeCreated, @{ n = 'User'; e = { $_.Properties[0].Value } }, @{ n = 'From'; e = { $_.Properties[1].Value } }
```

**Common culprits** on that device:

| Culprit | Fix |
|---|---|
| Phone or tablet email with the old password | Update the password in the mail app |
| Saved credentials | **Control Panel → Credential Manager → Windows Credentials**: remove old entries for the server |
| Mapped drive saved with old credentials | `net use` → `net use X: /delete`, then reconnect |
| Disconnected RDP session | Sign out of the old session on that server |
| Scheduled task or service running as the user | Update its credentials, or better, move it to a service account |

## Escalate when
- The account locks again within minutes and you can't find the source → **Systems**.
- **Several accounts lock at the same time**, or 4740 events come from an unknown computer → **Security**. This can be a password-spraying attack.
- The caller can't be verified, or is pressuring you to skip verification → **Security**.

Include the account name, the time of the lockouts, and the **Caller Computer Name** values.

## Related
- [KB-002: Set up MFA on a new phone](./KB-002-mfa-new-phone.md)
- [KB-006: Outlook keeps asking for a password](./KB-006-outlook-password-prompts.md)
