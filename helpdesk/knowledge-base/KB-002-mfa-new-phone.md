# KB-002: Set up MFA on a new phone

| | |
|---|---|
| **Applies to** | Microsoft 365 / Entra ID accounts with Microsoft Authenticator |
| **Audience** | End users (Part A), technicians (Part B) |
| **Time to fix** | 10 minutes |
| **Last tested** | _Not yet tested_ |

## Symptoms
- *"Approve sign-in request"* goes to a phone the user no longer has.
- The user got a new phone and Microsoft Authenticator shows no accounts.
- *"We couldn't verify your identity"* or a loop back to the sign-in prompt.

## Part A (end users): you still have your old phone

1. On a computer, go to **https://mysignins.microsoft.com/security-info** and sign in, approving on your **old** phone.
2. Select **Add sign-in method** → **Microsoft Authenticator** → **Add**.
3. On your **new** phone, install **Microsoft Authenticator** from the App Store or Google Play.
4. In Authenticator, tap **+** → **Work or school account** → **Scan QR code**, and scan the code shown on the computer.
5. Approve the test notification on the new phone.
6. Back on the Security info page, set **Microsoft Authenticator** on the new phone as your **default sign-in method**.
7. **Delete** the old phone from the list.

## Part B (technicians): the user doesn't have the old phone

### Before you start
**Verify identity strongly.** Re-registering MFA hands account access to whoever is on the phone. Use a callback to the number in the HR system, a video call, or manager confirmation. Follow your organization's policy.

### Fix
1. Open the **Microsoft Entra admin center** → **Users** → **All users** → select the user.
2. Select **Authentication methods**.
3. Choose one:
   - **Require re-register multifactor authentication.** At next sign-in, the user is prompted to set up MFA again.
   - **Add authentication method → Temporary Access Pass**, if your organization allows it. This is a time-limited passcode the user can use to sign in once and register their new phone. Give it to them only over the verified channel.
4. Delete the authentication methods tied to the lost phone.
5. Stay on the call while the user signs in and completes Part A, steps 3–6.

## If that didn't work
| Problem | Next step |
|---|---|
| QR code won't scan | Choose **Can't scan image?** and enter the code and URL manually |
| No notifications arrive on the new phone | Check that notifications are allowed for Authenticator, and that the phone's time is set automatically |
| Temporary Access Pass option is missing | It isn't enabled in the tenant. Escalate. |

## Escalate when
- You can't verify the user's identity → **Security**.
- The user reports MFA prompts they **didn't** start ("MFA fatigue") → **Security**, immediately. Someone else may have their password.

## Related
- [KB-001: Reset a password or unlock an account](./KB-001-password-reset-and-unlock.md)
- [KB-008: Report a suspicious email](./KB-008-report-phishing.md)
