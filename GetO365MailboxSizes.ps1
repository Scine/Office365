##This one is really simple. It just gets the mailbox sizes of your Office 365 users and displays them in a nice tidy order.##

$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session

get-mailbox | get-mailboxstatistics | ft displayname, totalitemsize 
