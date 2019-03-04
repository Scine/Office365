##Mass search and delete emails across multiple mailboxes.  This is helpful when cleaning out phishing emails from users mailboxes, so they aren't tempted to click on them.
##Note:  This is EXTREMELY POWERFUL!  I cannot stress this enough: Run this on test accounts you don't give a shit about.  You can cause some serious damage with this.  You have been warned.

#Without 2FA authentication enabled uncomment this section.

#$UserCredential = Get-Credential
#Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
#Import-PSSession $Session


#With 2FA authentication enabled already.  If you don't have this enabled, use the above section on line 6 and DISABLE the next 3 lines below by putting a # at the beginning of each line.

Import-Module $((Get-ChildItem -Path $($env:LOCALAPPDATA+"\Apps\2.0\") -Filter Microsoft.Exchange.Management.ExoPowershellModule.dll -Recurse ).FullName|?{$_ -notmatch "_none_"}|select -First 1)
$EXOSession = New-ExoPSSession
Import-PSSession $EXOSession

##Step1:  Create a compliance search.

New-ComplianceSearch -Name $search -ExchangeLocation all -ContentMatchQuery '(c:c)(subject:"Urgent Document to sign AND review")(received=2018-1-31..2018-1-31)(from:"user@domain.com")‎'

##Step2:  Search and destroy emails found with that compliance search.

New-ComplianceSearchAction -SearchName $search -Purge -PurgeType SoftDelete -Force -Confirm:$false -Verbose
