##This forces AD Connect sync to kick off from Active Directory to Office 365. Assuming you have AD Connect set up on one of your servers.
##change FQDN on line 4 to the server's FQDN name.  Find scripts like this at https://github.com/Scine/Office365  Enjoy!!

$AADComputer = "FQDN"
$session = New-PSSession -ComputerName $AADComputer
Invoke-Command -Session $session -ScriptBlock {Import-Module -Name 'ADSync'}
Invoke-Command -Session $session -ScriptBlock {Start-ADSyncSyncCycle -PolicyType Delta}
Remove-PSSession $session
