################################################################################################################################################################
# Script accepts 3 parameters from the command line (PS)	
#
# Office365Username - Mandatory - Administrator login ID for the tenant we are querying
# Office365Password - Mandatory - Administrator login password for the tenant we are querying
# UserIDFile - Optional - Path and File name of file full of UserPrincipalNames we want the Last Logon Dates for.  Seperated by New Line, no header.
#
#
# To run the script
#
# .\Get-LastLogonStats.ps1 -Office365Username admin@xxxxxx.onmicrosoft.com -Office365Password Password123 -InputFile c:\Files\InputFile.txt
#
# NOTE: If you do not pass an input file to the script, it will return the last logon time of ALL mailboxes in the tenant.  Not advisable for tenants with large
# user count (< 3,000)
#
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

#Constant Variables
$OutputFile = "LastLogonDate.csv"   #The CSV Output file that is created, change for your purposes


#Main
Function Main {

	#Remove all existing Powershell sessions
	Get-PSSession | Remove-PSSession

	#Call ConnectTo-ExchangeOnline function with correct credentials
	ConnectTo-ExchangeOnline -Office365AdminUsername $Office365Username -Office365AdminPassword $Office365Password

	#Prepare Output file with headers
	Out-File -FilePath $OutputFile -InputObject "UserPrincipalName,LastLogonDate" -Encoding UTF8

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
		$objUserMailbox = get-mailboxstatistics -Identity $($objUser.UserPrincipalName) | Select LastLogonTime

		#Prepare UserPrincipalName variable
		$strUserPrincipalName = $objUser.UserPrincipalName

		#Check if they have a last logon time. Users who have never logged in do not have this property
		if ($objUserMailbox.LastLogonTime -eq $null)
		{
			#Never logged in, update Last Logon Variable
			$strLastLogonTime = "Never Logged In"
		}
		else
		{
			#Update last logon variable with data from Office 365
			$strLastLogonTime = $objUserMailbox.LastLogonTime
		}

		#Output result to screen for debuging (Uncomment to use)
		#write-host "$strUserPrincipalName : $strLastLogonTime"

		#Prepare the user details in CSV format for writing to file
		$strUserDetails = "$strUserPrincipalName,$strLastLogonTime"

		#Append the data to file
		Out-File -FilePath $OutputFile -InputObject $strUserDetails -Encoding UTF8 -append
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
	$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Credential $Office365credentials -Authentication Basic �AllowRedirection

	#Import the session
    Import-PSSession $Session -AllowClobber | Out-Null
}


# Start script
. Main
