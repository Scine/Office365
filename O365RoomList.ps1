##Occasionally, I've needed to see the list of Conference Rooms set up in Office 365.  This does just that.##

$LiveCred = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $LiveCred -Authentication Basic -AllowRedirection
Import-PSSession $Session

foreach($roomlist in Get-DistributionGroup -RecipientTypeDetails RoomList) {
  $roomlistname = $roomlist.DisplayName
  Get-DistributionGroupMember $roomlist.alias | 
    Select-Object @{n="Room List";e={$roomlistname}},
                  @{n="Room";e={$_.DisplayName}}    
}
