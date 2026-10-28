<#
.SYNOPSIS
    Part 8: turns APP01 into an application and file server.

.DESCRIPTION
    Run on APP01 as LAB\adm-nwang, after it has joined the domain.
    Directory and DNS (done remotely against DC01 with RSAT tools):
      - Adds APP01 to GG-Intranet-Servers so it may use the intranet gMSA
      - Creates the DNS name intranet.lab.local (CNAME to APP01)
    Web server:
      - Installs IIS with Windows Authentication and ASP.NET 4.8
      - Installs the gMSA on APP01 and runs the intranet app pool as that account
      - Creates the Intranet site on HTTP and HTTPS, with Windows Authentication only
    File server:
      - Creates the Finance share with Access-Based Enumeration
      - Grants NTFS permissions to the domain local groups (AGDLP)

.EXAMPLE
    .\07-Deploy-AppServer.ps1
#>
#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [string]$ConfigPath = "$PSScriptRoot\lab-config.psd1"
)

$ErrorActionPreference = 'Stop'
$cfg  = Import-PowerShellDataFile $ConfigPath
$g    = $cfg.Intranet
$s    = $cfg.Share
$nb   = $cfg.NetbiosName
$dc   = $cfg.DC.Name

if ($env:COMPUTERNAME -ne $cfg.App.Name) {
    throw "Run this on $($cfg.App.Name). This computer is $env:COMPUTERNAME."
}

# ============================ Tools =========================================
Write-Output 'Installing IIS, Windows Authentication, ASP.NET, and RSAT tools...'
Install-WindowsFeature -Name Web-Server, Web-Windows-Auth, Web-Asp-Net45, Web-Mgmt-Console, `
    RSAT-AD-PowerShell, RSAT-DNS-Server -IncludeManagementTools | Out-Null
Import-Module ActiveDirectory, DnsServer, WebAdministration

# ============================ Directory and DNS ==============================
Write-Output "Adding $env:COMPUTERNAME to $($g.ServerGroup)"
Add-ADGroupMember -Identity $g.ServerGroup -Members (Get-ADComputer $env:COMPUTERNAME)

# The computer picks up new group memberships in its Kerberos ticket. Purge the
# SYSTEM account's tickets so it gets a fresh one now, instead of rebooting.
klist -li 0x3e7 purge | Out-Null

$short = $g.HostName.Split('.')[0]
if (-not (Get-DnsServerResourceRecord -ComputerName $dc -ZoneName $cfg.DomainName -Name $short -ErrorAction SilentlyContinue)) {
    Write-Output "Creating DNS alias $($g.HostName) -> $($cfg.App.Name).$($cfg.DomainName)"
    Add-DnsServerResourceRecordCName -ComputerName $dc -ZoneName $cfg.DomainName -Name $short `
        -HostNameAlias "$($cfg.App.Name).$($cfg.DomainName)"
}

# ============================ gMSA ===========================================
Write-Output "Installing gMSA $($g.Gmsa) on this server"
Install-ADServiceAccount -Identity $g.Gmsa
if (-not (Test-ADServiceAccount -Identity $g.Gmsa)) {
    throw "Test-ADServiceAccount failed. Restart $env:COMPUTERNAME and run this script again."
}

# ============================ Intranet site ==================================
Write-Output 'Creating the intranet site'
New-Item -ItemType Directory -Path $g.Path -Force | Out-Null
@"
<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"><title>LAB Intranet</title></head>
<body style="font-family: Segoe UI, sans-serif; max-width: 640px; margin: 48px auto;">
  <h1>Welcome to the LAB intranet</h1>
  <p>Served by $($cfg.App.Name) through IIS, running as the group managed service account <b>$nb\$($g.Gmsa)`$</b>.</p>
  <p>You signed in automatically with Windows Authentication.</p>
</body></html>
"@ | Set-Content -Path (Join-Path $g.Path 'index.html') -Encoding UTF8

# Only the gMSA (and admins) need to read the site files
icacls $g.Path /grant "$nb\$($g.Gmsa)`$:(OI)(CI)RX" | Out-Null

if (-not (Test-Path "IIS:\AppPools\$($g.AppPool)")) {
    New-WebAppPool -Name $g.AppPool | Out-Null
}
# identityType 3 = SpecificUser. A gMSA has no password to type: AD manages it.
Set-ItemProperty "IIS:\AppPools\$($g.AppPool)" -Name processModel -Value @{
    identityType = 3; userName = "$nb\$($g.Gmsa)`$"; password = ''
}

if (-not (Get-Website -Name $g.SiteName)) {
    New-Website -Name $g.SiteName -PhysicalPath $g.Path -ApplicationPool $g.AppPool `
        -HostHeader $g.HostName -Port 80 | Out-Null
}

# Windows Authentication on, anonymous off: only domain users can open the site
Set-WebConfigurationProperty -PSPath 'IIS:\' -Location $g.SiteName `
    -Filter 'system.webServer/security/authentication/anonymousAuthentication' -Name enabled -Value $false
Set-WebConfigurationProperty -PSPath 'IIS:\' -Location $g.SiteName `
    -Filter 'system.webServer/security/authentication/windowsAuthentication' -Name enabled -Value $true

# HTTPS with a self-signed certificate (a real company would use its internal CA)
if (-not (Get-WebBinding -Name $g.SiteName -Protocol https)) {
    Write-Output 'Adding an HTTPS binding'
    $cert = New-SelfSignedCertificate -DnsName $g.HostName -CertStoreLocation 'Cert:\LocalMachine\My' `
        -FriendlyName 'LAB intranet (self-signed)' -NotAfter (Get-Date).AddYears(2)
    New-WebBinding -Name $g.SiteName -Protocol https -Port 443 -HostHeader $g.HostName -SslFlags 1
    (Get-WebBinding -Name $g.SiteName -Protocol https).AddSslCertificate($cert.Thumbprint, 'My')
}
Restart-WebAppPool -Name $g.AppPool

# ============================ File share =====================================
Write-Output "Creating the $($s.Name) share"
New-Item -ItemType Directory -Path $s.Path -Force | Out-Null

# NTFS: stop inheriting broad permissions, then grant exactly what's needed
icacls $s.Path /inheritance:r `
    /grant 'SYSTEM:(OI)(CI)F' `
    /grant 'BUILTIN\Administrators:(OI)(CI)F' `
    /grant "$nb\$($s.ModifyGroup):(OI)(CI)M" `
    /grant "$nb\$($s.ReadGroup):(OI)(CI)RX" | Out-Null

# Share permissions: authenticated users can connect; NTFS decides what they can do
if (-not (Get-SmbShare -Name $s.Name -ErrorAction SilentlyContinue)) {
    New-SmbShare -Name $s.Name -Path $s.Path -FullAccess 'BUILTIN\Administrators' `
        -ChangeAccess 'NT AUTHORITY\Authenticated Users' -FolderEnumerationMode AccessBased | Out-Null
}

Write-Output ''
Write-Output 'Check your work (from CLIENT01, signed in as a Finance user):'
Write-Output "  https://$($g.HostName)   (accept the self-signed certificate warning)"
Write-Output "  \\$($cfg.App.Name)\$($s.Name)"
