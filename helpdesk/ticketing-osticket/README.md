# Help Desk Ticketing System (osTicket)

Set up a real service desk the way an IT department runs one: help topics, priorities, SLAs, departments, canned responses, and a customer portal. Then work a queue of 20 realistic tickets from the `lab.local` employees, from first response to closure.

> **Status:** tutorial ready. Results and screenshots to be added after the lab is run.

| | |
|---|---|
| **Role** | Help desk (Tier 1–2) |
| **Time** | 4–6 hours |
| **Cost** | Free (osTicket is open source) |
| **Builds on** | [Server lab](../../windows/server-lab/) for the users and network (optional: osTicket also works on its own) |
| **Resume keywords** | ITSM, ticket triage, SLAs, escalation, customer communication, documentation |

## Why this matters

Every help desk runs on a ticketing system (ServiceNow, Jira Service Management, Freshservice, osTicket). The tool changes; the workflow doesn't. Interviewers want to hear that you can **triage, prioritize, document, escalate, and close the loop**. This lab gives you real examples of each.

---

## Part 1: Create the help desk server

You'll run osTicket on a small Ubuntu server in the lab network.

| Setting | Value |
|---|---|
| VM name | `HD01` |
| OS | Ubuntu Server 24.04 LTS |
| CPU / RAM / disk | 1 vCPU / 2 GB / 20 GB |
| IP address | `10.10.10.40/24`, gateway `10.10.10.1`, DNS `10.10.10.10` |

1. Download the **Ubuntu Server 24.04 LTS** ISO from ubuntu.com.
2. Create the VM on `LabSwitch`, the same way as the server lab VMs.
   > **Hyper-V tip:** Ubuntu won't boot with the default Secure Boot template. In the VM's **Settings → Security**, change the template to **Microsoft UEFI Certificate Authority**.
3. Install Ubuntu:
   - On the network screen, choose **Edit IPv4 → Manual** and enter: subnet `10.10.10.0/24`, address `10.10.10.40`, gateway `10.10.10.1`, name servers `10.10.10.10`, search domains `lab.local`.
   - Check **Install OpenSSH server**.
4. On **DC01**, add a friendly DNS name. In **DNS Manager → lab.local → New Host (A)**: name `helpdesk`, IP `10.10.10.40`, ✅ *Create associated PTR record*.

### ✅ Check your work
From CLIENT01, `ping helpdesk.lab.local` replies from `10.10.10.40`. From HD01, `ping dc01.lab.local` and `ping ubuntu.com` both work.

---

## Part 2: Install the web stack and osTicket

SSH in from your PC or CLIENT01: `ssh youruser@10.10.10.40`.

### 2.1 Install Apache, MariaDB, and PHP

```bash
sudo apt update
sudo apt install -y apache2 mariadb-server unzip curl \
  php php-mysql php-imap php-intl php-apcu php-gd php-mbstring php-xml
```

**What each piece does:** Apache serves the web pages, MariaDB stores the tickets, and PHP runs osTicket. The extra PHP modules add database access, email fetching (imap), and international text.

### 2.2 Create the database

```bash
sudo mariadb
```
Then, at the `MariaDB>` prompt (pick your own strong password):
```sql
CREATE DATABASE osticket CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'osticket'@'localhost' IDENTIFIED BY 'Choose-A-Strong-Password';
GRANT ALL PRIVILEGES ON osticket.* TO 'osticket'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

> **Why a dedicated database user?** Least privilege. osTicket can only touch its own database, so a bug in the app can't damage anything else on the server.

### 2.3 Download and place osTicket

1. On **osticket.com → Download** (or the osTicket GitHub *Releases* page), copy the link to the latest release `.zip`.
2. On HD01:
   ```bash
   cd /tmp
   curl -LO <paste-the-release-zip-link>
   unzip osTicket-*.zip -d osticket
   sudo mkdir -p /var/www/html/osticket
   sudo cp -r osticket/upload/. /var/www/html/osticket/
   sudo cp /var/www/html/osticket/include/ost-sampleconfig.php /var/www/html/osticket/include/ost-config.php
   sudo chmod 0666 /var/www/html/osticket/include/ost-config.php
   sudo chown -R www-data:www-data /var/www/html/osticket
   sudo systemctl restart apache2
   ```
   The `0666` permission is temporary. The installer needs to write the config file, and you'll lock it down in Part 3.

### ✅ Check your work
From CLIENT01, open `http://helpdesk.lab.local/osticket/setup/`. You should see the osTicket installer with green checkmarks for the requirements.

💾 **Checkpoint** HD01: `HD01 - osTicket files in place`

---

## Part 3: Run the installer and lock it down

1. In the installer, enter:

| Field | Value |
|---|---|
| Helpdesk name | `LAB IT Service Desk` |
| Default email | `helpdesk@lab.local` (no mail server needed for this lab) |
| Admin user | Your name, username `nwang-admin`, a strong password |
| MySQL hostname / database / username | `localhost` / `osticket` / `osticket` |
| MySQL password | The password from 2.2 |

2. Click **Install Now**.
3. Lock down the installation, as the success page tells you to:
   ```bash
   sudo chmod 0644 /var/www/html/osticket/include/ost-config.php
   sudo rm -rf /var/www/html/osticket/setup
   ```

> ⚠️ **Don't skip step 3.** A world-writable config file and a reachable setup page are exactly the kind of misconfiguration your Nessus lab would flag.

### ✅ Check your work
- `http://helpdesk.lab.local/osticket/scp/` shows the **staff** sign-in. Sign in as `nwang-admin`.
- `http://helpdesk.lab.local/osticket/` shows the **customer** portal.

📸 Screenshot: the agent dashboard after first sign-in

---

## Part 4: Configure the service desk

osTicket has two panels: the **Agent Panel** (daily ticket work) and the **Admin Panel** (configuration). Switch with the link at the top right.

### 4.1 Departments
**Admin Panel → Agents → Departments → Add New Department**

| Department | Purpose |
|---|---|
| `Service Desk` | Tier 1: everything lands here first |
| `Systems` | Tier 2/3: servers, AD, network, escalations |
| `Security` | Phishing reports and incidents |

Delete or rename the sample departments.

### 4.2 Agents
**Admin Panel → Agents → Agents → Add New Agent**

| Agent | Primary department | Role |
|---|---|---|
| Nathaniel Wang | Systems | All Access |
| Carlos Reyes | Service Desk | Expanded Access |

Give Carlos access to **Systems** too (Access tab) so he can see escalations.

### 4.3 SLA plans
An **SLA** (service level agreement) is the promise of how fast a ticket gets resolved. osTicket marks tickets **Overdue** when they pass it.

**Admin Panel → Manage → SLA Plans → Add New SLA Plan**

| SLA plan | Grace period | Used for |
|---|---|---|
| `P1 - Emergency` | 4 hours | Outages, security incidents |
| `P2 - High` | 8 hours | One person fully blocked |
| `P3 - Normal` | 24 hours | Most requests and issues |
| `P4 - Low` | 72 hours | Questions, nice-to-haves |

Set `P3 - Normal` as the default in **Admin Panel → Settings → Tickets → Default SLA**.

### 4.4 Help topics
Help topics are the categories users pick from, and they route tickets automatically.

**Admin Panel → Manage → Help Topics → Add New Help Topic**

| Help topic | Department | Priority | SLA |
|---|---|---|---|
| Account / Password / Login | Service Desk | High | P2 - High |
| Hardware | Service Desk | Normal | P3 - Normal |
| Software / Install request | Service Desk | Low | P4 - Low |
| Network / Shared drives / Access | Service Desk | Normal | P3 - Normal |
| Printing | Service Desk | Normal | P3 - Normal |
| New hire / Departure | Systems | Normal | P3 - Normal |
| Security / Suspicious email | Security | Emergency | P1 - Emergency |

### 4.5 Customers (end users)
**Agent Panel → Users → Add User** for each lab employee: Jane Smith, Marcus Johnson, Priya Patel, Dana Lee, using `@lab.local` email addresses.

> In production, osTicket can authenticate users against Active Directory with its LDAP plugin, so people sign in with their domain password. That's a good stretch goal.

### 4.6 Canned responses
Canned responses keep replies fast and consistent. **Agent Panel → Knowledgebase → Canned Responses → Add New Response**:

| Title | Response |
|---|---|
| Acknowledge | Hi %{ticket.name.first}, thanks for reaching out. I'm looking into this now and will update you by the end of the day. |
| Need more info | Could you tell me the exact error message (a screenshot is perfect) and when it started? |
| Locked account: unlocked | Your account is unlocked. Please sign in now and let me know if it works. If it locks again, it's often a saved old password on your phone. |
| Resolved: confirm | I believe this is fixed. Could you confirm it's working for you? If I don't hear back in 2 business days, I'll close the ticket. |

### ✅ Check your work
Sign in to the **customer portal** as Jane (or open a ticket for her as an agent) and pick *Account / Password / Login*. The ticket should land in **Service Desk** with priority **High** and SLA **P2**, without anyone touching it.

📸 Screenshots: help topics list, SLA plans list
💾 **Checkpoint** HD01: `HD01 - osTicket configured`

---

## Part 5: Work the queue

Open the [20 mock tickets](./mock-tickets.md). They range from a locked account to a Finance outage, and the 🔧 ones can really be fixed in your lab.

For each ticket:

1. **Triage:** confirm the help topic and priority. Change them if the user picked wrong, for example a "slow computer" that's really a security incident.
2. **Assign:** to yourself, or **Transfer** to *Systems* or *Security* for Tier 2/3 work.
3. **Respond:** use a canned response, then personalize it.
4. **Work it:** fix it in the lab when you can, and use **Post Internal Note** to record what you checked.
5. **Resolve:** reply with the cause and fix, link a [KB article](../knowledge-base/), and close it.

### Three tickets to do especially well
- **#1 Locked out.** Verify identity first, then unlock in ADUC (or `Unlock-ADAccount jsmith`), then check *why* it locked with Event ID **4740** on DC01.
- **#10 Phishing.** Set it to Emergency and transfer to Security. Write the internal note an analyst would want: sender, subject, whether anyone clicked, what you've blocked.
- **#20 Finance outage.** Practice incident communication: an initial notice, updates every 30 minutes, and a resolution summary. On APP01, stop the share's access (for example `Stop-Service LanmanServer` and restart it later) to make it real.

### ✅ Check your work
**Agent Panel → Dashboard** shows tickets opened, closed, and overdue by department. Aim for every ticket closed with a resolution note, and none overdue.

📸 Screenshots: a fully worked ticket thread (internal notes, transfer, resolution), the dashboard

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| Installer shows a red X for a PHP extension | `sudo apt install php-<name>` then `sudo systemctl restart apache2` |
| "Unable to connect to database" | Recheck the password; test with `mariadb -u osticket -p osticket` |
| Blank white page | Read `sudo tail -n 50 /var/log/apache2/error.log` |
| Can't reach `helpdesk.lab.local` from CLIENT01 | Check the DNS A record on DC01 and `sudo ufw status` on HD01 |

## How to talk about it in an interview

> *"I built an osTicket service desk for my home lab with help topics that route automatically, four SLA tiers, and departments for Tier 1, systems, and security. Then I worked 20 realistic tickets end to end, from locked accounts to a simulated Finance file-share outage, where I practiced incident communication with regular status updates."*

## Results

_To be added after the lab is run:_
- [ ] Screenshots: dashboard, help topics, SLA plans, a fully worked ticket
- [ ] Number of tickets resolved, and how many met SLA
- [ ] One "lessons learned" paragraph
