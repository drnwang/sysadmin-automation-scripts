# Intune and Windows Autopilot

Deploy and manage Windows 11 from the cloud: register a VM with **Autopilot**, have it set itself up when a user signs in, push compliance rules, BitLocker, update rings, and apps with **Intune**, then require a compliant device to reach Microsoft 365. You'll finish by practicing the device tasks help desks handle every day, like retrieving a BitLocker recovery key and resetting a laptop for its next user.

> **Status:** tutorial ready. Results and screenshots to be added after the lab is run.

| | |
|---|---|
| **Role** | Help desk, desktop support, sysadmin |
| **Time** | 1–2 weekends |
| **Cost** | Uses the same trial tenant as the [Microsoft 365 lab](../m365-admin/) |
| **Builds on** | [Microsoft 365 admin lab](../m365-admin/) (users, break-glass account, Conditional Access) |
| **Resume keywords** | Intune, Windows Autopilot, Microsoft Entra join, compliance policies, BitLocker, Win32 apps, update rings, Conditional Access |

## Why this matters

Microsoft retired the Microsoft Deployment Toolkit (MDT) in January 2026. **Autopilot + Intune** is now Microsoft's main path for deploying Windows, and Intune appears in most desktop support and sysadmin postings. Your resume already lists Intune and Autopilot, and this lab gives you fresh, current hands-on experience to back it up.

---

## Part 1: Prepare the tenant

### 1.1 Turn on automatic enrollment
**Intune admin center → Devices → Enrollment → Windows → Automatic Enrollment** (this opens the Entra setting):
- **MDM user scope: All**
- **MAM user scope: None**

> This makes any device a user joins to Entra ID enroll in Intune automatically.

### 1.2 Create groups
In the **Entra admin center → Groups → New group**:

| Group | Type | Membership |
|---|---|---|
| `SG-Autopilot-Devices` | Security | **Dynamic device**, rule: `(device.devicePhysicalIDs -any (_ -contains "[ZTDId]"))` |
| `SG-Intune-Pilot-Users` | Security | Assigned: Jane, Carlos |

> The dynamic rule automatically adds **every device registered with Autopilot**. You'll target your Autopilot profile at this group.

---

## Part 2: Create the Windows 11 VM and register it

1. Create a new VM `AP01`: **Generation 2**, **TPM enabled**, 2 vCPU, 4 GB RAM, 64 GB disk, connected to a network with **internet access**. It doesn't need the `lab.local` domain.
2. Boot from the **Windows 11 Enterprise** ISO and install, but **stop at the first OOBE screen** (the region selection). Don't finish setup.
3. Press **Shift + F10** to open a command prompt, then:
   ```cmd
   powershell
   ```
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
   Install-Script -Name Get-WindowsAutopilotInfo -Force
   Get-WindowsAutopilotInfo -Online
   ```
4. Sign in as your **admin** when prompted, and consent to the permissions. The script uploads the VM's **hardware hash** to Autopilot.

> **Alternative without signing in on the device:** run `Get-WindowsAutopilotInfo -OutputFile C:\hwid.csv`, copy the file off, and import it in **Intune → Devices → Enrollment → Windows → Devices (Windows Autopilot) → Import**. That's how OEMs and resellers register devices at scale.

### ✅ Check your work
**Intune → Devices → Enrollment → Windows → Devices** lists the VM's serial number. Within about 15 minutes it also appears in `SG-Autopilot-Devices`.

Leave the VM at the OOBE screen. Don't sign in yet.

---

## Part 3: Autopilot profile and Enrollment Status Page

### 3.1 Deployment profile
**Intune → Devices → Enrollment → Windows → Deployment profiles → Create profile → Windows PC**:

| Setting | Value |
|---|---|
| Name | `LAB - User-driven` |
| Convert all targeted devices to Autopilot | No |
| Deployment mode | **User-Driven** |
| Join to Microsoft Entra ID as | **Microsoft Entra joined** |
| Privacy settings, license terms | **Hide** |
| User account type | **Standard** (users aren't local admins) |
| Apply device name template | Yes: `LAB-%RAND:5%` |
| Assignments | `SG-Autopilot-Devices` |

### 3.2 Enrollment Status Page (ESP)
**Intune → Devices → Enrollment → Windows → Enrollment Status Page** → edit the default (or create one):
- **Show app and profile configuration progress: Yes**
- **Block device use until all apps and profiles are installed: Yes**

> The ESP keeps the user on a progress screen until required apps and policies are in place, so they never get a half-configured laptop.

### ✅ Check your work
The device's **Profile status** shows **Assigned** in the Autopilot devices list. Wait for it before Part 7.

---

## Part 4: Compliance policy

**Intune → Devices → Compliance → Create policy → Windows 10 and later**:

| Category | Setting |
|---|---|
| Device Health | Require **BitLocker**, **Secure Boot**, **Code integrity** |
| Device Properties | Minimum OS version: a recent Windows 11 build |
| System Security | Require a password; **Firewall**: Require; **Antivirus**: Require; **Microsoft Defender Antimalware**: Require |
| Actions for noncompliance | Mark device noncompliant **immediately** (lab), or after a grace period (production) |
| Assignments | All users |

---

## Part 5: Configuration profiles and update rings

### 5.1 BitLocker
**Intune → Endpoint security → Disk encryption → Create policy → Windows → BitLocker**:
- **Require device encryption: Enabled**
- **Allow warning for other disk encryption: Disabled** (enables silent encryption)
- OS drive: **Save BitLocker recovery information to Microsoft Entra ID: Enabled**, and require it before encryption starts

Assign to `SG-Autopilot-Devices`.

### 5.2 Screen lock
**Devices → Configuration → Create → Windows 10 and later → Settings catalog** → search **Device Lock** → set the maximum inactivity before lock to **15 minutes**. Assign to `SG-Autopilot-Devices`.

### 5.3 Update rings
**Devices → Windows updates → Update rings → Create profile**:

| Ring | Quality update deferral | Assign to |
|---|---|---|
| `Ring 1 - Pilot` | 0 days | `SG-Intune-Pilot-Users` |
| `Ring 2 - Broad` | 7 days | All users, excluding the pilot group |

> Same idea as the [WSUS lab](../../windows/wsus-patching/)'s pilot and production rings, without a server to maintain.

---

## Part 6: Deploy apps

### 6.1 Microsoft 365 Apps
**Apps → Windows → Add → Microsoft 365 Apps (Windows 10 and later)** → select Word, Excel, Outlook, Teams, and others → **Required** for `SG-Autopilot-Devices`.

### 6.2 A Win32 app (7-Zip)
Intune installs traditional `.msi` and `.exe` software as **Win32 apps**, wrapped in an `.intunewin` package.

1. On any Windows PC, download the **7-Zip** 64-bit `.msi` into `C:\IntuneSrc\7zip`.
2. Download the **Microsoft Win32 Content Prep Tool** (`IntuneWinAppUtil.exe`) from Microsoft's GitHub.
3. Package it:
   ```cmd
   IntuneWinAppUtil.exe -c C:\IntuneSrc\7zip -s 7z-x64.msi -o C:\IntuneOut
   ```
4. **Apps → Windows → Add → Windows app (Win32)** → upload the `.intunewin`:

| Setting | Value |
|---|---|
| Install command | `msiexec /i "7z-x64.msi" /qn` (filled in automatically for MSIs) |
| Uninstall command | Filled in automatically from the MSI's product code |
| Install behavior | System |
| Requirements | 64-bit, Windows 11 |
| Detection rule | **MSI** product code (automatic) |
| Assignments | **Required** for `SG-Autopilot-Devices` |

---

## Part 7: Run Autopilot

1. Return to the **AP01** VM, still at OOBE. Restart it so it downloads the Autopilot profile.
2. Pick region and keyboard if asked. The branded sign-in page appears with your tenant name.
3. Sign in as **Jane** (`jsmith@labnwang.onmicrosoft.com`), completing MFA setup if prompted.
4. Watch the **Enrollment Status Page**: device preparation, device setup (policies, apps), then account setup.
5. Jane lands on a desktop with Microsoft 365 Apps and 7-Zip installed, BitLocker turning on, and a name like `LAB-4K2QZ`.

### ✅ Check your work
In **Intune → Devices → All devices**, the device shows:
- **Compliance: Compliant** (it can take a little while after BitLocker finishes)
- **Primary user: Jane Smith**
- **Device configuration** and **Managed apps**: all succeeded

📸 Screenshots: the ESP in progress, the device's Intune overview, compliance status

---

## Part 8: Require compliant devices for Microsoft 365

1. **Entra → Protection → Conditional Access → Create new policy**:

| Setting | Value |
|---|---|
| Name | `CA03 - Require compliant device for Office 365` |
| Users | `SG-Intune-Pilot-Users`; **exclude** break-glass |
| Target resources | **Office 365** |
| Grant | **Require device to be marked as compliant** |
| Enable policy | Report-only, then **On** |

2. Test: as Jane, Outlook on **AP01** works. Signing in as Jane from a personal browser on your PC is **blocked**, because that device isn't managed.

---

## Part 9: Practice help desk device tasks

| Task | Where |
|---|---|
| Force a device to check in now | Device → **Sync** |
| **Find a BitLocker recovery key** (very common call) | Device → **Recovery keys** → *Show recovery key* |
| Reset a laptop for its next user, keeping enrollment | Device → **Autopilot Reset** (or **Fresh Start**) |
| Remove company data only (BYOD) | Device → **Retire** |
| Lost or stolen laptop | Device → **Wipe** |
| Why is this device noncompliant? | Device → **Device compliance** → the failing setting |
| Collect logs from a device | Device → **Collect diagnostics** |

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| Profile status stays *Not assigned* | Check that the device is in `SG-Autopilot-Devices` (dynamic groups can take time) and that the profile is assigned to it |
| OOBE doesn't show the company sign-in page | The profile wasn't downloaded yet. Restart at OOBE after the profile shows *Assigned*. |
| Enrollment fails with an MDM error | Automatic enrollment scope (1.1); the user needs an Intune license |
| ESP stuck on an app | That app's install is failing. Check **Apps → (app) → Device install status**. |
| On the device: where are the logs? | Event Viewer → **Applications and Services Logs → Microsoft → Windows → DeviceManagement-Enterprise-Diagnostics-Provider → Admin**; or run `mdmdiagnosticstool.exe -area Autopilot -cab C:\autopilot.cab` |

## How to talk about it in an interview

> *"I set up Windows Autopilot with a user-driven, Entra-joined profile and an Enrollment Status Page, registered a device by hardware hash, and watched it configure itself at first sign-in. In Intune I built compliance policies, silent BitLocker with keys escrowed to Entra ID, update rings, and Win32 app packaging. Then I required compliant devices for Office 365 with Conditional Access. I also practiced recovery-key lookups, Autopilot Reset, retire, and wipe."*

## Results

_To be added after the lab is run:_
- [ ] Screenshots: Autopilot device registration, ESP, compliant device, BitLocker key in Intune, blocked sign-in from an unmanaged device
- [ ] Notes on what failed the first time and how you fixed it
