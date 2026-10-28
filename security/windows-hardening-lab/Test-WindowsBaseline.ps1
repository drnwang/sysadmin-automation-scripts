<#
.SYNOPSIS
    Read-only check of key Windows Server hardening settings from CIS Benchmarks and DISA STIGs.

.DESCRIPTION
    Checks 15 high-impact settings (SMBv1, SMB signing, TLS versions, NTLM, RDP, firewall,
    password and lockout policy, logging, Defender, and more) and reports Pass, Fail, or Unknown
    for each, with a short fix hint.

    It makes NO changes. Run it before and after applying a security baseline to show
    what improved.

.PARAMETER ReportPath
    Optional path to save results as CSV.

.EXAMPLE
    .\Test-WindowsBaseline.ps1

.EXAMPLE
    .\Test-WindowsBaseline.ps1 -ReportPath .\baseline-before.csv

.NOTES
    Run as administrator on Windows Server 2016-2022 or Windows 10/11.
    This is a quick spot check of important settings, not a full CIS or STIG assessment.
#>
[CmdletBinding()]
param(
    [string]$ReportPath
)

function Get-RegValue {
    param([string]$Path, [string]$Name)
    try { (Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop).$Name } catch { $null }
}

function Get-NetAccountsValue {
    # Reads a line from `net accounts`, e.g. "Minimum password length: 14"
    param([string]$Label)
    $line = (net accounts 2>$null) | Where-Object { $_ -like "$Label*" } | Select-Object -First 1
    if ($line) { ($line -split ':', 2)[1].Trim() } else { $null }
}

$lsa  = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
$tls  = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols'
$rdp  = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'

# Each check returns the actual value and whether it passes.
$checks = @(
    @{ Area = 'Network'; Check = 'SMBv1 server disabled'; Expected = 'False'
       Get = { (Get-SmbServerConfiguration -ErrorAction Stop).EnableSMB1Protocol }
       Pass = { param($v) $v -eq $false }
       Fix = 'Set-SmbServerConfiguration -EnableSMB1Protocol $false' }

    @{ Area = 'Network'; Check = 'SMB server signing required'; Expected = 'True'
       Get = { (Get-SmbServerConfiguration -ErrorAction Stop).RequireSecuritySignature }
       Pass = { param($v) $v -eq $true }
       Fix = 'GPO: Microsoft network server: Digitally sign communications (always) = Enabled' }

    @{ Area = 'Network'; Check = 'TLS 1.0 server disabled'; Expected = '0'
       Get = { Get-RegValue "$tls\TLS 1.0\Server" 'Enabled' }
       Pass = { param($v) $v -eq 0 }
       Fix = "Set $tls\TLS 1.0\Server Enabled = 0 (DWORD), then reboot" }

    @{ Area = 'Network'; Check = 'TLS 1.1 server disabled'; Expected = '0'
       Get = { Get-RegValue "$tls\TLS 1.1\Server" 'Enabled' }
       Pass = { param($v) $v -eq 0 }
       Fix = "Set $tls\TLS 1.1\Server Enabled = 0 (DWORD), then reboot" }

    @{ Area = 'Network'; Check = 'LLMNR disabled'; Expected = '0'
       Get = { Get-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient' 'EnableMulticast' }
       Pass = { param($v) $v -eq 0 }
       Fix = 'GPO: Network > DNS Client > Turn off multicast name resolution = Enabled' }

    @{ Area = 'Authentication'; Check = 'NTLMv2 only (LM and NTLMv1 refused)'; Expected = '5'
       Get = { Get-RegValue $lsa 'LmCompatibilityLevel' }
       Pass = { param($v) $v -eq 5 }
       Fix = 'GPO: Network security: LAN Manager authentication level = Send NTLMv2 response only. Refuse LM & NTLM' }

    @{ Area = 'Authentication'; Check = 'Anonymous enumeration of shares and accounts restricted'; Expected = '1'
       Get = { Get-RegValue $lsa 'RestrictAnonymous' }
       Pass = { param($v) $v -eq 1 }
       Fix = 'GPO: Network access: Do not allow anonymous enumeration of SAM accounts and shares = Enabled' }

    @{ Area = 'Authentication'; Check = 'Minimum password length'; Expected = '14 or more'
       Get = { Get-NetAccountsValue 'Minimum password length' }
       Pass = { param($v) [int]$v -ge 14 }
       Fix = 'Default Domain Policy: Minimum password length = 14' }

    @{ Area = 'Authentication'; Check = 'Account lockout threshold'; Expected = '1 to 5 attempts'
       Get = { Get-NetAccountsValue 'Lockout threshold' }
       Pass = { param($v) $v -match '^\d+$' -and [int]$v -ge 1 -and [int]$v -le 5 }
       Fix = 'Default Domain Policy: Account lockout threshold = 5 (0 means never lock out)' }

    @{ Area = 'Remote access'; Check = 'RDP requires Network Level Authentication'; Expected = '1'
       Get = { Get-RegValue $rdp 'UserAuthentication' }
       Pass = { param($v) $v -eq 1 }
       Fix = 'GPO: Remote Desktop Session Host > Security > Require user authentication ... using NLA = Enabled' }

    @{ Area = 'Host protection'; Check = 'Firewall enabled on all profiles'; Expected = 'Domain, Private, Public'
       Get = { ((Get-NetFirewallProfile -ErrorAction Stop | Where-Object Enabled).Name) -join ', ' }
       Pass = { param($v) @($v -split ', ').Count -eq 3 }
       Fix = 'Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled True' }

    @{ Area = 'Host protection'; Check = 'Defender real-time protection on'; Expected = 'True'
       Get = { (Get-MpComputerStatus -ErrorAction Stop).RealTimeProtectionEnabled }
       Pass = { param($v) $v -eq $true }
       Fix = 'Set-MpPreference -DisableRealtimeMonitoring $false' }

    @{ Area = 'Host protection'; Check = 'Guest account disabled'; Expected = 'False'
       Get = {
           $g = Get-CimInstance Win32_UserAccount -Filter "LocalAccount=True AND SID LIKE '%-501'" -ErrorAction Stop
           if ($g) { -not $g.Disabled } else { 'Not present' }
       }
       Pass = { param($v) $v -eq $false -or $v -eq 'Not present' }
       Fix = 'Disable-LocalUser -Name Guest (or GPO: Accounts: Guest account status = Disabled)' }

    @{ Area = 'Logging'; Check = 'PowerShell script block logging on'; Expected = '1'
       Get = { Get-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging' 'EnableScriptBlockLogging' }
       Pass = { param($v) $v -eq 1 }
       Fix = 'GPO: Windows PowerShell > Turn on PowerShell Script Block Logging = Enabled' }

    @{ Area = 'Logging'; Check = 'Logon events audited (success and failure)'; Expected = 'Success and Failure'
       Get = {
           $line = (auditpol /get /subcategory:"Logon" 2>$null) | Where-Object { $_ -match '^\s+Logon\s' }
           if ($line) { ($line -replace '^\s+Logon\s+', '').Trim() } else { $null }
       }
       Pass = { param($v) $v -eq 'Success and Failure' }
       Fix = 'GPO: Advanced Audit Policy > Logon/Logoff > Audit Logon = Success and Failure' }
)

$results = foreach ($c in $checks) {
    $actual = $null
    $result = 'Unknown'
    try {
        $actual = & $c.Get
        # Note: compare with $null/empty explicitly; a value of 0 or $false is a real answer.
        if (-not ($null -eq $actual -or ($actual -is [string] -and $actual.Length -eq 0))) {
            $result = if (& $c.Pass $actual) { 'Pass' } else { 'Fail' }
        } else {
            $actual = 'Not configured'
            $result = 'Fail'
        }
    } catch {
        $actual = "Could not read: $($_.Exception.Message)"
    }

    [pscustomobject]@{
        Area     = $c.Area
        Check    = $c.Check
        Expected = $c.Expected
        Actual   = "$actual"
        Result   = $result
        Fix      = if ($result -eq 'Pass') { '' } else { $c.Fix }
    }
}

$results | Format-Table Area, Check, Expected, Actual, Result -AutoSize -Wrap

$pass  = @($results | Where-Object Result -eq 'Pass').Count
$fail  = @($results | Where-Object Result -eq 'Fail').Count
$unk   = @($results | Where-Object Result -eq 'Unknown').Count
Write-Output ("Passed {0} of {1} checks ({2} failed, {3} unknown) on {4}" -f $pass, $results.Count, $fail, $unk, $env:COMPUTERNAME)

if ($ReportPath) {
    $results | Export-Csv -Path $ReportPath -NoTypeInformation
    Write-Output "Report saved to $ReportPath"
}
