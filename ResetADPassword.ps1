##This will reset the user's password, and force an AD sync across all your domain controllers.  Make sure you change the domain below.##

param(
    [ValidateSet("ExtraSuper","Normal")]
    [string]$Mode = 'Normal'
)  

$un = read-Host 'Please enter username of person to reset password:'
set-adaccountpassword -identity "$un" -reset



$DomainControllers = Get-ADDomainController -Filter *
ForEach ($DC in $DomainControllers.Name) {
    Write-Host "Processing for "$DC -ForegroundColor Green
    If ($Mode -eq "ExtraSuper") { 
        REPADMIN /kcc $DC
        REPADMIN /syncall /A /e /q $DC
    }
    Else {
        REPADMIN /syncall $DC "dc=changeme,dc=local" /d /e /q
    }
}
