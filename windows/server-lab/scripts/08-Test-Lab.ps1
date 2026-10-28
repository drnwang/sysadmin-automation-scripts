<#
.SYNOPSIS
    Part 10: health check for the whole lab.

.DESCRIPTION
    Run from any domain-joined machine (CLIENT01 is the most realistic) as a domain user.
    Read-only. Reports Pass or Fail for:
      - DNS: DC01, APP01, the intranet alias, reverse lookup, internet resolution
      - Domain: DC locator records, this computer's domain membership
      - Network: LDAP, Kerberos, DNS, SMB on DC01; HTTP and HTTPS on APP01
      - Services: the intranet site answers with Windows Authentication; the Finance share opens

.EXAMPLE
    .\08-Test-Lab.ps1
#>
[CmdletBinding()]
param(
    [string]$ConfigPath = "$PSScriptRoot\lab-config.psd1"
)

$cfg   = Import-PowerShellDataFile $ConfigPath
$dom   = $cfg.DomainName
$dcF   = "$($cfg.DC.Name).$dom"
$appF  = "$($cfg.App.Name).$dom"
$intra = $cfg.Intranet.HostName

$tests = [ordered]@{
    "DNS: $dcF resolves to $($cfg.DC.IP)"     = { (Resolve-DnsName $dcF -Type A -ErrorAction Stop).IPAddress -contains $cfg.DC.IP }
    "DNS: $appF resolves to $($cfg.App.IP)"   = { (Resolve-DnsName $appF -Type A -ErrorAction Stop).IPAddress -contains $cfg.App.IP }
    "DNS: $intra is an alias for APP01"       = { (Resolve-DnsName $intra -ErrorAction Stop | Where-Object Type -eq 'CNAME').NameHost -eq $appF }
    "DNS: reverse lookup of $($cfg.DC.IP)"    = { (Resolve-DnsName $cfg.DC.IP -ErrorAction Stop).NameHost -eq $dcF }
    'DNS: internet names resolve (forwarders)' = { [bool](Resolve-DnsName 'www.microsoft.com' -ErrorAction Stop) }
    'Domain: DC locator SRV records'          = { [bool](Resolve-DnsName "_ldap._tcp.dc._msdcs.$dom" -Type SRV -ErrorAction Stop) }
    'Domain: this computer is joined and finds a DC' = { [bool][System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain().FindDomainController().Name }
    'DC01: LDAP (389)'                        = { (Test-NetConnection $dcF -Port 389 -WarningAction SilentlyContinue).TcpTestSucceeded }
    'DC01: Kerberos (88)'                     = { (Test-NetConnection $dcF -Port 88 -WarningAction SilentlyContinue).TcpTestSucceeded }
    'DC01: DNS (53)'                          = { (Test-NetConnection $dcF -Port 53 -WarningAction SilentlyContinue).TcpTestSucceeded }
    'DC01: SMB / SYSVOL (445)'                = { Test-Path "\\$dom\SYSVOL" }
    'APP01: HTTP (80)'                        = { (Test-NetConnection $appF -Port 80 -WarningAction SilentlyContinue).TcpTestSucceeded }
    'APP01: HTTPS (443)'                      = { (Test-NetConnection $appF -Port 443 -WarningAction SilentlyContinue).TcpTestSucceeded }
    'Intranet: answers with Windows Auth'     = { (Invoke-WebRequest "http://$intra" -UseDefaultCredentials -UseBasicParsing -ErrorAction Stop).StatusCode -eq 200 }
    "Share: \\$($cfg.App.Name)\$($cfg.Share.Name) opens" = { Test-Path "\\$($cfg.App.Name)\$($cfg.Share.Name)" }
}

$results = foreach ($name in $tests.Keys) {
    $ok = $false; $detail = ''
    try { $ok = [bool](& $tests[$name]) } catch { $detail = $_.Exception.Message }
    [pscustomobject]@{ Test = $name; Result = if ($ok) { 'Pass' } else { 'Fail' }; Detail = $detail }
}

$results | Format-Table -AutoSize -Wrap
$passed = @($results | Where-Object Result -eq 'Pass').Count
Write-Output "Passed $passed of $($results.Count) checks."
if ($passed -lt $results.Count) {
    Write-Output 'See Part 10 of either guide for troubleshooting steps.'
    Write-Output "Note: the Finance share test fails for users outside Finance and HR. That's expected."
}
