# Linux

| Folder or file | What it is |
|---|---|
| [`ad-join/`](./ad-join/) | **Tutorial:** Ubuntu Server joined to Active Directory with realmd and SSSD, AD group sign-in and sudo, SSH and firewall hardening, nginx, logrotate, and cron |
| [`check_disk.sh`](./check_disk.sh) | Script that flags file systems above 80% full |

## Disk usage check: `check_disk.sh`

Prints any file system that is more than **80%** full, along with the `df -h` header row, so you can spot disks that need cleanup before they fill up.

```bash
chmod +x check_disk.sh
./check_disk.sh
```

To change the alert level, edit `THRESHOLD=80` at the top of the script. To run it every morning, add a cron entry:

```bash
0 6 * * * /path/to/check_disk.sh
```
