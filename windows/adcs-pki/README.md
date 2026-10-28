# Internal PKI with Active Directory Certificate Services

Run your own certificate authority (CA) so internal sites like `https://intranet.lab.local` get **trusted** certificates with no browser warnings, computers enroll for certificates **automatically**, and domain controllers gain **LDAPS** (encrypted LDAP). You'll also issue, inspect, and revoke certificates, and back up the CA.

> **Status:** tutorial ready. Results and screenshots to be added after the lab is run.

| | |
|---|---|
| **Role** | Sysadmin |
| **Time** | 4–6 hours |
| **Cost** | Free |
| **Builds on** | [Server lab](../server-lab/) (the intranet site on APP01) |
| **Resume keywords** | AD CS, PKI, certificate templates, autoenrollment, TLS, LDAPS, CRL |

## Why this matters

Expired or untrusted certificates cause outages and teach users to click through security warnings. Admins who understand certificate chains, templates, and revocation are valuable, and it ties directly to your security background: your ACAS scans flagged self-signed and expired certificates, and this is how organizations fix them.

---

## Part 1: Plan the CA

| Decision | Lab choice | Production best practice |
|---|---|---|
| CA type | **Enterprise** (integrated with AD, so templates and autoenrollment work) | Enterprise issuing CA |
| Hierarchy | **One tier**: a single root CA that issues certificates | **Two tiers**: an offline root CA that only signs issuing CAs, kept powered off |
| Server | **APP01** | A dedicated server, never a domain controller |
| Key | RSA 4096, SHA-256 | Same, ideally protected by a hardware security module (HSM) |
| CA name | `LAB-Root-CA` | Something neutral, because it can't be changed later |

> **Why never on a DC?** A CA and a DC are both "keys to the kingdom" systems, and a CA can't be renamed or moved easily. Combining them makes both harder to recover. In the lab, APP01 keeps it simple.

---

## Part 2: Install the certificate authority

On **APP01**. Configuring an enterprise CA requires **Enterprise Admins** membership. `LAB\Administrator` has it; your `adm-nwang` account (Domain Admins only) doesn't. Sign in as `LAB\Administrator` for this part, or add `adm-nwang` to Enterprise Admins temporarily and remove it afterward.

### Click-ops
1. **Add Roles and Features** → **Active Directory Certificate Services** → role service **Certification Authority** only → Install.
2. Yellow flag → **Configure Active Directory Certificate Services on the destination server**:

| Page | Setting |
|---|---|
| Credentials | `LAB\Administrator` (or another Enterprise Admins member) |
| Role Services | ✅ Certification Authority |
| Setup Type | **Enterprise CA** |
| CA Type | **Root CA** |
| Private Key | Create a new private key |
| Cryptography | RSA, **4096**, **SHA256** |
| CA Name | Common name `LAB-Root-CA` |
| Validity Period | **10 years** |

### PowerShell
```powershell
Install-WindowsFeature ADCS-Cert-Authority -IncludeManagementTools
Install-AdcsCertificationAuthority -CAType EnterpriseRootCa -CACommonName 'LAB-Root-CA' `
    -KeyLength 4096 -HashAlgorithmName SHA256 -ValidityPeriod Years -ValidityPeriodUnits 10 -Force
```

### What just happened
An enterprise CA **publishes its root certificate in Active Directory**. Every domain-joined computer adds it to its **Trusted Root Certification Authorities** store automatically at its next Group Policy refresh. That's why internal certificates become trusted everywhere with no extra work.

### ✅ Check your work
1. On CLIENT01: `gpupdate /force`, then open `certlm.msc` → **Trusted Root Certification Authorities → Certificates**. **LAB-Root-CA** is listed.
2. On APP01: `pkiview.msc` (**Enterprise PKI**) shows LAB-Root-CA. Review any red items it flags.

---

## Part 3: Create certificate templates

Templates define what a certificate is for, how long it lasts, and who may request it. Open **Certificate Templates** on APP01: `certtmpl.msc`.

### 3.1 Web server template
1. Right-click **Web Server** → **Duplicate Template**.
2. **General:** display name `LAB Web Server` (the template name becomes `LABWebServer`), validity **1 year**.
3. **Request Handling:** leave *Allow private key to be exported* **unchecked**.
4. **Subject Name:** **Supply in the request** (the requester provides the site's name).
5. **Security:** **Add** `GG-Intranet-Servers` → ✅ **Read**, ✅ **Enroll**.

### 3.2 Computer autoenrollment template
1. Right-click **Workstation Authentication** → **Duplicate Template**.
2. **General:** display name `LAB Workstation`.
3. **Security:** select **Domain Computers** → ✅ **Read**, ✅ **Enroll**, ✅ **Autoenroll**.

### 3.3 Publish the templates
Templates don't do anything until the CA is told to issue them.

**Click-ops:** `certsrv.msc` → **LAB-Root-CA → Certificate Templates** → right-click → **New → Certificate Template to Issue** → select **LAB Web Server** and **LAB Workstation**.

**PowerShell:**
```powershell
Add-CATemplate -Name 'LABWebServer' -Force
Add-CATemplate -Name 'LABWorkstation' -Force
```

---

## Part 4: Give the intranet a trusted certificate

### 4.1 Request the certificate
On **APP01** (it's in `GG-Intranet-Servers` from the server lab):

**Click-ops:** `certlm.msc` → **Personal** → right-click → **All Tasks → Request New Certificate** → Active Directory Enrollment Policy → ✅ **LAB Web Server** → click the warning link *More information is required*:
- Subject name: type **Common name** → `intranet.lab.local` → **Add**
- Alternative name: type **DNS** → `intranet.lab.local` → **Add**, then `app01.lab.local` → **Add**

→ **OK → Enroll**.

**PowerShell:**
```powershell
Get-Certificate -Template 'LABWebServer' -SubjectName 'CN=intranet.lab.local' `
    -DnsName 'intranet.lab.local', 'app01.lab.local' -CertStoreLocation 'Cert:\LocalMachine\My'
```

> **Why the DNS names (SANs)?** Browsers check the **Subject Alternative Name** list, not the common name. A certificate without the right SAN causes a name-mismatch warning even if it's trusted.

### 4.2 Bind it in IIS
**IIS Manager → Sites → Intranet → Bindings** → select the **https** binding → **Edit** → SSL certificate: the new one issued by **LAB-Root-CA** → **OK**. Then delete the old self-signed certificate from `certlm.msc` → Personal.

### ✅ Check your work
On CLIENT01, open `https://intranet.lab.local`. **No warning**. Click the padlock → the certificate chain shows **LAB-Root-CA → intranet.lab.local**. This also resolves [mock ticket #18](../../helpdesk/ticketing-osticket/mock-tickets.md).

📸 Screenshot: the browser's certificate viewer showing the chain

---

## Part 5: Autoenrollment

Computers request and renew their own certificates, so certificates never expire unnoticed.

1. On DC01, create a GPO `Corp - Certificate Autoenrollment` linked to **Corp\Computers** and **Corp\Servers**.
2. **Computer Configuration → Policies → Windows Settings → Security Settings → Public Key Policies → Certificate Services Client - Auto-Enrollment** → **Enabled**, ✅ **Renew expired certificates, update pending certificates, and remove revoked certificates**, ✅ **Update certificates that use certificate templates**.
3. On CLIENT01:
   ```cmd
   gpupdate /force
   certutil -pulse
   ```

### ✅ Check your work
`certlm.msc` → **Personal → Certificates** on CLIENT01 shows a certificate from the **LAB Workstation** template, issued by LAB-Root-CA. On APP01, `certsrv.msc` → **Issued Certificates** lists it.

---

## Part 6: LDAPS on the domain controllers (bonus)

With an enterprise CA in place, domain controllers automatically enroll for a **Kerberos Authentication** / **Domain Controller** certificate. That certificate turns on **LDAPS** (port 636), so apps can read the directory over an encrypted connection.

1. On DC01: `certlm.msc` → Personal shows a certificate from LAB-Root-CA (run `gpupdate /force` and wait a few minutes if not).
2. Test from CLIENT01:
   ```powershell
   Test-NetConnection dc01.lab.local -Port 636
   ```
3. For a full test, run `ldp.exe` → **Connection → Connect** → server `dc01.lab.local`, port **636**, ✅ **SSL**.

Now you can switch the [Snipe-IT LDAP sync](../../helpdesk/asset-inventory/) to `ldaps://dc01.lab.local`.

---

## Part 7: Revoke a certificate and back up the CA

### Revoke
1. `certsrv.msc` → **Issued Certificates** → right-click CLIENT01's workstation certificate → **All Tasks → Revoke Certificate** → reason **Superseded**.
2. Publish a new revocation list now instead of waiting: right-click **Revoked Certificates** → **All Tasks → Publish**, or run `certutil -CRL`.
3. Check what clients see:
   ```cmd
   certutil -verify -urlfetch <exported-certificate.cer>
   ```
4. On CLIENT01, `certutil -pulse` makes autoenrollment replace the revoked certificate.

### Back up the CA
Losing the CA's private key means re-issuing every certificate. Back it up:
```powershell
Backup-CARoleService -Path 'D:\CABackup' -Password (Read-Host -AsSecureString 'Backup password')
```
Also export the registry configuration: `reg export HKLM\SYSTEM\CurrentControlSet\Services\CertSvc\Configuration D:\CABackup\CAConfig.reg`. Use any backup disk (`D:` here), and store both files offline.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| Template doesn't appear in *Request New Certificate* | Not published on the CA (3.3), or the computer lacks **Enroll** permission (or hasn't refreshed group membership) |
| "Insufficient permissions" when configuring the CA | The account must be in **Enterprise Admins** |
| Browser still warns after binding | Wrong certificate bound, or the SAN is missing the name you browsed to |
| Autoenrollment does nothing | GPO not applied (`gpresult /r`), template missing **Autoenroll** permission, then `certutil -pulse` |
| Revocation checks fail | Run `pkiview.msc`; the CRL locations (CDP) must be reachable |

## How to talk about it in an interview

> *"I deployed an enterprise root CA with AD CS, created duplicated templates for web servers and workstation autoenrollment, and replaced the intranet's self-signed certificate with a trusted one, including proper SANs. Domain controllers picked up certificates automatically, which enabled LDAPS. I also revoked a certificate, published the CRL, and backed up the CA. I'd use a two-tier hierarchy with an offline root in production."*

## Results

_To be added after the lab is run:_
- [ ] Screenshots: pkiview, templates, the intranet's trusted chain, autoenrolled cert, LDAPS test
