# Linux Server in the Windows Domain

Add an **Ubuntu Server** to `lab.local`, harden it, and let domain users sign in with their AD accounts. Only the IT group can log in, and only Linux admins get `sudo`. Then host a small website on it with nginx, and set up logs and disk checks the way you would for any production server.

> **Status:** tutorial ready. Results and screenshots to be added after the lab is run.

| | |
|---|---|
| **Role** | Sysadmin |
| **Time** | 4–6 hours |
| **Cost** | Free |
| **Builds on** | [Server lab](../../windows/server-lab/) (DC01, DNS, OUs, `GG-IT-Staff`) |
| **Resume keywords** | Ubuntu Server, SSH, UFW, realmd, SSSD, Kerberos, AD integration, sudo, nginx, logrotate, cron |

## Why this matters

Most "Windows shops" still run some Linux: a web server, an appliance, a monitoring box. Being the Windows admin who can also join a Linux server to AD, control who can sign in, and keep it patched makes you more useful than most candidates. It's also the core of the Linux questions in sysadmin interviews.

---

## Part 1: Install Ubuntu Server

1. Download **Ubuntu Server 24.04 LTS** from ubuntu.com.
2. Create a VM `LNX01`: **Generation 2**, and under **Security** change the Secure Boot template to **Microsoft UEFI Certificate Authority** (Ubuntu won't boot with the default Windows template). 2 vCPU, 2 GB RAM, 25 GB disk, on **LabSwitch**.
3. Install with these choices:

| Installer screen | Choice |
|---|---|
| Network | Edit IPv4 → **Manual**: subnet `10.10.10.0/24`, address `10.10.10.41`, gateway `10.10.10.1`, name servers `10.10.10.10,10.10.10.11`, search domain `lab.local` |
| Storage | Use the entire disk (default LVM) |
| Profile | Your name, server name `lnx01`, username `nwang-local` (a local account for emergencies) |
| SSH | ✅ **Install OpenSSH server** |
| Featured snaps | None |

4. Reboot, sign in, and update everything:
   ```bash
   sudo apt update && sudo apt full-upgrade -y
   ```

### ✅ Check your work
```bash
ip -br addr            # shows 10.10.10.41/24
resolvectl status      # DNS servers are 10.10.10.10 and 10.10.10.11
host dc01.lab.local    # resolves to 10.10.10.10
```

---

## Part 2: Baseline security

### 2.1 SSH keys instead of passwords
On **CLIENT01** (or your PC), in PowerShell:
```powershell
ssh-keygen -t ed25519
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh nwang-local@10.10.10.41 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
ssh nwang-local@10.10.10.41
```

Then on LNX01, block root sign-in over SSH (you'll leave password sign-in on for now, since AD users need it in Part 4):
```bash
echo 'PermitRootLogin no' | sudo tee /etc/ssh/sshd_config.d/10-hardening.conf
sudo systemctl restart ssh
```

### 2.2 Firewall
```bash
sudo ufw allow from 10.10.10.0/24 to any port 22 proto tcp
sudo ufw enable
sudo ufw status verbose
```

> Only the lab subnet can reach SSH. You'll open ports 80 and 443 in Part 6.

### 2.3 Automatic security updates
```bash
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades    # choose Yes
```

### 2.4 Time
Kerberos fails if clocks differ by more than five minutes, so sync time with the domain controllers:
```bash
sudo sed -i 's/^#\?NTP=.*/NTP=dc01.lab.local dc02.lab.local/' /etc/systemd/timesyncd.conf
sudo systemctl restart systemd-timesyncd
timedatectl timesync-status
```

---

## Part 3: Join the domain

### 3.1 Prepare AD
On DC01, create a group for Linux admins and pre-create nothing else (the join creates the computer account):
```powershell
New-ADGroup -Name 'GG-Linux-Admins' -GroupScope Global -Path 'OU=Groups,OU=Corp,DC=lab,DC=local'
Add-ADGroupMember -Identity 'GG-Linux-Admins' -Members 'nwang'
```

### 3.2 Install the packages
```bash
sudo hostnamectl set-hostname lnx01.lab.local
sudo apt install -y realmd sssd sssd-tools libnss-sss libpam-sss adcli samba-common-bin oddjob oddjob-mkhomedir packagekit krb5-user
```
If asked for a default Kerberos realm, enter `LAB.LOCAL` (uppercase).

### 3.3 Discover and join
```bash
realm discover lab.local
sudo realm join -U adm-nwang --computer-ou='OU=Servers,OU=Corp,DC=lab,DC=local' lab.local
```
`realm discover` should list `type: kerberos`, `server-software: active-directory`, and the packages required. `realm join` asks for the `adm-nwang` password.

### 3.4 Friendlier usernames and home folders
By default, domain users sign in as `nwang@lab.local`. Make it just `nwang`, and create home folders automatically on first sign-in:
```bash
sudo sed -i 's/^use_fully_qualified_names = True/use_fully_qualified_names = False/' /etc/sssd/sssd.conf
sudo sed -i 's|^fallback_homedir = .*|fallback_homedir = /home/%u|' /etc/sssd/sssd.conf
sudo pam-auth-update --enable mkhomedir
sudo systemctl restart sssd
```

### ✅ Check your work
```bash
realm list                 # shows lab.local, configured: kerberos-member
id nwang                   # shows AD groups, such as gg-it-staff
getent passwd jsmith       # a domain user, resolved through SSSD
```
On DC01: `Get-ADComputer LNX01 | Select-Object DistinguishedName` shows it in `OU=Servers`, and DNS has an `lnx01` A record.

📸 Screenshots: `realm list`, `id nwang`, LNX01 in Active Directory Users and Computers

---

## Part 4: Control who can sign in and who gets sudo

Right now **every** domain user can sign in. Restrict it to IT:
```bash
sudo realm deny --all
sudo realm permit -g GG-IT-Staff GG-Linux-Admins
```

Give Linux admins `sudo`. SSSD shows AD group names in **lowercase**, so the sudoers entry must be lowercase too:
```bash
echo '%gg-linux-admins ALL=(ALL:ALL) ALL' | sudo tee /etc/sudoers.d/gg-linux-admins
sudo chmod 440 /etc/sudoers.d/gg-linux-admins
sudo visudo -c
```

> `visudo -c` checks the syntax. A broken sudoers file can lock everyone out of `sudo`, which is why you kept the local `nwang-local` account.

### ✅ Check your work

| Test | Expected |
|---|---|
| `ssh nwang@lnx01.lab.local` with Nathaniel's AD password | Signs in; home folder `/home/nwang` is created |
| `sudo whoami` as nwang | `root` |
| `ssh jsmith@lnx01.lab.local` (Finance, not IT) | **Denied** |
| `ssh creyes@lnx01.lab.local` (IT, not Linux admin) | Signs in; `sudo` is **refused** |
| Disable `creyes` in AD, wait a few minutes, try again | Denied |

### Kerberos single sign-on (bonus)
Signed in as nwang, run `klist`: you have a Kerberos ticket from the domain. From a domain-joined Windows machine, `ssh -K nwang@lnx01.lab.local` can sign you in with your Windows ticket and no password, once GSSAPI is enabled in `sshd_config`.

---

## Part 5: Logs and troubleshooting tools

Learn where to look when something breaks:

| Question | Command |
|---|---|
| Who signed in, and who failed? | `sudo journalctl -u ssh --since today` |
| Why did a domain sign-in fail? | `sudo journalctl -u sssd --since '10 min ago'` and `/var/log/sssd/` |
| Is a service running? | `systemctl status nginx` |
| What's using disk space? | `df -h` and `sudo du -xh / --max-depth=1 \| sort -h` |
| What's listening on the network? | `sudo ss -tulpn` |
| Clear SSSD's cache after an AD change | `sudo sss_cache -E` |

---

## Part 6: Host a website with nginx

1. Install nginx and open the firewall:
   ```bash
   sudo apt install -y nginx
   sudo ufw allow from 10.10.10.0/24 to any port 80 proto tcp
   ```
2. Create a site:
   ```bash
   sudo mkdir -p /var/www/status
   echo '<h1>LNX01 status page</h1>' | sudo tee /var/www/status/index.html
   sudo tee /etc/nginx/sites-available/status > /dev/null <<'EOF'
   server {
       listen 80;
       server_name status.lab.local;
       root /var/www/status;
       access_log /var/log/nginx/status.access.log;
       error_log  /var/log/nginx/status.error.log;
   }
   EOF
   sudo ln -s /etc/nginx/sites-available/status /etc/nginx/sites-enabled/
   sudo nginx -t && sudo systemctl reload nginx
   ```
3. Add a DNS record on DC01:
   ```powershell
   Add-DnsServerResourceRecordCName -ZoneName 'lab.local' -Name 'status' -HostNameAlias 'lnx01.lab.local'
   ```
4. From CLIENT01, browse to `http://status.lab.local`.

> **Extension:** request a certificate for `status.lab.local` from your [internal CA](../../windows/adcs-pki/) and add an HTTPS `server` block on port 443.

### Log rotation
nginx installs its own rotation rules in `/etc/logrotate.d/nginx`, and they cover your site's logs because they match `/var/log/nginx/*.log`. Read the file, then test it:
```bash
cat /etc/logrotate.d/nginx
sudo logrotate --debug /etc/logrotate.d/nginx
```

### Daily disk check
Reuse the [`check_disk.sh`](../check_disk.sh) script from this repo with cron:
```bash
sudo install -m 755 check_disk.sh /usr/local/bin/check_disk.sh
echo '0 6 * * * root /usr/local/bin/check_disk.sh | logger -t check_disk' | sudo tee /etc/cron.d/check-disk
```
Results go to the system journal: `journalctl -t check_disk`.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `realm discover` finds nothing | DNS: LNX01 must use the DCs as its DNS servers (`resolvectl status`) |
| Join fails with a clock skew error | Fix time (Part 2.4) and check `timedatectl` |
| `id nwang` says "no such user" | `sudo systemctl status sssd`; check `/etc/sssd/sssd.conf` permissions are `600`; `sudo sss_cache -E` |
| Permitted user is still denied | Group names in `realm permit` must match AD; check `realm list` for the `permitted-groups` line |
| `sudo` refused for a Linux admin | The sudoers group name must be lowercase; sign out and back in after group changes |
| Ubuntu VM won't boot | Gen 2 Secure Boot template must be **Microsoft UEFI Certificate Authority** |

## How to talk about it in an interview

> *"I joined an Ubuntu server to Active Directory with realmd and SSSD, restricted sign-in to IT groups with realm permit, and gave sudo to an AD Linux-admins group, so access is managed in AD like everything else and a disabled account loses access automatically. I hardened it with SSH keys, UFW scoped to the lab subnet, unattended security updates, and time synced to the DCs for Kerberos, then hosted an nginx site with log rotation and a daily disk check through cron."*

## Results

_To be added after the lab is run:_
- [ ] Screenshots: `realm list`, the sign-in test table results, the nginx page from CLIENT01
- [ ] Notes on anything that needed troubleshooting
