$MountPoint = "C:"
$KeyProtectors = (Get-BitLockerVolume -MountPoint $MountPoint).KeyProtector
foreach($KeyProtector in $KeyProtectors){
Remove-BitLockerKeyProtector -MountPoint $MountPoint -KeyProtectorId $KeyProtector.KeyProtectorId
}
shutdown -r -t 0 -f