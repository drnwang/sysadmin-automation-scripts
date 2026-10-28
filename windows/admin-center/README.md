# Windows Admin Center

Manage every server in the lab from a web browser: services, event logs, updates, files, storage, certificates, and a remote PowerShell console. Windows Admin Center (WAC) is Microsoft's free, modern replacement for juggling Server Manager, MMC consoles, and Remote Desktop sessions.

> **Status:** tutorial ready. Results and screenshots to be added after the lab is run.

| | |
|---|---|
| **Role** | Help desk, sysadmin |
| **Time** | 1–2 hours |
| **Cost** | Free |
| **Builds on** | [Server lab](../server-lab/) |
| **Resume keywords** | Windows Admin Center, remote server management, Server Core management |

## Why this matters

Admins manage dozens of servers, many of them Server Core with no desktop at all. WAC lets you do routine work (restart a service, read an event log, check disk space) from one browser tab, without signing in to each server. It's also an easy, visible win to mention in interviews: "I set up centralized browser-based server management."

---

## Part 1: Install WAC on APP01

1. On APP01, download **Windows Admin Center** from Microsoft (search "Windows Admin Center download" on microsoft.com).
2. Run the installer:

| Setting | Value | Why |
|---|---|---|
| Installation type | **Gateway** (or the default for a server install) | Others connect to it from their browsers |
| Port | **6600** (not 443) | IIS on APP01 already uses 443 for the intranet |
| Certificate | Self-signed for now. Use a certificate from your [PKI lab](../adcs-pki/) if you've done it. | |
| Allow WAC to modify this machine's trusted hosts | Yes | Needed to manage some machines |

3. Finish, and note the URL: `https://app01.lab.local:6600`.

> Installer screens change between WAC versions. If yours differs, keep the key decisions: install on a server as a gateway, and pick a port that doesn't clash with IIS.

### ✅ Check your work
From CLIENT01, browse to `https://app01.lab.local:6600` and sign in as `LAB\adm-nwang`. The WAC home page loads.

---

## Part 2: Add the lab servers

1. **+ Add → Servers** → add each by name: `dc01.lab.local`, `dc02.lab.local` (if built), `app01.lab.local`, `fs02.lab.local` (if built).
2. Or import a list: create a `.txt` file with one server name per line and use **Import a list**.

### ✅ Check your work
All servers show **Connected** in the connection list.

---

## Part 3: Do real admin tasks from the browser

Work through these on each server. They're the daily routine WAC replaces.

| Task | Where in WAC | Try this |
|---|---|---|
| Health at a glance | **Overview** | CPU, memory, disk, uptime |
| Restart a service | **Services** | Restart the Print Spooler on APP01 |
| Read errors | **Events** | Filter System log to **Error** for the last 24 hours on DC01 |
| Disk space | **Storage** | Check free space on every volume |
| Files | **Files & file sharing** | Browse `C:\Shares\Finance` on APP01 |
| Updates | **Updates** | See pending updates; compare with your [WSUS lab](../wsus-patching/) |
| Certificates | **Certificates** | Find expiring certificates on APP01 |
| Firewall | **Firewall** | Review inbound rules on FS02 |
| Command line | **PowerShell** | Run `Get-Service DNS` on DC01 |
| Remote Desktop | **Remote Desktop** | Open a session in the browser |

**Server Core is where WAC shines.** Open **FS02** (from the [DFS lab](../dfs-fsrm/)) and do the same tasks on a server with no desktop.

📸 Screenshots: the server list, Overview on DC01, Events filtered to errors, the PowerShell tool on FS02

---

## Part 4: Lock it down

WAC is a powerful admin entry point, so treat it like one:

1. **Restrict access:** in **Settings → Access** (gateway settings), allow only an admins group. Create `GG-WAC-Admins` in AD, add `adm-nwang`, and grant that group gateway access.
2. **Use a trusted certificate** from your internal CA instead of the self-signed one.
3. **Firewall:** allow port 6600 on APP01 only from admin workstations, not the whole network.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| Browser can't connect | Firewall rule for port 6600 on APP01; confirm the WAC service is running |
| Server shows "WinRM cannot complete the operation" | Enable remote management on the target (`Enable-PSRemoting` or SConfig option 4) |
| "You can't connect" with valid credentials | The account needs admin rights on the target server |
| Certificate warning | Expected with the self-signed certificate; replace it with one from your CA |

## How to talk about it in an interview

> *"I deployed Windows Admin Center as a gateway on a member server and used it to manage all my lab servers from a browser, including Server Core machines with no GUI: services, event logs, storage, updates, and remote PowerShell. I restricted gateway access to an AD admins group and moved it off the default port to avoid clashing with IIS."*

## Results

_To be added after the lab is run:_
- [ ] Screenshots of the tasks in Part 3
