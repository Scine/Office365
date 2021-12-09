Connect-ExchangeOnline

$SkippedUsers = @()
$FailedUsers = @()

$CSVrecords = Import-Csv "C:\temp\nonmfa.csv" -Delimiter ","
foreach($CSVrecord in $CSVrecords ){
    $upn = $CSVrecord.UserPrincipalName
    $user = Get-Mailbox -Filter "userPrincipalName -eq '$upn'"  
    if ($user) {
        try{
        $user | Set-Mailbox -customattribute1 $CSVrecord.customattribute1 
        } catch {
        $FailedUsers += $upn
        Write-Warning "$upn user found, but FAILED to update."
        }
    }
    else {
        Write-Warning "$upn not found, skipped"
        $SkippedUsers += $upn
    }
}