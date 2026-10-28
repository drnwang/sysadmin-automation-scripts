Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
cd XYZ:   # your site code

New-CMSoftwareUpdateAutoDeploymentRule -Name "Win10 Monthly CU" `
    -CollectionName "All Win10 Workstations" `
    -Product "Windows 10" -UpdateClassifications "Critical Updates","Security Updates" `
    -DayOfWeek Tuesday -WeekOrder First -MonthOffset 0 `
    -EnableComplianceReporting $true -AutoDeploymentEnabled $true 