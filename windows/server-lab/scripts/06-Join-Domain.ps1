<#
.SYNOPSIS
    Part 7 / Part 9: joins APP01 or CLIENT01 to the domain, into the right OU.

.DESCRIPTION
    Run on the machine being joined, as its local Administrator.
      - Confirms DNS can find the domain controller (the #1 cause of failed joins)
      - Joins the domain, placing the computer in Corp\Servers or Corp\Computers
      - Restarts

    You'll be asked for domain credentials: use LAB\adm-nwang.

.PARAMETER Type
    Server (APP01) or Workstation (CLIENT01).

.EXAMPLE
    .\06-Join-Domain.ps1 -Type Server
#>
#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Server', 'Workstation')]
    [string]$Type,

    [string]$ConfigPath = "$PSScriptRoot\lab-config.psd1"
)

$ErrorActionPreference = 'Stop'
$cfg = Import-PowerShellDataFile $ConfigPath
$ou  = if ($Type -eq 'Server') { 'Servers' } else { 'Computers' }
$ouPath = "OU=$ou,OU=$($cfg.TopOU),$($cfg.DomainDN)"

# A domain join finds the DC through DNS SRV records. Check that first.
Write-Output "Looking up the domain controller for $($cfg.DomainName)..."
try {
    $srv = Resolve-DnsName -Name "_ldap._tcp.dc._msdcs.$($cfg.DomainName)" -Type SRV -ErrorAction Stop |
        Where-Object Type -eq 'SRV'
    Write-Output "  Found: $($srv.NameTarget -join ', ')"
} catch {
    throw "Can't find a domain controller in DNS. Make sure this computer's DNS server is $($cfg.DC.IP), then try again."
}

$cred = Get-Credential -Message "Domain admin to join $($cfg.DomainName) (for example $($cfg.NetbiosName)\$($cfg.AdminAccount.Sam))"

Write-Output "Joining $env:COMPUTERNAME to $($cfg.DomainName) in $ouPath, then restarting..."
Add-Computer -DomainName $cfg.DomainName -OUPath $ouPath -Credential $cred -Restart -Force
