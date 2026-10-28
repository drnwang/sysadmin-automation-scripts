<#
.SYNOPSIS
    Part 3: installs Active Directory Domain Services and creates the lab.local forest.

.DESCRIPTION
    Run on DC01 as the local Administrator, after 01-Initialize-Server.ps1 -Role DC.
      - Installs the AD DS role and management tools
      - Runs a prerequisite check
      - Promotes DC01 to the first domain controller of a new forest, with DNS
      - Restarts automatically when done

    You'll be asked for the Directory Services Restore Mode (DSRM) password. It's the
    emergency password for restoring AD; store it somewhere safe.

.EXAMPLE
    .\02-Install-DomainController.ps1
#>
#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [string]$ConfigPath = "$PSScriptRoot\lab-config.psd1"
)

$ErrorActionPreference = 'Stop'
$cfg = Import-PowerShellDataFile $ConfigPath

if ($env:COMPUTERNAME -ne $cfg.DC.Name) {
    throw "Run this on $($cfg.DC.Name). This computer is $env:COMPUTERNAME."
}

Write-Output 'Installing the AD DS role...'
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools | Out-Null

$dsrm = Read-Host -AsSecureString 'Directory Services Restore Mode (DSRM) password'

$forest = @{
    DomainName                    = $cfg.DomainName
    DomainNetbiosName             = $cfg.NetbiosName
    ForestMode                    = 'WinThreshold'   # Windows Server 2016 functional level
    DomainMode                    = 'WinThreshold'
    InstallDns                    = $true
    SafeModeAdministratorPassword = $dsrm
    DatabasePath                  = 'C:\Windows\NTDS'
    LogPath                       = 'C:\Windows\NTDS'
    SysvolPath                    = 'C:\Windows\SYSVOL'
}

Write-Output 'Checking prerequisites...'
$test = Test-ADDSForestInstallation @forest -WarningAction SilentlyContinue
if ($test.Status -ne 'Success') {
    $test | Format-List
    throw 'Prerequisite check failed. Fix the issues above and run again.'
}

Write-Output "Creating forest $($cfg.DomainName). DC01 restarts automatically when finished."
Install-ADDSForest @forest -NoRebootOnCompletion:$false -Force
