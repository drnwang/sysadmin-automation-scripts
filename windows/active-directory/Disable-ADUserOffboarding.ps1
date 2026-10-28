<#
.SYNOPSIS
    Offboards a departing user's Active Directory account.

.DESCRIPTION
    For each user it:
      - records their current group memberships (so access can be restored if needed)
      - disables the account
      - resets the password to a random value
      - removes all group memberships except the primary group (Domain Users)
      - stamps the description with the date and ticket number
      - moves the account to a "Disabled Users" OU

    Supports -WhatIf so you can preview every change before making it.

.PARAMETER Identity
    One or more usernames (sAMAccountName) to offboard.

.PARAMETER DisabledOU
    Distinguished name of the OU that holds disabled accounts.

.PARAMETER Ticket
    The ticket or request number, recorded in the account description.

.PARAMETER ReportPath
    Where to save the offboarding report. Defaults to the current folder.

.EXAMPLE
    .\Disable-ADUserOffboarding.ps1 -Identity jsmith -Ticket INC0012345 `
        -DisabledOU "OU=Disabled Users,DC=corp,DC=example,DC=com" -WhatIf

.NOTES
    Requires the ActiveDirectory module (RSAT) and rights to modify users and groups.
    Mailbox, OneDrive, and license cleanup in Microsoft 365 are separate steps.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string[]]$Identity,

    [Parameter(Mandatory)]
    [string]$DisabledOU,

    [Parameter(Mandatory)]
    [string]$Ticket,

    [string]$ReportPath = ".\offboarding-report-$(Get-Date -Format 'yyyyMMdd-HHmm').csv"
)

Import-Module ActiveDirectory -ErrorAction Stop

function Get-RandomSecurePassword {
    # 32 random characters generated straight into a SecureString; never stored as plain text.
    $chars  = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$%*?-'
    $bytes  = New-Object byte[] 32
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    $secure = New-Object System.Security.SecureString
    foreach ($b in $bytes) { $secure.AppendChar($chars[$b % $chars.Length]) }
    # Guarantee complexity: one upper, lower, digit, and symbol.
    foreach ($c in 'Q', 'q', '7', '!') { $secure.AppendChar($c) }
    $secure.MakeReadOnly()
    $secure
}

$today = Get-Date -Format 'yyyy-MM-dd'

$results = foreach ($id in $Identity) {
    $status = 'Offboarded'
    $note   = ''
    $groupNames = ''

    try {
        $user = Get-ADUser -Identity $id -Properties MemberOf, Description -ErrorAction Stop
        $groups = foreach ($dn in $user.MemberOf) { Get-ADGroup -Identity $dn }
        $groupNames = ($groups.Name -join ';')

        if ($PSCmdlet.ShouldProcess($user.SamAccountName, 'Disable, reset password, remove groups, and move')) {
            Disable-ADAccount -Identity $user -ErrorAction Stop

            Set-ADAccountPassword -Identity $user -Reset -NewPassword (Get-RandomSecurePassword) -ErrorAction Stop

            foreach ($g in $groups) {
                try {
                    Remove-ADGroupMember -Identity $g -Members $user -Confirm:$false -ErrorAction Stop
                } catch {
                    $note += "Could not remove from '$($g.Name)': $($_.Exception.Message) "
                }
            }

            Set-ADUser -Identity $user -Description "Disabled $today - $Ticket" -ErrorAction Stop
            Move-ADObject -Identity $user.DistinguishedName -TargetPath $DisabledOU -ErrorAction Stop
        } else {
            $status = 'Preview (WhatIf)'
        }
    } catch {
        $status = 'Failed'
        $note  += $_.Exception.Message
    }

    [pscustomobject]@{
        SamAccountName = $id
        Ticket         = $Ticket
        Date           = $today
        GroupsRemoved  = $groupNames
        Status         = $status
        Notes          = $note.Trim()
    }
}

$results | Format-Table SamAccountName, Status, GroupsRemoved, Notes -AutoSize

if (-not $WhatIfPreference) {
    $results | Export-Csv -Path $ReportPath -NoTypeInformation
    Write-Host "Report saved to $ReportPath" -ForegroundColor Green
}
