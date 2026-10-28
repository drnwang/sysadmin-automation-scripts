<#
.SYNOPSIS
    Part 5: builds the OU structure, groups, users, admin account, and intranet service account.

.DESCRIPTION
    Run on DC01 as LAB\Administrator.
      - Creates OU=Corp with Admins, Users (by department), Computers, Servers, Groups, Service Accounts
      - Redirects the default Computers and Users containers into Corp, so new objects
        land where Group Policy can reach them
      - Creates global role groups and domain local resource groups (AGDLP)
      - Creates users from users.csv and adds them to their department group
      - Creates your separate admin account and adds it to Domain Admins
      - Creates the KDS root key and the gMSA that will run the intranet site

    Safe to rerun: anything that already exists is skipped.

.EXAMPLE
    .\04-New-ADStructure.ps1
#>
#Requires -RunAsAdministrator
#Requires -Modules ActiveDirectory
[CmdletBinding()]
param(
    [string]$ConfigPath = "$PSScriptRoot\lab-config.psd1"
)

$ErrorActionPreference = 'Stop'
$cfg   = Import-PowerShellDataFile $ConfigPath
$dn    = $cfg.DomainDN
$corp  = "OU=$($cfg.TopOU),$dn"
$ouOf  = @{}   # friendly name -> distinguished name

function Add-OUIfMissing {
    param([string]$Name, [string]$Path)
    $target = "OU=$Name,$Path"
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$target'" -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $Name -Path $Path -ProtectedFromAccidentalDeletion $true
        Write-Output "  OU created: $target"
    }
    $target
}

function Add-GroupIfMissing {
    param([string]$Name, [string]$Scope, [string]$Description)
    if (-not (Get-ADGroup -Filter "Name -eq '$Name'" -ErrorAction SilentlyContinue)) {
        New-ADGroup -Name $Name -GroupScope $Scope -GroupCategory Security `
            -Path $ouOf['Groups'] -Description $Description
        Write-Output "  Group created: $Name ($Scope)"
    }
}

# ============================ OUs ============================================
Write-Output 'Organizational units'
Add-OUIfMissing -Name $cfg.TopOU -Path $dn | Out-Null
foreach ($child in $cfg.ChildOUs) { $ouOf[$child] = Add-OUIfMissing -Name $child -Path $corp }
foreach ($dept in $cfg.Departments) { $ouOf["Users\$dept"] = Add-OUIfMissing -Name $dept -Path $ouOf['Users'] }

# New computers and users created without a path go here instead of the default containers
redircmp $ouOf['Computers'] | Out-Null
redirusr $ouOf['Users'] | Out-Null
Write-Output '  Default containers redirected to Corp\Computers and Corp\Users'

# ============================ Groups (AGDLP) =================================
Write-Output 'Groups'
foreach ($dept in $cfg.Departments) {
    Add-GroupIfMissing -Name "GG-$dept-Staff" -Scope Global -Description "All $dept staff (role group)"
}
Add-GroupIfMissing -Name $cfg.Share.ModifyGroup -Scope DomainLocal -Description "Modify access to \\$($cfg.App.Name)\$($cfg.Share.Name)"
Add-GroupIfMissing -Name $cfg.Share.ReadGroup   -Scope DomainLocal -Description "Read access to \\$($cfg.App.Name)\$($cfg.Share.Name)"
Add-GroupIfMissing -Name $cfg.Intranet.ServerGroup -Scope Global -Description 'Servers allowed to use the intranet gMSA'

# Role groups go into resource groups; permissions are granted only to resource groups
Add-ADGroupMember -Identity $cfg.Share.ModifyGroup -Members 'GG-Finance-Staff'
Add-ADGroupMember -Identity $cfg.Share.ReadGroup   -Members 'GG-HR-Staff'

# ============================ Users ==========================================
Write-Output 'Users'
$initial = Read-Host -AsSecureString 'Initial password for lab users (they must change it at first sign-in)'
$people  = Import-Csv (Join-Path $PSScriptRoot $cfg.UsersCsv)

foreach ($p in $people) {
    if (-not (Get-ADUser -Filter "SamAccountName -eq '$($p.Sam)'" -ErrorAction SilentlyContinue)) {
        New-ADUser -Name "$($p.FirstName) $($p.LastName)" -GivenName $p.FirstName -Surname $p.LastName `
            -DisplayName "$($p.FirstName) $($p.LastName)" -SamAccountName $p.Sam `
            -UserPrincipalName "$($p.Sam)@$($cfg.DomainName)" -Title $p.Title -Department $p.Department `
            -Path $ouOf["Users\$($p.Department)"] -AccountPassword $initial `
            -ChangePasswordAtLogon $true -Enabled $true
        Write-Output "  User created: $($p.Sam) ($($p.Department))"
    }
    Add-ADGroupMember -Identity "GG-$($p.Department)-Staff" -Members $p.Sam
}

# ============================ Admin account ==================================
Write-Output 'Admin account'
$adm = $cfg.AdminAccount
if (-not (Get-ADUser -Filter "SamAccountName -eq '$($adm.Sam)'" -ErrorAction SilentlyContinue)) {
    $admPass = Read-Host -AsSecureString "Password for your admin account $($adm.Sam)"
    New-ADUser -Name "$($adm.First) $($adm.Last)" -GivenName $adm.First -Surname $adm.Last `
        -SamAccountName $adm.Sam -UserPrincipalName "$($adm.Sam)@$($cfg.DomainName)" `
        -Path $ouOf['Admins'] -AccountPassword $admPass -Enabled $true `
        -Description 'Admin account. Use only for administrative tasks.'
    Write-Output "  Admin created: $($adm.Sam)"
}
Add-ADGroupMember -Identity 'Domain Admins' -Members $adm.Sam

# ============================ gMSA for the intranet ==========================
Write-Output 'Group Managed Service Account'
if (-not (Get-KdsRootKey)) {
    # LAB ONLY: backdating makes the key usable immediately. In production, run
    # Add-KdsRootKey -EffectiveImmediately and wait 10 hours for replication.
    Add-KdsRootKey -EffectiveTime ((Get-Date).AddHours(-10)) | Out-Null
    Write-Output '  KDS root key created'
}

$g = $cfg.Intranet
if (-not (Get-ADServiceAccount -Filter "Name -eq '$($g.Gmsa)'" -ErrorAction SilentlyContinue)) {
    New-ADServiceAccount -Name $g.Gmsa -DNSHostName "$($g.Gmsa).$($cfg.DomainName)" `
        -PrincipalsAllowedToRetrieveManagedPassword $g.ServerGroup `
        -Path $ouOf['Service Accounts'] -Description 'Runs the intranet IIS app pool'
    Write-Output "  gMSA created: $($g.Gmsa)"
}

Write-Output ''
Write-Output 'Check your work:'
Write-Output "  Get-ADOrganizationalUnit -Filter * -SearchBase '$corp' | Select-Object DistinguishedName"
Write-Output "  Get-ADGroupMember $($cfg.Share.ModifyGroup) -Recursive | Select-Object SamAccountName"
Write-Output "  Get-ADServiceAccount $($g.Gmsa) -Properties PrincipalsAllowedToRetrieveManagedPassword"
Write-Output "Sign out and sign back in as $($cfg.NetbiosName)\$($adm.Sam) for the rest of the lab."
