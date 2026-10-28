# Firewall, VLANs, and VPN with pfSense

Put a real firewall in the lab. You'll build a **pfSense** VM that routes between the server network and two new VLANs (one for domain clients, one isolated guest network), relay DHCP from the client VLAN to DC01, write firewall rules between networks, and set up **WireGuard** remote access. All of it runs inside Hyper-V with no extra hardware.

> **Status:** tutorial ready. Results and screenshots to be added after the lab is run.

| | |
|---|---|
| **Role** | Sysadmin, MSP Level 2/3 |
| **Time** | A weekend |
| **Cost** | Free (pfSense Community Edition) |
| **Builds on** | [Server lab](../../windows/server-lab/) (DC01 with DHCP and DNS); the Packet Tracer exercise in the [study plan](../../study-plan/) helps with the concepts |
| **Resume keywords** | pfSense, firewall rules, VLANs, 802.1Q trunking, inter-VLAN routing, NAT, DHCP relay, WireGuard VPN, network segmentation |

## Why this matters

MSP and sysadmin postings ask for "firewall, VLAN, and VPN experience," and networking is the gap most Windows admins have. Segmentation is also basic security: guests and IoT devices shouldn't reach your servers. After this lab you can explain, and show, how traffic moves between networks and why a rule allows or blocks it.

---

## Part 1: Understand the design

```
                Internet
                   │
          Hyper-V NAT (10.10.10.1)
                   │
  LabSwitch ── 10.10.10.0/24 ── DC01 .10, DC02 .11, APP01 .20, MON01 .30, LNX01 .41, CLIENT01 (DHCP)
                   │
          WAN  10.10.10.2
            ┌──────────┐
            │   FW01   │  pfSense
            └──────────┘
          LAN (802.1Q trunk on new switch "LabTrunk")
             ├── VLAN 30  CLIENTS  10.30.30.0/24   gateway .1, DHCP relayed to DC01
             └── VLAN 40  GUEST    10.40.40.0/24   gateway .1, DHCP from pfSense, internet only
```

| Network | VLAN | Subnet | Gateway | DHCP | Can reach |
|---|---|---|---|---|---|
| Servers (existing) | none | 10.10.10.0/24 | 10.10.10.1 | DC01 | Everything |
| Clients | 30 | 10.30.30.0/24 | 10.30.30.1 | DC01, through relay | Servers and internet |
| Guest | 40 | 10.40.40.0/24 | 10.40.40.1 | pfSense | **Internet only** |
| VPN | none | 10.50.50.0/24 | 10.50.50.1 | WireGuard config | Clients VLAN |

> The existing server network keeps its gateway (Hyper-V NAT), so nothing you've built breaks. The servers just need a **route** to reach the new VLANs through the firewall (Part 5).

### Key terms
- **VLAN:** a separate network sharing the same switch, marked with an 802.1Q **tag** (the VLAN ID).
- **Trunk port:** carries several tagged VLANs (here, the firewall's LAN adapter).
- **Access port:** carries one VLAN, untagged to the device (here, each client VM's adapter).
- **DHCP relay:** a router forwards DHCP requests from one network to a DHCP server on another.

---

## Part 2: Build the firewall VM

### 2.1 Create the switch and VM
On the **Hyper-V host**, in PowerShell as administrator:
```powershell
New-VMSwitch -Name 'LabTrunk' -SwitchType Private

New-VM -Name 'FW01' -Generation 2 -MemoryStartupBytes 1GB -NewVHDPath 'C:\Hyper-V\FW01.vhdx' -NewVHDSizeBytes 16GB -SwitchName 'LabSwitch'
Set-VMFirmware -VMName 'FW01' -EnableSecureBoot Off
Set-VMProcessor -VMName 'FW01' -Count 2
Rename-VMNetworkAdapter -VMName 'FW01' -NewName 'WAN'
Add-VMNetworkAdapter -VMName 'FW01' -Name 'LAN' -SwitchName 'LabTrunk'

# The LAN adapter is a trunk carrying VLANs 30 and 40
Set-VMNetworkAdapterVlan -VMName 'FW01' -VMNetworkAdapterName 'LAN' -Trunk -AllowedVlanIdList '30,40' -NativeVlanId 0

Add-VMDvdDrive -VMName 'FW01' -Path 'C:\ISOs\pfSense-CE-amd64.iso'
Set-VMFirmware -VMName 'FW01' -FirstBootDevice (Get-VMDvdDrive -VMName 'FW01')
```

> Download the pfSense CE installer from pfsense.org (Netgate's site asks you to sign in for the current installer). Use the path where you saved it.

### 2.2 Install pfSense
1. Start FW01 and connect to its console. Accept the defaults in the installer (ZFS, the single disk) and reboot. Remove the ISO.
2. At **"Should VLANs be set up now?"** answer **n** (you'll add them in the web interface).
3. Assign interfaces: **WAN = hn0**, **LAN = hn1**. Hyper-V adapters appear as `hn0`, `hn1` in the order you added them.
4. From the console menu, choose **2) Set interface(s) IP address**:
   - **WAN:** static `10.10.10.2/24`, upstream gateway `10.10.10.1`, no DHCP server, keep HTTPS for the web interface.
   - **LAN:** static `10.20.20.1/24` (a placeholder; nothing untagged connects to it), no DHCP server.

### 2.3 Reach the web interface from the server network
pfSense blocks web access on its WAN by default, and here your admin PC (CLIENT01) is on the WAN side. Open it up once, then add a proper rule:
1. In the console, choose **8) Shell** and run `pfctl -d` to turn the firewall off temporarily.
2. From CLIENT01, browse to `https://10.10.10.2`, sign in as `admin` / `pfsense`, and run the setup wizard:
   - Hostname `fw01`, domain `lab.local`, DNS `10.10.10.10`, `10.10.10.11`
   - Time server `dc01.lab.local`
   - WAN: keep the static settings; **uncheck "Block RFC1918 Private Networks"** and **"Block bogon networks"**, because this WAN *is* a private network
   - **Change the admin password**
3. **Firewall → Rules → WAN → Add**: Pass, protocol TCP, source **10.10.10.0/24**, destination **This firewall (self)**, port **HTTPS (443)**, description `Admin GUI from server network`. Save and **Apply**.
4. Back in the console shell: `pfctl -e` turns the firewall back on. The GUI stays reachable thanks to your rule.
5. **System → Advanced → Networking:** ✅ **Disable hardware checksum offload**, then reboot FW01. This avoids a known performance problem with pfSense on Hyper-V.

### ✅ Check your work
**Status → Dashboard** loads from CLIENT01, and **Diagnostics → Ping** to `8.8.8.8` from the WAN interface succeeds.

📸 Screenshot: the pfSense dashboard

---

## Part 3: Create the VLANs

1. **Interfaces → Assignments → VLANs → Add:**
   - Parent `hn1`, VLAN tag **30**, description `CLIENTS`
   - Parent `hn1`, VLAN tag **40**, description `GUEST`
2. **Interfaces → Assignments:** add both VLANs from the "Available network ports" list. They appear as **OPT1** and **OPT2**.
3. Configure each one (click its name):

| Interface | Enable | Description | IPv4 | Address |
|---|---|---|---|---|
| OPT1 | ✅ | `CLIENTS` | Static | `10.30.30.1/24` |
| OPT2 | ✅ | `GUEST` | Static | `10.40.40.1/24` |

Save and **Apply** each.

---

## Part 4: DHCP for each VLAN

### 4.1 Guest VLAN: pfSense hands out addresses
**Services → DHCP Server → GUEST:** ✅ Enable, range `10.40.40.100` to `10.40.40.200`. Leave DNS blank so guests use pfSense's own DNS resolver (not your domain DNS).

### 4.2 Client VLAN: relay to DC01
Domain clients should get their addresses from **DC01**, like everything else in the domain.

1. On **DC01**, add a scope for the new VLAN:
   ```powershell
   Add-DhcpServerv4Scope -Name 'VLAN30-Clients' -StartRange 10.30.30.100 -EndRange 10.30.30.200 -SubnetMask 255.255.255.0 -State Active
   Set-DhcpServerv4OptionValue -ScopeId 10.30.30.0 -Router 10.30.30.1 -DnsServer 10.10.10.10, 10.10.10.11 -DnsDomain 'lab.local'
   ```
2. In pfSense, make sure the DHCP **server** is off for CLIENTS (it is by default), then **Services → DHCP Relay**: ✅ Enable, interface **CLIENTS**, destination server **10.10.10.10**. Save.

> The relay forwards the request with the CLIENTS gateway address (10.30.30.1) inside it. That's how DC01 knows to pick the `10.30.30.0` scope instead of its original one.

---

## Part 5: Routing and NAT

### 5.1 Give the servers a route to the new VLANs
The servers' default gateway is still the Hyper-V NAT (10.10.10.1), which knows nothing about 10.30.30.0/24. Add a persistent route through the firewall on **DC01, DC02, APP01, and MON01**:
```powershell
New-NetRoute -DestinationPrefix '10.30.30.0/24' -NextHop 10.10.10.2 -InterfaceAlias 'Ethernet'
```

> Without this, DC01 receives the relayed DHCP request but its reply goes to the wrong gateway and never arrives. "Traffic gets there but the reply doesn't come back" is one of the most common network problems you'll troubleshoot.

### 5.2 Don't NAT traffic to the server network
pfSense translates (NATs) everything leaving its WAN to its own address, 10.10.10.2. That's right for the internet, but it would hide each client's real IP from DC01 and APP01, which breaks logging, DHCP, and troubleshooting.

**Firewall → NAT → Outbound:** choose **Hybrid Outbound NAT** → Save. Then **Add** a mapping:
- ✅ **Do not NAT**, interface **WAN**, source **10.30.30.0/24**, destination **10.10.10.0/24**, description `Clients to servers without NAT`.

Save and **Apply**. Traffic from clients to the internet is still NATed automatically.

---

## Part 6: Firewall rules

pfSense checks rules **on the interface where traffic arrives**, top to bottom, and the **first match wins**. Anything not allowed is blocked.

### 6.1 Create an alias
**Firewall → Aliases → Add:** name `PRIVATE_NETS`, type Network, entries `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`.

### 6.2 CLIENTS rules
**Firewall → Rules → CLIENTS**, in this order:

| # | Action | Protocol | Source | Destination | Port | Description |
|---|---|---|---|---|---|---|
| 1 | Block | TCP | CLIENTS net | 10.10.10.20 (APP01) | 3389 | No RDP to servers from clients |
| 2 | Pass | Any | CLIENTS net | Any | Any | Clients to servers and internet |

### 6.3 GUEST rules
**Firewall → Rules → GUEST**:

| # | Action | Protocol | Source | Destination | Port | Description |
|---|---|---|---|---|---|---|
| 1 | Pass | TCP/UDP | GUEST net | This firewall | 53 (DNS) | Guests use pfSense DNS |
| 2 | Block | Any | GUEST net | `PRIVATE_NETS` | Any | No access to any internal network |
| 3 | Pass | Any | GUEST net | Any | Any | Internet |

### 6.4 WAN rules (traffic from the server network)
Add below the admin GUI rule:

| Action | Protocol | Source | Destination | Description |
|---|---|---|---|---|
| Pass | Any | 10.10.10.0/24 | CLIENTS net | Servers and admins can reach clients (GPO, remote support, WAC) |

> **Tighten it later:** replace CLIENTS rule 2 with rules for only the ports clients need to reach the servers: DNS 53, Kerberos 88, NTP 123, RPC 135, LDAP 389, SMB 445, HTTPS 443, plus Active Directory's dynamic RPC range. That's real-world segmentation, and a great follow-up exercise.

---

## Part 7: Connect clients to the VLANs

1. Create two VMs on **LabTrunk**: `CLIENT02` (Windows 11) and `GUEST01` (any OS, even an Ubuntu desktop live ISO). Put each adapter in its VLAN as an **access port**:
   ```powershell
   Set-VMNetworkAdapterVlan -VMName 'CLIENT02' -Access -VlanId 30
   Set-VMNetworkAdapterVlan -VMName 'GUEST01'  -Access -VlanId 40
   ```
2. Join CLIENT02 to `lab.local`.
3. Windows blocks ping by default. So the tests below work, allow it on CLIENT02:
   ```powershell
   Enable-NetFirewallRule -DisplayName 'File and Printer Sharing (Echo Request - ICMPv4-In)'
   ```

### ✅ Check your work

| Test | From | Expected |
|---|---|---|
| `ipconfig /all` | CLIENT02 | Address `10.30.30.1xx`, gateway `10.30.30.1`, DNS `10.10.10.10` |
| DHCP lease | DC01, DHCP console → `VLAN30-Clients` → Address Leases | CLIENT02 listed |
| `Test-NetConnection dc01.lab.local -Port 389` | CLIENT02 | `TcpTestSucceeded: True` |
| Domain sign-in as `LAB\jsmith`, `\\APP01\Finance` opens | CLIENT02 | Works |
| `Test-NetConnection app01 -Port 3389` | CLIENT02 | **Fails** (rule 1) |
| Browse the internet | GUEST01 | Works |
| `ping 10.10.10.10` and `ping 10.30.30.1xx` | GUEST01 | **Fail** |
| `tracert 10.10.10.10` | CLIENT02 | First hop 10.30.30.1, then DC01 |

Check **Status → System Logs → Firewall** to see the blocked guest and RDP attempts, with the rule that blocked them.

📸 Screenshots: CLIENT02 `ipconfig /all`, the DC01 lease, the firewall log showing blocks

---

## Part 8: WireGuard remote access

Your **Hyper-V host** will play the "remote laptop." It's on the 10.10.10.0/24 network but has no route to the client VLAN, so reaching CLIENT02 proves the VPN works.

### 8.1 Install and configure WireGuard in pfSense
1. **System → Package Manager → Available Packages:** install **WireGuard**.
2. **VPN → WireGuard → Tunnels → Add Tunnel:** ✅ Enabled, listen port **51820**, click **Generate** for the keys, interface address `10.50.50.1/24`. Save.
3. **VPN → WireGuard → Settings:** ✅ Enable WireGuard. Save.
4. **Interfaces → Assignments:** add `tun_wg0` (it becomes OPT3), enable it, description `WG`, IPv4 **None**. Save.

### 8.2 Create the client (peer)
1. On the Hyper-V host, install **WireGuard for Windows** from wireguard.com. Click **Add Tunnel → Add empty tunnel**, name it `lab`, and copy its **public key**.
2. In pfSense, **VPN → WireGuard → Peers → Add Peer:** tunnel `tun_wg0`, description `nwang-laptop`, paste the host's public key, allowed IPs `10.50.50.2/32`. Save and **Apply**.
3. Finish the tunnel config on the host:
   ```ini
   [Interface]
   PrivateKey = (already filled in by WireGuard)
   Address = 10.50.50.2/32

   [Peer]
   PublicKey = (the pfSense tunnel's public key, from VPN → WireGuard → Tunnels)
   Endpoint = 10.10.10.2:51820
   AllowedIPs = 10.30.30.0/24
   ```
   `AllowedIPs` sends only lab client traffic through the tunnel (a **split tunnel**).

### 8.3 Rules
- **Firewall → Rules → WAN → Add:** Pass, UDP, source 10.10.10.0/24, destination **WAN address**, port **51820**, description `WireGuard`.
- **Firewall → Rules → WG → Add:** Pass, any, source 10.50.50.0/24, destination CLIENTS net, description `VPN users to clients`.

### ✅ Check your work
On the host: `ping CLIENT02's IP` **fails** with the tunnel off, and **succeeds** with **Activate** on. pfSense **Status → WireGuard** shows a recent handshake.

📸 Screenshots: WireGuard status with a handshake, the ping test with the tunnel on and off

---

## Part 9: Back up the configuration

**Diagnostics → Backup & Restore → Download configuration as XML.** Keep it with your lab notes. A firewall rebuild becomes a five-minute restore. (Strip the password hashes before sharing it anywhere.)

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| Locked out of the web interface | Console menu **8) Shell** → `pfctl -d`, fix the WAN rule, then `pfctl -e` |
| Client VLAN gets no DHCP address | DHCP relay enabled on CLIENTS? Scope active on DC01? **Route on DC01 to 10.30.30.0/24?** Check **Status → System Logs → DHCP** |
| Client gets an APIPA (169.254.x.x) address | The VM's adapter VLAN ID doesn't match (30), or the trunk doesn't allow it (`Get-VMNetworkAdapterVlan -VMName FW01`) |
| Clients reach the internet but not servers | Route on the servers (Part 5.1) and the do-not-NAT rule (Part 5.2) |
| Slow or broken connections | Disable hardware checksum offload (Part 2.3) and reboot |
| WireGuard shows no handshake | WAN rule for UDP 51820; keys swapped (each side needs the **other** side's public key); endpoint address |
| A rule seems to do nothing | Rules apply on the interface where traffic **arrives**, first match wins; check the order and the firewall log |

## How to talk about it in an interview

> *"I built a pfSense firewall in Hyper-V with an 802.1Q trunk carrying a client VLAN and an isolated guest VLAN. Client DHCP is relayed to the Windows DHCP server, so the domain still manages addressing, and I used hybrid outbound NAT so servers see real client IPs. Rules block guests from every private network and block RDP from clients to servers. I also set up a split-tunnel WireGuard VPN. The trickiest part was asymmetric routing: DHCP replies didn't reach clients until I added a return route on the servers."*

## Results

_To be added after the lab is run:_
- [ ] Screenshots from Parts 2, 7, and 8
- [ ] The Part 7 test table, filled in with your results
- [ ] Your rule set exported, and notes on what broke and how you fixed it
