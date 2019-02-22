##For creating a new VM on your Nutanix cluster

$server = read-Host 'Server'
$un = read-Host 'Username:'
$PlainPassword = Read-Host 'Password:'
$pw = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force

Connect-NutanixCluster -Server $server -UserName $un -Password $pw -AcceptInvalidSSLCerts


$Name = read-Host 'Virtual Machine Name:'
$NumVcpus = read-Host 'Number of Virtual CPUs:'
$MemoryMB = read-Host 'Virtual Memory in MB:'
$disksize = read-Host 'Size of Disk in MB:'

new-ntnxvirtualmachine -Name $Name -NumVcpus $NumVcpus -MemoryMB $MemoryMB

$vminfo = Get-NTNXVM | where {$_.vmName -eq $Name}
$vmId = ($vminfo.vmid.split(":"))[2]

# Set NIC for VM on default vlan (Get-NTNXNetwork -> NetworkUuid)
$nic = New-NTNXObject -Name VMNicSpecDTO
$nic.networkUuid = "UUID HERE"

# Adding a Nic
Add-NTNXVMNic -Vmid $vmId -SpecList $nic

## Disk Creation
# Creating the Disk
$vmDisk = New-NTNXObject -Name VMDiskDTO
$vmDisk.vmDiskCreate = $diskCreateSpec

# Setting the SCSI disk of 50GB on Containner ID 1025 (get-ntnxcontainer -> ContainerId)
$diskCreateSpec = New-NTNXObject -Name VmDiskSpecCreateDTO
$diskcreatespec.containerid = CONTAINERIDHERE
$diskcreatespec.sizeMb = $disksize

# Adding the Disk to the VM
Add-NTNXVMDisk -Vmid $vmId -Disks $vmDisk