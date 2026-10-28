# Managing Mobile Devices

*Self-study course · iPhone, iPad, and Android*

Twelve modules on managing company and personal phones and tablets with Microsoft Intune. It covers how MDM works, Apple Business and Automated Device Enrollment, Android Enterprise, configuration, apps, compliance, app protection for BYOD, updates, and day-to-day support. Each module ends with a short self-check.

**Total:** about 3½ hours · **Tool:** Microsoft Intune · **Lab:** your M365 trial tenant + a test phone

> Each module ends with a self-check. Open each answer to see the explanation.

## Contents

0. [Why and how phones are managed](#00-why-and-how-phones-are-managed) (14 min)
1. [How MDM works under the hood](#01-how-mdm-works-under-the-hood) (16 min)
2. [Connecting Apple to Intune](#02-connecting-apple-to-intune) (18 min)
3. [Enrolling iPhones and iPads](#03-enrolling-iphones-and-ipads) (18 min)
4. [Android Enterprise enrollment](#04-android-enterprise-enrollment) (18 min)
5. [Configuring devices](#05-configuring-devices) (18 min)
6. [Apps](#06-apps) (18 min)
7. [Compliance and Conditional Access](#07-compliance-and-conditional-access) (18 min)
8. [App protection for personal devices](#08-app-protection-for-personal-devices) (16 min)
9. [Updates and device lifecycle](#09-updates-and-device-lifecycle) (18 min)
10. [Mobile security](#10-mobile-security) (14 min)
11. [Help desk playbook and lab plan](#11-help-desk-playbook-and-lab-plan) (16 min)

---

## 00 Why and how phones are managed

*14 min*

*Before choosing any settings, you decide who owns the device and how much control the company needs.*

Phones carry company email, files, Teams chats, and MFA prompts. If one is lost, stolen, or kept by someone who left, IT needs to protect that data. Mobile management does three jobs:
1. **Set up** devices with the right apps, Wi-Fi, email, and restrictions.
2. **Protect** company data: passcodes, encryption, blocking copy-paste into personal apps, wiping company data.
3. **Prove** devices are safe before they reach company resources (compliance and Conditional Access).

### Three approaches

| Approach | What IT controls | Typical use |
|---|---|---|
| **MDM** (mobile device management) | The whole device: settings, apps, wipe | Company-owned phones and tablets |
| **MAM** (mobile application management, *app protection*) | Only company data inside specific apps (Outlook, Teams, OneDrive). No device enrollment. | Personal phones (BYOD) where users won't accept full management |
| **UEM** (unified endpoint management) | MDM + MAM for phones, laptops, and desktops in one tool | Intune, Jamf, Workspace ONE, Ivanti, and others |

### Ownership models
Your settings start from who owns the device:

| Model | Owner | Control | Android name | Apple equivalent |
|---|---|---|---|---|
| **Corporate-owned, business only** | Company | Full | Fully managed | Supervised device (Automated Device Enrollment) |
| **Corporate-owned, personally enabled** | Company | Full on work side, light on personal side | Corporate-owned work profile | Supervised device with personal use allowed |
| **Personally owned (BYOD)** | Employee | Only the work container or apps | Personally owned work profile | Account-driven User Enrollment, or app protection only |
| **Dedicated / kiosk** | Company | Locked to one or a few apps | Dedicated device | Single App Mode, Shared iPad |

> [!TIP]
> **Good practice: Privacy is part of the design**
>
> On a personal device, IT generally **can't** see personal apps, photos, messages, location history, or browsing, and can only wipe the work data. Telling users this clearly (Intune's Company Portal has a "What can my organization see?" screen) makes them far more willing to enroll.

> [!TIP]
> **In your lab**
>
> You'll use the Microsoft 365 Business Premium trial from your [Microsoft 365 labs](../m365) (it includes Intune), plus any spare iPhone, iPad, or Android device. For Android without hardware, the **Android Studio emulator** with a Google Play system image supports work profiles. iPhones can't be emulated.

### Check yourself

**1. A contractor refuses to enroll their personal phone but needs Outlook and Teams. What's the right approach?**

- a) Full MDM enrollment
- b) App protection (MAM) without enrollment
- c) Block them entirely

<details><summary>Answer</summary>

**b)** App protection secures company data inside managed apps without managing the device.

</details>

**2. What's the Android name for a company-owned phone used only for work?**

- a) Fully managed
- b) Personally owned work profile
- c) Dedicated

<details><summary>Answer</summary>

**a)** Fully managed devices are company-owned and entirely under IT control. Dedicated devices are single-purpose kiosks.

</details>




---

## 01 How MDM works under the hood

*16 min*

*Knowing how a phone talks to Intune explains most "the setting didn't apply" problems.*

### The check-in model
A managed phone doesn't keep an open connection to Intune. Instead:
1. Intune has something new for a device (a policy, an app, a wipe command).
2. Intune asks the platform's **push service** to wake the device: **Apple Push Notification service (APNs)** for Apple devices, **Firebase Cloud Messaging (FCM)** for Android.
3. The device receives the push and **checks in** with Intune over HTTPS.
4. Intune sends commands; the device applies them and reports results.

Devices also check in on a schedule (roughly every 8 hours after the first few hours following enrollment), and users can force it from Company Portal (**Check status** / **Sync**). If push traffic is blocked on a network, devices only update on their schedule.

### Apple: profiles, commands, and declarations
Apple's MDM protocol has three building blocks:
- **Configuration profiles** (`.mobileconfig`): bundles of settings (Wi-Fi, VPN, email, restrictions).
- **Commands:** actions like install an app, lock, erase, or query device information.
- **Declarative Device Management (DDM):** the newer model. The server sends **declarations** describing the desired state, and the device enforces them on its own and **reports status changes** back, instead of the server polling.

DDM is now required for some features. Starting with iOS, iPadOS, and macOS 27, Apple removed the legacy MDM commands for **software updates**, so OS update enforcement must use declarations (Module 9).

### Android: Android Enterprise
Google's management framework is **Android Enterprise**. Intune connects to it by linking your tenant to a **Managed Google Play** account. Devices run Google's **Android Device Policy** app (fully managed, dedicated, corporate work profile) or **Company Portal** (personal work profile), and receive policy through Google's **Android Management API** or Intune's own agent, depending on the enrollment type.

The old **device administrator** method is deprecated by Google. Intune ended device administrator management for devices with Google Mobile Services at the end of 2024. Everything new uses Android Enterprise.

### Device identity in Entra ID
When a device enrolls in Intune, it's also **registered** in Microsoft Entra ID. That's how Conditional Access can check "is this device compliant?" at sign-in (Module 7). The device record has two halves, the Intune object and the Entra object, linked by a device ID.

### Check yourself

**1. How does Intune tell an iPhone it has new work to do?**

- a) It opens a permanent VPN to the phone
- b) It sends a push through Apple Push Notification service, and the phone checks in
- c) It emails the user

<details><summary>Answer</summary>

**b)** Push wakes the device, which then connects to Intune over HTTPS to fetch commands and policies.

</details>

**2. What is Declarative Device Management?**

- a) A model where the device enforces a declared desired state and reports changes itself
- b) A legacy Android enrollment method
- c) A type of VPN profile

<details><summary>Answer</summary>

**a)** DDM lets Apple devices act on declarations and report status asynchronously. Apple now requires it for software update management.

</details>

**3. Which Android management method is deprecated?**

- a) Android Enterprise work profile
- b) Device administrator
- c) Fully managed

<details><summary>Answer</summary>

**b)** Google deprecated device administrator. Use Android Enterprise enrollment types.

</details>




---

## 02 Connecting Apple to Intune

*18 min*

*Three connections must be in place before Apple devices can be managed well. One of them expires every year.*

### 1. The Apple MDM push certificate
Intune needs an **APNs certificate** to send pushes to Apple devices. You create it at Apple's Push Certificates Portal with an Apple Account, then upload it to Intune: **Intune admin center → Devices → Enrollment → Apple → Apple MDM Push certificate**.

> [!WARNING]
> **Watch out: The yearly renewal trap**
>
> The push certificate expires every **365 days**. It must be **renewed** (not replaced) with the **same Apple Account** that created it. If it expires, or someone creates a new one with a different account, every enrolled Apple device stops receiving commands and must be **re-enrolled**. Use a shared company account (like `mdm-apple@company.com`), document it, and set calendar reminders well before expiry.

### 2. Apple Business
**Apple Business** (launched April 2026) is Apple's free portal for organizations, replacing **Apple Business Manager**, Apple Business Essentials, and Apple Business Connect. (Schools use **Apple School Manager**.) It's where you:
- see every device your company **bought from Apple or an authorized reseller**, linked to your organization by serial number,
- assign those devices to your **MDM server** (Intune) for **Automated Device Enrollment** (ADE),
- buy apps and books in volume (**Apps and Books**, formerly VPP),
- create **Managed Apple Accounts** for employees, often automatically by **federating with Microsoft Entra ID**, so users sign in with their work credentials.

Apple Business also includes its own basic built-in device management for small businesses. Organizations using Intune keep Intune as the MDM and use Apple Business for devices, apps, and accounts.

Devices bought elsewhere can be added to Apple Business with **Apple Configurator** (the iPhone app for iPhones and Macs, or the Mac app for iPhones and iPads). Devices added this way have a **30-day provisional period** during which the user can remove them.

### 3. The tokens in Intune
- **Enrollment program token (ADE):** download a public key from Intune, upload it in Apple Business when creating an MDM server, then upload the server token Apple gives you back to Intune. Renew yearly.
- **Apps and Books location token** (`.vpptoken`): download from Apple Business, upload to **Intune → Tenant administration → Connectors and tokens → Apple VPP tokens**. Renew yearly.

| Connection | Where | Renew |
|---|---|---|
| APNs certificate | Apple Push Certificates Portal → Intune | Every year, same Apple Account |
| ADE token | Apple Business ↔ Intune | Every year |
| Apps and Books token | Apple Business → Intune | Every year |

> [!TIP]
> **Good practice: Put the expiry dates somewhere visible**
>
> Intune shows warnings in **Tenant administration → Connectors and tokens**, but many outages happen because nobody looked. Put all three dates in a shared calendar and in your [monitoring](../infrastructure/monitoring-prtg) or ticket system.

> [!TIP]
> **In your lab**
>
> In your trial tenant, create the APNs certificate with a dedicated Apple Account and upload it. Signing up for Apple Business requires a real organization with a D-U-N-S number, so skip that in the lab; you can still practice every enrollment that doesn't use ADE.

### Check yourself

**1. The APNs certificate was renewed with a different Apple Account. What happens?**

- a) Nothing; any Apple Account works
- b) Existing Apple devices lose management and must re-enroll
- c) Only new devices are affected

<details><summary>Answer</summary>

**b)** The push certificate must be renewed with the same Apple Account, or the link to existing devices breaks.

</details>

**2. What does Apple Business do in an Intune setup?**

- a) Links company-purchased devices to Intune for automated enrollment, provides volume app licenses, and Managed Apple Accounts
- b) Replaces Intune as the policy engine
- c) Hosts users' iCloud backups

<details><summary>Answer</summary>

**a)** Intune remains the MDM. Apple Business supplies devices, app licenses, and accounts.

</details>

**3. A company bought iPads from a retail store. How can they still use Automated Device Enrollment?**

- a) They can't, ever
- b) Add them to Apple Business with Apple Configurator
- c) Ask users to send in serial numbers by email

<details><summary>Answer</summary>

**b)** Apple Configurator adds devices manually, with a 30-day provisional period.

</details>




---

## 03 Enrolling iPhones and iPads

*18 min*

*The enrollment method decides how much control you get, so it's chosen per ownership model.*

### Supervision
A **supervised** device is fully owned by the organization. Supervision unlocks many settings that aren't available otherwise: silent app installs, blocking the App Store, preventing removal of the management profile, **Lost Mode**, Single App Mode, web content filters, bypassing **Activation Lock**, and more. Devices enrolled through Automated Device Enrollment are supervised.

### Enrollment methods

| Method | Ownership | Supervised | How it starts |
|---|---|---|---|
| **Automated Device Enrollment (ADE)** | Corporate | Yes | The device contacts Apple during Setup Assistant, finds its MDM assignment, and enrolls automatically |
| **Device enrollment** (Company Portal or web-based) | Corporate or personal | No | User installs Company Portal or visits the enrollment site and installs a profile |
| **Account-driven User Enrollment** | Personal (BYOD) | No | User signs in with their work account in **Settings → VPN & Device Management**; work data goes on a separate, encrypted volume |
| **Apple Configurator** | Corporate | Yes (if prepared) | Prepare devices over USB, often for bulk or kiosk setups |

> [!NOTE]
> **How it works: What ADE looks like for the user**
>
> The user unboxes a new iPhone, picks a language, and connects to Wi-Fi. A **Remote Management** screen appears with the company's name, they sign in with their work account, and the phone sets itself up with apps and settings. The management profile can't be removed, and even after an erase, the phone re-enrolls itself.

### Enrollment profiles for ADE
In **Intune → Devices → Enrollment → Apple → Enrollment program tokens → (token) → Profiles**, an ADE profile controls:
- **User affinity:** enroll *with* user affinity (a personal-use phone signed in to Company Portal) or *without* (shared devices and kiosks).
- **Authentication method:** **Setup Assistant with modern authentication** (recommended), which signs the user in during setup.
- **Locked enrollment:** prevent users removing management.
- **Setup Assistant screens** to skip (Siri, Screen Time, Apple Pay, and others) to make setup faster.
- **Await final configuration:** keeps the user at Setup Assistant until critical policies install.

### Account-driven User Enrollment (BYOD)
For personal iPhones, Apple's privacy-focused option:
- Requires a **Managed Apple Account** (federated with Entra ID through Apple Business).
- The work data lives on a **separate cryptographic volume**. Removing management removes only that volume.
- IT can't see the serial number, the full app list, or personal data, and can't wipe the whole device.
- Intune ended support for the older User Enrollment *with Company Portal*; account-driven User Enrollment is the supported method.

### Enrollment restrictions
**Intune → Devices → Enrollment → Device platform restriction** lets you block personally owned iOS devices, set minimum OS versions, or limit how many devices each user can enroll (the default limit is 5; maximum 15).

### Check yourself

**1. Which enrollment method gives you a supervised iPhone that re-enrolls itself even after being erased?**

- a) Automated Device Enrollment
- b) Device enrollment through Company Portal
- c) Account-driven User Enrollment

<details><summary>Answer</summary>

**a)** ADE devices are tied to the organization in Apple Business, so they enroll and supervise themselves every time Setup Assistant runs.

</details>

**2. What happens to a BYOD iPhone's data when account-driven User Enrollment is removed?**

- a) The whole phone is erased
- b) Only the separate work volume is removed
- c) Nothing is removed

<details><summary>Answer</summary>

**b)** User Enrollment keeps work data on its own encrypted volume, which is deleted when management is removed.

</details>

**3. Which ADE setting keeps users in Setup Assistant until key policies are installed?**

- a) Locked enrollment
- b) Await final configuration
- c) User affinity

<details><summary>Answer</summary>

**b)** It holds the user at the end of setup until critical configuration is applied.

</details>




---

## 04 Android Enterprise enrollment

*18 min*

*Android offers several enrollment types, and choosing the right one for each ownership model matters.*

### Connect Managed Google Play
**Intune → Devices → Enrollment → Android → Managed Google Play** → sign in with a Google account (preferably a company one) and approve. This links your tenant to Android Enterprise and lets you approve apps from Google Play for your organization.

### Enrollment types

| Type | Ownership | What the user sees | How it's enrolled |
|---|---|---|---|
| **Personally owned work profile** | BYOD | A separate **Work** tab in the app drawer; work apps have a briefcase badge | Install Company Portal from Google Play and sign in |
| **Corporate-owned work profile** (COPE) | Corporate, personal use allowed | Personal and work sides; IT controls the device more than with BYOD | QR code, token, or zero-touch during setup |
| **Fully managed** (COBO) | Corporate, work only | One profile, entirely managed | QR code, NFC, token (`afw#setup`), or zero-touch |
| **Dedicated** (COSU, kiosk) | Corporate, single-purpose | Locked to one or a few apps (**Managed Home Screen**) | QR code or token |
| **AOSP** | Corporate | For devices **without** Google Play services (some AR/VR headsets, rugged devices) | QR code |

### Getting company devices enrolled at scale
- **Zero-touch enrollment:** devices bought from participating resellers are registered to your company. On first boot, they enroll themselves, similar to Apple's ADE.
- **Samsung Knox Mobile Enrollment:** the equivalent for Samsung devices.
- **QR code:** on a new or factory-reset device, tap the welcome screen **six times** to open the QR scanner, then scan the code from Intune's enrollment profile.
- **Token:** type `afw#setup` instead of a Google account during setup, then enter the enrollment token.

### Enrollment profiles and tokens
For corporate types, create an enrollment **profile** in **Intune → Devices → Enrollment → Android** under the right section. Each profile produces a **token** and **QR code**. Tokens have an expiration date you choose; shorter is safer. Anyone with the token can enroll a device into your tenant, so treat it like a credential.

> [!TIP]
> **Good practice: Work profile basics users ask about**
>
> - Work apps have a **briefcase** badge and appear in the **Work** tab.
> - Users can **pause** work apps (turn off the work profile) outside work hours, which stops notifications.
> - By default, apps on the two sides can't share data. Copy-paste and contact lookups between them can be allowed or blocked by policy.

### Factory reset protection
Android's **factory reset protection (FRP)** requires the last Google account after a reset, which can lock IT out of returned devices. For corporate devices, set **enterprise FRP** in a device restrictions profile, listing company Google account IDs that can unlock them. Removing the device from Intune first (a **Wipe**) also handles this.

> [!TIP]
> **In your lab**
>
> On a spare Android phone or the Android Studio emulator, install Company Portal and enroll as Jane with a **personally owned work profile**. Look at the Work tab, then pause the work profile. Next, factory reset it and enroll as **fully managed** with a QR code (tap the welcome screen six times).

### Check yourself

**1. A company buys 500 Android phones from a reseller and wants them to enroll on first boot. What do they use?**

- a) Zero-touch enrollment
- b) Personally owned work profile
- c) Device administrator

<details><summary>Answer</summary>

**a)** Zero-touch links devices to the company at purchase so they enroll automatically during setup.

</details>

**2. How do you open the QR enrollment scanner on a new Android device?**

- a) Hold the power button for 10 seconds
- b) Tap the welcome screen six times
- c) Type the token in Chrome

<details><summary>Answer</summary>

**b)** Six taps on the first setup screen launches the QR provisioning flow.

</details>

**3. Which enrollment type is for a single-purpose kiosk tablet?**

- a) Fully managed
- b) Dedicated
- c) Corporate-owned work profile

<details><summary>Answer</summary>

**b)** Dedicated devices run in kiosk mode, typically with Managed Home Screen.

</details>




---

## 05 Configuring devices

*18 min*

*Configuration profiles deliver the settings that make a device ready for work.*

Create profiles in **Intune → Devices → Configuration → Create** and pick the platform. Most settings now live in the **Settings catalog**, a searchable list of everything the platform supports.

### Common profiles

| Profile | Delivers |
|---|---|
| **Device restrictions** | Camera, screenshots, App Store, account changes, AirDrop, USB, Bluetooth, factory reset |
| **Passcode** | Required passcode, length, complexity, auto-lock time, wipe after failed attempts |
| **Wi-Fi** | Company Wi-Fi with WPA2/WPA3-Enterprise and certificate authentication |
| **VPN** | Always-on or per-app VPN (Microsoft Tunnel, or a vendor's client) |
| **Email** | Native Mail app account (most organizations push Outlook instead, Module 6) |
| **Certificates** | **Trusted root** certificates, plus **SCEP** or **PKCS** certificates for Wi-Fi, VPN, and email authentication |
| **Device features (Apple)** | Home Screen layout, notifications, wallpaper, single sign-on extension |
| **Web content filter** | Allow and block lists (supervised Apple devices) |

### Certificates for Wi-Fi and VPN
Using certificates instead of passwords for Wi-Fi and VPN means users never type a network password, and access stops when the device leaves management.
- **SCEP:** the device generates its key and gets a certificate through an **NDES** server (or a cloud PKI) that talks to your CA.
- **PKCS:** Intune's certificate connector requests the certificate on the device's behalf from your CA.
- **Microsoft Cloud PKI** is a cloud CA service that issues SCEP certificates without on-premises servers.

Every certificate profile needs a **trusted root certificate** profile assigned to the same devices first. That ties into your [AD CS lab](../windows/adcs-pki).

### Assigning to the right devices
- Assign to **groups** of users or devices. Use **device groups** for corporate devices and **user groups** where settings follow the person.
- **Filters** narrow assignments by device properties at sign-in time, for example only devices where `deviceOwnership` is `Corporate`, or a specific `model`.
- **Dynamic groups** (Module 2 of your Intune lab) build membership automatically, such as all ADE-enrolled iPhones.

### Checking results
Each profile shows per-device status: **Succeeded**, **Error**, **Conflict**, **Not applicable**, **Pending**. A **conflict** means two profiles set the same thing differently; the device applies neither in many cases, so fix it by removing one setting. **Not applicable** usually means the setting needs supervision or a newer OS.

### Check yourself

**1. A setting shows "Not applicable" on some iPhones. What's a likely reason?**

- a) The setting requires a supervised device
- b) The user is offline
- c) The APNs certificate expired

<details><summary>Answer</summary>

**a)** Many restrictions apply only to supervised devices enrolled through ADE or Apple Configurator.

</details>

**2. What must be assigned along with a SCEP certificate profile?**

- a) A web content filter
- b) A trusted root certificate profile
- c) A passcode profile

<details><summary>Answer</summary>

**b)** The device must trust the issuing CA before it can use certificates from it.

</details>

**3. Two profiles set different auto-lock times. What status do you see?**

- a) Succeeded
- b) Conflict
- c) Not applicable

<details><summary>Answer</summary>

**b)** Conflicting settings show as Conflict. Remove the duplicate setting from one profile.

</details>




---

## 06 Apps

*18 min*

*Getting the right apps onto devices, and configuring them so users don't have to.*

### Getting apps into Intune

| Platform | App source |
|---|---|
| iOS/iPadOS | **Apps and Books** licenses from Apple Business (synced through the location token), App Store apps, line-of-business `.ipa` files, web links |
| Android | **Managed Google Play** (approve apps there, and they sync to Intune), private apps you upload to Managed Google Play, web links |
| Both | **Microsoft apps** (Outlook, Teams, OneDrive, Edge, Authenticator) are available directly |

### Assignment intents

| Intent | Result |
|---|---|
| **Required** | Installed automatically (silently on supervised Apple devices and Android Enterprise) |
| **Available for enrolled devices** | Shown in Company Portal for users to install themselves |
| **Uninstall** | Removed |

### Device licensing vs. user licensing (Apple)
Apps and Books licenses can be assigned to the **device** (no Apple Account needed, silent install on supervised devices, best for corporate devices) or to the **user** (needs the user's Apple Account; the license follows them across devices). Device licensing is simpler for most company-owned phones.

### App configuration policies
**App configuration policies** pre-fill settings inside apps so users don't have to:
- **Outlook:** the user's email address and account type, so it's set up on first launch; whether to allow personal accounts.
- **Edge:** a homepage, managed bookmarks, and allowed URLs.
- **Any app** that supports managed configuration (many VPN, security, and line-of-business apps).

Two kinds exist: **Managed devices** (delivered through MDM to enrolled devices) and **Managed apps** (delivered through the Intune SDK to apps with app protection, even without enrollment).

### Microsoft apps to push to every managed phone
- **Company Portal** (iOS; Android installs it as part of work profile enrollment)
- **Microsoft Authenticator** (MFA, and the broker for single sign-on on iOS)
- **Outlook, Teams, OneDrive, Edge**
- **Microsoft Defender** (threat protection, Module 10)

> [!TIP]
> **Good practice: Single sign-on**
>
> On iOS, **Microsoft Authenticator** acts as the sign-in broker for Microsoft apps, and Apple's **Enterprise SSO plug-in** (deployed with a device features profile) extends single sign-on to Safari and other apps. On Android, **Company Portal** is the broker. With these in place, users sign in once.

### Check yourself

**1. For company-owned iPads, how should Apps and Books licenses usually be assigned?**

- a) To the device, so no Apple Account is needed and installs are silent on supervised devices
- b) To each user's personal Apple Account
- c) Licenses aren't needed for paid apps

<details><summary>Answer</summary>

**a)** Device licensing is simpler for corporate devices and avoids involving personal Apple Accounts.

</details>

**2. How do you make Outlook set itself up with the user's address on first launch?**

- a) A Wi-Fi profile
- b) An app configuration policy
- c) A compliance policy

<details><summary>Answer</summary>

**b)** App configuration policies pass settings like the email address into the app.

</details>




---

## 07 Compliance and Conditional Access

*18 min*

*Compliance answers "is this device safe?" Conditional Access acts on the answer at sign-in.*

### Compliance policies
In **Intune → Devices → Compliance → Create policy**, set the rules a device must meet:

| Rule | iOS | Android Enterprise |
|---|---|---|
| Not jailbroken / rooted | ✅ | ✅ (with **Play Integrity** verdicts) |
| Minimum and maximum OS version | ✅ | ✅ |
| Minimum security patch level | | ✅ |
| Passcode required, length, type | ✅ | ✅ |
| Device threat level (Defender or another Mobile Threat Defense app) | ✅ | ✅ |
| Encryption required | Always on with a passcode | ✅ |

### Actions for noncompliance
Each policy has a schedule of actions:
- **Mark device noncompliant** (immediately, or after a grace period such as 1 day to give users time to fix it)
- **Send email** or **push notification** to the user with instructions
- **Remotely lock** the device
- **Retire** the device after a long period of noncompliance

### Tenant-wide settings
**Intune → Devices → Compliance → Compliance settings**:
- **Mark devices with no compliance policy assigned as:** set it to **Not compliant**, so devices that slip through aren't treated as safe.
- **Compliance status validity period:** how long a device can go without checking in before it's marked noncompliant (default 30 days).

### Conditional Access
In **Entra admin center → Conditional Access**, a policy like *"Require a compliant device for Office 365 on iOS and Android"* means a phone that's jailbroken, out of date, or unmanaged can't open company email, Teams, or files. Your [Intune lab](../m365/intune-autopilot) builds the Windows version of this policy. For BYOD, use the **app protection** grant instead (Module 8).

| Grant control | Works for |
|---|---|
| **Require device to be marked as compliant** | Enrolled devices |
| **Require approved client app / app protection policy** | Personal devices with app protection, no enrollment |
| **Require one of the selected controls** | Mixed populations: corporate devices compliant *or* personal devices with app protection |

> [!WARNING]
> **Watch out: Start in report-only**
>
> As with any Conditional Access change, start in **Report-only**, exclude your break-glass account, and check the sign-in logs before turning it on.

### Check yourself

**1. Why set "devices with no compliance policy assigned" to Not compliant?**

- a) So devices that aren't covered by any policy aren't treated as safe
- b) To speed up enrollment
- c) It's required for Android only

<details><summary>Answer</summary>

**a)** The default is Compliant, which can let unmanaged-in-practice devices through Conditional Access.

</details>

**2. Which grant control works for a personal phone that isn't enrolled?**

- a) Require device to be marked as compliant
- b) Require app protection policy
- c) Require hybrid joined device

<details><summary>Answer</summary>

**b)** Unenrolled devices can't be marked compliant. App protection proves company data is protected inside the apps.

</details>




---

## 08 App protection for personal devices

*16 min*

*App protection keeps company data inside company apps without touching the rest of the phone.*

### What app protection policies do
**App protection policies (APP)**, also called MAM, apply to apps built with the Intune SDK (Outlook, Teams, OneDrive, Edge, Word, Excel, and many third-party apps). They control **data**, not the device:

| Category | Example settings |
|---|---|
| **Data protection** | Block copy-paste to unmanaged apps, block "Save as" to personal storage, block screenshots (Android), encrypt app data, restrict which keyboards and browsers can be used, block backups to iCloud or Google |
| **Access requirements** | App PIN or biometrics, work account credentials after a timeout |
| **Conditional launch** | Minimum OS and app version, block jailbroken/rooted devices, max offline period, wipe company data after a number of failed PIN attempts or a long time offline |

### Microsoft's framework levels
Microsoft publishes a **data protection framework** with three starting configurations:
- **Level 1: Basic** – PIN, encryption, selective wipe. Fine for most BYOD.
- **Level 2: Enhanced** – adds data transfer restrictions and minimum OS versions. For users handling sensitive data.
- **Level 3: High** – adds stricter rules for highly sensitive data and high-risk users.

### Selective wipe
When someone leaves, **Apps → App selective wipe → Create wipe request** removes only the company account data from managed apps. Their personal email accounts, photos, and apps are untouched. Conditional launch rules can also wipe company data automatically after the device has been offline too long.

### MAM for unenrolled vs. enrolled devices
App protection works on both. On enrolled devices it adds a second layer (data controls inside apps), and on unenrolled devices it's the *only* layer. You can target policies to **unmanaged** or **managed** devices with filters or app types.

> [!TIP]
> **In your lab**
>
> In your trial, create an iOS and Android app protection policy at Level 1 for Jane: require a PIN, block copy to other apps. On your personal phone (no enrollment), install Outlook and sign in as Jane. Try copying text from an email into Notes, then run a selective wipe and watch Outlook remove the account.

### Check yourself

**1. What does selective wipe remove?**

- a) Only company data inside managed apps
- b) The entire phone
- c) Personal apps only

<details><summary>Answer</summary>

**a)** Selective wipe removes the work account and its data from protected apps, leaving personal data alone.

</details>

**2. Which apps can app protection policies manage?**

- a) Any app on the phone
- b) Apps that include the Intune SDK or app wrapping
- c) Only built-in Apple and Google apps

<details><summary>Answer</summary>

**b)** Microsoft 365 apps and many partner apps support app protection through the Intune SDK.

</details>




---

## 09 Updates and device lifecycle

*18 min*

*Keeping phones current, and handling them safely when they're lost, replaced, or returned.*

### OS updates on Apple devices
Starting with iOS, iPadOS, and macOS 27, update enforcement uses **Declarative Device Management** only. In Intune, create a **software update policy** with the **Settings catalog** (Declarative Device Management → Software Update) and set a target OS version and an **enforcement deadline**. The user is notified and the update installs by the deadline. Supervised devices can also **defer** updates for up to 90 days so you have time to test.

Plan a **pilot ring** (IT staff), then everyone a week or two later, just like your Windows [update rings](../m365/intune-autopilot).

### OS updates on Android
Android Enterprise system update policies (fully managed, dedicated, corporate work profile) can install **automatically**, **postpone** for up to 30 days, or install in a **maintenance window**. Security patches arrive from the manufacturer and carrier, so the **minimum security patch level** compliance rule is your main lever.

### Device actions

| Action | What it does | When to use |
|---|---|---|
| **Sync** | Forces a check-in | Testing, troubleshooting |
| **Remote lock** | Locks the screen | Device temporarily misplaced |
| **Reset passcode** | Clears or resets the device passcode | User forgot it (supported on some enrollment types) |
| **Lost Mode** (supervised iOS) | Locks with a message and phone number on screen, enables location | Lost or stolen company iPhone |
| **Locate device** | Shows location | Lost corporate device (supervised iOS, fully managed Android) |
| **Retire** | Removes company data and management; personal data stays | Personal device leaving the program, employee departure |
| **Wipe** | Factory reset | Company device being reassigned, lost, or stolen |
| **Delete** | Removes the record from Intune only | Clean up stale records after wipe or retire |

### Activation Lock
On Apple devices, **Find My** links a device to the user's personal Apple Account, so after an erase it asks for that account. That's Activation Lock. On **supervised** devices, Intune can store an **Activation Lock bypass code**, letting IT reuse a device after an employee leaves without needing their Apple password. Make sure this is enabled *before* devices go out.

### End-of-life checklist
1. **Wipe** the device from Intune (or Retire, for personal devices).
2. For Apple: confirm Activation Lock is cleared; for Android: confirm enterprise FRP accounts are set or the device was removed properly.
3. **Release** the device from Apple Business or zero-touch if you're selling or recycling it, so the next owner isn't enrolled into your company.
4. Delete the device record from Intune and Entra ID.
5. Update your [asset inventory](../helpdesk/asset-inventory).

### Check yourself

**1. An employee's personal iPhone was enrolled with User Enrollment and they're leaving. Which action?**

- a) Retire
- b) Wipe
- c) Lost Mode

<details><summary>Answer</summary>

**a)** Retire removes company data and management while leaving personal data intact.

</details>

**2. What lets IT reuse a supervised iPhone that's locked to a departed employee's Apple Account?**

- a) A new APNs certificate
- b) The Activation Lock bypass code stored in Intune
- c) A factory reset from Recovery mode

<details><summary>Answer</summary>

**b)** Supervised devices let Intune escrow a bypass code to clear Activation Lock.

</details>

**3. You're recycling 50 company iPhones. What must you do in Apple Business?**

- a) Nothing
- b) Release them from your organization
- c) Assign them to a new MDM server

<details><summary>Answer</summary>

**b)** Releasing them stops future owners being automatically enrolled into your organization.

</details>




---

## 10 Mobile security

*14 min*

*The threats specific to phones, and the tools that address them.*

### Main risks
- **Phishing** through SMS, messaging apps, and QR codes ("smishing" and "quishing"), where small screens hide suspicious links
- **Malicious or risky apps**, especially sideloaded Android apps
- **Jailbroken or rooted** devices, which bypass the platform's security model
- **Unsafe networks** and malicious Wi-Fi
- **Lost and stolen** devices
- **Outdated OS versions** with known, exploited vulnerabilities

### Defenses

| Control | Where |
|---|---|
| Minimum OS and patch level | Compliance policy |
| Jailbreak/root detection | Compliance policy, app protection conditional launch |
| **Mobile Threat Defense** (Microsoft Defender for Endpoint on iOS and Android, or a partner like Lookout or Zimperium) | Detects malicious apps, phishing links, risky networks; sends a **device threat level** to Intune compliance |
| Block sideloading and unknown sources | Android device restrictions |
| Passcode plus wipe after failed attempts | Passcode / device restrictions |
| Certificate-based Wi-Fi and VPN | Configuration profiles |
| Phishing-resistant MFA (passkeys in Authenticator) | Entra ID authentication methods |
| Separate work and personal data | Work profile, User Enrollment, app protection |

### Exchange ActiveSync: the legacy approach
Before MDM, many organizations managed phones only through **Exchange ActiveSync** policies (passcode, remote wipe) in [Exchange](./exchange-server.md). It's still there, but it controls only the native mail app and a few settings. Modern setups use Outlook with app protection and block basic ActiveSync clients with Conditional Access.

```powershell
# Exchange (on-premises or Online): see which phones sync mail for a user
Get-MobileDevice -Mailbox jsmith | Format-Table FriendlyName, DeviceOS, DeviceAccessState, FirstSyncTime
```

### Check yourself

**1. What does a Mobile Threat Defense integration add to compliance?**

- a) A device threat level based on detected malicious apps, phishing, and risky networks
- b) Faster enrollment
- c) App licenses

<details><summary>Answer</summary>

**a)** Defender or a partner reports a risk level that compliance policies can require to be low or secured.

</details>

**2. Why block basic Exchange ActiveSync clients with Conditional Access?**

- a) They can't receive email
- b) They're managed only by limited ActiveSync policies and can't use app protection
- c) They use too much battery

<details><summary>Answer</summary>

**b)** Native mail apps over ActiveSync bypass app protection. Requiring Outlook with app protection keeps data controlled.

</details>




---

## 11 Help desk playbook and lab plan

*16 min*

*The calls you'll get, and how to answer them.*

| Ticket | What to check | Usual fix |
|---|---|---|
| "I can't open Outlook on my phone; it says my device must be compliant" | Device in Intune: compliance status and which setting fails | Update the OS, set a passcode, or let the device check in (**Sync** in Company Portal) |
| "It says I need to install Company Portal / Authenticator" | Conditional Access with app protection needs the broker app | Install the broker app and sign in once |
| Enrollment fails: "device limit reached" | Enrollment restrictions | Remove old devices from the user, or raise the limit |
| Enrollment fails on iPhone: "profile installation failed" | APNs certificate valid? Enrollment restrictions (personal iOS blocked)? | Fix the certificate or restriction |
| New iPhone didn't show the company setup screen | Serial in Apple Business? Assigned to the Intune MDM server? Profile assigned to the device? | Assign it, then erase and restart setup |
| App didn't install | App assignment, license count (Apple), device OS version | Check the app's **Device install status** |
| Wi-Fi profile installed but won't connect | Certificate profile succeeded? Trusted root assigned? RADIUS/NPS logs | Fix the certificate chain |
| Lost phone | Ownership type | Corporate: Lost Mode or Wipe. Personal: Retire or selective wipe, and revoke sessions in Entra |
| New phone, same person | MFA methods move? | Follow [KB-002](../helpdesk/knowledge-base); enroll the new device; retire the old one |
| Android work apps disappeared | Work profile paused | Turn work apps back on from the Work tab |

### Where to look
- **Intune → Devices → (device):** compliance, configuration status per profile, app install status, hardware info, and the **device action status**.
- **Intune → Troubleshooting + support → (user):** every device, policy, app, and enrollment failure for one user on one screen.
- **Company Portal → Settings → Save logs / Send logs** (Android) or **Help & support → Send logs** (iOS): collects logs and gives an incident ID for Microsoft support.
- **Entra → Sign-in logs:** why Conditional Access blocked a mobile sign-in.

### A weekend lab plan
1. **Saturday morning:** in your trial tenant, upload the APNs certificate, connect Managed Google Play, set enrollment restrictions, and set compliance settings to "Not compliant" for devices without a policy.
2. **Saturday afternoon:** build compliance, passcode, and restrictions policies for iOS and Android. Enroll your test device (Android work profile or iOS device enrollment) and watch them apply.
3. **Sunday morning:** deploy Outlook, Teams, and Edge as required apps with an Outlook app configuration policy; add a Level 1 app protection policy.
4. **Sunday afternoon:** add Conditional Access in report-only, read the sign-in logs, then switch it on. Finish with a retire and a selective wipe, and write two [KB articles](../helpdesk/knowledge-base) from what you learned.

### Check yourself

**1. Which Intune view shows one user's devices, policies, and failures together?**

- a) Troubleshooting + support
- b) Tenant administration
- c) Apps → Monitor

<details><summary>Answer</summary>

**a)** The Troubleshooting pane is the help desk's starting point for a single user.

</details>

**2. A user's company iPhone was stolen. What's the right action?**

- a) Retire
- b) Lost Mode first, then Wipe if it isn't recovered
- c) Delete the device record

<details><summary>Answer</summary>

**b)** For corporate supervised devices, Lost Mode locks and helps locate it. Wipe if it can't be recovered, and revoke the user's sessions.

</details>




---

*Written in plain language from Microsoft Intune, Apple, and Google documentation, current as of October 2026 (iOS 27, Android 16 era). Mobile platforms change every year. Check Microsoft Learn and Apple's Platform Deployment guide before changing production settings.*
