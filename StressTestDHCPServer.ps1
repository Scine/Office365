##This is mainly for testing DHCP servers by changing your MAC address on your
##network adapter, then disconnecting and reconnecting to the DHCP server via the
##standard ipconfig /release/renew method.

##You MUST run this as an administrator

##Note, it is looking for the name of your network adapter, so be sure to change
##the name down below.  Mine is set to "Ethernet 3"

##This line generates a random MAC address and puts it in the variable called $mac

$ethernetname = "Ethernet 3"

$mac = [BitConverter]::ToString([BitConverter]::GetBytes((Get-Random -Maximum 0xFFFFFFFFFFFF)), 0, 6).Replace('-', ':')

Set-NetAdapter -Name "$ethernetname" -MacAddress "$mac" -confirm:$false

ipconfig /release "$ethernetname"
ipconfig /renew "$ethernetname"
