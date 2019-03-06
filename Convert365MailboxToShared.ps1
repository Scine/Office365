##Converts an Office 365 Mailbox from a standard one to a shared one, and removes the licenses.

$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session


$usermailbox = read-Host 'Users mailbox to convert to shared mailbox'
$supervisor = read-Host 'User who is going to be having access to shared mailbox'

Set-Mailbox $usermailbox -Type shared

##I've seen Microsoft be a bit slow when doing this, so I've added
##the start sleep command.  Feel free to adjust this according to your needs.

start-sleep -s 90


##Adjust these licenses according to the license that you have, but these two
##are the most common ones.


Add-MailboxPermission -Identity $usermailbox -User $supervisor -AccessRights FullAccess
connect-msolservice -credential $UserCredential
Set-MsolUserLicense -UserPrincipalName "$usermailbox" -RemoveLicenses YOURO365NAME:EXCHANGESTANDARD
Set-MsolUserLicense -UserPrincipalName "$usermailbox" -RemoveLicenses YOURO365NAME:O365_BUSINESS
