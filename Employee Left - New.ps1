##This script is to disable users, change their passwords, move them to a different OU, force sync your domain controllers, remove Office 365 licenses,
##add an Exchange 2 license for litigation hold, and turn on litigation hold on the account.

##Change the DomainForOffice365 to your domain.  Specifically the part before .onmicrosoft.com
##Also change yourdomain at various points.  The OU "Disabled Accounts" portion moves the account to that OU, and keeps things tidy.


##This section requires the profile.ps1 file found here:  https://github.com/Scine/Powershell/blob/master/profile.ps1
##Put that file under your Documents\Windows Powershell\ folder. 

#If you don't have 2FA authentication enabled uncomment this section

#$UserCredential = Get-Credential
#Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
#Import-PSSession $Session


#With 2FA authentication enabled already.  If you don't have this enabled, use the above section on line 6 and comment out the next 3 lines below by putting a # at the beginning of each line.

Import-Module $((Get-ChildItem -Path $($env:LOCALAPPDATA+"\Apps\2.0\") -Filter Microsoft.Exchange.Management.ExoPowershellModule.dll -Recurse ).FullName|?{$_ -notmatch "_none_"}|select -First 1)
$EXOSession = New-ExoPSSession
Import-PSSession $EXOSession

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

##This section removes all licenses (use get-msolaccountsku to find out yours), and adds Exchange Enterprise license
##which is required for litigation hold.  You may not need that for your environment, so adjust accordingly.

Set-MsolUserLicense -UserPrincipalName "$EmailAddress" -RemoveLicenses DomainForOffice365:EXCHANGESTANDARD
Set-MsolUserLicense -UserPrincipalName "$EmailAddress" -RemoveLicenses DomainForOffice365:O365_BUSINESS_PREMIUM
Set-MsolUserLicense -UserPrincipalName "$EmailAddress" -AddLicenses DomainForOffice:EXCHANGEENTERPRISE
Set-Mailbox "$EmailAddress" -LitigationHoldEnabled $true

Get-ADUser $un | Move-ADObject -TargetPath 'OU=Disabled Accounts,DC=yourdomain,Dc=local'
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
        REPADMIN /syncall $DC "dc=yourdomain,dc=local" /d /e /q
    }
}
