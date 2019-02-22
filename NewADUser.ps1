##Check the profile.ps1 file on my Github/Powershell folder and put it in your respective C:\users\username\my documents\windowspowershell\ folder to export the vcard for Outlook##

## This section prompts you for your Office 365 administrator credentials##


#Without 2FA authentication enabled uncomment this section

#$UserCredential = Get-Credential
#Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
#Import-PSSession $Session


#With 2FA authentication enabled already.  If you don't have this enabled, use the above section on line 6 and DISABLE the next 3 lines below by putting a # at the beginning of each line.

Import-Module $((Get-ChildItem -Path $($env:LOCALAPPDATA+"\Apps\2.0\") -Filter Microsoft.Exchange.Management.ExoPowershellModule.dll -Recurse ).FullName|?{$_ -notmatch "_none_"}|select -First 1)
$EXOSession = New-ExoPSSession
Import-PSSession $EXOSession

## This section is where you're prompted for various aspects of a user's account.  Feel free to add/remove as you see fit##

$first = read-Host 'First Name:'
$last = read-Host 'Last Name:'
$Description = read-host 'Title:'
$Office = read-Host 'Department:'
$Phone = read-Host 'Cell or Extension Number:'
$un = read-Host 'Username:'
$pw = Read-Host -AsSecureString 'Secure Password:'
$Name = $first + ' ' + $last
$homedr = 'X:'
$Homedir = '\server\userdirs\' + $un
new-ADUser $name -Enabled $true -AccountPassword $pw -Path 'OU=Accounts,DC=domain,DC=local' -Department $Office -Description $Description -DisplayName $name -HomeDirectory $Homedir -Manager $Manager -Office $Office -ScriptPath $logon -Title $Description -OfficePhone $Phone -SamAccountName $un -GivenName $first -Surname $last -OtherAttributes @{userprincipalname="$un@domain.local";mail="$un@emaildomain.com";proxyaddresses="SMTP:$un@emaildomain.com";targetaddress="SMTP:$un@domain.onmicrosoft.com";mobile="$Phone"} -passwordneverexpires 1
set-aduser -Identity $un -homedrive $homedr
add-ADGroupMember 'Domain Group' -Members $un
add-ADGroupMember $Office -Members $un

##We have multiple sites, and the user's information will depend on their particular site.  This is a menu asking for the site, and will populate accordingly.##

$message = "Please select an option.  Use UPPER CASE LETTER!"

$pdx = New-Object System.Management.Automation.Host.ChoiceDescription "&1Site","Add Site1 info"
$slm = New-Object System.Management.Automation.Host.ChoiceDescription "&2Site","Add Site2 info"
$field = New-Object System.Management.Automation.Host.ChoiceDescription "&field","Add field info"

$options = [System.Management.Automation.Host.ChoiceDescription[]]($pdx,$slm,$field)

$result = $host.ui.PromptForChoice($title, $message, $options, 0) 


switch ($result)
    {
        0 {set-ADUser $un -City "City1" -Company "Company Name" -PostalCode "ZipCode" -State "State" -StreetAddress "Address1" -Title $Description -OfficePhone $Phone}
        1 {set-ADUser $un -City "City2" -Company "Company Name" -PostalCode "ZipCode" -State "State" -StreetAddress "Address2" -Title $Description -OfficePhone $Phone}
        2 {"Field"}
    }
	
set-aduser $un -Enabled $true


##We have 4 domain controllers, with two per site, so this forces an AD replication.  This may not be necessary in your case##

$DomainControllers = Get-ADDomainController -Filter *
ForEach ($DC in $DomainControllers.Name) {
    Write-Host "Processing for "$DC -ForegroundColor Green
    If ($Mode -eq "ExtraSuper") { 
        REPADMIN /kcc $DC
        REPADMIN /syncall /A /e /q $DC
    }
    Else {
        REPADMIN /syncall $DC "dc=domain,dc=local" /d /e /q
    }
}

##Finally, we use dirsync to sync our AD users to Office 365.  This section below runs the dirsync on that particular machine.##

connect-msolservice -credential $UserCredential

Write-host "Setting Office 365 Account Password"

New-MsolUser -DisplayName "$First $Last" -FirstName $First -LastName $Last -UserPrincipalName "$un@domain.com" -PasswordNeverExpires $true -UsageLocation US -password $PlainPassword
Set-MsolUserLicense -UserPrincipalName "$un@domain.com" -AddLicenses DOMAIN:O365_BUSINESS_PREMIUM
Set-MsolUser -UserPrincipalName "$un@domain.com" -StrongPasswordRequired $True

Get-ADUser $un -Properties * | Out-vCard

$ol = New-Object -comObject Outlook.Application

$mail = $ol.CreateItem(0)
$Mail.Recipients.Add("all@domain.com")
$mail.Subject = "Welcome New User $name"
$mail.Body = "Please welcome our newest user $name.  Attached you will find his contact information that you can double click on and add to your Outlook contacts.  Admin Guy"
$Mail.Attachments.Add("c:\users\Admin\desktop\$name.vcf")

$mail.save()

$inspector = $mail.GetInspector
$inspector.Display()
$Mail.send()

