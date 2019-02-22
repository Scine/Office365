###This is for hiding your user in Office 365's global address list.  However, this is only for people who sync their Active Directory to Office 365.  If you don't, you can take out the syncing of your domain controllers

$user = read-Host 'Username:'
Set-ADUser -Identity "$user" -Replace @{msExchHideFromAddressLists=$True}
$DomainControllers = Get-ADDomainController -Filter *
ForEach ($DC in $DomainControllers.Name) {
    Write-Host "Processing for "$DC -ForegroundColor Green
    If ($Mode -eq "ExtraSuper") { 
        REPADMIN /kcc $DC
        REPADMIN /syncall /A /e /q $DC
    }
    Else {
        REPADMIN /syncall $DC "dc=DOMAIN,dc=local" /d /e /q
    }
}
Invoke-Command -ComputerName SYNCCOMPUTER.DOMAIN.local -ScriptBlock {import-module dirsync;Start-onlinecoexistencesync}
