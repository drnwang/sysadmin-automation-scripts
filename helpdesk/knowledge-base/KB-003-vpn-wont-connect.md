# KB-003: VPN won't connect

| | |
|---|---|
| **Applies to** | Company VPN client (WireGuard in the lab; the same steps apply to Cisco Secure Client, GlobalProtect, and others) |
| **Audience** | End users (first steps), technicians |
| **Time to fix** | 5–20 minutes |
| **Last tested** | _Not yet tested_ |

## Symptoms
- *"Authentication failed"* or *"Login failed."*
- The client spins on *Connecting…* and times out.
- The VPN says **Connected**, but shared drives, the intranet, or internal sites don't open.

## First steps (end users)
1. **Is the internet working?** Open any public website. If it doesn't load, the problem is your Wi-Fi, not the VPN.
2. **Hotel, airport, or café Wi-Fi?** Open a browser first and accept the network's sign-in page, then try the VPN again.
3. **Restart the VPN client**: quit it fully (check the system tray), then open it again.
4. **Restart your computer.**
5. Still stuck? Contact the help desk with the **exact error message** (a screenshot is best).

## Fix (technicians)
Work out which of the three symptoms you have.

### "Authentication failed"
The VPN uses the user's domain password and MFA.
1. Check the account in ADUC: locked out? Password expired? See [KB-001](./KB-001-password-reset-and-unlock.md).
2. Did the user approve the MFA prompt? See [KB-002](./KB-002-mfa-new-phone.md) if they changed phones.
3. Is the user in the VPN access group? Check **Member Of**.

### Times out
1. Ask the user to try a **phone hotspot**. If it works there, their home or hotel network is blocking VPN traffic (often UDP). Common with guest networks.
2. Check the device's **date and time** are correct. Certificate-based VPNs fail when the clock is wrong.
3. Check whether **other remote users** can connect. If none can, it's an outage. Escalate now.

### Connected, but internal resources don't work
Usually DNS: the computer is still using the home router for name lookups.
1. Run:
   ```cmd
   ipconfig /all
   nslookup dc01.lab.local
   ```
2. If `nslookup` fails or answers from the home router's address, the VPN didn't apply its DNS server. Disconnect and reconnect.
3. Test by IP: `ping 10.10.10.10`. If ping by IP works but by name doesn't, it's DNS. If neither works, it's routing. Escalate.

## Escalate when
- More than one user can't connect → **Systems** (possible outage; open one parent ticket and link the others).
- Authentication fails for a user whose account is healthy → **Systems**.
- Connected but routing fails (ping by IP fails) → **Systems**.

Include the user's location type (home, hotel), the exact error, the time, and what you tested.

## Related
- [KB-001: Reset a password or unlock an account](./KB-001-password-reset-and-unlock.md)
- [KB-004: Mapped drive missing or "access denied"](./KB-004-mapped-drive-missing.md)
