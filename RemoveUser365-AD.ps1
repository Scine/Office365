#Import-Module $((Get-ChildItem -Path $($env:LOCALAPPDATA+"\Apps\2.0\") -Filter Microsoft.Exchange.Management.ExoPowershellModule.dll -Recurse ).FullName|?{$_ -notmatch "_none_"}|select -First 1)
#$EXOSession = New-ExoPSSession
#Import-PSSession $EXOSession

#Connect-SPOService -Url https://YOUR365URL-admin.sharepoint.com
connect-msolservice
connect-azuread
Import-Module ActiveDirectory

$un = read-Host 'Office 365 Username:'
$user = read-Host 'Active Directory Name:'

(get-MsolUser -UserPrincipalName $un).licenses.AccountSkuId |
foreach{
    Set-MsolUserLicense -UserPrincipalName $un -RemoveLicenses $_
}

$Password = [system.web.security.membership]::GeneratePassword(10,2)
$Results = write-host "New password is:    $Password"
Set-ADAccountPassword -Identity $user -Reset -NewPassword (ConvertTo-SecureString -AsPlainText "$Password" -Force)



Write-host "Completed.  Password changed to $Password for account $EmailAddress"




Get-ADUser -Identity $user -Properties MemberOf | ForEach-Object {
  $_.MemberOf | Remove-ADGroupMember -Members $_.DistinguishedName -Confirm:$false
}


Disable-ADAccount -Identity $user

$date = get-date
Set-ADUser -identity "$user" -Description "Disabled as of $date"

Get-ADUser $user | Set-ADObject -ProtectedFromAccidentalDeletion:$false -PassThru

Get-ADUser $user | Move-ADObject -TargetPath 'OU=Disabled Accounts,DC=DOMAIN,Dc=SUFFIX'

Get-ADUser $user | Set-ADObject -ProtectedFromAccidentalDeletion:$true -PassThru

$DomainControllers = Get-ADDomainController -Filter *
ForEach ($DC in $DomainControllers.Name) {
    Write-Host "Processing for "$DC -ForegroundColor Green
    If ($Mode -eq "ExtraSuper") {
        REPADMIN /kcc $DC
        REPADMIN /syncall /A /e /q $DC
    }
    Else {
        REPADMIN /syncall $DC "dc=DOMAIN,dc=SUFFIX" /d /e /q
    }
}

$AADComputer = "SERVER.DOMAIN.SUFFIX"
$session = New-PSSession -ComputerName $AADComputer
Invoke-Command -Session $session -ScriptBlock {Import-Module -Name 'ADSync'}
Invoke-Command -Session $session -ScriptBlock {Start-ADSyncSyncCycle -PolicyType Delta}
Remove-PSSession $session


Remove-AzureADUser -ObjectID $un
