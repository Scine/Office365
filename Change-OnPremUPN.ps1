##Blatantly stolen from another site that escapes me at the moment, but thought you guys could use it!  This allows you to change your UPN in AD


Param(
  [Parameter(Mandatory=$True)]
   [string]$OldUPNString,

   [Parameter(Mandatory=$True)]
   [string]$NewUPNString,

   [Parameter(Mandatory=$True)]
   [string]$TargetDN
)
$Date = Get-Date
$numberdate = get-date -format M.d.yyyy_hh.mm.ss
$location = get-location
$LogFileName = "\UPNChangeLog"

$LogMessage = "Running Change-OnPremUPN.ps1 on " + $Date
$FullLogFilePath = ( "" + $location + $LogFileName + "_" + $numberdate + ".log")
Out-File -filepath $FullLogFilePath -append -noclobber -inputobject $LogMessage

Get-ADUser -Filter * -SearchBase $TargetDN |
ForEach-Object {

If ($_.UserPrincipalName -eq $NULL) {Write-Host $_.SamAccountName "has a null value for UPN"}
Else{
$OriginalUPNValue = $_.UserPrincipalName
$SplitUPN = $OriginalUPNValue.split("@")
If ($SplitUPN[1].contains($OldUPNString))
    {$NewUPN = $SplitUPN[0] + "@" + $NewUPNString
    Set-ADUser $_ -UserPrincipalName $NewUPN -whatif
    Write-Host "User Account"$_.SamAccountName"'s UPN Value does contain" $OldUPNString "and has been changed to" $NewUPNString
    Out-File -filepath $FullLogFilePath -append -noclobber -inputobject $_.SamAccountName}
Else {Write-Host $_.SamAccountName "UPN Value does not contain" $OldUPNString}}
}
Write-Host $FullLogFilePath "contains the SAMAccountName of each user whose UPN value was changed"

<#
.SYNOPSIS
Change ONPremise Active Directory User Account UPN Value.
.DESCRIPTION
    Identifies all users with UPN suffix containing string provided with [-OldUPNString] located under [-TargetDN] and replaces that string with value provided in [-NewUPNString]
.EXAMPLE
	Change-OnPremUPN -OldUPNString "Contoso.com" -NewUPNString "Fabrikam.com -TargetDN "OU=Corp Users,DC=Corp,DC=Contoso,DC=Com"
.Notes
    Line 53 of this script (Set-ADUser) contains the -Whatif flag by default. No Changes will be made until this is removed.
