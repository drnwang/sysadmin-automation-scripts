# Build a Help Desk PowerShell Toolbox

Build a small Windows app, step by step, that puts the most common Tier 1 and Tier 2 tasks behind buttons: unlock an account, reset a password, find which computer a user is on, check a computer's health remotely, and clear a stuck print queue. You'll learn the PowerShell behind each task first, then wrap it in a simple GUI.

> **Status:** tutorial ready. Results and screenshots to be added after the lab is run.

| | |
|---|---|
| **Role** | Help desk, sysadmin |
| **Time** | 1–2 weekends |
| **Cost** | Free |
| **Builds on** | [Server lab](../../windows/server-lab/) (needs DC01, APP01, and CLIENT01) |
| **Resume keywords** | PowerShell, automation, Windows Forms, CIM/WMI, PowerShell remoting, Active Directory |

## Why this matters

"Do you have scripting experience?" is in almost every help desk and sysadmin interview. A tool that saves your team clicks on every ticket is a much better answer than "I know some PowerShell." It also shows you understand **what** help desk work involves.

---

## Part 1: Prepare your admin workstation

Run the toolbox from **CLIENT01**, signed in as an IT account.

1. Install the Active Directory tools. **Settings → System → Optional features → View features** → search **RSAT: Active Directory Domain Services** → install. (Or in admin PowerShell: `Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0`.)
2. Make sure PowerShell remoting works to the servers. It's on by default for Windows Server in a domain. Test it:
   ```powershell
   Test-WSMan APP01
   Invoke-Command -ComputerName APP01 -ScriptBlock { hostname }
   ```
3. For the computer health checks to reach **CLIENT01**-type machines too, allow WMI and remoting through their firewalls with a GPO. On DC01, edit **Corp - Computer Security Baseline** → **Computer Configuration → Policies → Windows Settings → Security Settings → Windows Defender Firewall with Advanced Security → Inbound Rules → New Rule → Predefined: Windows Remote Management** and **Windows Management Instrumentation (WMI)**. Limit them to the IT subnet in the rule's **Scope** tab.

### ✅ Check your work
`Get-ADUser jsmith` returns Jane's account, and `Invoke-Command -ComputerName APP01 { hostname }` returns `APP01`.

---

## Part 2: Learn each task in the console first

Always get a task working in the console before putting it behind a button. Try each one against your lab.

### Unlock an account
```powershell
Get-ADUser jsmith -Properties LockedOut, BadLogonCount, LastBadPasswordAttempt |
    Select-Object Name, LockedOut, BadLogonCount, LastBadPasswordAttempt
Unlock-ADAccount -Identity jsmith
```
Lock `jsmith` first by typing a wrong password 5 times on CLIENT01, so you see `LockedOut: True`.

### Reset a password, with a change required at next sign-in
```powershell
$temp = Read-Host -AsSecureString 'Temporary password'
Set-ADAccountPassword -Identity jsmith -Reset -NewPassword $temp
Set-ADUser -Identity jsmith -ChangePasswordAtLogon $true
```

### Find which computer a user is signed in to
There's no single "where is this user" command in AD, so ask each computer who's signed in:
```powershell
$computers = Get-ADComputer -Filter * -SearchBase 'OU=Computers,OU=Corp,DC=lab,DC=local' | Select-Object -ExpandProperty Name
Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $computers -ErrorAction SilentlyContinue |
    Where-Object UserName -like '*jsmith' |
    Select-Object Name, UserName
```
`Win32_ComputerSystem.UserName` shows the user signed in at the console. It doesn't show RDP sessions, which is a good limitation to mention in an interview.

### Check a computer's health remotely
```powershell
$pc = 'CLIENT01'
$os = Get-CimInstance Win32_OperatingSystem -ComputerName $pc
[pscustomobject]@{
    Computer   = $pc
    OS         = $os.Caption
    LastBoot   = $os.LastBootUpTime
    UptimeDays = [math]::Round(((Get-Date) - $os.LastBootUpTime).TotalDays, 1)
    FreeMemGB  = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
}
Get-CimInstance Win32_LogicalDisk -ComputerName $pc -Filter 'DriveType=3' |
    Select-Object DeviceID, @{ n = 'FreeGB'; e = { [math]::Round($_.FreeSpace / 1GB, 1) } }
Get-HotFix -ComputerName $pc | Sort-Object InstalledOn -Descending | Select-Object -First 1
```

### Clear one printer's stuck jobs on the print server
```powershell
Get-PrintJob -ComputerName APP01 -PrinterName 'Finance-Printer' | Remove-PrintJob
```
(Requires the printer from the [printer deployment lab](../../windows/printer-deployment/).)

---

## Part 3: Build the GUI, one piece at a time

Create a file `HelpdeskToolbox.ps1` in VS Code or PowerShell ISE. Add each block below in order, running the file after each step so you see it grow.

### 3.1 The window
```powershell
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Import-Module ActiveDirectory

$form = New-Object System.Windows.Forms.Form
$form.Text = 'LAB Help Desk Toolbox'
$form.Size = New-Object System.Drawing.Size(560, 520)
$form.StartPosition = 'CenterScreen'
$form.Font = New-Object System.Drawing.Font('Segoe UI', 10)

# Show the window (this line always stays at the very bottom of the file)
[void]$form.ShowDialog()
```
**Run it.** You should see an empty window titled *LAB Help Desk Toolbox*.

### 3.2 Inputs and an output box
Add these lines **above** the `ShowDialog()` line:
```powershell
function New-Label($text, $x, $y) {
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $text; $l.Location = New-Object System.Drawing.Point($x, $y); $l.AutoSize = $true
    $form.Controls.Add($l)
}
function New-TextBox($x, $y) {
    $t = New-Object System.Windows.Forms.TextBox
    $t.Location = New-Object System.Drawing.Point($x, $y); $t.Width = 200
    $form.Controls.Add($t); $t
}

New-Label 'Username' 20 20
$userBox = New-TextBox 120 18
New-Label 'Computer' 20 55
$pcBox = New-TextBox 120 53

$output = New-Object System.Windows.Forms.TextBox
$output.Multiline = $true; $output.ScrollBars = 'Vertical'; $output.ReadOnly = $true
$output.Location = New-Object System.Drawing.Point(20, 230)
$output.Size = New-Object System.Drawing.Size(505, 230)
$output.Font = New-Object System.Drawing.Font('Consolas', 9)
$form.Controls.Add($output)

function Write-Out($text) { $output.AppendText(($text | Out-String) + "`r`n") }
```

### 3.3 A helper for buttons
Every button runs some code and shows errors in the output box instead of crashing:
```powershell
function New-Button($text, $x, $y, [scriptblock]$action) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $text; $b.Location = New-Object System.Drawing.Point($x, $y); $b.Size = New-Object System.Drawing.Size(160, 32)
    $b.Tag = $action          # store this button's code on the button itself
    $b.Add_Click({
        # $this is the button that was clicked
        try { & $this.Tag } catch { Write-Out "ERROR: $($_.Exception.Message)" }
    })
    $form.Controls.Add($b)
}
```
> **Why `Tag`?** Each button needs its own code. Storing it in the button's `Tag` property and running `$this.Tag` on click is the simplest reliable way to do that in Windows Forms.

### 3.4 The account buttons
```powershell
New-Button 'Check account' 20 100 {
    $u = Get-ADUser $userBox.Text -Properties LockedOut, Enabled, PasswordExpired, LastLogonDate, BadLogonCount
    Write-Out ($u | Select-Object Name, Enabled, LockedOut, PasswordExpired, BadLogonCount, LastLogonDate)
}

New-Button 'Unlock account' 190 100 {
    $answer = [System.Windows.Forms.MessageBox]::Show("Unlock $($userBox.Text)? Identity verified?", 'Confirm', 'YesNo')
    if ($answer -eq 'Yes') { Unlock-ADAccount $userBox.Text; Write-Out "Unlocked $($userBox.Text)" }
}

New-Button 'Reset password' 360 100 {
    $answer = [System.Windows.Forms.MessageBox]::Show("Reset the password for $($userBox.Text)? Identity verified?", 'Confirm', 'YesNo')
    if ($answer -ne 'Yes') { return }
    # Random 16-character temporary password, shown once
    $chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$%'
    $temp  = -join (1..16 | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
    $secure = New-Object System.Security.SecureString
    $temp.ToCharArray() | ForEach-Object { $secure.AppendChar($_) }
    Set-ADAccountPassword $userBox.Text -Reset -NewPassword $secure
    Set-ADUser $userBox.Text -ChangePasswordAtLogon $true
    Unlock-ADAccount $userBox.Text
    Write-Out "Temporary password for $($userBox.Text): $temp  (give it by phone; user must change it at sign-in)"
}
```
> **Why the confirmation boxes?** Every action that changes something asks "Identity verified?" first. That habit is exactly what the [password reset KB](../knowledge-base/KB-001-password-reset-and-unlock.md) requires, and it's a good detail to point out in an interview.
>
> `Get-Random` is fine for a lab tool. For production, use a cryptographic generator, like the [onboarding script](../../windows/active-directory/New-ADUserOnboarding.ps1) does.

### 3.5 The computer buttons
```powershell
New-Button 'Find user''s computer' 20 140 {
    $names = Get-ADComputer -Filter * -SearchBase 'OU=Computers,OU=Corp,DC=lab,DC=local' | Select-Object -ExpandProperty Name
    $hits = Get-CimInstance Win32_ComputerSystem -ComputerName $names -ErrorAction SilentlyContinue |
        Where-Object UserName -like "*\$($userBox.Text)"
    if ($hits) { Write-Out ($hits | Select-Object Name, UserName); $pcBox.Text = $hits[0].Name }
    else { Write-Out "$($userBox.Text) isn't signed in at any computer in Corp\Computers." }
}

New-Button 'Computer health' 190 140 {
    $os = Get-CimInstance Win32_OperatingSystem -ComputerName $pcBox.Text
    Write-Out ([pscustomobject]@{
        Computer = $pcBox.Text; OS = $os.Caption; LastBoot = $os.LastBootUpTime
        UptimeDays = [math]::Round(((Get-Date) - $os.LastBootUpTime).TotalDays, 1)
        FreeMemGB = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
    })
    Write-Out (Get-CimInstance Win32_LogicalDisk -ComputerName $pcBox.Text -Filter 'DriveType=3' |
        Select-Object DeviceID, @{ n = 'FreeGB'; e = { [math]::Round($_.FreeSpace / 1GB, 1) } })
}

New-Button 'Clear print queue' 360 140 {
    $printer = 'Finance-Printer'
    $answer = [System.Windows.Forms.MessageBox]::Show("Delete all jobs on $printer?", 'Confirm', 'YesNo')
    if ($answer -eq 'Yes') {
        $jobs = @(Get-PrintJob -ComputerName APP01 -PrinterName $printer)
        $jobs | Remove-PrintJob
        Write-Out "Removed $($jobs.Count) job(s) from $printer"
    }
}
```

### 3.6 Run it
```powershell
powershell.exe -ExecutionPolicy Bypass -File .\HelpdeskToolbox.ps1
```

### ✅ Check your work
Test every button against a real lab problem:
1. Lock `jsmith` (5 wrong passwords) → **Check account** shows `LockedOut: True` → **Unlock account** → Jane can sign in.
2. **Reset password** for `ppatel` → sign in as Priya with the temporary password → Windows asks for a new one.
3. Sign in to CLIENT01 as `mjohnson` → **Find user's computer** with `mjohnson` → the Computer box fills in with `CLIENT01`.
4. **Computer health** shows uptime and free disk space for CLIENT01.

📸 Screenshot: the toolbox after each button

---

## Part 4: Make it production-ready (stretch goals)

| Improvement | Why |
|---|---|
| Write every action to a log file (who, what, when) | Audit trail for account changes |
| Check that the person running it is in **GG-IT-Staff** | Stops the tool being misused if it's copied |
| Use `Get-ADUser -Filter "Name -like '*$text*'"` to search by name | Users often don't know their username |
| Show RDP sessions with `quser /server:APP01` | Find users on servers, not just workstations |
| Add a button for [Get-PasswordExpiryReport.ps1](../../windows/active-directory/) | Proactive outreach before users get locked out |

## Troubleshooting

| Symptom | Fix |
|---|---|
| "The term 'Get-ADUser' is not recognized" | Install RSAT AD tools (Part 1, step 1) |
| Computer health: "The WinRM client cannot process the request" or RPC unavailable | Firewall rules for WinRM and WMI (Part 1, step 3); check the computer is on |
| Buttons do nothing | Errors appear in the output box. Read them there. |
| "Access denied" on unlock or reset | Run as an IT account with rights to manage users in Corp\Users |

## How to talk about it in an interview

> *"I built a PowerShell GUI toolbox for common help desk tasks: account unlocks and resets with an identity-verification prompt, finding which computer a user is signed in to with CIM queries, remote health checks, and clearing print queues on the print server. I tested each command in the console first, then wrapped it in Windows Forms with error handling so it never crashes in front of a user."*

## Results

_To be added after the lab is run:_
- [ ] Screenshots of each button working
- [ ] Final `HelpdeskToolbox.ps1` committed to this folder
- [ ] Which stretch goals you added
