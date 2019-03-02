################################################################################################################################################################
# This script connects to Office 365 and retrieves detailed SMTP mail traffic statistics by user
# Requires Office 365 Wave 15
#
# Office365Username - Mandatory - Administrator login ID for the tenant we are querying
# Office365Password - Mandatory - Administrator login password for the tenant we are querying
#
# This script outputs the results to a CSV file called DetailedMessageStats.csv
#
# To run the script
#
# .\Get-DetailedMessageStats.ps1 -Office365Username admin@xxxxxx.onmicrosoft.com -Office365Password Password123
#
#
################################################################################################################################################################ 

#Accept input parameters
Param(
    [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
    [string] $Office365Username,
    [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
    [string] $Office365Password
)

$OutputFile = "DetailedMessageStats.csv"

#Did they provide creds?  If not, ask them for it.
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

#Create remote Powershell session
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Credential $Office365credentials -Authentication Basic –AllowRedirection

#Import the session
Import-PSSession $Session -AllowClobber | Out-Null

Write-Host "Collecting Recipients..."

#Collect all recipients from Office 365
$Recipients = Get-Recipient * -ResultSize Unlimited | select PrimarySMTPAddress

$MailTraffic = @{}
foreach($Recipient in $Recipients)
{
    $MailTraffic[$Recipient.PrimarySMTPAddress.ToLower()] = @{}
}
$Recipients = $null

#Collect Message Tracking Logs (These are broken into "pages" in Office 365 so we need to collect them all with a loop)
$Messages = $null
$Page = 1
do
{
    Write-Host "Collecting Message Tracking - Page $Page..."
    $CurrMessages = Get-MessageTrace -PageSize 5000 -Page $Page | Select Received,SenderAddress,RecipientAddress,Size
    $Page++
    $Messages += $CurrMessages
}
until ($CurrMessages -eq $null)

Remove-PSSession $session

Write-Host "Crunching Results..."

#Read each message tracking entry and add it to a hash table
foreach($Message in $Messages)
{
    if ($Message.SenderAddress -ne $null)
    {
        if ($MailTraffic.ContainsKey($Message.SenderAddress))
        {
            $MessageDate = Get-Date -Date $Message.Received -Format yyyy-MM-dd

            if ($MailTraffic[$Message.SenderAddress].ContainsKey($MessageDate))
            {
                $MailTraffic[$Message.SenderAddress][$MessageDate]['Outbound']++
                $MailTraffic[$Message.SenderAddress][$MessageDate]['OutboundSize'] += $Message.Size
            }
            else
            {
                $MailTraffic[$Message.SenderAddress][$MessageDate] = @{}
                $MailTraffic[$Message.SenderAddress][$MessageDate]['Outbound'] = 1
                $MailTraffic[$Message.SenderAddress][$MessageDate]['Inbound'] = 0
				$MailTraffic[$Message.SenderAddress][$MessageDate]['InboundSize'] = 0
				$MailTraffic[$Message.SenderAddress][$MessageDate]['OutboundSize'] += $Message.Size
            }

        }
    }

    if ($Message.RecipientAddress -ne $null)
    {
        if ($MailTraffic.ContainsKey($Message.RecipientAddress))
        {
            $MessageDate = Get-Date -Date $Message.Received -Format yyyy-MM-dd

            if ($MailTraffic[$Message.RecipientAddress].ContainsKey($MessageDate))
            {
                $MailTraffic[$Message.RecipientAddress][$MessageDate]['Inbound']++
				$MailTraffic[$Message.RecipientAddress][$MessageDate]['InboundSize'] += $Message.Size
            }
            else
            {
                $MailTraffic[$Message.RecipientAddress][$MessageDate] = @{}
                $MailTraffic[$Message.RecipientAddress][$MessageDate]['Inbound'] = 1
                $MailTraffic[$Message.RecipientAddress][$MessageDate]['Outbound'] = 0
				$MailTraffic[$Message.RecipientAddress][$MessageDate]['OutboundSize'] = 0
				$MailTraffic[$Message.RecipientAddress][$MessageDate]['InboundSize'] += $Message.Size

			}
        }
    }
}

Write-Host "Formatting Results..."

#Build a table to format the results
$table = New-Object system.Data.DataTable "DetailedMessageStats"
$col1 = New-Object system.Data.DataColumn Date,([datetime])
$table.columns.add($col1)
$col2 = New-Object system.Data.DataColumn Recipient,([string])
$table.columns.add($col2)
$col3 = New-Object system.Data.DataColumn Inbound,([int])
$table.columns.add($col3)
$col4 = New-Object system.Data.DataColumn Outbound,([int])
$table.columns.add($col4)
$col5 = New-Object system.Data.DataColumn InboundSize,([int])
$table.columns.add($col5)
$col6 = New-Object system.Data.DataColumn OutboundSize,([int])
$table.columns.add($col6)

#Transpose hashtable to datatable
ForEach ($Recipient in $MailTraffic.keys)
{
    $RecipientName = $Recipient

    foreach($Date in $MailTraffic[$RecipientName].keys)
    {
        $row = $table.NewRow()
        $row.Date = $Date
        $row.Recipient = $RecipientName
        $row.Inbound = $MailTraffic[$RecipientName][$Date].Inbound
        $row.Outbound = $MailTraffic[$RecipientName][$Date].Outbound
		$row.InboundSize = $MailTraffic[$RecipientName][$Date].InboundSize
        $row.OutboundSize = $MailTraffic[$RecipientName][$Date].OutboundSize
        $table.Rows.Add($row)
    }
}

#Export data to CSV and Screen

$table | sort Date,Recipient,Inbound,Outbound, InboundSize, OutboundSize | Out-GridView -Title "Messages Sent By User"

$table | sort Date,Recipient,Inbound,Outbound, InboundSize, OutboundSize | export-csv $OutputFile

Write-Host "Results saved to $OutputFile"
