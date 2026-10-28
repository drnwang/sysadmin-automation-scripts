<#
.SYNOPSIS
    Part 1: creates the lab network and the three VMs in Hyper-V.

.DESCRIPTION
    Run on YOUR PC (the Hyper-V host), in an elevated PowerShell window.
      - Creates an internal virtual switch and gives the host the gateway IP (10.10.10.1)
      - Creates a NAT so lab VMs can reach the internet without touching your home network
      - Creates DC01, APP01, and CLIENT01 (Generation 2, Secure Boot, TPM for Windows 11)
        with the right ISO attached as the first boot device
      - Takes no action on anything that already exists, so it's safe to rerun

.NOTES
    Requires Windows 10/11 Pro or Enterprise with Hyper-V enabled:
      Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
    Using VirtualBox instead? Follow Part 1 of the click-ops guide.
#>
#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [string]$ConfigPath = "$PSScriptRoot\lab-config.psd1"
)

$ErrorActionPreference = 'Stop'
$cfg = Import-PowerShellDataFile $ConfigPath
$hv  = $cfg.HyperV

# --- Virtual switch: internal, so only the host and the VMs can see it ---------
if (-not (Get-VMSwitch -Name $hv.SwitchName -ErrorAction SilentlyContinue)) {
    Write-Output "Creating internal switch $($hv.SwitchName)"
    New-VMSwitch -Name $hv.SwitchName -SwitchType Internal | Out-Null
}

# --- Give the host the gateway address on that switch -------------------------
$alias = "vEthernet ($($hv.SwitchName))"
if (-not (Get-NetIPAddress -InterfaceAlias $alias -IPAddress $cfg.Gateway -ErrorAction SilentlyContinue)) {
    Write-Output "Assigning $($cfg.Gateway) to $alias"
    New-NetIPAddress -InterfaceAlias $alias -IPAddress $cfg.Gateway -PrefixLength $cfg.PrefixLength | Out-Null
}

# --- NAT: lab traffic leaves through the host's internet connection ------------
if (-not (Get-NetNat -Name $hv.NatName -ErrorAction SilentlyContinue)) {
    Write-Output "Creating NAT $($hv.NatName) for $($cfg.Subnet)/$($cfg.PrefixLength)"
    New-NetNat -Name $hv.NatName -InternalIPInterfaceAddressPrefix "$($cfg.Subnet)/$($cfg.PrefixLength)" | Out-Null
}

# --- Virtual machines ---------------------------------------------------------
New-Item -ItemType Directory -Path $hv.VMPath -Force | Out-Null

foreach ($m in $hv.Machines) {
    if (Get-VM -Name $m.Name -ErrorAction SilentlyContinue) {
        Write-Output "$($m.Name) already exists, skipping"
        continue
    }

    $iso = if ($m.Iso -eq 'Client') { $hv.ClientIso } else { $hv.ServerIso }
    if (-not (Test-Path $iso)) { throw "ISO not found: $iso. Update HyperV.ServerIso / ClientIso in lab-config.psd1." }

    Write-Output "Creating $($m.Name)"
    $vm = New-VM -Name $m.Name -Generation 2 `
        -MemoryStartupBytes ([int64]$m.MemoryGB * 1GB) `
        -NewVHDPath (Join-Path $hv.VMPath "$($m.Name).vhdx") `
        -NewVHDSizeBytes ([int64]$m.DiskGB * 1GB) `
        -SwitchName $hv.SwitchName -Path $hv.VMPath

    Set-VMProcessor -VM $vm -Count $m.CPU
    Set-VMMemory -VM $vm -DynamicMemoryEnabled $false   # domain controllers prefer fixed memory

    # Windows 11 requires TPM 2.0 and Secure Boot
    Set-VMKeyProtector -VM $vm -NewLocalKeyProtector
    Enable-VMTPM -VM $vm

    $dvd = Add-VMDvdDrive -VM $vm -Path $iso -Passthru
    Set-VMFirmware -VM $vm -FirstBootDevice $dvd

    # Turn off automatic checkpoints; take them deliberately before big changes instead
    Set-VM -VM $vm -AutomaticCheckpointsEnabled $false -CheckpointType Production
}

Write-Output ""
Write-Output "Done. Start each VM with Start-VM <name>, connect with vmconnect, and install Windows (Part 2)."
Write-Output "Tip: press a key quickly when you see 'Press any key to boot from CD or DVD'."
