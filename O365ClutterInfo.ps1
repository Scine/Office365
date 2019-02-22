##Find the status of Clutter for your Office 365 Users##

Param( 
    [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)] 
    [string] $Office365Username, 
    [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)] 
    [string] $Office365AdminPassword
) 
 
$OutputFile = "ClutterDetails.csv"   #The CSV Output file that is created, change for your purposes 
 
Get-PSSession | Remove-PSSession 
  
if (([string]::IsNullOrEmpty($Office365Username) -eq $false) -and ([string]::IsNullOrEmpty($Office365AdminPassword) -eq $false))
{
    $SecureOffice365AdminPassword = ConvertTo-SecureString -AsPlainText $Office365AdminPassword -Force     
     
    #Build credentials object 
    $Office365Credentials  = New-Object System.Management.Automation.PSCredential $Office365Username, $SecureOffice365AdminPassword 
}
else
{
    #Build credentials object 
    $Office365Credentials  = Get-Credential
}

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Credential $Office365credentials -Authentication Basic –AllowRedirection         

Import-PSSession $Session -AllowClobber | Out-Null                     
 
Out-File -FilePath $OutputFile -InputObject "UserPrincipalName,SamAccountName,ClutterEnabled" -Encoding UTF8 
 
write-host "Retrieving Users"
$objUsers = get-mailbox -ResultSize Unlimited | select UserPrincipalName, SamAccountName 
 
Foreach ($objUser in $objUsers) 
{     
    #Prepare UserPrincipalName variable 
    $strUserPrincipalName = $objUser.UserPrincipalName 
    $strSamAccountName = $objUser.SamAccountName 
    
    write-host "Processing $strUserPrincipalName"
    #Get Clutter info to the users mailbox 
    $strClutterInfo = $(get-clutter -Identity $($objUser.UserPrincipalName)).isenabled  
    
    #Prepare the user details in CSV format for writing to file 
    $strUserDetails = "$strUserPrincipalName,$strSamAccountName,$strClutterInfo"
     
    #Append the data to file 
    Out-File -FilePath $OutputFile -InputObject $strUserDetails -Encoding UTF8 -append 
} 

write-host "Completed - data saved to $OutputFile"
 
#Clean up session 
Get-PSSession | Remove-PSSession 
