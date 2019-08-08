## License:  Share it, enjoy it, maybe tell people about this Github spot.  Freely copy this and modify it how you see fit.

## This Powershell script will generate a random 10 character password, based upon information found here:
## https://www.undocumented-features.com/2016/09/20/powershell-random-password-generator/
## Note: You can change the length in the $newpass line from 10 to whatever you want

## It will then change the AD user's password to the random one generated and let you know the new password

## It will then sync that change across all domain controllers and then do a force synce from AD to Office 365, assuming you
## have AD Connect set up and working properly.

## The script will then remove the security token for all devices connected to Office 365, forcing them to be logged out
## and ask for the new password.

## It will also list and disable all inbox rules for the user, as this is a common tactic for hackers to use to gain information.

## If you wish to have an alert sent to you when a forward is created, check it out here:
## https://docs.microsoft.com/en-us/office365/securitycompliance/alert-policies

## While this script won't cover every possible way a hacker can do bad things in your environment, it can help tremendously
## towards getting the mess cleaned up and you notified as early as possible.

## Change the DOMAIN and TLD to your respective ones, and change server.domain.tld to your respective
## server that's syncing AD to Office 365.

##Find scripts like this at https://github.com/Scine/Office365  Enjoy!

Import-Module $((Get-ChildItem -Path $($env:LOCALAPPDATA+"\Apps\2.0\") -Filter Microsoft.Exchange.Management.ExoPowershellModule.dll -Recurse ).FullName|?{$_ -notmatch "_none_"}|select -First 1)
$EXOSession = New-ExoPSSession
Import-PSSession $EXOSession


$newpass = [system.web.security.membership]::GeneratePassword(10,2)
$mailbox = read-Host 'Office 365 Login:'
$aduser = read-Host 'Active Directory Username:'

Set-ADAccountPassword -Identity $aduser -Reset -NewPassword (ConvertTo-SecureString -AsPlainText "$newpass" -Force)

$Results = write-host "New password is:    $newpass"

connect-azuread

###Sync Domain Controllers


$DomainControllers = Get-ADDomainController -Filter *
ForEach ($DC in $DomainControllers.Name) {
    Write-Host "Processing for "$DC -ForegroundColor Green
    If ($Mode -eq "ExtraSuper") {
        REPADMIN /kcc $DC
        REPADMIN /syncall /A /e /q $DC
    }
    Else {
        REPADMIN /syncall $DC "dc=DOMAIN,dc=TLD" /d /e /q
    }
}

##Wait for all Domain Controllers to sync

Start-Sleep -s 30


##Force synce of Active Directory to Office 365, assuming you have AD Connect set up properly.

$AADComputer = "server.domain.TLD"
$session = New-PSSession -ComputerName $AADComputer
Invoke-Command -Session $session -ScriptBlock {Import-Module -Name 'ADSync'}
Invoke-Command -Session $session -ScriptBlock {Start-ADSyncSyncCycle -PolicyType Delta}
Remove-PSSession $session

Get-InboxRule -Mailbox $mailbox | Select Name, Description, Enabled | FL

Get-InboxRule -Mailbox $mailbox | disable-inboxrule -confirm:$false -AlwaysDeleteOutlookRulesBlob


Set-Mailbox $mailbox -ForwardingAddress $Null

Set-Mailbox $mailbox -ForwardingSmtpAddress $Null

Revoke-AzureADUserAllRefreshToken -ObjectId $mailbox
