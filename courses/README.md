# Self-Study Courses

Five courses on how core IT systems work and how to run them day to day. Each module explains the concepts, shows the commands, links to the matching hands-on tutorial in this repo, and ends with a short self-check (open each answer to see the explanation).

| Course | Modules | Time | Covers |
|---|---|---|---|
| [**Inside Active Directory**](./active-directory.md) | 16 | ~5 h | Forests, domains, and OUs; replication and sites; DNS and the DC locator; Kerberos; Group Policy; groups and accounts; delegation and LAPS; FSMO roles; troubleshooting; recovery; security; Windows Server 2025 |
| [**Running Exchange Server**](./exchange-server.md) | 14 | ~4½ h | Building a lab Exchange server, recipients and permissions, databases, mail flow, message tracking, client access and certificates, DAGs, security, patching, hybrid with Exchange Online |
| [**Managing Mobile Devices**](./mobile-devices.md) | 12 | ~3½ h | iPhone, iPad, and Android in Intune: Apple Business, Automated Device Enrollment, Android Enterprise, configuration, apps, compliance, app protection for BYOD, updates, support |
| [**Managing Macs**](./mac-admin.md) | 12 | ~3½ h | macOS for Windows admins, Mac security, enrollment, Platform SSO, configuration profiles, apps and scripts, updates, FileVault, Terminal troubleshooting |
| [**Linux Admin Guide**](./linux-admin.md) | 16 | ~6 h | Shell, permissions, users and sudo, packages, systemd, storage and LVM, networking, SSH, logs, automation, security, services, backup and recovery (Ubuntu and RHEL side by side) |

**Suggested order:** Active Directory → Linux → Exchange → Mobile devices → Macs. They fit alongside the [12-week study plan](../study-plan/): read a course's modules on weeknights, then build the matching tutorial at the weekend.

> Current as of October 2026 (Windows Server 2025, Exchange Server SE, iOS/macOS 27, Ubuntu 26.04 LTS, RHEL 10). Product versions and defaults change, so check vendor documentation before changing production systems.
