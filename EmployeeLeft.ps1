##Employee left company.  Reset's password, converts mailbox to shared, add's supervisor to shared mailbox, syncs AD/O365, and removes licenses.##

$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session



Write-host "Setting Office 365 Account Password"
$EmailAddress = read-host 'Enter user login address:'

$Password = read-host 'New Password:'
$un = read-Host 'Please enter Active Directory username of person to reset password:'
$supervisor = read-Host 'User who is going to be having access to shared mailbox'
set-adaccountpassword -identity $un -reset

connect-msolservice -credential $UserCredential
Set-Mailbox $EmailAddress -Type shared
Add-MailboxPermission -Identity $EmailAddress -User $supervisor -AccessRights FullAccess

Set-MsolUser  -UserPrincipalName $EmailAddress -StrongPasswordRequired $False
Set-MsolUserPassword -UserPrincipalName $EmailAddress -NewPassword $Password -ForceChangePassword $false

Write-host "Completed.  Password changed to $Password for account $EmailAddress"


Set-MsolUserLicense -UserPrincipalName "$EmailAddress" -RemoveLicenses domainname:EXCHANGESTANDARD
Set-MsolUserLicense -UserPrincipalName "$EmailAddress" -RemoveLicenses domainname:O365_BUSINESS



Get-ADUser $un | Move-ADObject -TargetPath 'OU=Disabled_Accounts,DC=domainname,Dc=local'
Disable-ADAccount -identity $un

Set-ADUser -Identity $un -Replace @{msExchHideFromAddressLists=$True}

$DomainControllers = Get-ADDomainController -Filter *
ForEach ($DC in $DomainControllers.Name) {
    Write-Host "Processing for "$DC -ForegroundColor Green
    If ($Mode -eq "ExtraSuper") { 
        REPADMIN /kcc $DC
        REPADMIN /syncall /A /e /q $DC
    }
    Else {
        REPADMIN /syncall $DC "dc=domainname,dc=local" /d /e /q
    }
}
Invoke-Command -ComputerName machinewithdirsync.domainname.local -ScriptBlock {import-module dirsync;Start-onlinecoexistencesync}

