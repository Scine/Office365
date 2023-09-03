##Mass Apply Retention Policy to ALL Office 365 Mailbox’s.  Make sure you change the <Policy Name>

#Without 2FA authentication enabled uncomment this section.

#$UserCredential = Get-Credential
#Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
#Import-PSSession $Session


#With 2FA authentication enabled already.  If you don't have this enabled, use the above section on line 6 and DISABLE the next 3 lines below by putting a # at the beginning of each line.

Import-Module $((Get-ChildItem -Path $($env:LOCALAPPDATA+"\Apps\2.0\") -Filter Microsoft.Exchange.Management.ExoPowershellModule.dll -Recurse ).FullName|?{$_ -notmatch "_none_"}|select -First 1)
$EXOSession = New-ExoPSSession
Import-PSSession $EXOSession

$retentionPolicy = "Standard"
$retentionComment = "Standard Retention Policy  - 90-day delete"
$retentionURL = "https://support.youdomain.com/policies/retention/standard.html"

$UserMailboxes = Get-Mailbox -Filter {(RecipientTypeDetails -eq 'UserMailbox')} $UserMailboxes | Set-Mailbox –RetentionPolicy $retentionPolicy -RetentionComment $retentionComment -RetentionURL $retentionURL
