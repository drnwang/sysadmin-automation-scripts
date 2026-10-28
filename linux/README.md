# Linux Scripts

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
