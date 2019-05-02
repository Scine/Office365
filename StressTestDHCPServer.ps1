##This is mainly for testing DHCP servers by changing your MAC address on your
##network adapter, then disconnecting and reconnecting to the DHCP server via the
##standard ipconfig /release/renew method.

##You MUST run this as an administrator

##Note, it is looking for the name of your network adapter, so be sure to change
##the name down below.  Mine is set to "Ethernet 3"

##This line generates a random MAC address and puts it in the variable called $mac

$ethernetname = "Ethernet 3"

start-sleep 3

$mac = [BitConverter]::ToString([BitConverter]::GetBytes((Get-Random -Maximum 0xFFFFFFFFFFFF)), 0, 6).Replace('-', ':')

start-sleep 10

Set-NetAdapter -Name "$ethernetname" -MacAddress "$mac" -confirm:$false

start-sleep 10
ipconfig /release "$ethernetname"

start-sleep 10
ipconfig /renew "$ethernetname"
