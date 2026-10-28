# IT Asset Inventory (Snipe-IT + Lansweeper)

Track every device, license, and accessory in the lab: who has it, where it is, and what state it's in. Then scan the network to find what you **missed**, and reconcile the two lists, the way help desks keep inventories honest.

> **Status:** tutorial ready. Results and screenshots to be added after the lab is run.

| | |
|---|---|
| **Role** | Help desk |
| **Time** | 3–4 hours |
| **Cost** | Free (Snipe-IT is open source; Lansweeper has a free plan with full detail for 100 assets) |
| **Builds on** | [Server lab](../../windows/server-lab/); HD01 from the [osTicket lab](../ticketing-osticket/) |
| **Resume keywords** | IT asset management, inventory, license tracking, LDAP/AD integration, device lifecycle |

## Why this matters

Help desks issue laptops to new hires, collect them from leavers, track warranty repairs, and answer "how many Adobe licenses do we have left?" Without an inventory, devices disappear and licenses get overbought or overused. Interviewers for help desk roles often ask how you'd track equipment. This lab gives you a real answer.

---

## Part 1: Install Snipe-IT

Snipe-IT runs well in Docker. Use the **HD01** Ubuntu server from the [osTicket lab](../ticketing-osticket/), or another small Ubuntu VM.

1. Install Docker:
   ```bash
   sudo apt update
   sudo apt install -y docker.io docker-compose-v2
   sudo usermod -aG docker $USER   # sign out and back in afterward
   ```
2. Follow Snipe-IT's official **Docker** installation guide (on snipe-it.readme.io). In short, you will:
   - download Snipe-IT's `docker-compose.yml` and example environment file into a new folder,
   - set `APP_URL` to `http://assets.lab.local:8080` (any free port works if 80 is taken by osTicket),
   - set strong database passwords,
   - generate an **APP_KEY** with the command the guide gives,
   - run `docker compose up -d`.
3. On **DC01**, add a DNS record: **DNS Manager → lab.local → New Host (A)**: `assets` → the server's IP (for example `10.10.10.40`).
4. Browse to `http://assets.lab.local:8080` from CLIENT01 and complete the setup wizard: site name `LAB Assets`, your admin account.

> **Why Docker here?** Snipe-IT needs PHP, a web server, and a database. Docker packages all of that so it doesn't conflict with osTicket on the same server. Knowing basic `docker compose` is a plus on any IT resume.

### ✅ Check your work
`docker compose ps` shows the Snipe-IT and database containers as **running**, and you can sign in to the web interface.

---

## Part 2: Set up the structure

Do these in order, since each one is used by the next. All are under **Settings** (the gear icon) unless noted.

### 2.1 Status labels
**Settings → Status Labels.** These describe where a device is in its life:

| Label | Type | Meaning |
|---|---|---|
| Ready to Deploy | Deployable | In stock, imaged, ready for a user |
| Deployed | Deployable | Checked out to someone |
| In Repair | Pending | Out for warranty or repair |
| Lost / Stolen | Undeployable | Triggers a security review |
| Retired | Archived | Wiped and disposed of |

### 2.2 Categories, manufacturers, and locations
- **Categories:** Laptop, Desktop, Server, Monitor, Phone, Software
- **Manufacturers:** Microsoft (virtual machines), Dell, Lenovo, HP
- **Locations:** HQ - IT Room, HQ - Finance, Remote

### 2.3 Asset models
**Assets → Asset Models → Create New:**

| Model | Category | Manufacturer |
|---|---|---|
| Hyper-V Virtual Machine | Server | Microsoft |
| Latitude 5450 (example) | Laptop | Dell |
| 24" Monitor (example) | Monitor | Dell |

---

## Part 3: Import users from Active Directory

Rather than typing users by hand, connect Snipe-IT to `lab.local` over **LDAP**.

1. On DC01, create a **service account** for reading the directory:
   - ADUC → **Corp\Service Accounts** → New User `svc-snipeit`, strong password, ✅ *Password never expires*.
   - It needs no group memberships. Any domain user can read basic directory information.
2. In Snipe-IT, **Settings → LDAP**:

| Field | Value |
|---|---|
| LDAP integration | Enabled |
| LDAP server | `ldap://dc01.lab.local` |
| Bind username | `svc-snipeit@lab.local` |
| Bind password | The service account's password |
| Base bind DN | `OU=Users,OU=Corp,DC=lab,DC=local` |
| LDAP filter | `&(objectClass=user)(objectCategory=person)` |
| Username field | `samaccountname` |
| First name / Last name / Email | `givenname` / `sn` / `mail` |
| Active flag | Leave blank for now |

3. **Test LDAP Synchronization** on the same page, then **People → LDAP Sync → Synchronize**.

> **Production note:** use **LDAPS** (`ldaps://`, port 636) so the bind password isn't sent in clear text. That needs a certificate on the DC, which is a good follow-up after the [PKI lab](../../windows/adcs-pki/).

### ✅ Check your work
**People** lists Jane, Marcus, Priya, Dana, Carlos, and Nathaniel.

---

## Part 4: Add assets and check them out

### 4.1 Add the lab's devices
**Assets → Create New** for each VM, using its real serial number. Find it on each VM with:
```powershell
(Get-CimInstance Win32_BIOS).SerialNumber
```

| Asset tag | Model | Serial | Status | Location |
|---|---|---|---|---|
| LAB-0001 | Hyper-V Virtual Machine | (DC01's) | Deployed | HQ - IT Room |
| LAB-0002 | Hyper-V Virtual Machine | (APP01's) | Deployed | HQ - IT Room |
| LAB-0003 | Hyper-V Virtual Machine | (CLIENT01's) | Ready to Deploy | HQ - IT Room |
| LAB-0004 | 24" Monitor | MON-0001 (example) | Ready to Deploy | HQ - IT Room |

### 4.2 Check out CLIENT01 to Jane
Open **LAB-0003 → Checkout** → **User: Jane Smith** → add a note ("New hire laptop, ticket #4") → **Checkout**. The status changes to **Deployed**, and Jane's profile now lists the device.

### 4.3 Simulate a repair and a departure
1. **Repair:** check LAB-0004 out, then edit it to **In Repair** with a note about the warranty case.
2. **Departure:** check LAB-0003 back in from Jane (**Checkin**), set it to **Ready to Deploy**, and note "Wiped with Autopilot Reset," as in the [departure checklist](../knowledge-base/KB-010-departure-checklist.md).

### 4.4 Licenses
**Licenses → Create New:**

| License | Seats | Assign to |
|---|---|---|
| Microsoft 365 Business Premium | 10 | All six lab users |
| Adobe Acrobat Pro (example) | 2 | Marcus, then try to assign a third and watch it warn you |

### ✅ Check your work
- **Reports → Activity Report** shows every checkout, check-in, and status change with who did it and when.
- The **dashboard** shows assets by status and remaining license seats.

📸 Screenshots: dashboard, Jane's profile with her laptop, the activity report

---

## Part 5: Discover what's really on the network (Lansweeper)

An inventory you type in by hand is only as good as your memory. A network scan finds what you forgot.

1. Create a free **Lansweeper** account and follow its setup wizard to install the scanning component on **APP01**. Product and screen names change between versions; the wizard walks you through it.
2. Create a dedicated scanning account in AD (`svc-lansweeper`). Add it to the local **Administrators** group on the lab machines through Group Policy (**Restricted Groups** or **Group Policy Preferences → Local Users and Groups**), so it can read hardware and software details over WMI.
3. Add a **scan target**: the IP range `10.10.10.1–10.10.10.254`, with the `svc-lansweeper` credentials.
4. Run the scan and wait for results.

> The free plan scans everything, with full details for the first 100 assets.

### ✅ Check your work
Lansweeper lists DC01, APP01, CLIENT01, HD01, and anything else on the subnet, with installed software, OS versions, and serial numbers.

---

## Part 6: Reconcile the two lists

Compare Lansweeper's discovered devices with Snipe-IT's inventory and record the differences:

| Finding | What it means | Action |
|---|---|---|
| In Lansweeper, not in Snipe-IT | Unrecorded device (shadow IT, or you forgot it) | Add it, or investigate who owns it |
| In Snipe-IT, not seen by Lansweeper | Powered off, lost, or retired | Find it, or mark it Lost / Retired |
| Serial numbers don't match | Data entry error | Fix the record |
| Software installed with no license record | Possible compliance problem | Add the license, or uninstall |

Write a short **reconciliation report** (half a page) of what you found and fixed.

## Troubleshooting

| Symptom | Fix |
|---|---|
| Snipe-IT shows a 500 error | `docker compose logs app`; usually a wrong `APP_KEY` or database password in the environment file |
| LDAP test fails: "Can't contact LDAP server" | Check DNS (`nslookup dc01.lab.local` from HD01) and that port 389 is reachable |
| LDAP sync finds no users | Check the Base bind DN and filter; test with `ldapsearch` if needed |
| Lansweeper shows devices with no details | The scanning account isn't a local admin, or the firewall blocks WMI |

## How to talk about it in an interview

> *"I ran Snipe-IT as an asset inventory, synced users from Active Directory over LDAP, and tracked the full device lifecycle: issue, repair, return, and wipe. Then I scanned the network with Lansweeper and reconciled the two, which found devices nobody had recorded. That's how I'd keep an inventory honest on a real help desk."*

## Results

_To be added after the lab is run:_
- [ ] Screenshots: dashboard, a user's assigned assets, the activity report
- [ ] Lansweeper scan results
- [ ] Reconciliation report
