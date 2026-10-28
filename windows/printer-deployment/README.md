# Printer Deployment with a Print Server and Group Policy

Set up APP01 as a print server, share a printer with group-based permissions, deploy it automatically to the Finance department through Group Policy, then practice the troubleshooting that fills real help desk queues: offline printers, stuck jobs, and driver errors.

> **Status:** tutorial ready. Results and screenshots to be added after the lab is run.

| | |
|---|---|
| **Role** | Help desk, sysadmin |
| **Time** | About 2 hours |
| **Cost** | Free (no physical printer needed) |
| **Builds on** | [Server lab](../server-lab/) (DC01, APP01, CLIENT01) |
| **Resume keywords** | Print Management, print server, Group Policy Preferences, Point and Print, spooler troubleshooting |

## Why this matters

Printing is one of the top ticket categories on any help desk. Admins who can deploy printers centrally, instead of walking to each desk, save their team hours. Understanding the **PrintNightmare** driver restrictions (2021) also shows you're current on Windows security changes.

---

## Part 1: Install the print server role

On **APP01**, signed in as `LAB\adm-nwang`:

**Click-ops:** Server Manager → **Add Roles and Features** → **Print and Document Services** → role service **Print Server** → **Install**.

**PowerShell:**
```powershell
Install-WindowsFeature Print-Server -IncludeManagementTools
```

Open **Print Management**: `Start → Run → printmanagement.msc`.

---

## Part 2: Create a printer (no hardware needed)

You'll point the printer at an IP address where no real device exists. Jobs will queue and then error, which is perfect for practicing stuck-queue troubleshooting.

**Click-ops:**
1. Print Management → **Print Servers → APP01** → right-click **Printers** → **Add Printer**.
2. **Add a TCP/IP or Web Services Printer by IP address or hostname** → IP `10.10.10.50` → uncheck *Auto detect the printer driver to use*.
3. Device type: **Standard → Generic Network Card**.
4. **Install a new driver** → Manufacturer **Generic** → **Generic / Text Only**.
5. Printer name `Finance-Printer`, ✅ **Share this printer**, share name `Finance-Printer`, location `HQ - Finance`.

**PowerShell:**
```powershell
Add-PrinterPort   -Name 'IP_10.10.10.50' -PrinterHostAddress '10.10.10.50'
Add-PrinterDriver -Name 'Generic / Text Only'
Add-Printer -Name 'Finance-Printer' -DriverName 'Generic / Text Only' -PortName 'IP_10.10.10.50' `
    -Shared -ShareName 'Finance-Printer' -Location 'HQ - Finance' -Published
```

`-Published` lists the printer in Active Directory, so users can search for it.

> **Why "Generic / Text Only"?** It's built into Windows clients, so users can connect without installing a driver. With a real printer, you'd use the manufacturer's driver, and that's where Part 4's driver rules matter.

### ✅ Check your work
```powershell
Get-Printer -ComputerName APP01 | Select-Object Name, ShareName, Shared, Published, PortName
```

---

## Part 3: Control who can print (AGDLP)

Printers follow the same group model as the [file share](../server-lab/01-clickops-guide.md#87-create-the-finance-share): permissions go to a domain local group, and people go into role groups.

1. On **DC01**, in ADUC → **Corp\Groups** → New Group: `DL-FinancePrinter-Print`, **Domain local**, Security. Add `GG-Finance-Staff` as a member.
2. On APP01, in Print Management → right-click **Finance-Printer** → **Properties → Security**:
   - Remove **Everyone**.
   - Add `LAB\DL-FinancePrinter-Print` → **Print**.
   - Keep **Administrators** with *Manage this printer* and *Manage documents*.

### ✅ Check your work
The Security tab lists `DL-FinancePrinter-Print` with **Print** only, and Everyone is gone.

---

## Part 4: Deploy the printer with Group Policy

Use **Group Policy Preferences**, the most flexible method, which can target by group and set a default printer.

On **DC01**, open **Group Policy Management**:
1. Right-click **Corp\Users** → **Create a GPO in this domain, and Link it here** → `Corp - Printers`.
2. Edit it → **User Configuration → Preferences → Control Panel Settings → Printers** → right-click → **New → Shared Printer**.
3. **General** tab:

| Setting | Value |
|---|---|
| Action | **Update** (adds the printer if missing, fixes it if changed) |
| Share path | `\\APP01\Finance-Printer` |
| Set this printer as the default printer | ✅ Only if a local printer isn't present |

4. **Common** tab → ✅ **Item-level targeting** → **Targeting… → New Item → Security Group** → `LAB\GG-Finance-Staff`.

> **Why Update, not Create?** *Create* only adds the printer once. If a user deletes it, it never comes back. *Update* puts it back at each refresh, which prevents a whole category of tickets.

### About drivers and PrintNightmare
After the 2021 **PrintNightmare** vulnerabilities, Microsoft changed Windows so that, by default, **only administrators can install printer drivers** through Point and Print. That means:
- If the driver is already on the computer (like *Generic / Text Only*), users connect with no prompt.
- If it isn't, users get an administrator prompt and the connection fails.

The secure fix is to **pre-install drivers** on computers (through Intune, Configuration Manager, or a computer startup script), **not** to turn the restriction off. Expect an interview question about this.

### ✅ Check your work
On **CLIENT01**, sign in as `jsmith`:
```cmd
gpupdate /force
```
Sign out and back in. **Settings → Bluetooth & devices → Printers & scanners** lists **Finance-Printer on APP01**.

Then sign in as `ppatel` (HR): **no** Finance printer appears. If Priya adds it manually (`\\APP01\Finance-Printer`), Windows refuses, because the printer's permissions don't include HR.

📸 Screenshots: the GPP printer item with targeting, the printer on Jane's computer

---

## Part 5: Practice troubleshooting

### 5.1 A stuck queue
1. As Jane, print a few test pages (**Printer properties → Print Test Page**). The device doesn't exist, so the jobs pile up.
2. On APP01, in Print Management → **Custom Filters → Printers With Jobs**: Finance-Printer appears.
3. Clear one printer's jobs:
   ```powershell
   Get-PrintJob -ComputerName APP01 -PrinterName 'Finance-Printer' | Remove-PrintJob
   ```
4. Practice the "spooler is wedged" fix (this clears **all** queues, so warn users first):
   ```powershell
   Stop-Service Spooler -Force
   Remove-Item "$env:SystemRoot\System32\spool\PRINTERS\*" -Force
   Start-Service Spooler
   ```
5. Follow along with [KB-005: Printer offline or jobs stuck](../../helpdesk/knowledge-base/KB-005-printer-offline.md) and correct anything in the article that doesn't match.

### 5.2 Turn on print logging
Printing events aren't logged by default. Turn them on so you can answer "did my job ever reach the server?":

**Event Viewer → Applications and Services Logs → Microsoft → Windows → PrintService → Operational** → right-click → **Enable Log**.

Print again, then look for **Event ID 307** (document printed), which shows the user, the document, and the printer.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| Printer doesn't appear for Finance users | `gpresult /r`: is *Corp - Printers* applied? Is the user in `GG-Finance-Staff`? Sign out and in after group changes. |
| "Windows can't connect to the printer: access denied" | Printer permissions (Part 3), or a driver needs admin install (Part 4) |
| "Do you trust this printer?" or admin prompt | The driver isn't on the client. Pre-install it. Don't disable the security restriction. |
| Event 307 never appears | The PrintService Operational log isn't enabled (5.2) |

## How to talk about it in an interview

> *"I set up a Windows print server, restricted the printer to Finance with AGDLP groups, and deployed it with Group Policy Preferences using item-level targeting and the Update action, so it reappears if a user removes it. I also practiced clearing stuck queues remotely and explained the post-PrintNightmare driver rules: pre-install drivers instead of loosening Point and Print."*

## Results

_To be added after the lab is run:_
- [ ] Screenshots: Print Management, the GPP item, the printer on CLIENT01, Event 307
- [ ] Notes from the stuck-queue exercise
