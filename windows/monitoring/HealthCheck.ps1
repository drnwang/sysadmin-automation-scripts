<# HealthCheck.ps1 – runs from Task Scheduler at 06:00 #>
$report = New-Object System.Text.StringBuilder

# CPU & Memory snapshot
$cpu   = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples[0].CookedValue
$memOK = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB -gt 2048

$report.AppendLine("CPU Load: {0:N1} %" -f $cpu)         | Out-Null
$report.AppendLine("Memory OK (>2 GB free): $memOK")      | Out-Null

# Disk space check
Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 } |
  ForEach-Object {
      $pct = $_.Used / $_.Size * 100
      $report.AppendLine("$($_.Name): {0:N1} % used" -f $pct) | Out-Null
  }

# Event Log scan
$err = Get-WinEvent -FilterHashtable @{LogName='System'; Level=2; StartTime=(Get-Date).AddHours(-24)}
$report.AppendLine("Critical Errors last 24 h: $($err.Count)") | Out-Null

# Send summary
Send-MailMessage -SmtpServer mail.corp -To infra@corp -From healthbot@corp `
    -Subject "Daily Health Report – $env:COMPUTERNAME" `
    -Body $report.ToString() 