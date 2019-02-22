Import-Module $((Get-ChildItem -Path $($env:LOCALAPPDATA+"\Apps\2.0\") -Filter Microsoft.Exchange.Management.ExoPowershellModule.dll -Recurse ).FullName|?{$_ -notmatch "_none_"}|select -First 1)
$EXOSession = New-ExoPSSession
Import-PSSession $EXOSession

#This script will enable non-owner mailbox access auditing on every mailbox in your tenancy
#First, let's get us a cred!
$userCredential = Get-Credential

#This gets us connected to an Exchange remote powershell service
#$ExoSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $userCredential -Authentication Basic -AllowRedirection
#Import-PSSession $ExoSession

#With 2FA authentication enabled, remove the #'s below.  If you don't have this enabled, use the above section on line 10 and DISABLE the next 3 lines below by putting a # at the beginning of each line.

#Import-Module $((Get-ChildItem -Path $($env:LOCALAPPDATA+"\Apps\2.0\") -Filter Microsoft.Exchange.Management.ExoPowershellModule.dll -Recurse ).FullName|?{$_ -notmatch "_none_"}|select -First 1)
#$EXOSession = New-ExoPSSession
#Import-PSSession $EXOSession

#Enable global audit logging
Get-Mailbox -ResultSize Unlimited -Filter {RecipientTypeDetails -eq "UserMailbox"} | Set-Mailbox -AuditEnabled $true -AuditLogAgeLimit 365 -AuditOwner Create,HardDelete,MailboxLogin,MoveToDeletedItems,SoftDelete,Update

#Double-Check It!
Get-Mailbox | Select Name, AuditEnabled, AuditLogAgeLimit
