<#
.SYNOPSIS
    Creates new Active Directory user accounts for new hires.

.DESCRIPTION
    Creates one user from parameters, or many users from a CSV file. For each user it:
      - builds the username (first initial + last name, e.g. jsmith) and checks it isn't taken
      - creates the account in the target OU with title, department, and manager
      - sets a random temporary password and forces a change at first logon
      - adds the user to the listed security groups
      - writes a summary (and the temporary passwords) to a CSV report

    Supports -WhatIf so you can preview every change before making it.

.PARAMETER CsvPath
    Path to a CSV with columns: FirstName, LastName, Title, Department, Manager, OU, Groups
    Groups is a semicolon-separated list, e.g. "VPN Users;HR Staff".

.PARAMETER FirstName, LastName, Title, Department, Manager, OU, Groups
    Use these instead of -CsvPath to create a single user.

.PARAMETER Domain
    The UPN suffix for new accounts, e.g. corp.example.com.

.PARAMETER ReportPath
    Where to save the onboarding report. Defaults to the current folder.

.EXAMPLE
    .\New-ADUserOnboarding.ps1 -CsvPath .\new-hires.csv -Domain corp.example.com -WhatIf

.EXAMPLE
    .\New-ADUserOnboarding.ps1 -FirstName Jane -LastName Smith -Title "Analyst" -Department "Finance" `
        -OU "OU=Users,OU=Finance,DC=corp,DC=example,DC=com" -Groups "Finance Staff","VPN Users" -Domain corp.example.com

.NOTES
    Requires the ActiveDirectory module (RSAT) and rights to create users in the target OU.
    The report contains temporary passwords: hand them off securely and delete the file afterward.
#>
[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Csv')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Csv')]
    [string]$CsvPath,

    [Parameter(Mandatory, ParameterSetName = 'Single')] [string]$FirstName,
    [Parameter(Mandatory, ParameterSetName = 'Single')] [string]$LastName,
    [Parameter(ParameterSetName = 'Single')] [string]$Title,
    [Parameter(ParameterSetName = 'Single')] [string]$Department,
    [Parameter(ParameterSetName = 'Single')] [string]$Manager,
    [Parameter(Mandatory, ParameterSetName = 'Single')] [string]$OU,
    [Parameter(ParameterSetName = 'Single')] [string[]]$Groups,

    [Parameter(Mandatory)]
    [string]$Domain,

    [string]$ReportPath = ".\onboarding-report-$(Get-Date -Format 'yyyyMMdd-HHmm').csv"
)

Import-Module ActiveDirectory -ErrorAction Stop

function New-TempPassword {
    # 16 characters drawn from upper, lower, digits, and symbols using a cryptographic random generator.
    $sets = @('ABCDEFGHJKLMNPQRSTUVWXYZ', 'abcdefghijkmnopqrstuvwxyz', '23456789', '!@#$%*?-')
    $all  = -join $sets
    $rng  = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $bytes = New-Object byte[] 1
    $pick = {
        param($chars)
        $rng.GetBytes($bytes)
        $chars[$bytes[0] % $chars.Length]
    }
    # Guarantee one character from each set, then fill the rest.
    $chars = foreach ($s in $sets) { & $pick $s }
    $chars += 1..12 | ForEach-Object { & $pick $all }
    -join ($chars | Sort-Object { Get-Random })
}

function Get-UniqueSam {
    param([string]$First, [string]$Last)
    $base = ($First.Substring(0, 1) + $Last) -replace '[^a-zA-Z0-9]', ''
    $base = $base.ToLower()
    if ($base.Length -gt 20) { $base = $base.Substring(0, 20) }   # sAMAccountName limit
    $sam = $base
    $n = 1
    while (Get-ADUser -Filter "SamAccountName -eq '$sam'" -ErrorAction SilentlyContinue) {
        $n++
        $suffix = "$n"
        $sam = $base.Substring(0, [Math]::Min($base.Length, 20 - $suffix.Length)) + $suffix
    }
    $sam
}

# Build the list of people to onboard.
if ($PSCmdlet.ParameterSetName -eq 'Csv') {
    $people = Import-Csv -Path $CsvPath
} else {
    $people = @([pscustomobject]@{
        FirstName = $FirstName; LastName = $LastName; Title = $Title; Department = $Department
        Manager = $Manager; OU = $OU; Groups = ($Groups -join ';')
    })
}

$results = foreach ($p in $people) {
    $sam         = Get-UniqueSam -First $p.FirstName -Last $p.LastName
    $displayName = "$($p.FirstName) $($p.LastName)"
    $upn         = "$sam@$Domain"
    $tempPass    = New-TempPassword
    $status      = 'Created'
    $note        = ''

    $userParams = @{
        Name                  = $displayName
        GivenName             = $p.FirstName
        Surname               = $p.LastName
        DisplayName           = $displayName
        SamAccountName        = $sam
        UserPrincipalName     = $upn
        Path                  = $p.OU
        AccountPassword       = (ConvertTo-SecureString $tempPass -AsPlainText -Force)
        ChangePasswordAtLogon = $true
        Enabled               = $true
    }
    if ($p.Title)      { $userParams.Title = $p.Title }
    if ($p.Department) { $userParams.Department = $p.Department }
    if ($p.Manager) {
        $mgr = Get-ADUser -Filter "SamAccountName -eq '$($p.Manager)'" -ErrorAction SilentlyContinue
        if ($mgr) { $userParams.Manager = $mgr.DistinguishedName }
        else      { $note += "Manager '$($p.Manager)' not found. " }
    }

    try {
        if ($PSCmdlet.ShouldProcess($upn, "Create user in $($p.OU)")) {
            New-ADUser @userParams -ErrorAction Stop

            $groupList = @($p.Groups -split ';' | Where-Object { $_.Trim() })
            foreach ($g in $groupList) {
                try {
                    Add-ADGroupMember -Identity $g.Trim() -Members $sam -ErrorAction Stop
                } catch {
                    $note += "Could not add to '$($g.Trim())': $($_.Exception.Message) "
                }
            }
        } else {
            $status   = 'Preview (WhatIf)'
            $tempPass = ''
        }
    } catch {
        $status   = 'Failed'
        $tempPass = ''
        $note    += $_.Exception.Message
    }

    [pscustomobject]@{
        DisplayName       = $displayName
        SamAccountName    = $sam
        UserPrincipalName = $upn
        OU                = $p.OU
        Groups            = $p.Groups
        TempPassword      = $tempPass
        Status            = $status
        Notes             = $note.Trim()
    }
}

$results | Format-Table DisplayName, SamAccountName, Status, Notes -AutoSize

if (-not $WhatIfPreference) {
    $results | Export-Csv -Path $ReportPath -NoTypeInformation
    Write-Host "Report saved to $ReportPath. It contains temporary passwords: share them securely, then delete it." -ForegroundColor Yellow
}
