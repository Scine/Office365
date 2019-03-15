##This script will pull users mailbox or shared mailbox sizes, and display them, or export them to a CSV, depending on which line/lines you uncomment.

##If you like this script, come over to my github at https://github.com/Scine/Office365 as I add more all the time.



##This section connects to Office 365 via powershell.  Make sure you have the proper Exchange Powershell modules installed

Import-Module $((Get-ChildItem -Path $($env:LOCALAPPDATA+"\Apps\2.0\") -Filter Microsoft.Exchange.Management.ExoPowershellModule.dll -Recurse ).FullName|?{$_ -notmatch "_none_"}|select -First 1)
$EXOSession = New-ExoPSSession
Import-PSSession $EXOSession


##This section will get all users mailboxes and sort them by size in GB.  Uncomment this next line out if that's what you're looking for.

##Get-Mailbox | Get-MailboxStatistics | Select-Object DisplayName, @{name=”TotalItemSize (GB)”;expression={[math]::Round((($_.TotalItemSize.Value.ToString()).Split(“(“)[1].Split(” “)[0].Replace(“,”,””)/1GB),2)}},ItemCount | Sort “TotalItemSize (GB)” -Descending

##This section will get all shared mailboxes and sort them by size in GB. Uncomment this next line out if that's what you're looking for.
##Get-Mailbox -RecipientTypeDetails SharedMailbox | Get-MailboxStatistics | Select-Object DisplayName, @{name=”TotalItemSize (GB)”;expression={[math]::Round((($_.TotalItemSize.Value.ToString()).Split(“(“)[1].Split(” “)[0].Replace(“,”,””)/1GB),2)}},ItemCount | Sort “TotalItemSize (GB)” -Descending

##This section will get all users mailboxes and sort them by size in GB and export them to a CSV file to open in Excel. Uncomment this next line out if that's what you're looking for.
##Get-Mailbox | Get-MailboxStatistics | Select-Object DisplayName, @{name=”TotalItemSize (GB)”;expression={[math]::Round((($_.TotalItemSize.Value.ToString()).Split(“(“)[1].Split(” “)[0].Replace(“,”,””)/1GB),2)}},ItemCount | Sort “TotalItemSize (GB)” -Descending | Export-CSV c:\temp\Office365-MailboxSize-Report.csv

##This section will get all Shared mailboxes and sort them by size in GB and export them to a CSV file to open in Excel. Uncomment this next line out if that's what you're looking for.
##Get-Mailbox -RecipientTypeDetails SharedMailbox | Get-MailboxStatistics | Select-Object DisplayName, @{name=”TotalItemSize (GB)”;expression={[math]::Round((($_.TotalItemSize.Value.ToString()).Split(“(“)[1].Split(” “)[0].Replace(“,”,””)/1GB),2)}},ItemCount | Sort “TotalItemSize (GB)” -Descending | Export-CSV c:\temp\Office365-MailboxSize-Report.csv
