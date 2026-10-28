<#
.SYNOPSIS
    Part 6: sets the domain password policy and creates the lab's Group Policy Objects.

.DESCRIPTION
    Run on DC01 as LAB\adm-nwang.
      - Domain password and lockout policy (14+ characters, lockout after 5 tries)
      - Creates the ADMX Central Store so every admin edits GPOs with the same templates
      - "Corp - Computer Security Baseline": turns off LLMNR, requires NLA for RDP,
        turns on PowerShell script block logging, and puts intranet.lab.local in the
        Local intranet zone. Linked to Computers and Servers.
      - "Corp - User Settings": locks idle screens after 15 minutes. Linked to Users.

.EXAMPLE
    .\05-New-GroupPolicy.ps1
#>
#Requires -RunAsAdministrator
#Requires -Modules ActiveDirectory, GroupPolicy
[CmdletBinding()]
param(
    [string]$ConfigPath = "$PSScriptRoot\lab-config.psd1"
)

$ErrorActionPreference = 'Stop'
$cfg  = Import-PowerShellDataFile $ConfigPath
$corp = "OU=$($cfg.TopOU),$($cfg.DomainDN)"

# ============================ Password policy ================================
Write-Output 'Default domain password and lockout policy'
Set-ADDefaultDomainPasswordPolicy -Identity $cfg.DomainName `
    -MinPasswordLength 14 -ComplexityEnabled $true -PasswordHistoryCount 24 `
    -MaxPasswordAge (New-TimeSpan -Days 365) -MinPasswordAge (New-TimeSpan -Days 1) `
    -LockoutThreshold 5 -LockoutDuration (New-TimeSpan -Minutes 15) `
    -LockoutObservationWindow (New-TimeSpan -Minutes 15)

# ============================ Central Store ==================================
$central = "\\$($cfg.DomainName)\SYSVOL\$($cfg.DomainName)\Policies\PolicyDefinitions"
if (-not (Test-Path $central)) {
    Write-Output 'Creating the ADMX Central Store'
    Copy-Item -Path "$env:windir\PolicyDefinitions" -Destination $central -Recurse
}

function Add-LinkedGpo {
    param([string]$Name, [string]$Comment, [string[]]$Targets)
    $gpo = Get-GPO -Name $Name -ErrorAction SilentlyContinue
    if (-not $gpo) {
        $gpo = New-GPO -Name $Name -Comment $Comment
        Write-Output "  GPO created: $Name"
    }
    foreach ($t in $Targets) {
        $linked = (Get-GPInheritance -Target $t).GpoLinks | Where-Object DisplayName -eq $Name
        if (-not $linked) {
            New-GPLink -Guid $gpo.Id -Target $t | Out-Null
            Write-Output "    linked to $t"
        }
    }
    $gpo
}

# ============================ Computer baseline ==============================
Write-Output 'Group Policy Objects'
$comp = Add-LinkedGpo -Name 'Corp - Computer Security Baseline' `
    -Comment 'LLMNR off, RDP requires NLA, PowerShell script block logging, intranet zone' `
    -Targets @("OU=Computers,$corp", "OU=Servers,$corp")

# Turn off LLMNR (attackers abuse it to capture password hashes)
Set-GPRegistryValue -Guid $comp.Id -Key 'HKLM\Software\Policies\Microsoft\Windows NT\DNSClient' `
    -ValueName EnableMulticast -Type DWord -Value 0 | Out-Null
# Require Network Level Authentication for Remote Desktop
Set-GPRegistryValue -Guid $comp.Id -Key 'HKLM\Software\Policies\Microsoft\Windows NT\Terminal Services' `
    -ValueName UserAuthentication -Type DWord -Value 1 | Out-Null
# Log the content of PowerShell scripts that run (Event ID 4104)
Set-GPRegistryValue -Guid $comp.Id -Key 'HKLM\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging' `
    -ValueName EnableScriptBlockLogging -Type DWord -Value 1 | Out-Null
# Put the intranet in the Local intranet zone so browsers sign users in automatically
# (names with dots are treated as Internet sites, which prompt for a password)
Set-GPRegistryValue -Guid $comp.Id -Key 'HKLM\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMapKey' `
    -ValueName $cfg.Intranet.HostName -Type String -Value '1' | Out-Null

# ============================ User settings ==================================
$user = Add-LinkedGpo -Name 'Corp - User Settings' `
    -Comment 'Lock idle screens after 15 minutes' `
    -Targets @("OU=Users,$corp")

$desktop = 'HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop'
Set-GPRegistryValue -Guid $user.Id -Key $desktop -ValueName ScreenSaveActive    -Type String -Value '1'   | Out-Null
Set-GPRegistryValue -Guid $user.Id -Key $desktop -ValueName ScreenSaverIsSecure -Type String -Value '1'   | Out-Null
Set-GPRegistryValue -Guid $user.Id -Key $desktop -ValueName ScreenSaveTimeOut   -Type String -Value '900' | Out-Null

Write-Output ''
Write-Output 'Check your work:'
Write-Output "  Get-ADDefaultDomainPasswordPolicy"
Write-Output "  Get-GPInheritance -Target 'OU=Computers,$corp'"
Write-Output "  Get-GPOReport -Name 'Corp - Computer Security Baseline' -ReportType Html -Path .\baseline.html"
