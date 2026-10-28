<#
.SYNOPSIS
    Part 2 / Part 7: first-boot setup for DC01 or APP01.

.DESCRIPTION
    Run on the new server right after installing Windows, as the local Administrator.
      - Sets a static IP address, gateway, and DNS server
      - Sets the time zone
      - Enables Remote Desktop (with Network Level Authentication) and its firewall rules
      - Renames the computer and restarts

    DC01 temporarily points DNS at public resolvers so it can download updates; it switches
    to itself after it becomes a domain controller (03-Configure-DnsDhcp.ps1).
    APP01 points DNS at DC01, which it needs to find the domain.

.PARAMETER Role
    DC or App.

.EXAMPLE
    .\01-Initialize-Server.ps1 -Role DC
#>
#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('DC', 'App')]
    [string]$Role,

    [string]$ConfigPath = "$PSScriptRoot\lab-config.psd1"
)

$ErrorActionPreference = 'Stop'
$cfg    = Import-PowerShellDataFile $ConfigPath
$server = if ($Role -eq 'DC') { $cfg.DC } else { $cfg.App }
$dns    = if ($Role -eq 'DC') { $cfg.DnsForwarders } else { @($cfg.DC.IP) }

# --- Static IP on the (only) connected network adapter ------------------------
$nic = Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1
if (-not $nic) { throw 'No connected network adapter found.' }
Write-Output "Configuring $($nic.Name): $($server.IP)/$($cfg.PrefixLength), gateway $($cfg.Gateway), DNS $($dns -join ', ')"

# Remove any DHCP or old static address first
Set-NetIPInterface -InterfaceIndex $nic.ifIndex -Dhcp Disabled
Get-NetIPAddress -InterfaceIndex $nic.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
Get-NetRoute -InterfaceIndex $nic.ifIndex -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue |
    Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue

New-NetIPAddress -InterfaceIndex $nic.ifIndex -IPAddress $server.IP `
    -PrefixLength $cfg.PrefixLength -DefaultGateway $cfg.Gateway | Out-Null
Set-DnsClientServerAddress -InterfaceIndex $nic.ifIndex -ServerAddresses $dns

# --- Time zone (Kerberos needs clocks within 5 minutes; the DC becomes the domain's time source)
Set-TimeZone -Id $cfg.TimeZone

# --- Remote Desktop with NLA ---------------------------------------------------
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name UserAuthentication -Value 1
Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'

# --- Allow ping inside the lab, which makes troubleshooting easier -------------
Enable-NetFirewallRule -Name 'FPS-ICMP4-ERQ-In' -ErrorAction SilentlyContinue

# --- Rename and restart --------------------------------------------------------
if ($env:COMPUTERNAME -ne $server.Name) {
    Write-Output "Renaming $env:COMPUTERNAME to $($server.Name) and restarting..."
    Rename-Computer -NewName $server.Name -Force -Restart
} else {
    Write-Output "Name is already $($server.Name). Restart if you changed anything else."
}
