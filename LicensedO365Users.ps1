Connect-MsolService -Credential $UserCredential
Get-MsolUser | Where-Object { $_.isLicensed -eq "TRUE" } | Export-Csv c:\users\YOURNAME\desktop\LicensedUsers.csv
