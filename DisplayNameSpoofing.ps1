Import-Module $((Get-ChildItem -Path $($env:LOCALAPPDATA+"\Apps\2.0\") -Filter Microsoft.Exchange.Management.ExoPowershellModule.dll -Recurse ).FullName|?{$_ -notmatch "_none_"}|select -First 1)
$EXOSession = New-ExoPSSession
Import-PSSession $EXOSession

$ruleName = "External Senders with matching Display Names (Domain1)"

$rule = Get-TransportRule | Where-Object {$_.Identity -contains $ruleName}
$displayNames = (Get-Mailbox | Where {$_.EmailAddresses -like "*@domain1.com"}).DisplayName
 
if (!$rule) {
    Write-Host "Rule not found, creating rule" -ForegroundColor Green
    New-TransportRule -Name $ruleName -Priority 0 -FromScope "NotInOrganization" -HeaderMatchesMessageHeader From -HeaderMatchesPatterns $displayNames -Quarantine $true -ExceptIfFrom "example@domain.com" -ExceptIfSentTo "exception@domain.com"
}
else {
    Write-Host "Rule found, updating rule" -ForegroundColor Green
    Set-TransportRule -Identity $ruleName -Priority 0 -FromScope "NotInOrganization" -HeaderMatchesMessageHeader From -HeaderMatchesPatterns $displayNames -Quarantine $true -ExceptIfFrom "example@domain.com" -ExceptIfSentTo "exception@domain.com"
}



$ruleName = "External Senders with matching Display Names (Domain2)"

$rule = Get-TransportRule | Where-Object {$_.Identity -contains $ruleName}
$displayNames = (Get-Mailbox | Where {$_.EmailAddresses -like "*@domain2.com"}).DisplayName
 
if (!$rule) {
    Write-Host "Rule not found, creating rule" -ForegroundColor Green
    New-TransportRule -Name $ruleName -Priority 0 -FromScope "NotInOrganization" -HeaderMatchesMessageHeader From -HeaderMatchesPatterns $displayNames -Quarantine $true -ExceptIfFrom "example@domain.com" -ExceptIfSentTo "exception@domain.com"
}
else {
    Write-Host "Rule found, updating rule" -ForegroundColor Green
    Set-TransportRule -Identity $ruleName -Priority 0 -FromScope "NotInOrganization" -HeaderMatchesMessageHeader From -HeaderMatchesPatterns $displayNames -Quarantine $true -ExceptIfFrom "example@domain.com" -ExceptIfSentTo "exception@domain.com"
}


$ruleName = "External Senders with matching Display Names (Domain3)"

$rule = Get-TransportRule | Where-Object {$_.Identity -contains $ruleName}
$displayNames = (Get-Mailbox | Where {$_.EmailAddresses -like "*@domain3.com"}).DisplayName
 
if (!$rule) {
    Write-Host "Rule not found, creating rule" -ForegroundColor Green
    New-TransportRule -Name $ruleName -Priority 0 -FromScope "NotInOrganization" -HeaderMatchesMessageHeader From -HeaderMatchesPatterns $displayNames -Quarantine $true -ExceptIfFrom "example@domain.com" -ExceptIfSentTo "exception@domain.com"
}
else {
    Write-Host "Rule found, updating rule" -ForegroundColor Green
    Set-TransportRule -Identity $ruleName -Priority 0 -FromScope "NotInOrganization" -HeaderMatchesMessageHeader From -HeaderMatchesPatterns $displayNames -Quarantine $true -ExceptIfFrom "example@domain.com" -ExceptIfSentTo "exception@domain.com"
}
