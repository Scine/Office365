#connecting to the Azure AD
Connect-AzureAD 

#importing the CSV source which has the changes 
$data = Import-Csv users.csv

#Iterating through each row in the CSV
foreach ($row in $data)
{
#INFO in the Console
#Note:  The CSV called users.csv should have the columes "User Username" and "Manager Username"
Write-Host "Updating the user :"  $row.'User Username'    " manager to "  $row.'Manager Username'  -ForegroundColor Yellow 

#Updating the Manager 
Set-AzureADUserManager -ObjectId (Get-AzureADUser -ObjectId $row.'User Username').Objectid -RefObjectId (Get-AzureADUser -ObjectId $row.'Manager Username').Objectid

#Completion info in the console for the specified row
Write-Host "Updated." -ForegroundColor Green

}
