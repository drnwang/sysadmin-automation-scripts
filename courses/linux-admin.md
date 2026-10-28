# Linux Admin Guide

*Self-study course · Linux system administration*

Sixteen modules taking you from the shell to running production Linux servers, covering files and permissions, users and sudo, packages, systemd, storage and LVM, networking, SSH, logs, automation, security, common services, backup and recovery, and a troubleshooting method. Commands are shown for both Ubuntu and Red Hat-family systems, and each module ends with a short self-check.

**Total:** about 6 hours · **Distros:** Ubuntu 26.04 LTS, RHEL 10 / Rocky / Alma · **Lab:** LNX01 on lab.local

> Each module ends with a self-check. Open each answer to see the explanation.

## Contents

0. [Linux at work](#00-linux-at-work) (14 min)
1. [The shell](#01-the-shell) (22 min)
2. [Files, the directory tree, and permissions](#02-files-the-directory-tree-and-permissions) (22 min)
3. [Users, groups, and sudo](#03-users-groups-and-sudo) (18 min)
4. [Software and updates](#04-software-and-updates) (20 min)
5. [Processes and systemd](#05-processes-and-systemd) (22 min)
6. [Storage, file systems, and LVM](#06-storage-file-systems-and-lvm) (24 min)
7. [Networking](#07-networking) (22 min)
8. [SSH and remote administration](#08-ssh-and-remote-administration) (18 min)
9. [Logs and performance](#09-logs-and-performance) (22 min)
10. [Automation: scripts, cron, and timers](#10-automation-scripts-cron-and-timers) (22 min)
11. [Security hardening](#11-security-hardening) (22 min)
12. [Common services](#12-common-services) (20 min)
13. [Backup, boot problems, and recovery](#13-backup-boot-problems-and-recovery) (22 min)
14. [Linux in a Windows domain](#14-linux-in-a-windows-domain) (12 min)
15. [A troubleshooting method](#15-a-troubleshooting-method) (16 min)

---

## 00 Linux at work

*14 min*

*Which Linux you'll meet, and how the two big families differ.*

Linux runs most of the internet's servers, most cloud workloads, containers, network appliances, and plenty of servers inside "Windows shops": web servers, monitoring, databases, security tools. A **distribution** ("distro") packages the Linux kernel with tools, a package manager, and support.

### The two families you'll see most

| | Debian family | Red Hat family |
|---|---|---|
| Distros | **Ubuntu Server**, Debian | **RHEL** (Red Hat Enterprise Linux), **Rocky Linux**, **AlmaLinux**, Oracle Linux, Fedora (upstream) |
| Package format / tool | `.deb` / `apt` | `.rpm` / `dnf` |
| Firewall tool | `ufw` (Ubuntu) | `firewalld` (`firewall-cmd`) |
| Mandatory access control | AppArmor | SELinux |
| Network config | Netplan (server) | NetworkManager (`nmcli`) |
| Current long-term release | **Ubuntu 26.04 LTS** (April 2026): 5 years of standard support, up to 10+ with Ubuntu Pro | **RHEL 10** (2025): about 10 years of support; Rocky and Alma 10 are free rebuilds |

Most skills transfer directly. In this course, when commands differ, both are shown as **Ubuntu** / **RHEL**.

> [!NOTE]
> **How it works: What's new in Ubuntu 26.04 LTS**
>
> If you learned on older Ubuntu, a few defaults changed: `sudo` is now **sudo-rs** (a Rust rewrite; the classic version is still installed as `sudo.ws`), many core utilities come from the Rust **uutils** project, new installs use **chrony** for time sync, `/tmp` is a memory-backed tmpfs, `apt-key` is gone (repository keys go in `/etc/apt/keyrings/`), cgroup v1 is removed, and OpenSSH dropped DSA keys. Everyday commands work the same.

### Releases and support
Use **LTS** or enterprise releases for servers. Plan upgrades well before end of support: an out-of-support server stops getting security updates, which shows up immediately in vulnerability scans.

```bash
cat /etc/os-release        # distro and version
uname -r                   # kernel version
hostnamectl                # hostname, OS, kernel, hardware
```

> [!TIP]
> **In your lab**
>
> You built **LNX01** (Ubuntu Server, 10.10.10.41) in the [Linux AD join tutorial](../linux/ad-join). It's the practice machine for this course. For the Red Hat side, create a second VM with **Rocky Linux 10** or **AlmaLinux 10** (free), or get a free **Red Hat Developer** subscription for RHEL.

### Check yourself

**1. Which package tool does RHEL use?**

- a) apt
- b) dnf
- c) snap

<details><summary>Answer</summary>

**b)** RHEL, Rocky, and Alma use `dnf` with `.rpm` packages. Ubuntu and Debian use `apt` with `.deb` packages.

</details>

**2. What should you run on a server: an LTS release or the latest interim release?**

- a) LTS (or an enterprise release like RHEL)
- b) The latest interim release for new features
- c) Whatever came preinstalled

<details><summary>Answer</summary>

**a)** LTS and enterprise releases get years of security updates, which servers need.

</details>




---

## 01 The shell

*22 min*

*Linux administration happens in a terminal. These are the habits that make it fast.*

### Getting around

| Command | Does |
|---|---|
| `pwd` | Print the current directory |
| `ls -lah` | List files: long format, all (including hidden dotfiles), human-readable sizes |
| `cd /etc` / `cd ~` / `cd -` | Change directory / go home / go back to the previous one |
| `mkdir -p a/b/c` | Make directories, including parents |
| `cp -a src dst` / `mv` / `rm -r` | Copy (preserving attributes) / move or rename / remove recursively |
| `cat`, `less`, `head -n 20`, `tail -f` | Show a file / page through it / first lines / follow a growing log |
| `touch file` | Create an empty file or update its timestamp |
| `find /var -name '*.log' -mtime +7` | Find files by name, age, size, owner |
| `grep -ri 'error' /var/log/nginx` | Search text recursively, case-insensitive |
| `which nginx` / `type ll` | Where a command lives / what kind of command it is |

> [!WARNING]
> **Watch out: `rm` has no Recycle Bin**
>
> `rm` deletes immediately. Be especially careful with `rm -rf` and wildcards, and with variables in scripts (`rm -rf "$DIR"/*` with an empty `$DIR` becomes `rm -rf /*`). Run `ls` with the same pattern first.

### Getting help
- `man ls` opens the manual page (press **/** to search, **q** to quit). `man -k keyword` searches all manual pages.
- `ls --help` gives a quick summary.
- `tldr ls` (if installed) gives practical examples.

### Pipes and redirection
Commands are small tools you chain together:
```bash
ps aux | grep nginx                   # pipe one command's output into another
df -h > disk.txt                      # write output to a file (overwrite)
echo "checked" >> notes.txt           # append
command 2> errors.txt                 # redirect errors (stderr)
command > all.txt 2>&1                # output and errors to one file
journalctl -u ssh | grep Failed | wc -l
sort access.log | uniq -c | sort -rn | head   # count and rank repeated lines
```

### Text tools you'll use daily

| Tool | Example |
|---|---|
| `grep` | `grep -v '^#' /etc/ssh/sshd_config` (hide comments) |
| `awk` | `df -h \| awk '$5+0 > 80'` (lines where column 5 exceeds 80) |
| `cut` | `cut -d: -f1 /etc/passwd` (first field, colon-separated) |
| `sed` | `sed -i 's/old/new/g' file` (replace in place) |
| `sort`, `uniq`, `wc -l` | Sort, deduplicate, count |
| `tee` | `echo text \| sudo tee /etc/file` (write a file as root from a pipe) |

### Editing files
- **nano** is simple: edit, then **Ctrl+O** to save and **Ctrl+X** to exit.
- **vim** is everywhere and worth learning the basics: **i** to insert, **Esc** to stop, `:wq` to save and quit, `:q!` to quit without saving, `/text` to search, `dd` to delete a line, `u` to undo.

### Shortcuts that save time
**Tab** completes names, **↑** recalls history, **Ctrl+R** searches history, **Ctrl+C** stops a command, **Ctrl+L** clears the screen, `!!` repeats the last command (`sudo !!` reruns it with sudo).

### Globs and quoting
`*` matches anything, `?` one character, `[abc]` one of a set, `{a,b}` expands to both. Use **single quotes** to keep text exactly as typed, **double quotes** to allow `$VARIABLES` while keeping spaces together.

### Check yourself

**1. How do you send both output and errors to one file?**

- a) `command > file 2> file`
- b) `command > file 2>&1`
- c) `command | file`

<details><summary>Answer</summary>

**b)** `2>&1` sends stderr to wherever stdout is going.

</details>

**2. Which command follows a log file as new lines are written?**

- a) `tail -f`
- b) `head -f`
- c) `cat -n`

<details><summary>Answer</summary>

**a)** `tail -f` keeps the file open and prints new lines as they arrive.

</details>

**3. How do you quit vim without saving?**

- a) `:wq`
- b) `:q!`
- c) Ctrl+X

<details><summary>Answer</summary>

**b)** `:q!` quits and discards changes. `:wq` saves and quits.

</details>




---

## 02 Files, the directory tree, and permissions

*22 min*

*Everything in Linux is a file, and every file has an owner, a group, and permissions.*

### The directory tree

| Path | Holds |
|---|---|
| `/etc` | System configuration (text files) |
| `/var` | Variable data: logs (`/var/log`), web content (`/var/www`), databases, caches, mail |
| `/home` | Users' home directories (`/root` for root) |
| `/usr` | Installed programs and libraries (`/usr/bin`, `/usr/lib`) |
| `/opt` | Add-on software installed outside the package manager |
| `/tmp` | Temporary files (often cleared at reboot) |
| `/dev` | Device files (disks are `/dev/sda`, `/dev/nvme0n1`, `/dev/vda`) |
| `/proc`, `/sys` | Virtual files exposing kernel and process information |
| `/boot` | Kernel and bootloader files |
| `/mnt`, `/media`, `/run/media` | Mount points for other file systems |

### Reading permissions
```
$ ls -l /etc/ssh/sshd_config
-rw-r--r-- 1 root root 3282 Oct  1 09:12 /etc/ssh/sshd_config
│└┬┘└┬┘└┬┘    └┬─┘ └┬─┘
│ │  │  │      │    group
│ │  │  │      owner
│ │  │  others: read
│ │  group: read
│ owner: read, write
type: - file, d directory, l link
```

| Permission | On a file | On a directory |
|---|---|---|
| **r** (4) | Read contents | List names |
| **w** (2) | Change contents | Create, delete, rename files inside |
| **x** (1) | Run as a program | Enter it (`cd`) and reach files inside |

### Changing permissions and ownership
```bash
chmod 640 app.conf                 # owner rw, group r, others none
chmod u+x deploy.sh                # add execute for the owner
chmod -R g+rw /srv/shared          # recursive
sudo chown www-data:www-data /var/www/status -R
sudo chgrp developers project/
umask                              # default permissions mask for new files (022 means files 644, dirs 755)
```

Common values: **644** (files readable by all), **600** (private files, SSH keys), **755** (programs and directories), **750** / **640** (group-only access), **700** (private directories).

### Special permissions
- **setuid** (`chmod u+s`): a program runs as its **owner** (for example `passwd` runs as root to update password hashes). A security-sensitive setting; audit it with `find / -perm -4000 -type f 2>/dev/null`.
- **setgid** on a directory (`chmod g+s`): new files inherit the directory's **group**. Great for shared team folders.
- **Sticky bit** (`chmod +t`): only a file's owner can delete it, even if others can write to the directory. `/tmp` uses it.

### ACLs for finer control
Standard permissions allow one owner and one group. **Access control lists** add more:
```bash
setfacl -m u:jsmith:rw report.csv
setfacl -m g:finance:rx /srv/finance
getfacl /srv/finance
```

### Links
- **Symbolic link** (`ln -s target link`): a shortcut that points to a path. Breaks if the target moves.
- **Hard link** (`ln target link`): a second name for the same data on the same file system.

> [!TIP]
> **In your lab**
>
> On LNX01, create `/srv/it-share` owned by group `gg-it-staff` (your AD group, through SSSD) with `chmod 2770`. Sign in as `nwang` and `creyes` and confirm both can create and edit files there, and that new files get the `gg-it-staff` group because of setgid.

### Check yourself

**1. What does `chmod 640 file` give the group?**

- a) Read and write
- b) Read only
- c) Nothing

<details><summary>Answer</summary>

**b)** 6 = rw for the owner, 4 = r for the group, 0 = nothing for others.

</details>

**2. A shared folder should give every new file the folder's group. What do you set?**

- a) setgid on the directory (`chmod g+s`)
- b) The sticky bit
- c) setuid

<details><summary>Answer</summary>

**a)** setgid on a directory makes new files inherit its group.

</details>

**3. Which permission on a directory lets you `cd` into it?**

- a) r
- b) w
- c) x

<details><summary>Answer</summary>

**c)** Execute on a directory means you can enter it and access its contents by name.

</details>




---

## 03 Users, groups, and sudo

*18 min*

*Who can sign in, and who can act as root.*

### Where accounts live

| File | Holds |
|---|---|
| `/etc/passwd` | Accounts: name, UID, GID, home, shell (no passwords) |
| `/etc/shadow` | Password hashes and aging (readable only by root) |
| `/etc/group` | Groups and members |
| `/etc/sudoers`, `/etc/sudoers.d/` | Who may use sudo |

**UID 0** is root. System accounts (for services like `www-data` or `nginx`) usually have UIDs below 1000; people start at 1000.

### Managing users and groups
```bash
sudo useradd -m -s /bin/bash -c "Jane Smith" jsmith    # -m creates the home directory
sudo adduser jsmith                                     # Ubuntu's friendlier interactive version
sudo passwd jsmith
sudo usermod -aG developers jsmith                      # -a appends; without it you'd REPLACE all groups
sudo groupadd developers
id jsmith ; groups jsmith
sudo usermod -L jsmith                                  # lock the account
sudo chage -l jsmith                                    # password aging info
sudo chage -E 2026-12-31 jsmith                         # account expiry date
sudo userdel -r jsmith                                  # delete, with home directory
who ; w ; last | head                                   # who's signed in now, and recent sign-ins
```

> [!WARNING]
> **Watch out: `usermod -G` without `-a`**
>
> `usermod -G developers jsmith` **removes** jsmith from every other supplementary group, including `sudo` or `wheel`. Always use `-aG` to add.

### sudo
Admins don't sign in as root; they use **sudo** to run individual commands as root, with each use logged.
- Ubuntu: members of the **`sudo`** group can use sudo.
- RHEL: members of the **`wheel`** group can use sudo.

```bash
sudo usermod -aG sudo nwang              # Ubuntu
sudo usermod -aG wheel nwang             # RHEL
sudo -l                                  # what can I run?
sudo -i                                  # a root shell (use sparingly)
```

Always edit sudo rules with **`visudo`** (or `visudo -f /etc/sudoers.d/file`), which checks syntax before saving. A broken sudoers file can lock everyone out of sudo.
```
# /etc/sudoers.d/helpdesk  - let help desk restart the web server, nothing else
%helpdesk ALL=(root) /usr/bin/systemctl restart nginx, /usr/bin/systemctl status nginx
```

> [!NOTE]
> **How it works: sudo-rs on Ubuntu 26.04**
>
> Ubuntu's default `sudo` is now **sudo-rs**. It supports the common sudoers syntax but drops some rarely used options (for example `sudo -E` is ignored and `requiretty` isn't accepted). If an old sudoers file fails `visudo -c`, check it against the sudo-rs documentation, or use the classic implementation, still installed as `sudo.ws`.

### Central accounts
Managing local accounts on 50 servers doesn't scale. Organizations use **central identity**: Active Directory through **SSSD** (your [AD join tutorial](../linux/ad-join)), **FreeIPA / Red Hat Identity Management**, or LDAP. Access is then granted by AD group, exactly like on Windows.

### Check yourself

**1. What does `usermod -G developers jsmith` (without `-a`) do?**

- a) Adds jsmith to developers
- b) Replaces all of jsmith's supplementary groups with just developers
- c) Creates the developers group

<details><summary>Answer</summary>

**b)** Without `-a`, `-G` sets the complete list, removing other groups like sudo or wheel.

</details>

**2. Which group grants sudo on RHEL by default?**

- a) sudo
- b) wheel
- c) admin

<details><summary>Answer</summary>

**b)** RHEL uses `wheel`; Ubuntu uses `sudo`.

</details>

**3. Why use `visudo` instead of a normal editor?**

- a) It checks the syntax before saving, so a mistake can't break sudo
- b) It's faster
- c) It encrypts the file

<details><summary>Answer</summary>

**a)** A syntax error in sudoers can lock everyone out of sudo. visudo refuses to save an invalid file.

</details>




---

## 04 Software and updates

*20 min*

*Installing, updating, and removing software the supported way.*

### Package managers

| Task | Ubuntu / Debian | RHEL / Rocky / Alma |
|---|---|---|
| Refresh package lists | `sudo apt update` | (automatic; `sudo dnf makecache`) |
| Install | `sudo apt install nginx` | `sudo dnf install nginx` |
| Upgrade everything | `sudo apt upgrade` (or `full-upgrade`) | `sudo dnf upgrade` |
| Remove | `sudo apt remove nginx` (`purge` to delete config too) | `sudo dnf remove nginx` |
| Search | `apt search nginx` | `dnf search nginx` |
| Info | `apt show nginx` | `dnf info nginx` |
| Which package owns a file | `dpkg -S /usr/sbin/nginx` | `rpm -qf /usr/sbin/nginx` |
| List installed | `apt list --installed` | `dnf list installed` |
| Update history | `/var/log/apt/history.log` | `dnf history` (and `dnf history undo <id>`) |
| Security updates only | `unattended-upgrades` | `sudo dnf upgrade --security` |

### Repositories
Packages come from **repositories** your system trusts:
- Ubuntu: `/etc/apt/sources.list.d/` (the newer `.sources` format), with repository signing keys stored in `/etc/apt/keyrings/`. Ubuntu's **main** and **universe** components, plus vendor repositories (Docker, Microsoft, PostgreSQL).
- RHEL: `/etc/yum.repos.d/*.repo`. On RHEL, a **subscription** enables Red Hat's repositories (`subscription-manager`). **EPEL** adds community packages to RHEL-family systems.

Only add repositories from vendors you trust; a repository can install anything as root.

### Automatic security updates
```bash
# Ubuntu
sudo apt install unattended-upgrades && sudo dpkg-reconfigure -plow unattended-upgrades
# RHEL family
sudo dnf install dnf-automatic
sudo sed -i 's/^apply_updates.*/apply_updates = yes/' /etc/dnf/automatic.conf
sudo systemctl enable --now dnf-automatic.timer
```

### Do I need to reboot?
Kernel and core library updates take effect only after a reboot (or service restarts):
```bash
[ -f /var/run/reboot-required ] && cat /var/run/reboot-required.pkgs    # Ubuntu
sudo dnf needs-restarting -r                                           # RHEL
```
**Livepatch** (Ubuntu Pro) and **kpatch** (RHEL) can apply critical kernel fixes without rebooting.

### Other ways software arrives
- **Snap** (Ubuntu) and **Flatpak**: self-contained app packages with their own update mechanism.
- **Containers** (Docker, Podman): an app with all its dependencies, isolated from the host. Your [osTicket and Snipe-IT labs](../helpdesk) use Docker.
- **Tarballs and `curl | bash` installers:** avoid on servers when a package exists. They aren't tracked or updated by the package manager.

### Check yourself

**1. How do you find which package installed `/usr/sbin/nginx` on RHEL?**

- a) `rpm -qf /usr/sbin/nginx`
- b) `dnf search nginx`
- c) `which nginx`

<details><summary>Answer</summary>

**a)** `rpm -qf` (or `dpkg -S` on Ubuntu) maps a file to its package.

</details>

**2. On Ubuntu, what tells you a reboot is needed after updates?**

- a) `uptime`
- b) The file `/var/run/reboot-required`
- c) `apt list --upgradable`

<details><summary>Answer</summary>

**b)** Ubuntu creates `/var/run/reboot-required` (and lists the packages in `.pkgs`) when a reboot is needed.

</details>




---

## 05 Processes and systemd

*22 min*

*How programs run, how services are managed, and how to stop what's misbehaving.*

### Processes
Every running program is a **process** with a **PID**, an owner, and a parent.
```bash
ps aux                         # every process
ps -ef --forest                # with parent/child tree
pgrep -a nginx                 # find by name
top                            # live view (press P for CPU, M for memory, q to quit)
htop                           # friendlier top (install it)
```

### Signals
```bash
kill 1234                      # SIGTERM (15): ask the process to exit cleanly
kill -9 1234                   # SIGKILL: force it to stop immediately (last resort)
kill -HUP 1234                 # SIGHUP: many daemons reload configuration
pkill -u jsmith                # every process owned by jsmith
```
Use plain `kill` first so the program can clean up. `kill -9` can leave lock files and half-written data.

### systemd
**systemd** starts the system and manages **services** (called **units**). It's the Linux equivalent of Windows services plus the Task Scheduler and part of Event Viewer.

| Task | Command |
|---|---|
| Status, recent log lines | `systemctl status nginx` |
| Start / stop / restart | `sudo systemctl start\|stop\|restart nginx` |
| Reload config without dropping connections | `sudo systemctl reload nginx` |
| Start at boot | `sudo systemctl enable nginx` (`enable --now` to also start it) |
| Don't start at boot | `sudo systemctl disable nginx` |
| Prevent starting at all | `sudo systemctl mask nginx` |
| What failed? | `systemctl --failed` |
| All services | `systemctl list-units --type=service` |
| Boot time breakdown | `systemd-analyze blame` |

### Writing a service
A unit file describes how to run your program:
```ini
# /etc/systemd/system/healthcheck.service
[Unit]
Description=Lab health check web page
After=network-online.target

[Service]
User=svc-health
ExecStart=/usr/local/bin/healthcheck --port 8081
Restart=on-failure

[Install]
WantedBy=multi-user.target
```
```bash
sudo systemctl daemon-reload            # after creating or editing unit files
sudo systemctl enable --now healthcheck
```

To change a packaged service's settings without editing its file (which updates would overwrite), use `sudo systemctl edit nginx`, which creates an override in `/etc/systemd/system/nginx.service.d/`.

### Targets (runlevels)
`multi-user.target` is a normal server (no graphical desktop); `graphical.target` adds a desktop; `rescue.target` is single-user maintenance mode. `systemctl get-default` shows which one the system boots into.

### Check yourself

**1. How do you make a service start at boot and start it right now?**

- a) `systemctl enable --now <service>`
- b) `systemctl start <service>`
- c) `systemctl reload <service>`

<details><summary>Answer</summary>

**a)** `enable` sets it to start at boot; `--now` also starts it immediately.

</details>

**2. What should you run after editing a unit file?**

- a) `systemctl reboot`
- b) `systemctl daemon-reload`
- c) `systemctl mask`

<details><summary>Answer</summary>

**b)** systemd caches unit files. `daemon-reload` makes it reread them.

</details>

**3. Which signal should you try before `kill -9`?**

- a) SIGTERM (plain `kill`)
- b) SIGSTOP
- c) SIGKILL

<details><summary>Answer</summary>

**a)** SIGTERM lets the process shut down cleanly. SIGKILL can't be caught and may leave a mess.

</details>




---

## 06 Storage, file systems, and LVM

*24 min*

*Adding disks, growing file systems, and fixing "disk full" without panic.*

### Seeing what you have
```bash
lsblk -f                    # disks, partitions, file systems, mount points
df -hT                      # space used per mounted file system, with type
du -xh --max-depth=1 / 2>/dev/null | sort -h      # what's using space
sudo ncdu /var              # interactive disk usage (install it)
findmnt                     # what's mounted where
```

### Common file systems

| File system | Notes |
|---|---|
| **ext4** | Ubuntu's default. Can grow and shrink (shrink only offline). |
| **XFS** | RHEL's default. Fast for large files; can grow but **not shrink**. |
| **Btrfs**, **ZFS** | Snapshots, checksums, built-in RAID. Used on some systems and storage servers. |
| **tmpfs** | Lives in memory. `/tmp` on Ubuntu 26.04 is tmpfs. |
| **swap** | Disk space used when memory runs out (`swapon --show`, `free -h`) |

### Adding a new disk (the plain way)
```bash
sudo parted /dev/sdb --script mklabel gpt mkpart data ext4 0% 100%
sudo mkfs.ext4 /dev/sdb1                      # or mkfs.xfs on RHEL
sudo mkdir /data
sudo blkid /dev/sdb1                          # copy its UUID
echo 'UUID=<uuid> /data ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab
sudo systemctl daemon-reload && sudo mount -a && df -h /data
```

> [!WARNING]
> **Watch out: /etc/fstab mistakes stop a server from booting**
>
> A typo or a missing disk in `/etc/fstab` can drop the server into emergency mode at boot. Always run `sudo mount -a` (and `findmnt --verify`) after editing it, and use `nofail` for non-essential disks.

### LVM (Logical Volume Manager)
LVM puts a flexible layer between disks and file systems, so you can grow volumes and add disks without repartitioning:
- **Physical volumes (PV):** disks or partitions given to LVM
- **Volume group (VG):** a pool made of one or more PVs
- **Logical volumes (LV):** "virtual partitions" carved from the pool, each with a file system

Ubuntu Server and RHEL both use LVM by default. The most common task is **growing a file system** when it fills up:

```bash
sudo pvs ; sudo vgs ; sudo lvs                         # what exists, and free space in the VG
# 1. If the VG has no free space, add a disk to it:
sudo pvcreate /dev/sdc
sudo vgextend ubuntu-vg /dev/sdc
# 2. Grow the logical volume AND its file system in one step:
sudo lvextend -r -L +20G /dev/ubuntu-vg/ubuntu-lv
df -h /
```
`-r` resizes the file system too (`resize2fs` for ext4, `xfs_growfs` for XFS).

> [!TIP]
> **Good practice: Growing a virtual disk**
>
> If you enlarge a VM's disk in Hyper-V or VMware, the OS also has to grow the partition: `sudo growpart /dev/sda 3` (from `cloud-guest-utils`), then `sudo pvresize /dev/sda3`, then `lvextend -r`.

### Network file systems
- **NFS:** Linux-to-Linux file sharing. Mount with `mount -t nfs server:/export /mnt/point`.
- **SMB/CIFS:** mount Windows shares like `\\APP01\Finance`:
```bash
sudo apt install cifs-utils                             # or dnf install cifs-utils
sudo mount -t cifs //app01.lab.local/Finance /mnt/finance -o sec=krb5,cruid=$(id -u),uid=$(id -u)
```

### Check yourself

**1. The root file system is full, and the volume group has free space. What grows it?**

- a) `lvextend -r -L +10G <logical volume>`
- b) `mkfs.ext4` on the volume
- c) `fdisk` to make a new partition

<details><summary>Answer</summary>

**a)** `lvextend -r` grows the logical volume and resizes the file system on it.

</details>

**2. Which file system can't be shrunk?**

- a) ext4
- b) XFS
- c) tmpfs

<details><summary>Answer</summary>

**b)** XFS can only grow. Plan sizes accordingly on RHEL systems.

</details>

**3. What should you run after editing `/etc/fstab`?**

- a) `sudo mount -a` to test it before the next reboot
- b) `sudo reboot` immediately
- c) Nothing

<details><summary>Answer</summary>

**a)** Testing with `mount -a` catches mistakes that would otherwise stop the server at boot.

</details>




---

## 07 Networking

*22 min*

*Configuring and troubleshooting a server's network, from IP addresses to firewalls.*

### Seeing the configuration
```bash
ip -br addr                 # interfaces and IPs (brief)
ip route                    # routing table and default gateway
resolvectl status           # DNS servers in use (Ubuntu, systemd-resolved)
cat /etc/resolv.conf        # DNS (RHEL; on Ubuntu it points to the local resolver)
ss -tulpn                   # listening ports and which process owns them
hostname -f                 # fully qualified name
```

### Setting a static IP

**Ubuntu (Netplan):** edit a YAML file in `/etc/netplan/`, then apply.
```yaml
# /etc/netplan/50-static.yaml
network:
  version: 2
  ethernets:
    eth0:
      addresses: [10.10.10.41/24]
      routes:
        - to: default
          via: 10.10.10.1
      nameservers:
        addresses: [10.10.10.10, 10.10.10.11]
        search: [lab.local]
```
```bash
sudo netplan try        # applies, and rolls back after 120 seconds unless you confirm
```

**RHEL (NetworkManager):**
```bash
nmcli connection show
sudo nmcli connection modify eth0 ipv4.method manual ipv4.addresses 10.10.10.42/24 \
  ipv4.gateway 10.10.10.1 ipv4.dns "10.10.10.10 10.10.10.11" ipv4.dns-search lab.local
sudo nmcli connection up eth0
```

> [!TIP]
> **Good practice: Use `netplan try` over SSH**
>
> `netplan try` reverts automatically if you lose your connection, so a typo doesn't lock you out of a remote server.

### Firewalls

| Task | Ubuntu (`ufw`) | RHEL (`firewalld`) |
|---|---|---|
| Status | `sudo ufw status verbose` | `sudo firewall-cmd --list-all` |
| Allow SSH | `sudo ufw allow OpenSSH` | `sudo firewall-cmd --permanent --add-service=ssh` |
| Allow a port | `sudo ufw allow 443/tcp` | `sudo firewall-cmd --permanent --add-port=443/tcp` |
| Allow from a subnet only | `sudo ufw allow from 10.10.10.0/24 to any port 22 proto tcp` | `sudo firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address=10.10.10.0/24 service name=ssh accept'` |
| Turn on / apply | `sudo ufw enable` | `sudo firewall-cmd --reload` |

Both are front ends to the kernel's **nftables** firewall. In firewalld, changes without `--permanent` are lost at reload; changes with it don't apply until `--reload`.

### Troubleshooting from the bottom up

| Layer | Check |
|---|---|
| Link | `ip -br link` (is it UP?) |
| IP and route | `ip -br addr`, `ip route`, `ping -c3 10.10.10.1` |
| DNS | `dig app01.lab.local` / `host app01.lab.local` / `resolvectl query app01.lab.local` |
| Reaching a port | `nc -vz app01.lab.local 443` or `curl -v https://intranet.lab.local` |
| The path | `tracepath 8.8.8.8` / `mtr 8.8.8.8` |
| What's listening locally | `ss -tulpn \| grep :80` |
| Local firewall | `ufw status` / `firewall-cmd --list-all` |
| Packets | `sudo tcpdump -ni eth0 port 53` |

### Check yourself

**1. How do you see which process is listening on port 443?**

- a) `ss -tulpn | grep :443`
- b) `ip route`
- c) `dig :443`

<details><summary>Answer</summary>

**a)** `ss -tulpn` lists listening TCP/UDP sockets with their process names.

</details>

**2. Why use `netplan try` instead of `netplan apply` on a remote server?**

- a) It's faster
- b) It rolls back automatically if you don't confirm, so a mistake doesn't lock you out
- c) It also updates DNS records

<details><summary>Answer</summary>

**b)** `try` gives you a safety net when changing the network you're connected through.

</details>

**3. In firewalld, a rule added with `--permanent` doesn't work yet. Why?**

- a) It needs a reboot
- b) Permanent rules apply after `firewall-cmd --reload`
- c) firewalld ignores permanent rules

<details><summary>Answer</summary>

**b)** Permanent rules are saved to configuration and take effect on reload.

</details>




---

## 08 SSH and remote administration

*18 min*

*SSH is how you reach every Linux server. Set it up securely once and it serves you for years.*

### Keys instead of passwords
```bash
ssh-keygen -t ed25519 -C "nwang@lab"         # creates ~/.ssh/id_ed25519 (private) and .pub (public)
ssh-copy-id nwang@lnx01.lab.local             # puts the public key in the server's ~/.ssh/authorized_keys
ssh nwang@lnx01.lab.local
```
Protect the private key with a passphrase, and use `ssh-agent` so you type it once per session. The private key never leaves your machine.

### A client config file
`~/.ssh/config` saves typing:
```
Host lnx01
    HostName lnx01.lab.local
    User nwang
    IdentityFile ~/.ssh/id_ed25519

Host *.lab.local
    User nwang
```
Now `ssh lnx01` is enough.

### Hardening the server
Put changes in a drop-in file, then test and reload:
```bash
sudo tee /etc/ssh/sshd_config.d/10-hardening.conf >/dev/null <<'EOF'
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
MaxAuthTries 3
AllowGroups gg-linux-admins sshusers
EOF
sudo sshd -t && sudo systemctl reload ssh      # 'sshd' on RHEL
```

> [!WARNING]
> **Watch out: Don't lock yourself out**
>
> Keep your current SSH session open while you change SSH settings, and test a **new** connection from a second terminal before closing the first. If you turn off password authentication, make sure your key works first. AD users signing in with passwords (like in your AD join lab) need password authentication to stay on, or Kerberos/GSSAPI set up instead.

### Copying files

| Tool | Example |
|---|---|
| `scp` | `scp report.csv lnx01:/tmp/` |
| `rsync` | `rsync -avz --delete ./site/ lnx01:/var/www/status/` (copies only changes; `--delete` mirrors deletions) |
| `sftp` | Interactive file transfer; WinSCP on Windows uses it |

### Tunnels
```bash
ssh -L 8080:localhost:80 lnx01         # browse http://localhost:8080 to reach LNX01's port 80
ssh -J jumphost.lab.local lnx01         # connect through a bastion (jump) host
```

### Detecting brute force
Internet-facing SSH gets constant password-guessing attempts. Keys plus `PasswordAuthentication no` stop them working; **fail2ban** blocks IPs that keep trying; and restricting SSH to a VPN or admin subnet removes the exposure entirely.

### Check yourself

**1. Which file on the server holds the public keys allowed to sign in as a user?**

- a) `~/.ssh/authorized_keys`
- b) `~/.ssh/id_ed25519`
- c) `/etc/ssh/ssh_host_ed25519_key`

<details><summary>Answer</summary>

**a)** Public keys go in the user's `authorized_keys`. The private key stays on the client.

</details>

**2. What should you do before closing your session after changing sshd settings?**

- a) Reboot the server
- b) Test a new connection from another terminal
- c) Delete your private key

<details><summary>Answer</summary>

**b)** If the new settings lock you out, your existing session lets you fix them.

</details>

**3. Which tool copies only changed files and can mirror deletions?**

- a) scp
- b) rsync
- c) sftp

<details><summary>Answer</summary>

**b)** rsync compares source and destination and transfers only differences.

</details>




---

## 09 Logs and performance

*22 min*

*Finding out what happened, and why a server is slow.*

### journald
systemd's journal collects logs from the kernel, services, and applications:
```bash
journalctl -u nginx --since today                 # one service
journalctl -u ssh --since '1 hour ago' -g Failed  # filter by pattern
journalctl -p err -b                              # errors since this boot
journalctl -k                                     # kernel messages (like dmesg)
journalctl -f                                     # follow everything
journalctl --list-boots ; journalctl -b -1        # previous boot (needs persistent storage)
journalctl --disk-usage ; sudo journalctl --vacuum-time=30d
```

### Traditional log files

| File | Contents |
|---|---|
| `/var/log/syslog` (Ubuntu) / `/var/log/messages` (RHEL) | General system log |
| `/var/log/auth.log` (Ubuntu) / `/var/log/secure` (RHEL) | Sign-ins, sudo, SSH |
| `/var/log/nginx/`, `/var/log/httpd/` | Web server access and error logs |
| `/var/log/apt/`, `/var/log/dnf.log` | Package history |
| `/var/log/audit/audit.log` | auditd and SELinux denials (RHEL) |

### logrotate
`logrotate` rotates, compresses, and deletes old log files on a schedule, using rules in `/etc/logrotate.d/`. Without it, logs fill disks. Test a rule with `sudo logrotate --debug /etc/logrotate.d/nginx`.

Send important logs to a **central log server** or SIEM (with rsyslog forwarding or an agent) so they survive the server and can be searched together.

### Performance: the first five minutes
When a server is "slow," check these in order:

| Command | Tells you |
|---|---|
| `uptime` | Load averages for 1, 5, and 15 minutes. Compare with the CPU count (`nproc`). |
| `top` / `htop` | Which processes use CPU and memory; `wa` in the CPU line is time waiting for disk |
| `free -h` | Memory. Look at **available**, not "free"; Linux uses spare memory as cache. |
| `vmstat 1 5` | Run queue, swapping (`si`/`so`), I/O wait, every second |
| `iostat -xz 1` | Disk utilization and latency per device (package `sysstat`) |
| `df -h` / `df -i` | Disk space / inodes (a disk can be "full" of tiny files with space left) |
| `ss -s` | Socket summary (connection storms) |
| `dmesg -T \| tail` | Kernel errors: disk failures, out-of-memory kills, network problems |

### The OOM killer
When memory runs out, the kernel's **out-of-memory killer** stops a process (often the biggest one, like a database). Look for it:
```bash
journalctl -k | grep -i 'out of memory\|oom'
```
Fix the cause (memory leak, too many workers, missing swap), not just the symptom.

> [!TIP]
> **In your lab**
>
> On LNX01, run `stress-ng --cpu 2 --timeout 60` (install `stress-ng`) in one session and watch `top` and `uptime` in another. Then fill a disk with `fallocate -l 5G /tmp/fill` and watch `df -h`, and if you set up the [PRTG lab](../infrastructure/monitoring-prtg), add an SSH sensor for LNX01 and watch it alert.

### Check yourself

**1. `free -h` shows very little "free" memory. Is the server out of memory?**

- a) Yes, add RAM immediately
- b) Not necessarily; check "available", because Linux uses spare memory for cache
- c) Yes, restart every service

<details><summary>Answer</summary>

**b)** Cache is released when programs need it. "Available" is the useful number.

</details>

**2. Which log shows SSH sign-ins on RHEL?**

- a) `/var/log/syslog`
- b) `/var/log/secure`
- c) `/var/log/auth.log`

<details><summary>Answer</summary>

**b)** RHEL logs authentication in `/var/log/secure`; Ubuntu uses `/var/log/auth.log`.

</details>

**3. `df -h` shows free space, but writes fail with "No space left on device." What do you check?**

- a) Inodes with `df -i`
- b) Memory with `free -h`
- c) Load with `uptime`

<details><summary>Answer</summary>

**a)** Running out of inodes (usually millions of tiny files) blocks new files even with free space.

</details>




---

## 10 Automation: scripts, cron, and timers

*22 min*

*Turning repeated tasks into scripts that run by themselves.*

### Bash script basics
```bash
#!/usr/bin/env bash
set -euo pipefail                         # stop on errors, unset variables, and failed pipes

THRESHOLD=${1:-80}                        # first argument, default 80
LOG=/var/log/disk-check.log

df -h --output=pcent,target | tail -n +2 | while read -r pct mount; do
  used=${pct%\%}
  if (( used > THRESHOLD )); then
    echo "$(date -Is) WARNING $mount at $pct" | tee -a "$LOG"
  fi
done
```

| Concept | Syntax |
|---|---|
| Variables | `name=value` (no spaces), use as `"$name"` (always quote) |
| Command output | `today=$(date +%F)` |
| Tests | `if [[ -f /etc/app.conf ]]; then ... fi` (`-f` file, `-d` directory, `-z` empty string) |
| Numbers | `(( count > 5 ))` |
| Loops | `for host in web1 web2; do ssh "$host" uptime; done` |
| Exit codes | `$?` is the last command's result; 0 means success. `exit 1` signals failure. |
| Functions | `log() { echo "$(date -Is) $*"; }` |

Check scripts with **ShellCheck** (`shellcheck script.sh`), the same tool your [repo's CI pipeline](https://github.com/drnwang/sysadmin-automation-scripts) runs.

### cron
```bash
crontab -e                   # edit your own schedule
sudo crontab -e              # root's schedule
ls /etc/cron.d/ /etc/cron.daily/
```
```
# ┌ minute  ┌ hour  ┌ day of month  ┌ month  ┌ day of week (0=Sunday)
  0         6       *               *        1-5     /usr/local/bin/check_disk.sh >> /var/log/check_disk.log 2>&1
  */15      *       *               *        *       /usr/local/bin/sync-reports.sh
```
cron runs with a minimal environment, so use **full paths** in scripts and redirect output to a log; otherwise errors vanish.

### systemd timers
Timers are the modern alternative: they log to the journal, can catch up on runs missed while the server was off (`Persistent=true`), and add random delays.
```ini
# /etc/systemd/system/disk-check.service
[Service]
Type=oneshot
ExecStart=/usr/local/bin/check_disk.sh 80

# /etc/systemd/system/disk-check.timer
[Timer]
OnCalendar=Mon..Fri 06:00
Persistent=true

[Install]
WantedBy=timers.target
```
```bash
sudo systemctl daemon-reload && sudo systemctl enable --now disk-check.timer
systemctl list-timers
journalctl -u disk-check.service
```

### Beyond scripts: configuration management
When you manage many servers, **Ansible** describes the desired state (packages, files, users, services) in YAML **playbooks** and applies them over SSH, with no agent. It's the most common next step after shell scripting, and it also manages Windows servers through WinRM.

### Check yourself

**1. What does `set -euo pipefail` do in a bash script?**

- a) Stops the script on errors, unset variables, and failures inside pipelines
- b) Makes the script run faster
- c) Enables debugging output

<details><summary>Answer</summary>

**a)** It makes scripts fail loudly instead of continuing after an error.

</details>

**2. What does the cron schedule `0 6 * * 1-5` mean?**

- a) Every 6 minutes
- b) 6:00 a.m. Monday to Friday
- c) The 6th of every month

<details><summary>Answer</summary>

**b)** Minute 0, hour 6, any day of month, any month, days 1–5 (Monday–Friday).

</details>

**3. What advantage do systemd timers have over cron?**

- a) They run more often
- b) They log to the journal and can catch up on missed runs
- c) They don't need root

<details><summary>Answer</summary>

**b)** `Persistent=true` runs a missed job at the next boot, and output goes to journalctl.

</details>




---

## 11 Security hardening

*22 min*

*A practical baseline that closes most of the holes attackers use.*

### The baseline
1. **Patch** regularly and automatically for security updates (Module 4).
2. **Minimize:** remove software and services you don't need (`systemctl list-units --type=service`, `ss -tulpn`).
3. **SSH:** keys only, no root sign-in, restricted groups and source networks (Module 8).
4. **Firewall:** default deny inbound; allow only what's needed, from where it's needed (Module 7).
5. **Least privilege:** personal accounts with sudo, no shared root password, sudo rules scoped to tasks.
6. **Central identity** and access by group (Module 3).
7. **Logs** forwarded centrally, and **time** synced (chrony) so logs line up.
8. **Mandatory access control** left on (below).
9. **Backups** tested (Module 13).
10. **Scan and measure:** vulnerability scans (your [Nessus lab](../security/nessus-scan-lab)) and a CIS benchmark check.

### SELinux and AppArmor
Both limit what a program can do **even if it's compromised or running as root**, by enforcing a policy per program.
- **SELinux** (RHEL): files and processes carry **labels**; policy says which labels may interact. Keep it **Enforcing**.
- **AppArmor** (Ubuntu): **profiles** list the paths and capabilities each program may use.

```bash
getenforce ; sestatus                         # SELinux mode
sudo ausearch -m avc -ts recent               # recent SELinux denials
ls -Z /var/www/html                           # file labels
sudo restorecon -Rv /var/www/html             # reset labels to the policy default
sudo setsebool -P httpd_can_network_connect on   # allow web server outbound connections
sudo aa-status                                # AppArmor profiles (Ubuntu)
```

> [!WARNING]
> **Watch out: Don't turn SELinux off**
>
> When an app fails on RHEL, the internet often suggests `setenforce 0`. Instead, read the denial (`ausearch -m avc`), then fix the cause: wrong file labels (`restorecon`, `semanage fcontext`), a boolean (`setsebool`), or a non-standard port (`semanage port -a`). `sealert` (from `setroubleshoot`) explains denials in plain English.

### Auditing
**auditd** records security-relevant events (file changes, sudo use, sign-ins) in `/var/log/audit/audit.log`:
```bash
sudo auditctl -w /etc/sudoers -p wa -k sudoers-change
sudo ausearch -k sudoers-change
```

### Benchmarks and scanning tools
- **CIS Benchmarks** for Ubuntu and RHEL: the Linux side of your [hardening lab](../security/windows-hardening-lab).
- **OpenSCAP** (`oscap`) scans RHEL against CIS or DISA STIG profiles and generates a report; **Ubuntu Security Guide** (`usg`, with Ubuntu Pro) does the same for Ubuntu.
- **Lynis**: a free, quick security audit for any distro (`sudo lynis audit system`).
- **fail2ban**: blocks IPs after repeated failures.

### Check yourself

**1. An app on RHEL fails with SELinux denials. What's the right fix?**

- a) `setenforce 0` permanently
- b) Read the denial and fix the label, boolean, or port policy
- c) Reinstall the app

<details><summary>Answer</summary>

**b)** SELinux protects the system even when an app is compromised. Fix the specific cause instead of turning it off.

</details>

**2. Which tool can scan RHEL against a DISA STIG profile?**

- a) OpenSCAP
- b) logrotate
- c) rsync

<details><summary>Answer</summary>

**a)** `oscap` evaluates systems against SCAP content, including CIS and STIG profiles.

</details>




---

## 12 Common services

*20 min*

*The services Linux servers most often run in a business, and how to set each one up.*

### Web servers: nginx and Apache

| Task | nginx | Apache |
|---|---|---|
| Package | `nginx` | `apache2` (Ubuntu) / `httpd` (RHEL) |
| Site configs | `/etc/nginx/sites-available/` + `sites-enabled/` (Ubuntu), `/etc/nginx/conf.d/` (RHEL) | `/etc/apache2/sites-available/` + `a2ensite` (Ubuntu), `/etc/httpd/conf.d/` (RHEL) |
| Test config | `sudo nginx -t` | `sudo apachectl configtest` |
| Logs | `/var/log/nginx/` | `/var/log/apache2/` or `/var/log/httpd/` |

A **reverse proxy** setup is very common: nginx accepts HTTPS and forwards to an app on a local port:
```nginx
server {
    listen 443 ssl;
    server_name assets.lab.local;
    ssl_certificate     /etc/ssl/lab/assets.crt;
    ssl_certificate_key /etc/ssl/lab/assets.key;
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}
```
For public sites, **Let's Encrypt** with `certbot` provides free certificates that renew automatically. For internal sites, use your [internal CA](../windows/adcs-pki).

### File sharing
- **Samba** shares Linux folders with Windows clients over SMB, and can join AD for permissions.
- **NFS** shares between Linux and Unix systems (`/etc/exports`, `exportfs -ra`).

### Databases
**PostgreSQL** and **MySQL/MariaDB** are the common open-source databases. Admin basics: install from the distro or vendor repository, keep the listener on localhost unless remote access is needed, create a separate user per application, and back up with `pg_dump` / `mysqldump` (Module 13).

### Containers
**Docker** and **Podman** (RHEL's default, daemonless and rootless-capable) run apps packaged as images:
```bash
docker ps ; docker logs -f snipeit ; docker compose up -d ; docker compose pull && docker compose up -d
podman ps ; podman generate systemd   # older Podman; newer versions use Quadlet unit files
```
Your [asset inventory lab](../helpdesk/asset-inventory) runs Snipe-IT this way. Keep images updated just like packages, and don't run containers you don't trust.

### Time and DNS
- **chrony** keeps time (`chronyc tracking`, `chronyc sources -v`). Point servers at your domain controllers or a reliable NTP pool.
- **BIND** or **dnsmasq** can serve DNS on Linux; in a Windows domain, you'll usually point Linux at the AD DNS servers instead.

### Check yourself

**1. Which command checks nginx's configuration before reloading?**

- a) `nginx -t`
- b) `nginx --check`
- c) `systemctl verify nginx`

<details><summary>Answer</summary>

**a)** Always run `nginx -t`, then `systemctl reload nginx` if it passes.

</details>

**2. What does a reverse proxy do?**

- a) Blocks all inbound traffic
- b) Accepts client connections and forwards them to a backend app
- c) Caches DNS records

<details><summary>Answer</summary>

**b)** A reverse proxy terminates HTTPS and passes requests to an app server, often on a local port.

</details>




---

## 13 Backup, boot problems, and recovery

*22 min*

*Recovering files, recovering servers, and getting an unbootable system running again.*

### What to back up
- **Configuration:** `/etc`, plus app configs in `/opt` or `/srv`
- **Data:** web content, file shares, home directories
- **Databases:** dumped consistently, not just copied while running
- **The list of installed packages**, so you can rebuild: `dpkg --get-selections` / `dnf history`

Many teams back up data and configuration and **rebuild** the server itself (from automation or a VM template) rather than restoring the whole OS.

### Tools

| Tool | Use |
|---|---|
| `tar -czf etc-$(date +%F).tar.gz /etc` | A compressed archive |
| `rsync -a --delete /srv/ backup:/backups/lnx01/srv/` | Mirror to another server |
| `pg_dump app > app.sql`, `mysqldump app > app.sql` | Consistent database dumps |
| **Restic**, **BorgBackup** | Encrypted, deduplicated, versioned backups to disk or cloud |
| LVM / Btrfs / VM snapshots | Quick point-in-time copies (a snapshot isn't a backup unless it's copied elsewhere) |
| **Veeam Agent for Linux** | Fits in with your [Veeam lab](../windows/backup-dr) |

Follow **3-2-1**: three copies, on two kinds of media, one off-site. And **test restores**; a backup you've never restored from is a hope, not a backup.

### How Linux boots
1. **UEFI firmware** starts the bootloader.
2. **GRUB** loads the kernel and the initial RAM disk (**initramfs**).
3. The kernel starts **systemd** (PID 1).
4. systemd mounts file systems from `/etc/fstab` and starts services up to the default target.

### When a server won't boot

| Symptom | Likely cause | Fix |
|---|---|---|
| Drops to **emergency mode** | Bad `/etc/fstab` entry or a failed disk | Enter the root password, `mount -o remount,rw /`, fix fstab, reboot |
| File system errors | Unclean shutdown, failing disk | Boot to rescue mode and run `fsck` (ext4) or `xfs_repair` (XFS) on the **unmounted** file system |
| Kernel panic after an update | Bad kernel or initramfs | In the GRUB menu (hold **Shift** or press **Esc** at boot), choose **Advanced options** and an older kernel |
| Forgot the root/admin password | | At GRUB, edit the boot entry: add `rd.break` (RHEL) or `init=/bin/bash` (Ubuntu) to the kernel line, remount root read-write, `passwd`, and on RHEL `touch /.autorelabel` for SELinux |
| Disk full stops services | Logs, old kernels, Docker images | `du` to find it; `journalctl --vacuum-size=500M`, `apt autoremove` / `dnf remove --oldinstallonly`, `docker system prune` |

> [!TIP]
> **In your lab**
>
> Take a checkpoint of LNX01 in Hyper-V first. Then add a bad line to `/etc/fstab` (a disk that doesn't exist, without `nofail`), reboot, and recover from emergency mode. Restore the checkpoint and try resetting a forgotten password through GRUB.

### Check yourself

**1. A server drops into emergency mode after you added a disk to `/etc/fstab`. What's the likely cause?**

- a) A mistake in the new fstab line, or the disk isn't present
- b) The kernel was updated
- c) SSH is misconfigured

<details><summary>Answer</summary>

**a)** fstab errors stop the boot. Fix the line (and use `nofail` for non-essential disks).

</details>

**2. Why dump a database instead of copying its files?**

- a) Dumps are smaller
- b) Copying files while the database runs can produce an inconsistent, unusable copy
- c) Databases can't be copied

<details><summary>Answer</summary>

**b)** Dump tools produce a consistent snapshot of the data that can be restored reliably.

</details>

**3. How do you boot an older kernel after a bad update?**

- a) Choose it from GRUB's Advanced options menu at boot
- b) Reinstall the OS
- c) Run `apt upgrade` again

<details><summary>Answer</summary>

**a)** GRUB keeps previous kernels. Hold Shift or press Esc at boot to see the menu.

</details>




---

## 14 Linux in a Windows domain

*12 min*

*How Linux servers fit alongside Active Directory, Windows management, and your existing tools.*

### Identity
- **SSSD + realmd** join Linux to AD so domain users sign in with their AD accounts and access is managed by AD group. Your [AD join tutorial](../linux/ad-join) covers this end to end, and the [Inside Active Directory](./active-directory.md) course explains the Kerberos and DNS underneath.
- **Kerberos SSO:** domain users with a ticket can SSH without a password (GSSAPI) and mount Windows shares with `sec=krb5`.
- **Sudo by AD group:** `%gg-linux-admins ALL=(ALL:ALL) ALL` in `/etc/sudoers.d/`.

### Management from Windows tools
- **Microsoft Defender for Endpoint** and most EDR tools have Linux agents.
- **Azure Arc** lets Azure policies, updates, and monitoring manage on-premises Linux servers.
- **Ansible** (from a Linux control node) manages both Linux and Windows.
- Monitoring tools like **PRTG** use SSH sensors, and **Zabbix** has a Linux agent.
- **Nessus/ACAS** credentialed scans log in over SSH with a scan account and sudo rights.

### Windows commands and their Linux equivalents

| Windows | Linux |
|---|---|
| `ipconfig /all` | `ip addr`, `resolvectl status` |
| `ping`, `tracert`, `nslookup` | `ping`, `tracepath`/`mtr`, `dig`/`host` |
| `netstat -ano` | `ss -tulpn` |
| `tasklist`, `taskkill` | `ps aux`, `kill` |
| Services console, `Get-Service` | `systemctl` |
| Event Viewer, `Get-WinEvent` | `journalctl`, `/var/log` |
| Task Scheduler | cron, systemd timers |
| `gpupdate` | Configuration management (Ansible) |
| `chkdsk` | `fsck`, `xfs_repair` |
| Windows Update | `apt` / `dnf` |
| `whoami /groups` | `id` |
| `icacls` | `ls -l`, `chmod`, `chown`, `getfacl` |
| PowerShell remoting | SSH |

### Check yourself

**1. What's the Linux equivalent of `netstat -ano` for finding listening ports?**

- a) `ss -tulpn`
- b) `ip route`
- c) `journalctl -k`

<details><summary>Answer</summary>

**a)** `ss -tulpn` shows listening sockets and their processes.

</details>

**2. How does a Nessus credentialed scan usually authenticate to Linux?**

- a) Over RDP
- b) Over SSH with a scan account (often with sudo)
- c) With a domain computer account

<details><summary>Answer</summary>

**b)** Credentialed Linux scans sign in over SSH to check installed packages and settings.

</details>




---

## 15 A troubleshooting method

*16 min*

*A repeatable way to work through any Linux problem, plus the questions to ask first.*

### The method
1. **Define the problem precisely.** "The website is down" → "Since 09:40, `https://status.lab.local` returns 502 to everyone."
2. **Ask what changed:** updates (`/var/log/apt/history.log`, `dnf history`), config edits, deployments, certificates, firewall rules, disk filling.
3. **Check the obvious layers in order:** is the server up? Disk space? Memory? Is the service running? Is it listening? Firewall? DNS?
4. **Read the logs** for that service and the time it started: `journalctl -u <service> --since '09:30'`.
5. **Form one hypothesis, test it, change one thing at a time.** Note what you changed.
6. **Fix, verify from the user's side**, then write it up (your [KB format](../helpdesk/knowledge-base)) so the next person fixes it in minutes.

### Quick triage commands
```bash
uptime ; df -h ; df -i ; free -h          # load, disk, inodes, memory
systemctl --failed                        # broken services
journalctl -p err -b --no-pager | tail -50
ss -tulpn                                 # what's listening
sudo tail -n 50 /var/log/nginx/error.log  # the app's own error log
last -n 10 ; journalctl -u ssh --since today | tail   # who's been on the box
```

### Common problems

| Symptom | Usual cause | First command |
|---|---|---|
| "Permission denied" | Ownership/mode, SELinux/AppArmor, wrong user | `ls -l`, `id`, `ausearch -m avc` |
| Service won't start | Config error, port in use, missing file | `systemctl status`, `journalctl -u`, the app's `-t`/config test |
| "Address already in use" | Another process on the port | `ss -tulpn \| grep :80` |
| Can't SSH in | Firewall, sshd down, AllowGroups, key permissions (`~/.ssh` must be 700, `authorized_keys` 600) | Console access; `journalctl -u ssh` |
| Name resolution fails | Wrong DNS servers, search domain | `resolvectl status`, `dig` |
| 502 Bad Gateway from nginx | The backend app is down or on a different port | `systemctl status <app>`, `curl localhost:<port>` |
| Disk full | Logs, old kernels, containers, a runaway file | `du -xh --max-depth=1 / \| sort -h` |
| High load, low CPU use | Processes waiting on slow disk or NFS | `top` (`wa`), `iostat -xz 1` |
| Time wrong, Kerberos fails | chrony not syncing | `chronyc tracking` |

> [!TIP]
> **Good practice: Keep a personal runbook**
>
> Every time you solve something new, add the symptom, the command that found it, and the fix to your notes. After a few months, it becomes the most useful document you own.

### Check yourself

**1. nginx returns 502 Bad Gateway. Where do you look?**

- a) Whether the backend app nginx forwards to is running and reachable
- b) The client's browser cache
- c) The DNS MX record

<details><summary>Answer</summary>

**a)** 502 means nginx couldn't get a valid response from its upstream app.

</details>

**2. SSH key login fails with "Permission denied (publickey)" though the key is in `authorized_keys`. What's a common cause?**

- a) The server's clock
- b) Permissions on `~/.ssh` or `authorized_keys` are too open
- c) The firewall

<details><summary>Answer</summary>

**b)** sshd ignores keys if `~/.ssh` or `authorized_keys` are writable by others. Use 700 and 600.

</details>




---

*Written in plain language from Ubuntu, Red Hat, and upstream documentation, current as of October 2026 (Ubuntu 26.04 LTS, RHEL 10). Defaults differ between distributions and releases. Check your distribution's documentation before changing production systems.*
