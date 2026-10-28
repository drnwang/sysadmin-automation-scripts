<#
.SYNOPSIS
    Lists Active Directory users whose passwords expire soon, or already have.

.DESCRIPTION
    Uses the msDS-UserPasswordExpiryTimeComputed attribute, which accounts for both the
    default domain policy and fine-grained password policies. Skips disabled accounts and
    accounts set to "password never expires".

    Useful for proactive help desk outreach: contact users before they get locked out,
    especially remote users who need to change their password while on VPN.

.PARAMETER Days
    Report passwords that expire within this many days. Default: 14.

.PARAMETER SearchBase
    Optional OU to limit the search, e.g. "OU=Users,DC=corp,DC=example,DC=com".

.PARAMETER ReportPath
    Optional path to export the results as CSV.

.EXAMPLE
    .\Get-PasswordExpiryReport.ps1 -Days 7

.EXAMPLE
    .\Get-PasswordExpiryReport.ps1 -Days 14 -SearchBase "OU=Users,DC=corp,DC=example,DC=com" -ReportPath .\expiring.csv

.NOTES
    Requires the ActiveDirectory module (RSAT). Read-only: makes no changes.
#>
[CmdletBinding()]
param(
    [int]$Days = 14,
    [string]$SearchBase,
    [string]$ReportPath
)

Import-Module ActiveDirectory -ErrorAction Stop

$now    = Get-Date
$cutoff = $now.AddDays($Days)

$query = @{
    Filter     = 'Enabled -eq $true -and PasswordNeverExpires -eq $false'
    Properties = 'DisplayName', 'EmailAddress', 'PasswordLastSet', 'msDS-UserPasswordExpiryTimeComputed'
}
if ($SearchBase) { $query.SearchBase = $SearchBase }

$results = Get-ADUser @query | ForEach-Object {
    $raw = $_.'msDS-UserPasswordExpiryTimeComputed'
    # 0 or the max value means "never expires" or "must change at next logon" with no expiry date.
    if (-not $raw -or $raw -eq 0 -or $raw -eq [int64]::MaxValue) { return }

    $expires = [datetime]::FromFileTime($raw)
    if ($expires -le $cutoff) {
        [pscustomobject]@{
            DisplayName     = $_.DisplayName
            SamAccountName  = $_.SamAccountName
            Email           = $_.EmailAddress
            PasswordLastSet = $_.PasswordLastSet
            Expires         = $expires
            DaysLeft        = [math]::Floor(($expires - $now).TotalDays)
            Status          = if ($expires -lt $now) { 'Expired' } else { 'Expiring soon' }
        }
    }
} | Sort-Object Expires

if (-not $results) {
    Write-Host "No passwords expire in the next $Days days." -ForegroundColor Green
    return
}

$results | Format-Table DisplayName, SamAccountName, Expires, DaysLeft, Status -AutoSize

if ($ReportPath) {
    $results | Export-Csv -Path $ReportPath -NoTypeInformation
    Write-Host "Report saved to $ReportPath" -ForegroundColor Green
}
