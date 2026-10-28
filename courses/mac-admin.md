# Managing Macs

*Self-study course · macOS in the enterprise*

Twelve modules on supporting and managing Macs, written for a Windows admin. It covers how macOS is built and secured, Apple Business and automated enrollment, Intune and Jamf, Platform SSO, configuration profiles, apps and scripts, updates, FileVault, and a Terminal troubleshooting toolkit. Each module ends with a short self-check.

**Total:** about 3½ hours · **Tools:** Intune, with Jamf Pro compared · **Lab:** a Mac or macOS VM + your M365 trial

> Each module ends with a self-check. Open each answer to see the explanation.

## Contents

0. [The Mac at work](#00-the-mac-at-work) (12 min)
1. [macOS for Windows admins](#01-macos-for-windows-admins) (18 min)
2. [How macOS is secured](#02-how-macos-is-secured) (18 min)
3. [Management platforms](#03-management-platforms) (14 min)
4. [Enrolling Macs](#04-enrolling-macs) (18 min)
5. [Accounts, sign-in, and admin rights](#05-accounts-sign-in-and-admin-rights) (18 min)
6. [Configuration profiles](#06-configuration-profiles) (18 min)
7. [Apps and scripts](#07-apps-and-scripts) (18 min)
8. [macOS updates](#08-macos-updates) (14 min)
9. [FileVault and data protection](#09-filevault-and-data-protection) (16 min)
10. [Terminal troubleshooting toolkit](#10-terminal-troubleshooting-toolkit) (18 min)
11. [Help desk playbook and lifecycle](#11-help-desk-playbook-and-lifecycle) (16 min)

---

## 00 The Mac at work

*12 min*

*Macs are common in design, engineering, and executive teams, and many help desks now support them alongside Windows.*

### Hardware and versions
- **Apple silicon** (M-series chips) has replaced Intel in every current Mac. **macOS 26 was the last release for Intel Macs**; **macOS 27** (released September 2026) runs only on Apple silicon. Intel Macs still in service won't get new major versions and will eventually stop getting security updates.
- Apple releases a **major macOS version every fall**, with point releases and security updates through the year. Apple typically provides security updates for the current version and the two before it, though it doesn't publish a formal schedule.

```bash
sw_vers                                   # macOS version and build
system_profiler SPHardwareDataType        # model, chip, serial number, memory
```

### How Mac management differs from Windows

| Windows habit | Mac equivalent |
|---|---|
| Domain join and Group Policy | **MDM** enrollment and **configuration profiles** |
| Imaging with MDT or SCCM | No imaging. Macs are **erased** to factory state and set themselves up with **Automated Device Enrollment** |
| Local admin through GPO or LAPS | Standard users by default; admin rights through MDM tools or elevation apps |
| BitLocker | **FileVault** |
| Windows Update / WSUS | **Software Update**, enforced through Declarative Device Management |
| Event Viewer | **Console** app and the `log` command |
| Services | **launchd** daemons and agents |
| Registry | Preference files (`.plist`) and managed preferences |

> [!TIP]
> **In your lab**
>
> You need a Mac (any Apple silicon model) or a macOS virtual machine. On an Apple silicon Mac, **UTM** or Apple's own Virtualization framework can run macOS VMs, which can enroll in Intune through device enrollment. Use the Intune in your [Microsoft 365 trial](../m365).

### Check yourself

**1. Which macOS version was the last to support Intel Macs?**

- a) macOS 25
- b) macOS 26
- c) macOS 27

<details><summary>Answer</summary>

**b)** macOS 26 was the final release with Intel support; macOS 27 requires Apple silicon.

</details>

**2. What replaces imaging when deploying a new Mac?**

- a) Automated Device Enrollment from a factory-fresh Mac
- b) MDT task sequences
- c) Copying a disk image with Disk Utility

<details><summary>Answer</summary>

**a)** Modern Macs aren't imaged. They enroll in MDM during Setup Assistant and pull their configuration and apps.

</details>




---

## 01 macOS for Windows admins

*18 min*

*Enough of macOS's internals to find your way around and troubleshoot confidently.*

### The file system
Macs use **APFS** (Apple File System). The startup disk is split into a read-only, cryptographically sealed **System** volume (macOS itself, which nothing can modify) and a writable **Data** volume (users, apps, settings). They appear as one disk in Finder.

| Path | Holds |
|---|---|
| `/Applications` | Apps for all users |
| `/Users/<name>` | Home folders (`~` in Terminal) |
| `/Library` | System-wide settings, launch daemons, logs, managed preferences |
| `~/Library` | Per-user settings, caches, logs (hidden in Finder; **Option**-click **Go** to show it) |
| `/System` | macOS itself (read-only) |
| `/Library/Managed Preferences` | Settings delivered by configuration profiles |
| `/var/log`, `/Library/Logs` | Logs |

### Users and groups
- **Local accounts** live in the local directory, managed with **System Settings → Users & Groups** or `dscl` / `sysadminctl`.
- **Admin** accounts can install software and change system settings after authenticating; **standard** accounts can't. Most organizations give users **standard** accounts.
- The first account created during setup gets a **secure token**, which matters for FileVault (Module 9).
- **Mobile accounts** (cached network accounts from AD binding) are legacy; modern setups use local accounts linked to the identity provider (Module 5).

```bash
id                                         # your user and groups
dscl . -list /Users | grep -v '^_'         # local users
dseditgroup -o checkmember -m jsmith admin # is jsmith an admin?
sudo sysadminctl -secureTokenStatus jsmith
```

### Processes and services
**launchd** starts everything. **Launch daemons** run as root at startup (`/Library/LaunchDaemons`); **launch agents** run as the user at sign-in (`~/Library/LaunchAgents`, `/Library/LaunchAgents`). Most management agents (Intune's, Jamf's, security tools) are launch daemons.
```bash
sudo launchctl list | grep -i intune
launchctl print system/com.microsoft.intune.agent 2>/dev/null | head
```

### Preferences
App and system settings are stored in **property list** (`.plist`) files. The `defaults` command reads and writes them:
```bash
defaults read com.apple.dock orientation
defaults read /Library/Preferences/com.apple.SoftwareUpdate
```
Settings delivered by MDM override user preferences and show as **managed** (often greyed out in System Settings).

### Logs
macOS uses the **unified log**. Read it in the **Console** app or with `log`:
```bash
log show --last 30m --predicate 'process == "mdmclient"' --info
log stream --predicate 'subsystem == "com.apple.ManagedClient"'
```

### Keyboard and Finder survival guide

| Task | How |
|---|---|
| Spotlight search (launch anything) | **⌘ Space** |
| Force quit | **⌘ ⌥ Esc** |
| Screenshot (selection) | **⌘ ⇧ 4** |
| Show hidden files in Finder | **⌘ ⇧ .** |
| Go to a path in Finder | **⌘ ⇧ G** |
| Activity Monitor (Task Manager) | Spotlight → Activity Monitor |
| System Information | Hold **⌥** and choose the Apple menu → System Information |

### Check yourself

**1. Which volume holds users' files and apps on a modern Mac?**

- a) The System volume
- b) The Data volume
- c) The Recovery volume

<details><summary>Answer</summary>

**b)** The System volume is sealed and read-only. Everything changeable is on the Data volume.

</details>

**2. What's the Mac equivalent of Windows services?**

- a) launchd daemons and agents
- b) Kernel extensions
- c) Login items in Finder

<details><summary>Answer</summary>

**a)** launchd starts daemons (system-wide, as root) and agents (per user) from plist files.

</details>

**3. Which command reads a preference from a `.plist`?**

- a) `dscl`
- b) `defaults read`
- c) `sysadminctl`

<details><summary>Answer</summary>

**b)** `defaults` reads and writes property list preferences.

</details>




---

## 02 How macOS is secured

*18 min*

*Mac security features shape what MDM can and can't do, so understanding them saves a lot of confusion.*

| Feature | What it does |
|---|---|
| **Secure Enclave** | A separate secure processor that protects encryption keys, Touch ID data, and FileVault keys |
| **Signed System Volume / System Integrity Protection (SIP)** | macOS system files are sealed and can't be changed, even by root |
| **Secure boot** | Only Apple-signed, trusted macOS versions can start |
| **Gatekeeper** | Apps from outside the App Store must be signed by an identified developer and **notarized** (scanned by Apple) before they open |
| **XProtect** | Built-in signature-based malware detection and removal, updated silently |
| **Transparency, Consent, and Control (TCC)** | Apps must ask the user before accessing the camera, microphone, screen, files, contacts, and more |
| **FileVault** | Full-disk encryption (Module 9) |
| **Activation Lock** | Links the Mac to an Apple Account through Find My, so a stolen Mac can't be erased and reused |

```bash
csrutil status          # SIP enabled?
spctl --status          # Gatekeeper enabled?
fdesetup status         # FileVault on?
```

### What this means for IT
- You **can't** modify system files or turn off SIP remotely, by design.
- Security and management tools need **TCC** permissions like **Full Disk Access**. MDM can grant many of these silently with a **Privacy Preferences Policy Control (PPPC)** profile. It **can't** silently grant camera, microphone, or screen recording; for screen recording it can only let standard users approve it themselves.
- Tools that extend the system (antivirus, VPN, DLP) use **system extensions** and **network extensions**, which MDM must approve with a profile. Older **kernel extensions** are deprecated and require reduced security settings on Apple silicon.
- **Bootstrap token:** when a Mac enrolls, it can escrow a **bootstrap token** to the MDM server. The MDM uses it to give **secure tokens** to new accounts, authorize software updates, and approve some security changes on Apple silicon without the user's password. Check with `sudo profiles status -type bootstraptoken`.

### Check yourself

**1. An antivirus tool needs Full Disk Access on 300 Macs. How do you grant it without asking each user?**

- a) Deploy a Privacy Preferences Policy Control (PPPC) profile from MDM
- b) Turn off SIP
- c) Ask each user to approve it

<details><summary>Answer</summary>

**a)** PPPC profiles can pre-approve Full Disk Access for specific signed apps.

</details>

**2. Which permission can MDM never grant silently?**

- a) Full Disk Access
- b) Microphone access
- c) Accessibility

<details><summary>Answer</summary>

**b)** Camera and microphone always require the user's consent. Screen recording can at most be made approvable by standard users.

</details>

**3. What is the bootstrap token used for?**

- a) Encrypting email
- b) Letting MDM grant secure tokens and authorize updates on Apple silicon
- c) Signing apps for Gatekeeper

<details><summary>Answer</summary>

**b)** The bootstrap token, escrowed to MDM at enrollment, authorizes actions that would otherwise need an admin's password.

</details>




---

## 03 Management platforms

*14 min*

*Intune, Jamf, and Apple Business each play a role. Knowing which does what avoids confusion.*

### Apple Business
**Apple Business** (Apple's free portal, which replaced Apple Business Manager in April 2026) links Macs bought from Apple or authorized resellers to your organization, assigns them to an MDM server, provides **Apps and Books** licenses, and creates **Managed Apple Accounts**, usually federated with Entra ID. The setup and the yearly token renewals are the same as for iPhones; see Module 2 of [Managing Mobile Devices](./mobile-devices.md). The **APNs push certificate** is shared by all of your Apple devices in Intune.

### MDM choices

| | Microsoft Intune | Jamf Pro |
|---|---|---|
| Strength | One tool for Windows, Mac, and mobile, tightly linked to Entra ID and Conditional Access | Apple-only, very deep Mac features, large admin community |
| Organizing devices | Entra ID groups (assigned or dynamic) and filters | **Smart groups** based on any inventory data |
| Custom data | **Custom attributes** (shell scripts that report a value) | **Extension attributes** |
| Software | PKG and DMG apps, Microsoft 365 apps, Apps and Books apps, shell scripts | **Policies** (triggered on check-in, sign-in, or on demand) and **Self Service** app catalog |
| Agent | Intune management agent (installs when scripts or PKG apps are assigned) | `jamf` binary, with `sudo jamf policy` and `sudo jamf recon` |
| Compliance with Entra ID | Built in | Through the Jamf and Microsoft device compliance integration |

Other Apple-focused options include Kandji, Mosyle, and Apple Business's own built-in management for small organizations. The Apple concepts in this course apply to all of them; only the screens differ.

> [!TIP]
> **Good practice: Pick one MDM per device**
>
> A Mac can be enrolled in only one MDM at a time. Moving from one MDM to another usually means unenrolling and re-enrolling (or, for ADE Macs, reassigning in Apple Business and running Setup Assistant again). Apple added a supported way to **migrate between MDM servers** without erasing for ADE devices, but check that both vendors support it.

### Check yourself

**1. Where do you assign company-purchased Macs to Intune for automated enrollment?**

- a) In Jamf Pro
- b) In Apple Business
- c) In System Settings on each Mac

<details><summary>Answer</summary>

**b)** Apple Business links serial numbers to your organization and assigns them to your MDM server.

</details>

**2. What's the Jamf equivalent of an Intune dynamic device group?**

- a) A smart group
- b) A policy
- c) A configuration profile

<details><summary>Answer</summary>

**a)** Smart groups update membership automatically from inventory data, like OS version or installed apps.

</details>




---

## 04 Enrolling Macs

*18 min*

*How a Mac goes from the box to managed, and why the enrollment method matters.*

### Enrollment methods

| Method | Ownership | Supervised | User experience |
|---|---|---|---|
| **Automated Device Enrollment (ADE)** | Corporate | Yes | Turn on, connect to Wi-Fi, see **Remote Management**, sign in, done. Management can't be removed. |
| **Device enrollment** (Company Portal or profile download) | Corporate or personal | No | User installs Company Portal (or downloads a profile) and approves it in **System Settings → General → Device Management** |
| **Account-driven User Enrollment** | Personal (BYOD) | No | User signs in with a Managed Apple Account; work data is kept separate |
| **Apple Configurator for iPhone** | Corporate | Yes | Adds an existing Mac to Apple Business by holding an iPhone near it during Setup Assistant |

### User-approved MDM
Many powerful settings (kernel and system extension approval, some PPPC settings) work only when MDM enrollment is **user-approved**. ADE enrollments are automatically treated as user-approved; profile-based enrollments are approved when the user approves the profile in System Settings (it can't be clicked by a script).

```bash
sudo profiles status -type enrollment
# Enrolled via DEP: Yes          <- ADE ("DEP" was ADE's old name)
# MDM enrollment: Yes (User Approved)
```

### The ADE experience in Intune
In **Intune → Devices → Enrollment → Apple → Enrollment program tokens → (token) → Profiles → Create profile → macOS**:
- **User affinity:** **Enroll with user affinity** for Macs assigned to a person.
- **Authentication method:** **Setup Assistant with modern authentication**, so users sign in with their work account during setup.
- **Await final configuration:** keeps the user at Setup Assistant until critical policies and apps are installed.
- **Locked enrollment:** **Yes**, so users can't remove management.
- **Local primary account:** prefill the account name from the user's work identity, and choose whether it's an **admin** or **standard** account.
- **Local admin account with LAPS:** Intune can create a hidden local admin account during ADE and rotate its password automatically; IT views it in the device record.
- **Setup Assistant screens:** hide ones you don't need (Siri, Screen Time, Apple Pay).

> [!NOTE]
> **How it works: What happens when a Mac powers on**
>
> 1. During Setup Assistant, the Mac contacts Apple with its serial number.
> 2. Apple Business says: "this Mac belongs to LAB, and its MDM server is Intune."
> 3. The Mac shows **Remote Management**, downloads the enrollment profile, and the user signs in.
> 4. The Mac enrolls, creates the local account, escrows the **bootstrap token**, and starts receiving profiles and apps.
> 5. On every future erase, the same thing happens, so a stolen or reset Mac returns to management.

### Re-running enrollment on a Mac that's already set up
If a corporate Mac was set up without enrolling (for example, before it was assigned in Apple Business), this prompts it to enroll:
```bash
sudo profiles renew -type enrollment
```

### Check yourself

**1. Which output shows that a Mac was enrolled through Automated Device Enrollment?**

- a) `Enrolled via DEP: Yes` from `profiles status -type enrollment`
- b) `SIP: enabled` from `csrutil status`
- c) `FileVault is On` from `fdesetup status`

<details><summary>Answer</summary>

**a)** DEP is ADE's old name. `profiles status -type enrollment` shows both ADE and user-approved status.

</details>

**2. Why does "user-approved MDM" matter?**

- a) It's required to install any app
- b) Some security settings, like approving system extensions, only work on user-approved enrollments
- c) It turns on FileVault automatically

<details><summary>Answer</summary>

**b)** Apple limits certain powerful settings to MDM enrollments the user (or ADE) has approved.

</details>




---

## 05 Accounts, sign-in, and admin rights

*18 min*

*How people sign in to a managed Mac, and how to give admin rights safely.*

### The old way: binding to Active Directory
Macs can be **bound** to AD (System Settings → Users & Groups → Network Account Server, or `dsconfigad`), creating **mobile accounts** that cache AD credentials. Apple now discourages it: bound Macs break when off the network, password changes cause keychain and FileVault problems, and binding doesn't work with cloud identity. Most organizations have moved away from binding.

### Platform SSO (the modern way)
**Platform Single Sign-On** connects the Mac's local account to the identity provider (Microsoft Entra ID through the **Company Portal** app's SSO extension, or Okta and others):
- Users sign in to the Mac with an account that's linked to their Entra ID identity.
- After sign-in, Microsoft apps, Safari, and other apps sign in automatically.
- Authentication options: **Secure Enclave key** (a hardware-bound, phishing-resistant credential; the recommended option), **password sync** (local password kept in sync with Entra ID), or **smart card**.
- In macOS 27, Platform SSO can show the identity provider's sign-in page directly at the **login window**, Lock Screen, and FileVault unlock, including passwordless and QR-code flows, and can create accounts at the login window for shared Macs.

Configure it in Intune with a **Settings catalog** profile (**Authentication → Extensible Single Sign On (SSO)**), using the Microsoft Enterprise SSO plug-in settings from Microsoft's Platform SSO guide.

### Kerberos for on-premises resources
To reach on-premises file shares and intranet sites that use Kerberos (like `\\APP01\Finance` in your lab), deploy Apple's **Kerberos SSO extension** profile. It gets Kerberos tickets from your AD domain controllers when the Mac is on the network or VPN, without binding the Mac to AD.

### Admin rights
Giving every user permanent admin rights is the Mac equivalent of making everyone a local admin on Windows. Better options:
- **Standard accounts** by default, with apps delivered through MDM (Module 7).
- **Time-limited elevation** with tools like the open-source **Privileges** app or an endpoint privilege management product, which grant admin rights for a short period and log it.
- A **managed local admin account** for IT, with a unique rotating password (Intune's LAPS-style macOS local admin for ADE Macs, or similar features in Jamf).

```bash
sudo dseditgroup -o edit -d jsmith -t user admin    # remove jsmith from admins
sudo dseditgroup -o edit -a jsmith -t user admin    # add back
```

### Check yourself

**1. Why does Apple discourage binding Macs to Active Directory?**

- a) Bound Macs have password sync, off-network, and keychain problems, and binding doesn't fit cloud identity
- b) Binding is no longer possible
- c) It disables FileVault

<details><summary>Answer</summary>

**a)** Platform SSO and the Kerberos SSO extension give the benefits without binding's problems.

</details>

**2. Which Platform SSO method uses a hardware-bound, phishing-resistant credential?**

- a) Password sync
- b) Secure Enclave key
- c) Mobile accounts

<details><summary>Answer</summary>

**b)** The Secure Enclave key method creates a credential protected by the Mac's Secure Enclave, similar to Windows Hello for Business.

</details>

**3. A Mac with no AD binding needs to open an on-premises SMB share with single sign-on. What do you deploy?**

- a) A Wi-Fi profile
- b) The Kerberos SSO extension
- c) A PPPC profile

<details><summary>Answer</summary>

**b)** The Kerberos SSO extension gets tickets from your domain controllers without binding.

</details>




---

## 06 Configuration profiles

*18 min*

*Profiles are Group Policy for Macs: they deliver settings that users can't change.*

### What profiles can configure
In Intune, create them under **Devices → Configuration → Create → macOS**. Most settings are in the **Settings catalog**; some use **templates**; anything else can be uploaded as a **custom** `.mobileconfig`.

| Area | Examples |
|---|---|
| **Security** | Firewall on with stealth mode, Gatekeeper, screen saver password, auto-lock |
| **Restrictions** | Block AirDrop, iCloud Drive, external storage, password autofill, Apple Intelligence features |
| **Login and setup** | Login window message, show name and password fields, disable guest account |
| **Network** | Wi-Fi (with certificates), VPN, 802.1X, proxy |
| **Certificates** | Trusted root, SCEP, PKCS (as on mobile) |
| **Privacy (PPPC)** | Full Disk Access and other permissions for security and management tools |
| **System extensions** | Allow specific team IDs and extensions (antivirus, VPN) |
| **Managed login items** | Background items users can't turn off (management and security agents) |
| **Software Update** | Declarative update enforcement (Module 8) |
| **App preferences** | Preference files for Microsoft 365 apps, Edge, Chrome, and others |

### Profiles vs. declarations
Apple is moving configuration to **Declarative Device Management**. Some areas (software updates, and in macOS 27 many network settings) are declarations; your MDM handles which format it uses. For you, the workflow is the same: create the setting in Intune and assign it.

### Seeing what's installed on the Mac
- **System Settings → General → Device Management** lists every profile and what it contains.
- In Terminal:
```bash
sudo profiles show -type configuration       # every installed profile and its payloads
sudo profiles list                           # just the identifiers
defaults read "/Library/Managed Preferences/com.apple.applicationaccess"
```

> [!TIP]
> **Good practice: Test before you scope widely**
>
> A wrong profile can lock users out of Wi-Fi or block an app everyone needs. Test on your own Mac or a pilot group first, just like a GPO. Remember that removing the assignment removes the profile from Macs.

### Check yourself

**1. Where can a user see every profile installed by IT?**

- a) System Settings → General → Device Management
- b) Finder → Applications
- c) Activity Monitor

<details><summary>Answer</summary>

**a)** The Device Management pane lists each profile and its settings.

</details>

**2. How do you deploy a setting Intune has no built-in option for?**

- a) You can't
- b) Upload a custom `.mobileconfig` profile
- c) Edit the Mac's registry

<details><summary>Answer</summary>

**b)** Custom profiles let you deliver any payload Apple supports.

</details>




---

## 07 Apps and scripts

*18 min*

*Getting software onto Macs without making users admins.*

### App types in Intune

| Type | Use it for |
|---|---|
| **Microsoft 365 apps for macOS** | Word, Excel, Outlook, Teams, and the rest, plus Microsoft AutoUpdate |
| **Microsoft Edge, Defender** | Built-in app types |
| **App Store apps (Apps and Books)** | Licensed from Apple Business, installed silently on supervised Macs |
| **macOS app (PKG)** | Any installer package, signed by a developer; can run pre- and post-install scripts |
| **macOS app (DMG)** | Apps distributed as a disk image containing a `.app` |
| **Line-of-business (PKG)** | Older type for signed PKGs |
| **Web clip** | A shortcut to a website |

### Detection
Intune checks whether an app is installed using its **bundle ID** and **version**. Find them on a Mac that already has the app:
```bash
defaults read /Applications/zoom.us.app/Contents/Info.plist CFBundleIdentifier
defaults read /Applications/zoom.us.app/Contents/Info.plist CFBundleShortVersionString
pkgutil --pkgs | grep -i zoom                 # receipts from PKG installs
```

### Shell scripts and custom attributes
- **Shell scripts** (Intune → Devices → macOS → Shell scripts) run on the Mac through the Intune management agent: as root or as the signed-in user, once or on a schedule. Use them for tasks profiles can't do: setting a computer name from the serial number, installing a font, cleaning up an old app.
- **Custom attributes** are scripts that **report** a value (an app version, whether a setting is on) into the device record in Intune.

```bash
#!/bin/zsh
# Example shell script: name the Mac after its serial number
serial=$(system_profiler SPHardwareDataType | awk '/Serial Number/{print $4}')
scutil --set ComputerName "MAC-$serial"
scutil --set LocalHostName "MAC-$serial"
scutil --set HostName "MAC-$serial"
```

Intune agent logs are in `/Library/Logs/Microsoft/Intune/` (system) and `~/Library/Logs/Microsoft/Intune/` (user). Jamf's equivalent is `/var/log/jamf.log`.

### Keeping apps updated
Patching third-party apps is a large part of Mac work. Options include **Microsoft AutoUpdate** for Microsoft apps, apps' own updaters, the App Store for Apps and Books apps, open-source tools such as **Installomator** (a script that downloads and installs the current version of hundreds of apps), and your MDM's patch management features.

### Check yourself

**1. How does Intune decide whether a macOS app is installed?**

- a) By its bundle ID and version
- b) By the file size of the installer
- c) By the app's icon

<details><summary>Answer</summary>

**a)** Intune compares the bundle ID and version reported by the Mac with the app's detection settings.

</details>

**2. Where are the Intune agent's logs on a Mac?**

- a) `C:\ProgramData\Microsoft\IntuneManagementExtension`
- b) `/Library/Logs/Microsoft/Intune/`
- c) `/System/Library/Intune`

<details><summary>Answer</summary>

**b)** System-level logs are in `/Library/Logs/Microsoft/Intune/`; user-context logs are under `~/Library/Logs`.

</details>




---

## 08 macOS updates

*14 min*

*Keeping Macs current without surprising users, now that Apple requires declarative updates.*

### The update model
- Apple releases **minor updates** (27.0.1, 27.1) and **Rapid Security Responses / background security fixes** throughout the year, and **major upgrades** each fall.
- Starting with macOS 27, legacy MDM software update commands and settings no longer work. Update management uses **Declarative Device Management** declarations: you set a **target version**, a **deadline**, and optionally a **deferral** for major or minor updates.
- On Apple silicon, the **bootstrap token** lets MDM-initiated updates install without a user entering an admin password.

### In Intune
1. **Settings catalog → Declarative Device Management → Software Update:** set the **target OS version** and **target date/time**. Before the deadline, users get notifications and can update at a convenient time; at the deadline, the Mac installs and restarts.
2. **Settings catalog → Restrictions:** **defer** major and minor updates (up to 90 days) to give yourself time to test, or hide major upgrades until you're ready.
3. Use **update rings** with groups: IT first, then a pilot, then everyone.

```bash
softwareupdate --list                         # available updates
softwareupdate --history | head               # what was installed, and when
sudo profiles show -type configuration | grep -i -A3 softwareupdate
```

> [!TIP]
> **Good practice: Major upgrades**
>
> Before allowing a new major macOS version, check that your security tools, VPN, and key apps support it. Vendors usually publish compatibility notes in September. Many organizations defer major upgrades 30 to 90 days.

### Check yourself

**1. What changed for MDM software update management in macOS 27?**

- a) Legacy MDM update commands stopped working; updates must be managed with declarations
- b) Updates can no longer be enforced at all
- c) Apple stopped releasing minor updates

<details><summary>Answer</summary>

**a)** Declarative Device Management is now the only supported way to enforce updates.

</details>

**2. How long can MDM defer macOS updates?**

- a) 7 days
- b) Up to 90 days
- c) 1 year

<details><summary>Answer</summary>

**b)** Deferrals of up to 90 days give time to test before updates appear to users.

</details>




---

## 09 FileVault and data protection

*16 min*

*FileVault protects data on a lost Mac. Recovery keys are what make it safe to turn on.*

### FileVault basics
**FileVault** encrypts the Data volume. On Apple silicon and T2 Macs, the storage is always hardware-encrypted; FileVault adds the requirement to enter a password at startup, so the data can't be read without it.

### Turning it on through MDM
In Intune: **Endpoint security → Disk encryption → Create policy → macOS → FileVault** (or the Settings catalog):
- **Enable FileVault**
- **Escrow the personal recovery key** to Intune, and **hide** it from the user
- **Defer** enablement until the user signs in or out (FileVault needs a user with a secure token)
- **Rotate the recovery key** periodically and after it's used

The recovery key then appears in Intune on the device's **Recovery keys** page, and users can retrieve their own from the Company Portal website.

### Secure tokens and volume owners
Only users with a **secure token** (on Apple silicon, also **volume owners**) can unlock FileVault, approve some changes, and enable other users. The first account created on the Mac gets one automatically. If the MDM has escrowed a **bootstrap token**, it can grant secure tokens to accounts created later (such as Platform SSO accounts).

```bash
fdesetup status                               # FileVault on?
sudo fdesetup list                            # users who can unlock it
sudo sysadminctl -secureTokenStatus jsmith
sudo profiles status -type bootstraptoken     # escrowed to MDM?
diskutil apfs listCryptoUsers /               # crypto users on the startup volume
```

### When a user forgets their password
1. Get the **personal recovery key** from Intune (**Devices → the Mac → Recovery keys**) after verifying the user's identity.
2. At the login window, enter the wrong password a few times, or click **?** and choose to reset using the recovery key.
3. Have the user set a new password. If they use password sync with Platform SSO, the password follows Entra ID.
4. **Rotate** the key afterward so the used key no longer works.

### Other data protection
- Back up user data to **OneDrive** (Known Folder Move for Mac redirects Desktop and Documents) or another approved service. Block personal iCloud Drive if policy requires.
- Control removable storage and data sharing with a DLP or endpoint security tool (Microsoft Defender for Endpoint on Mac has device control).

### Check yourself

**1. Why must the FileVault recovery key be escrowed to MDM?**

- a) So IT can unlock the Mac if the user forgets their password or leaves
- b) So FileVault runs faster
- c) It's required for Gatekeeper

<details><summary>Answer</summary>

**a)** Without an escrowed key, a forgotten password can mean the data is lost.

</details>

**2. Which users can unlock a FileVault-encrypted Mac?**

- a) Any local user
- b) Users with a secure token (volume owners on Apple silicon)
- c) Only root

<details><summary>Answer</summary>

**b)** Secure token users are added to FileVault. The bootstrap token helps grant tokens to later accounts.

</details>




---

## 10 Terminal troubleshooting toolkit

*18 min*

*The commands you'll actually use when a managed Mac misbehaves.*

### Management state

| Question | Command |
|---|---|
| Is it enrolled? ADE? User approved? | `sudo profiles status -type enrollment` |
| Which profiles are installed? | `sudo profiles show -type configuration` |
| Is the bootstrap token escrowed? | `sudo profiles status -type bootstraptoken` |
| Force an MDM check-in | Company Portal → **Check settings**, or Intune → device → **Sync** |
| What is the MDM client doing? | `log show --last 1h --predicate 'process == "mdmclient"'` |
| Device details the MDM sees | `sudo /usr/libexec/mdmclient QueryDeviceInformation` |
| Jamf: run policies / update inventory | `sudo jamf policy` / `sudo jamf recon` |

### System and hardware

| Question | Command |
|---|---|
| macOS version | `sw_vers` |
| Model, chip, serial, memory | `system_profiler SPHardwareDataType` |
| Disk space | `df -h /` or `diskutil info /` |
| What's using CPU or memory | `top -o cpu` (or Activity Monitor) |
| Uptime | `uptime` |
| Installed packages | `pkgutil --pkgs` |
| Apps installed and versions | `system_profiler SPApplicationsDataType` |

### Network

| Question | Command |
|---|---|
| IP addresses | `ipconfig getifaddr en0` or `ifconfig` |
| DNS servers in use | `scutil --dns \| grep nameserver` |
| Test name resolution | `dscacheutil -q host -a name app01.lab.local` |
| Flush DNS cache | `sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder` |
| Test a port | `nc -vz app01.lab.local 445` |
| Wi-Fi details | Hold **⌥** and click the Wi-Fi icon |
| Kerberos tickets | `klist` (Kerberos SSO extension: `app-sso -l`) |

### Collecting logs for support
```bash
sudo sysdiagnose           # full diagnostic bundle (can take several minutes)
```
For Intune, **Company Portal → Help → Save diagnostic report** or use **Collect diagnostics** from the device record.

### Recovery and reinstalling
- **macOS Recovery:** on Apple silicon, hold the **power button** until "Loading startup options" appears, then choose **Options**. From there: Disk Utility, Reinstall macOS, Terminal, Startup Security Utility.
- **Erase All Content and Settings** (System Settings → General → Transfer or Reset) quickly returns the Mac to factory state while keeping macOS installed. ADE Macs re-enroll on the next setup.
- **Remote wipe** from Intune does the same from the console.

### Check yourself

**1. How do you flush DNS on a Mac?**

- a) `sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder`
- b) `ipconfig /flushdns`
- c) `scutil --dns`

<details><summary>Answer</summary>

**a)** macOS caches DNS in mDNSResponder; both commands together clear it.

</details>

**2. How do you open macOS Recovery on an Apple silicon Mac?**

- a) Hold Command-R at startup
- b) Hold the power button until startup options appear
- c) Press F8

<details><summary>Answer</summary>

**b)** Command-R was the Intel method. Apple silicon uses a long press of the power button.

</details>




---

## 11 Help desk playbook and lifecycle

*16 min*

*Common Mac tickets, and handling a Mac from purchase to retirement.*

| Ticket | Check | Fix |
|---|---|---|
| New Mac didn't show Remote Management during setup | Serial in Apple Business and assigned to Intune? Enrollment profile assigned? | Assign it, then erase and run setup again (or `sudo profiles renew -type enrollment`) |
| App not installing | Intune app status; agent logs; is the app signed? | Fix detection rules or the package; check `/Library/Logs/Microsoft/Intune` |
| "This setting is managed by your organization" | Expected: a profile sets it | Change the profile if the setting is wrong |
| Antivirus or VPN asks for permissions | PPPC and system extension profiles missing or mis-scoped | Assign the vendor's recommended profiles before installing the app |
| Forgot password, FileVault enabled | Recovery key in Intune | Reset with the recovery key, then rotate it |
| Can't reach the file server | Network, DNS, Kerberos SSO extension, `klist` | Check VPN or network, refresh Kerberos credentials |
| Mac is slow | Activity Monitor, free disk space, login items | Clear space; remove unneeded login items; check for a runaway process |
| Outlook or Teams sign-in loops | Platform SSO registration; Company Portal; keychain | Re-register Platform SSO from System Settings → Users & Groups; check Company Portal |
| Can't update macOS | Disk space, deferral and target version, bootstrap token | Fix deferral and target settings; free space |

### Lifecycle
1. **Purchase** through Apple or an authorized reseller with your Apple Business organization ID, so serials appear automatically.
2. **Assign** to Intune in Apple Business (or set Intune as the **default MDM server** for new Macs).
3. **Ship** the Mac sealed to the user. They unbox it and sign in; ADE does the rest (zero-touch).
4. **Run:** updates by deadline, apps through Company Portal, compliance through Intune and Conditional Access.
5. **Reassign:** wipe from Intune; the next user goes through Setup Assistant again.
6. **Retire:** wipe, confirm **Activation Lock** is off (Intune can escrow an Activation Lock bypass code for supervised Macs), **release** the Mac from Apple Business, delete it from Intune and Entra ID, update the [asset inventory](../helpdesk/asset-inventory).

### A weekend lab plan
1. Enroll a Mac or macOS VM in your trial tenant through **Company Portal** (device enrollment), and approve the profile.
2. Deploy: a restrictions profile, firewall, a FileVault policy with key escrow, Microsoft 365 apps, Edge, and a PPPC profile for Defender.
3. Add a shell script that names the Mac and a custom attribute that reports FileVault status.
4. Configure Platform SSO with the Secure Enclave key, sign out and in, and open Outlook without a password prompt.
5. Retrieve the FileVault recovery key from Intune, use it to reset the password, then rotate it.
6. Write two [KB articles](../helpdesk/knowledge-base): "Mac password reset with FileVault" and "Mac won't enroll."

### Check yourself

**1. A company Mac was erased and given to a new employee. What happens at setup if it's assigned in Apple Business?**

- a) It shows Remote Management and enrolls in Intune automatically
- b) It must be reimaged first
- c) IT has to install the Intune agent manually

<details><summary>Answer</summary>

**a)** ADE assignments survive erasing, so the Mac re-enrolls during Setup Assistant.

</details>

**2. What's the last step before selling an old company Mac?**

- a) Delete it from Intune only
- b) Wipe it, clear Activation Lock, and release it from Apple Business
- c) Turn off FileVault

<details><summary>Answer</summary>

**b)** Releasing it from Apple Business stops the next owner being enrolled into your organization.

</details>




---

*Written in plain language from Apple's Platform Deployment and Platform Security guides and Microsoft Intune documentation, current as of October 2026 (macOS 27). Apple changes management features every year. Check Apple's documentation and your MDM vendor's notes before changing production settings.*
