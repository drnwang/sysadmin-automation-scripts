# KB-008: Report a suspicious email

| | |
|---|---|
| **Applies to** | All email users |
| **Audience** | End users (Part A), technicians (Part B) |
| **Time to fix** | Report: 1 minute. Response: depends on what happened. |
| **Last tested** | _Not yet tested_ |

## Signs an email may be phishing
- It creates **urgency**: "Your account will be closed today," "Payroll needs you to verify now."
- It asks you to **sign in**, **pay**, **buy gift cards**, or **open an attachment** you didn't expect.
- The sender's address doesn't match the name, or is spelled slightly wrong.
- Hovering over a link shows a website that isn't the real company's.

## Part A (end users): what to do
1. **Don't** click links, open attachments, or reply.
2. **Report it**: in Outlook, select the message → **Report** → **Report phishing**. If you don't see that button, forward it **as an attachment** to the help desk.
3. Then delete it.

### If you already clicked, entered your password, or opened an attachment
**Call the help desk right away.** Don't just send an email. Fast action limits the damage, and you won't get in trouble for reporting it.

## Part B (technicians): handling the ticket
**Priority: Emergency.** Transfer to **Security** after the first steps below.

### 1. Ask three questions
1. Did you **click** a link?
2. Did you **enter your password** or any other information?
3. Did you **open an attachment**?

### 2. Act based on the answers
| What happened | Do this now |
|---|---|
| Only received it | Confirm it was reported; reassure the user |
| Clicked, but entered nothing | Note the time; Security reviews the link |
| **Entered their password** | Reset the password ([KB-001](./KB-001-password-reset-and-unlock.md)). In the Entra admin center, open the user and select **Revoke sessions**. Check **Authentication methods** for any MFA method the user didn't add. |
| **Opened an attachment** | Disconnect the computer from the network (unplug or turn off Wi-Fi), but **don't turn it off**. Security may need what's in memory. |

### 3. Write the internal note Security needs
- Sender address, subject line, and time received
- What the user did (from the three questions), with times
- What you've done so far (reset, sessions revoked, device isolated)
- Whether other users received the same email, if you can see it

## Escalate when
**Always**, to **Security**, after the steps above. Phishing tickets are never closed by Tier 1 alone.

## Related
- [KB-001: Reset a password or unlock an account](./KB-001-password-reset-and-unlock.md)
- [KB-002: Set up MFA on a new phone](./KB-002-mfa-new-phone.md)
