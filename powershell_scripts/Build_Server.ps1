<# Build_Server.ps1 – 10 min zero-touch build  #>

param(
    [string]$Hostname,
    [string]$Domain = 'corp.example.com'
)

Write-Host "Starting build for $Hostname"

# 1) Set computer name & reboot once
Rename-Computer -NewName $Hostname -Force
Restart-Computer –Force

# 2) Join domain and reboot again
Add-Computer -DomainName $Domain -Credential (Get-Credential) -Restart -Force

# 3) Enable required roles/features
$features = @(
  'FS-FileServer','FS-DFS-Namespace','FS-DFS-Replication',
  'Hyper-V','RSAT-AD-Tools'
)
Install-WindowsFeature -Name $features -IncludeManagementTools

# 4) Apply baseline GPOs (link already set in AD)
gpupdate /force

# 5) Install SCCM agent
Invoke-WebRequest 'https://sccm.corp/bin/ccmsetup.exe' -OutFile "$env:TEMP\ccmsetup.exe"
Start-Process "$env:TEMP\ccmsetup.exe" -ArgumentList '/mp:sccm.corp /source:"\\sccm\client"' -Wait

Write-Host "Build complete for $Hostname"
