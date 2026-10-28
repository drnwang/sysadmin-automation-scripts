<#
.SYNOPSIS
    Part 4: configures DNS and DHCP on DC01.

.DESCRIPTION
    Run on DC01 as LAB\Administrator after it restarts as a domain controller.
    DNS:
      - Points DC01's own DNS client at itself
      - Creates the reverse lookup zone (10.10.10.x -> name) for PTR records
      - Adds forwarders so lab machines can resolve internet names
      - Re-registers DC01's records
    DHCP:
      - Installs the role, creates its security groups, and authorizes it in AD
      - Creates the client scope with router, DNS server, and domain name options
      - Registers clients in DNS automatically (and removes records when leases expire)

.EXAMPLE
    .\03-Configure-DnsDhcp.ps1
#>
#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [string]$ConfigPath = "$PSScriptRoot\lab-config.psd1"
)

$ErrorActionPreference = 'Stop'
$cfg   = Import-PowerShellDataFile $ConfigPath
$dcFqdn = "$($cfg.DC.Name).$($cfg.DomainName)".ToLower()

# ============================ DNS ============================================
$nic = Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1
Write-Output "Pointing DC01's DNS client at itself ($($cfg.DC.IP))"
Set-DnsClientServerAddress -InterfaceIndex $nic.ifIndex -ServerAddresses $cfg.DC.IP

$o = $cfg.Subnet.Split('.')
$reverseZone = "$($o[2]).$($o[1]).$($o[0]).in-addr.arpa"   # 10.10.10.0/24 -> 10.10.10.in-addr.arpa
if (-not (Get-DnsServerZone -Name $reverseZone -ErrorAction SilentlyContinue)) {
    Write-Output "Creating reverse lookup zone for $($cfg.Subnet)/$($cfg.PrefixLength)"
    Add-DnsServerPrimaryZone -NetworkId "$($cfg.Subnet)/$($cfg.PrefixLength)" `
        -ReplicationScope Domain -DynamicUpdate Secure
}

Write-Output "Setting forwarders: $($cfg.DnsForwarders -join ', ')"
Set-DnsServerForwarder -IPAddress $cfg.DnsForwarders

# Register DC01's A and PTR records now that the reverse zone exists
ipconfig /registerdns | Out-Null

# ============================ DHCP ===========================================
Write-Output 'Installing DHCP...'
Install-WindowsFeature -Name DHCP -IncludeManagementTools | Out-Null

# Creates the local 'DHCP Administrators' and 'DHCP Users' groups
Add-DhcpServerSecurityGroup
Restart-Service DHCPServer

# A DHCP server in a domain must be authorized in AD before it hands out addresses
if (-not (Get-DhcpServerInDC | Where-Object DnsName -eq $dcFqdn)) {
    Write-Output "Authorizing $dcFqdn in Active Directory"
    Add-DhcpServerInDC -DnsName $dcFqdn -IPAddress $cfg.DC.IP
}

# Tell Server Manager that post-install configuration is complete (clears its yellow flag)
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\ServerManager\Roles\12' -Name ConfigurationState -Value 2

$d = $cfg.Dhcp
if (-not (Get-DhcpServerv4Scope -ScopeId $cfg.Subnet -ErrorAction SilentlyContinue)) {
    Write-Output "Creating scope '$($d.ScopeName)' $($d.StartRange)-$($d.EndRange)"
    Add-DhcpServerv4Scope -Name $d.ScopeName -StartRange $d.StartRange -EndRange $d.EndRange `
        -SubnetMask $d.SubnetMask -LeaseDuration ([TimeSpan]::FromDays($d.LeaseDays)) -State Active
}

Set-DhcpServerv4OptionValue -ScopeId $cfg.Subnet -Router $cfg.Gateway `
    -DnsServer $cfg.DC.IP -DnsDomain $cfg.DomainName

# Register clients in DNS (A + PTR) and clean up when leases expire
Set-DhcpServerv4DnsSetting -ScopeId $cfg.Subnet -DynamicUpdates Always -DeleteDnsRRonLeaseExpiry $true

Write-Output ''
Write-Output 'Check your work:'
Write-Output "  Resolve-DnsName $dcFqdn"
Write-Output "  Resolve-DnsName $($cfg.DC.IP)"
Write-Output '  Resolve-DnsName www.microsoft.com'
Write-Output "  Get-DhcpServerv4Scope; Get-DhcpServerv4OptionValue -ScopeId $($cfg.Subnet)"
