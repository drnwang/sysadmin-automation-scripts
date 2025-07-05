# Audit Active Directory for users not logged in for 90+ days
Import-Module ActiveDirectory

$cutoff = (Get-Date).AddDays(-90)
Get-ADUser -Filter * -Properties LastLogonDate | Where-Object {
    $_.LastLogonDate -lt $cutoff -or !$_.LastLogonDate
} | Select-Object Name, SamAccountName, LastLogonDate
