##This one is a two parter.  This gets your mobile device information about a particular user, and then you need to manually run the command with the identity, since I don't know how to pull that info :)  ##
##This is because when you have a user who's left, fired, etc, when you change their password, it can take up to 24 hours for it to process.  That's unacceptable.  However, when you use this, it instantly removes their access. (At least in my experience)##

$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session

$account = read-Host 'Email Address Login:'

Get-MobileDevice -Mailbox $account | select DeviceModel, Identity

"If you would like me to remove the device, please use the command: Remove-MobileDevice -Identity <Identity>"
