# KB-004: Mapped drive missing or "access denied"

| | |
|---|---|
| **Applies to** | Department shares, for example `\\APP01\Finance` (F:) |
| **Audience** | Technicians |
| **Time to fix** | 5–15 minutes |
| **Last tested** | _Not yet tested_ |

## Symptoms
- The **F:** drive is missing from File Explorer.
- *"Windows cannot access \\\\APP01\\Finance. You do not have permission to access..."*
- *"The network path was not found."*
- A red X on the drive icon.

## Fix
The error message tells you which direction to look:

| Message | Meaning | Go to |
|---|---|---|
| "You do not have permission" / "Access is denied" | The server answered and said no | **A. Permissions** |
| "The network path was not found" | The computer couldn't reach the share at all | **B. Connectivity** |
| Drive simply missing | The mapping didn't apply | **C. Drive mapping** |

### A. Permissions
1. Should the user have access? Check the **request or approval**. Don't add people to groups just because they asked.
2. On the user's computer, check their current groups:
   ```cmd
   whoami /groups | findstr /i finance
   ```
3. **Group missing from the list, but the user is in it in ADUC?** Their sign-in token is older than the change. Have them **sign out and back in**. This fixes most cases right after someone is added to a group.
4. **Not in the group in ADUC?** With approval, add them to the role group (`GG-Finance-Staff`), not directly to the folder's permissions.
5. Still denied? On APP01, check **effective access**: right-click `C:\Shares\Finance` → **Properties → Security → Advanced → Effective Access** → select the user → **View effective access**.

### B. Connectivity
1. `ping app01.lab.local`. If it fails, check the user's network and VPN (see [KB-003](./KB-003-vpn-wont-connect.md)).
2. Try the full path directly: **Win + R** → `\\APP01\Finance`.
3. If **nobody** can reach it, the share or server is down. Escalate as an outage.

### C. Drive mapping
1. Run `gpresult /r` and confirm **Corp - User Settings** appears under *Applied Group Policy Objects*.
2. Run `gpupdate /force`, then sign out and back in. Drive maps apply at sign-in.
3. Check for a stale mapping: `net use`. If F: shows as *Unavailable* or points somewhere else, remove it with `net use F: /delete` and sign in again.
4. Check **Credential Manager** for saved credentials for APP01 and remove them.

## Escalate when
- More than one user can't reach the share → **Systems**, as an outage.
- Effective access shows the user should have access, but they're still denied → **Systems**.
- Someone requests access without an approval → back to the requester for approval. Don't escalate.

## Related
- [KB-001: Reset a password or unlock an account](./KB-001-password-reset-and-unlock.md)
- [KB-003: VPN won't connect](./KB-003-vpn-wont-connect.md)
