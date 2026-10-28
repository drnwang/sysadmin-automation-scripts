@{
    # ---------------------------------------------------------------------
    # One place for every name and address in the lab.
    # All scripts read this file. Change values here, not in the scripts.
    # ---------------------------------------------------------------------

    # Domain
    DomainName      = 'lab.local'
    NetbiosName     = 'LAB'
    DomainDN        = 'DC=lab,DC=local'
    TimeZone        = 'Eastern Standard Time'

    # Network
    Subnet          = '10.10.10.0'
    PrefixLength    = 24
    Gateway         = '10.10.10.1'
    DnsForwarders   = @('1.1.1.1', '8.8.8.8')

    # Servers
    DC = @{
        Name = 'DC01'
        IP   = '10.10.10.10'
    }
    App = @{
        Name = 'APP01'
        IP   = '10.10.10.20'
    }

    # DHCP
    Dhcp = @{
        ScopeName  = 'Lab clients'
        StartRange = '10.10.10.100'
        EndRange   = '10.10.10.200'
        SubnetMask = '255.255.255.0'
        LeaseDays  = 8
    }

    # Hyper-V (used only by 00-New-LabVMs.ps1 on your PC)
    HyperV = @{
        SwitchName  = 'LabSwitch'
        NatName     = 'LabNAT'
        VMPath      = 'C:\HyperV\Lab'
        ServerIso   = 'C:\ISO\WindowsServer2022_Eval.iso'
        ClientIso   = 'C:\ISO\Windows11_Enterprise_Eval.iso'
        Machines    = @(
            @{ Name = 'DC01';     Iso = 'Server'; MemoryGB = 4; DiskGB = 60; CPU = 2 }
            @{ Name = 'APP01';    Iso = 'Server'; MemoryGB = 4; DiskGB = 60; CPU = 2 }
            @{ Name = 'CLIENT01'; Iso = 'Client'; MemoryGB = 4; DiskGB = 64; CPU = 2 }
        )
    }

    # Active Directory structure (created under OU=Corp)
    TopOU           = 'Corp'
    ChildOUs        = @('Admins', 'Users', 'Computers', 'Servers', 'Groups', 'Service Accounts')
    Departments     = @('Finance', 'HR', 'IT')

    # Accounts
    AdminAccount    = @{ Sam = 'adm-nwang'; First = 'Nathaniel'; Last = 'Wang (Admin)' }
    UsersCsv        = 'users.csv'

    # Application server
    Intranet = @{
        SiteName    = 'Intranet'
        HostName    = 'intranet.lab.local'
        Path        = 'C:\inetpub\intranet'
        AppPool     = 'IntranetPool'
        Gmsa        = 'gmsa-intranet'
        ServerGroup = 'GG-Intranet-Servers'
    }
    Share = @{
        Name        = 'Finance'
        Path        = 'C:\Shares\Finance'
        ModifyGroup = 'DL-FinanceShare-Modify'
        ReadGroup   = 'DL-FinanceShare-Read'
    }
}
