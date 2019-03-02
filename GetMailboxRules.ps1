##This will connect to Office 365, and list all mailbox rules for an individual user.  Helpful when troubleshooting

Import-Module $((Get-ChildItem -Path $($env:LOCALAPPDATA+"\Apps\2.0\") -Filter Microsoft.Exchange.Management.ExoPowershellModule.dll -Recurse ).FullName|?{$_ -notmatch "_none_"}|select -First 1)
$EXOSession = New-ExoPSSession
Import-PSSession $EXOSession

$mailbox = read-Host 'Mailbox address:'
Get-InboxRule -Mailbox $mailbox | Select Name, Description, Enabled | FL
