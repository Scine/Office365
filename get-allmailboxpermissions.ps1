################################################################################################################################################################
# Script accepts 3 parameters from the command line
#
# Office365Username - Mandatory - Administrator login ID for the tenant we are querying
# Office365Password - Mandatory - Administrator login password for the tenant we are querying
# UserIDFile - Optional - Path and File name of file full of UserPrincipalNames we want the Mailbox Permissions for.  Seperated by New Line, no header.
#
#
# To run the script
#
# .\Get-AllMailboxPermissions.ps1 -Office365Username admin@xxxxxx.onmicrosoft.com -Office365Password Password123 -InputFile c:\Files\InputFile.txt
#
# NOTE: If you do not pass an input file to the script, it will return the permissions of ALL mailboxes in the tenant.  Not advisable for tenants with large
# user count (< 3,000) 
#
# Author: 				Alan Byrne
# Version: 				1.0
# Last Modified Date: 	19/08/2012
# Last Modified By: 	Alan Byrne
################################################################################################################################################################
#Accept input parameters
Param(
	[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
    [string] $Office365Username,
	[Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
    [string] $Office365Password,	
	[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
    [string] $UserIDFile
)

#$ErrorActionPreference = "SilentlyContinue"

#Constant Variables
$OutputFile = "MailboxPerms.csv"   #The CSV Output file that is created, change for your purposes


#Main
Function Main {

	#Remove all existing Powershell sessions
	Get-PSSession | Remove-PSSession
	
	#Call ConnectTo-ExchangeOnline function with correct credentials
	ConnectTo-ExchangeOnline -Office365AdminUsername $Office365Username -Office365AdminPassword $Office365Password			
	
	#Prepare Output file with headers
	Out-File -FilePath $OutputFile -InputObject "UserPrincipalName,ObjectWithAccess,ObjectType,AccessType,Inherited,AllowOrDeny" -Encoding UTF8
	
	#Check if we have been passed an input file path
	if ($userIDFile -ne "")
	{
		#We have an input file, read it into memory
		$objUsers = import-csv -Header "UserPrincipalName" $UserIDFile
	}
	else
	{
		#No input file found, gather all mailboxes from Office 365
		$objUsers = get-mailbox -ResultSize Unlimited | select UserPrincipalName
	}
	
	#Iterate through all users	
	Foreach ($objUser in $objUsers)
	{	
		#Connect to the users mailbox
		$objUserMailbox = get-mailboxpermission -Identity $($objUser.UserPrincipalName) | Select User,AccessRights,Deny,IsInherited
		
		#Prepare UserPrincipalName variable
		$strUserPrincipalName = $objUser.UserPrincipalName
		
		#Loop through each permission
		foreach ($objPermission in $objUserMailbox)
		{			
			#Get the remaining permission details (We're only interested in real users, not built in system accounts/groups)
			if (($objPermission.user.tolower().contains("\domain admin")) -or ($objPermission.user.tolower().contains("\enterprise admin")) -or ($objPermission.user.tolower().contains("\organization management")) -or ($objPermission.user.tolower().contains("\administrator")) -or ($objPermission.user.tolower().contains("\exchange servers")) -or ($objPermission.user.tolower().contains("\public folder management")) -or ($objPermission.user.tolower().contains("nt authority")) -or ($objPermission.user.tolower().contains("\exchange trusted subsystem")) -or ($objPermission.user.tolower().contains("\discovery management")) -or ($objPermission.user.tolower().contains("s-1-5-21")))
			{}
			Else 
			{
				$objRecipient = (get-recipient $($objPermission.user)  -EA SilentlyContinue) 
				
				if ($objRecipient)
				{
					$strUserWithAccess = $($objRecipient.DisplayName) + " (" + $($objRecipient.PrimarySMTPAddress) + ")"
					$strObjectType = $objRecipient.RecipientType
				}
				else
				{
					$strUserWithAccess = $($objPermission.user)
					$strObjectType = "Other"
				}
				
				$strAccessType = $($objPermission.AccessRights) -replace ",",";"
				
				if ($objPermission.Deny -eq $true)
				{
					$strAllowOrDeny = "Deny"
				}
				else
				{
					$strAllowOrDeny = "Allow"
				}
				
				$strInherited = $objPermission.IsInherited
								
				#Prepare the user details in CSV format for writing to file
				$strUserDetails = "$strUserPrincipalName,$strUserWithAccess,$strObjectType,$strAccessType,$strInherited,$strAllowOrDeny"
				
				Write-Host $strUserDetails
				
				#Append the data to file
				Out-File -FilePath $OutputFile -InputObject $strUserDetails -Encoding UTF8 -append
			}
		}
	}
	
	#Clean up session
	Get-PSSession | Remove-PSSession
}

###############################################################################
#
# Function ConnectTo-ExchangeOnline
#
# PURPOSE
#    Connects to Exchange Online Remote PowerShell using the tenant credentials
#
# INPUT
#    Tenant Admin username and password.
#
# RETURN
#    None.
#
###############################################################################
function ConnectTo-ExchangeOnline
{   
	Param( 
		[Parameter(
		Mandatory=$true,
		Position=0)]
		[String]$Office365AdminUsername,
		[Parameter(
		Mandatory=$true,
		Position=1)]
		[String]$Office365AdminPassword

    )
		
	#Encrypt password for transmission to Office365
	$SecureOffice365Password = ConvertTo-SecureString -AsPlainText $Office365AdminPassword -Force    
	
	#Build credentials object
	$Office365Credentials  = New-Object System.Management.Automation.PSCredential $Office365AdminUsername, $SecureOffice365Password
	
	#Create remote Powershell session
	$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Credential $Office365credentials -Authentication Basic –AllowRedirection    	

	#Import the session
    Import-PSSession $Session -AllowClobber | Out-Null
}


# Start script
. Main