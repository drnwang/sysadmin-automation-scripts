# KB-006: Outlook keeps asking for a password

| | |
|---|---|
| **Applies to** | Microsoft Outlook (Microsoft 365) on Windows |
| **Audience** | Technicians |
| **Time to fix** | 10–20 minutes |
| **Last tested** | _Not yet tested_ |

## Symptoms
- A sign-in window keeps popping up even after the user enters the right password.
- Outlook shows **Need Password** or **Disconnected** in the bottom bar.
- Mail stops syncing after a password change.

## Before you start
Check whether it's the **account** or the **computer**:
1. Ask the user to open **https://outlook.office.com** in a browser and sign in.
2. **Works in the browser?** The account is fine. The problem is on the computer. Continue below.
3. **Fails in the browser too?** It's the account. Check the password, lockout, MFA, and license (see [KB-001](./KB-001-password-reset-and-unlock.md) and [KB-002](./KB-002-mfa-new-phone.md)).

## Fix
Try these in order, and test Outlook after each one.

1. **Sign out and back in to Office.** In Outlook: **File → Office Account → Sign out**. Close Outlook, reopen it, and sign in.
2. **Clear saved credentials.** Close Outlook. Open **Control Panel → Credential Manager → Windows Credentials** and remove entries that start with **MicrosoftOffice**. Reopen Outlook and sign in.
3. **Check the date and time.** **Settings → Time & language → Date & time** → *Set time automatically* on. Sign-in tokens fail when the clock is off.
4. **Create a new Outlook profile.** This fixes a corrupted profile:
   - Close Outlook.
   - **Control Panel → Mail (Microsoft Outlook) → Show Profiles → Add** → name it `Outlook-New` → sign in.
   - Select **Always use this profile → Outlook-New** → **OK**.
   - Open Outlook and let it sync. Once it works, remove the old profile.

> "New Outlook for Windows" doesn't use classic profiles. For it, step 1 (sign out and back in) and step 2 are the main fixes.

## If that didn't work
| Clue | Likely cause |
|---|---|
| Prompts started right after a password change | Old password cached elsewhere. Repeat step 2 and check the phone's mail app. |
| Only happens off the company network | Conditional Access may require a compliant device or MFA. Check Entra **sign-in logs** for the reason. |
| Many users at once | A Microsoft 365 service issue. Check **Microsoft 365 admin center → Health → Service health**. |

## Escalate when
- Outlook on the web also fails and the account looks healthy → **Systems**.
- Entra sign-in logs show sign-ins from locations the user doesn't recognize → **Security**.
- Several users are affected → **Systems**. Check service health first and link the incident.

## Related
- [KB-001: Reset a password or unlock an account](./KB-001-password-reset-and-unlock.md)
- [KB-002: Set up MFA on a new phone](./KB-002-mfa-new-phone.md)
