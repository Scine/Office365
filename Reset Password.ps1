#See below about 2 form authentication and comment/uncomment accordingly.  At the very bottom (Line 57), where the domain controllers are forced to sync, put in your domain information.

#Without 2FA authentication enabled uncomment this section

#$UserCredential = Get-Credential
#Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
#Import-PSSession $Session


#With 2FA authentication enabled already.  If you don't have this enabled, use the above section on line 6 and DISABLE the next 3 lines below by putting a # at the beginning of each line.

Import-Module $((Get-ChildItem -Path $($env:LOCALAPPDATA+"\Apps\2.0\") -Filter Microsoft.Exchange.Management.ExoPowershellModule.dll -Recurse ).FullName|?{$_ -notmatch "_none_"}|select -First 1)
$EXOSession = New-ExoPSSession
Import-PSSession $EXOSession

Write-host "Setting Office 365 Account Password"
$EmailAddress = read-host 'Enter user login address:'

$Password = read-host 'New Password:'

connect-msolservice

Set-MsolUser  -UserPrincipalName $EmailAddress -StrongPasswordRequired $False
Set-MsolUserPassword -UserPrincipalName $EmailAddress -NewPassword $Password -ForceChangePassword $false

Write-host "Completed.  Password changed to $Password for account $EmailAddress"

$un = read-Host 'Please enter Active Directory username of person to reset password:'
set-adaccountpassword -identity "$un" -reset



$message = "Hide from the Global Address List?  Please select an option.  Use UPPER CASE LETTER!"

$hide = New-Object System.Management.Automation.Host.ChoiceDescription "&Hide","Hide from Global Address List"
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No","Do not hide from Global Address List"

$options = [System.Management.Automation.Host.ChoiceDescription[]]($hide,$no)

$result = $host.ui.PromptForChoice($title, $message, $options, 0) 

switch ($result)
    {
        0 {Set-ADUser -Identity $un -Replace @{msExchHideFromAddressLists=$True}}
        1 {"No"}
        2 {"Field"}
    }
	
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
