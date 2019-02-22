##We have 4 domain controllers, across 2 sites, and because of the unique nature of things, sometimes we need to force a replication rather than wait.  The below script will do that for all your domain controllers.  Simply put in your domain name and run it in Powershell##


param(
    [ValidateSet("ExtraSuper","Normal")]
    [string]$Mode = 'Normal'
)  

$DomainControllers = Get-ADDomainController -Filter *
ForEach ($DC in $DomainControllers.Name) {
    Write-Host "Processing for "$DC -ForegroundColor Green
    If ($Mode -eq "ExtraSuper") { 
        REPADMIN /kcc $DC
        REPADMIN /syncall /A /e /q $DC
    }
    Else {
        REPADMIN /syncall $DC "dc=domainname,dc=local" /d /e /q
    }
}
