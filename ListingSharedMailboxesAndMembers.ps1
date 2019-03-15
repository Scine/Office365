##This will show you what users have access to what shared mailbox within Office 365


##This section connects to Office 365 via powershell.  Make sure you have the proper Exchange Powershell modules installed

Import-Module $((Get-ChildItem -Path $($env:LOCALAPPDATA+"\Apps\2.0\") -Filter Microsoft.Exchange.Management.ExoPowershellModule.dll -Recurse ).FullName|?{$_ -notmatch "_none_"}|select -First 1)
$EXOSession = New-ExoPSSession
Import-PSSession $EXOSession


##This is the command that gets the information you're looking for.

Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize:Unlimited | Get-MailboxPermission | select identity,user,accessrights  | where { ($_.User -like '*@*')   }
