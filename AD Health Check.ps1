#Blatantly copied from this guy:  https://pastebin.com/GGMnBs5G  Just wanted it in my repository in case he brought his down. :)
#EDITED TO ONLY SEND EMAIL ON FAILURES/WARNINGS TO HELP CUT DOWN ON SPAM
#Sets screen buffer from 120 width to 500 width. This stops truncation in the log.
$pshost = get-host
$pswindow = $pshost.ui.rawui
 
$newsize = $pswindow.buffersize
$newsize.height = 3000
$newsize.width = 500
$pswindow.buffersize = $newsize
 
$newsize = $pswindow.windowsize
$newsize.height = 50
$newsize.width = 500
$pswindow.windowsize = $newsize
 
#Log Parameters.
$LogDirectory =  "C:\Temp"
$LogRetentionDays = 30
 
#Starts logging.
New-Item -ItemType directory -Path $LogDirectory -Force | Out-Null
$Today = Get-Date -Format M-d-y
Start-Transcript -Append -Path $LogDirectory\ADHealthCheck.$Today.log | Out-Null
 
#Purges log files older than X days
$RetentionDate = (Get-Date).AddDays(-$LogRetentionDays)
Get-ChildItem -Path $LogDirectory -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $RetentionDate } | Remove-Item -Force
 
#############################################################################
#       Author: Vikas Sukhija
#       Reviewer:    
#       Date: 12/25/2014
#       Satus: Ping,Netlogon,NTDS,DNS,DCdiag Test(Replication,sysvol,Services)
#       Update: Added Advertising
#       Description: AD Health Status
#############################################################################
###########################Define Variables##################################
 
$reportpath = "C:\TaskScheduler\ADReport.htm"
 
if((test-path $reportpath) -like $false)
{
new-item $reportpath -type file
}
$smtphost = "smtpserver.domain.local"
$from = "noreply@domain.com"
$email1 = "recipient@domain.com"
$timeout = "60"
 
###############################HTml Report Content############################
$report = $reportpath
 
Clear-Content $report
Add-Content $report "<html>"
Add-Content $report "<head>"
Add-Content $report "<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>"
Add-Content $report '<title>AD Status Report</title>'
add-content $report '<STYLE TYPE="text/css">'
add-content $report  "<!--"
add-content $report  "td {"
add-content $report  "font-family: Tahoma;"
add-content $report  "font-size: 11px;"
add-content $report  "border-top: 1px solid #999999;"
add-content $report  "border-right: 1px solid #999999;"
add-content $report  "border-bottom: 1px solid #999999;"
add-content $report  "border-left: 1px solid #999999;"
add-content $report  "padding-top: 0px;"
add-content $report  "padding-right: 0px;"
add-content $report  "padding-bottom: 0px;"
add-content $report  "padding-left: 0px;"
add-content $report  "}"
add-content $report  "body {"
add-content $report  "margin-left: 5px;"
add-content $report  "margin-top: 5px;"
add-content $report  "margin-right: 0px;"
add-content $report  "margin-bottom: 10px;"
add-content $report  ""
add-content $report  "table {"
add-content $report  "border: thin solid #000000;"
add-content $report  "}"
add-content $report  "-->"
add-content $report  "</style>"
Add-Content $report "</head>"
Add-Content $report "<body>"
add-content $report  "<table width='100%'>"
add-content $report  "<tr bgcolor='Lavender'>"
add-content $report  "<td colspan='7' height='25' align='center'>"
add-content $report  "<font face='tahoma' color='#003399' size='4'><strong>Active Directory Health Check</strong></font>"
add-content $report  "</td>"
add-content $report  "</tr>"
add-content $report  "</table>"
 
add-content $report  "<table width='100%'>"
Add-Content $report  "<tr bgcolor='IndianRed'>"
Add-Content $report  "<td width='9%' align='center'><B>Identity</B></td>"
Add-Content $report  "<td width='9%' align='center'><B>PingStatus</B></td>"
Add-Content $report  "<td width='9%' align='center'><B>NetlogonService</B></td>"
Add-Content $report  "<td width='9%' align='center'><B>NTDSService</B></td>"
Add-Content $report  "<td width='9%' align='center'><B>DNSServiceStatus</B></td>"
Add-Content $report  "<td width='9%' align='center'><B>NetlogonsTest</B></td>"
Add-Content $report  "<td width='9%' align='center'><B>ReplicationTest</B></td>"
Add-Content $report  "<td width='9%' align='center'><B>ServicesTest</B></td>"
Add-Content $report  "<td width='9%' align='center'><B>AdvertisingTest</B></td>"
Add-Content $report  "<td width='9%' align='center'><B>FSMOCheckTest</B></td>"
Add-Content $report  "<td width='9%' align='center'><B>DfsrLastRepTest</B></td>"
 
Add-Content $report "</tr>"
 
#####################################Custom Functions#################################
#        Additional functions added to Vika's script for my customizations.
$DeclareFunctions = {
    Function Get-DfsrLastUpdateTime {
        param ([string]$ComputerName)
        $ErrorActionPreference = "Stop"
 
        If (!$ComputerName){Throw "You must supply a value for ComputerName."}
 
        $DfsrWmiObj = Get-WmiObject -Namespace "root\microsoftdfs" -Class dfsrVolumeConfig -ComputerName $ComputerName
        If ($DfsrWmiObj.LastChangeTime.Count -le 1){
            [datetime]$LastChangeTime = [System.Management.ManagementDateTimeconverter]::ToDateTime($DfsrWmiObj.LastChangeTime)
        }
        Else {
            $OldestChangeTime = ($DfsrWmiObj.LastChangeTime | Measure -Minimum).Minimum
            [datetime]$LastChangeTime = [System.Management.ManagementDateTimeconverter]::ToDateTime($OldestChangeTime)
        }
 
        Return $LastChangeTime
    }
 
    #This one is unused
    Function Get-DfsrGuid {
        param ([string]$ComputerName)
        $ErrorActionPreference = "Stop"
 
        If (!$ComputerName){Throw "You must supply a value for ComputerName."}
 
        $DfsrWmiObj = Get-WmiObject -Namespace "root\microsoftdfs" -Class dfsrVolumeConfig -ComputerName $ComputerName
 
        Return $DfsrWmiObj.VolumeGUID
    }
 
    Function Get-DfsrLastUpdateDelta {
        param ([string]$ComputerName)
        $ErrorActionPreference = "Stop"
 
        If (!$ComputerName){Throw "You must supply a value for ComputerName."}
 
        $LastUpdateTime = Get-DfsrLastUpdateTime -ComputerName $ComputerName
        $TimeDelta = (Get-Date) - $LastUpdateTime
   
        Return $TimeDelta
    }
}
 
#####################################Get ALL DC Servers#################################
$getForest = [system.directoryservices.activedirectory.Forest]::GetCurrentForest()
 
$DCServers = $getForest.domains | ForEach-Object {$_.DomainControllers} | ForEach-Object {$_.Name}
 
 
################Ping Test######
 
foreach ($DC in $DCServers){
    $Identity = $DC
                    Add-Content $report "<tr>"
    if ( Test-Connection -ComputerName $DC -Count 1 -ErrorAction SilentlyContinue ) {
    Write-Host $DC `t $DC `t Ping Success -ForegroundColor Green
       
        $ShortIdentity = $Identity.Replace(('.'+$getForest.Name),'')                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
        Add-Content $report "<td bgcolor= 'GainsBoro' align=center><B>$ShortIdentity</B></td>"
                Add-Content $report "<td bgcolor= 'Aquamarine' align=center>  <B>Success</B></td>"
 
               
                ##############Netlogon Service Status################
        $serviceStatus = start-job -scriptblock {get-service -ComputerName $($args[0]) -Name "Netlogon" -ErrorAction SilentlyContinue} -ArgumentList $DC
                wait-job $serviceStatus -timeout $timeout
                if($serviceStatus.state -like "Running")
                {
                 Write-Host $DC `t Netlogon Service TimeOut -ForegroundColor Yellow
                 Add-Content $report "<td bgcolor= 'Yellow' align=center><B>Timeout</B></td>"
                 stop-job $serviceStatus
                }
                else
                {
                $serviceStatus1 = Receive-job $serviceStatus
                 if ($serviceStatus1.status -eq "Running") {
           Write-Host $DC `t $serviceStatus1.name `t $serviceStatus1.status -ForegroundColor Green
               $svcName = $serviceStatus1.name
               $svcState = $serviceStatus1.status          
               Add-Content $report "<td bgcolor= 'Aquamarine' align=center><B>$svcState</B></td>"
                  }
                 else
                  {
              Write-Host $DC `t $serviceStatus1.name `t $serviceStatus1.status -ForegroundColor Red
              $svcName = $serviceStatus1.name
              $svcState = $serviceStatus1.status          
              Add-Content $report "<td bgcolor= 'Red' align=center><B>$svcState</B></td>"
                  }
                }
               ######################################################
                ##############NTDS Service Status################
        $serviceStatus = start-job -scriptblock {get-service -ComputerName $($args[0]) -Name "NTDS" -ErrorAction SilentlyContinue} -ArgumentList $DC
                wait-job $serviceStatus -timeout $timeout
                if($serviceStatus.state -like "Running")
                {
                 Write-Host $DC `t NTDS Service TimeOut -ForegroundColor Yellow
                 Add-Content $report "<td bgcolor= 'Yellow' align=center><B>Timeout</B></td>"
                 stop-job $serviceStatus
                }
                else
                {
                $serviceStatus1 = Receive-job $serviceStatus
                 if ($serviceStatus1.status -eq "Running") {
           Write-Host $DC `t $serviceStatus1.name `t $serviceStatus1.status -ForegroundColor Green
               $svcName = $serviceStatus1.name
               $svcState = $serviceStatus1.status          
               Add-Content $report "<td bgcolor= 'Aquamarine' align=center><B>$svcState</B></td>"
                  }
                 else
                  {
              Write-Host $DC `t $serviceStatus1.name `t $serviceStatus1.status -ForegroundColor Red
              $svcName = $serviceStatus1.name
              $svcState = $serviceStatus1.status          
              Add-Content $report "<td bgcolor= 'Red' align=center><B>$svcState</B></td>"
                  }
                }
               ######################################################
                ##############DNS Service Status################
        $serviceStatus = start-job -scriptblock {get-service -ComputerName $($args[0]) -Name "DNS" -ErrorAction SilentlyContinue} -ArgumentList $DC
                wait-job $serviceStatus -timeout $timeout
                if($serviceStatus.state -like "Running")
                {
                 Write-Host $DC `t DNS Server Service TimeOut -ForegroundColor Yellow
                 Add-Content $report "<td bgcolor= 'Yellow' align=center><B>Timeout</B></td>"
                 stop-job $serviceStatus
                }
                else
                {
                $serviceStatus1 = Receive-job $serviceStatus
                 if ($serviceStatus1.status -eq "Running") {
           Write-Host $DC `t $serviceStatus1.name `t $serviceStatus1.status -ForegroundColor Green
               $svcName = $serviceStatus1.name
               $svcState = $serviceStatus1.status          
               Add-Content $report "<td bgcolor= 'Aquamarine' align=center><B>$svcState</B></td>"
                  }
                 else
                  {
              Write-Host $DC `t $serviceStatus1.name `t $serviceStatus1.status -ForegroundColor Red
              $svcName = $serviceStatus1.name
              $svcState = $serviceStatus1.status          
              Add-Content $report "<td bgcolor= 'Red' align=center><B>$svcState</B></td>"
                  }
                }
               ######################################################
 
               ####################Netlogons status##################
               add-type -AssemblyName microsoft.visualbasic
               $cmp = "microsoft.visualbasic.strings" -as [type]
               $sysvol = start-job -scriptblock {dcdiag /test:netlogons /s:$($args[0])} -ArgumentList $DC
               wait-job $sysvol -timeout $timeout
               if($sysvol.state -like "Running")
               {
               Write-Host $DC `t Netlogons Test TimeOut -ForegroundColor Yellow
               Add-Content $report "<td bgcolor= 'Yellow' align=center><B>Timeout</B></td>"
               stop-job $sysvol
               }
               else
               {
               $sysvol1 = Receive-job $sysvol
               if($cmp::instr($sysvol1, "passed test NetLogons"))
                  {
                  Write-Host $DC `t Netlogons Test passed -ForegroundColor Green
                  Add-Content $report "<td bgcolor= 'Aquamarine' align=center><B>Pass</B></td>"
                  }
               else
                  {
                  Write-Host $DC `t Netlogons Test Failed -ForegroundColor Red
                  Add-Content $report "<td bgcolor= 'Red' align=center><B>Fail</B></td>"
                  }
                }
               ########################################################
               ####################Replications status##################
               add-type -AssemblyName microsoft.visualbasic
               $cmp = "microsoft.visualbasic.strings" -as [type]
               $sysvol = start-job -scriptblock {dcdiag /test:Replications /s:$($args[0])} -ArgumentList $DC
               wait-job $sysvol -timeout $timeout
               if($sysvol.state -like "Running")
               {
               Write-Host $DC `t Replications Test TimeOut -ForegroundColor Yellow
               Add-Content $report "<td bgcolor= 'Yellow' align=center><B>Timeout</B></td>"
               stop-job $sysvol
               }
               else
               {
               $sysvol1 = Receive-job $sysvol
               if($cmp::instr($sysvol1, "passed test Replications"))
                  {
                  Write-Host $DC `t Replications Test passed -ForegroundColor Green
                  Add-Content $report "<td bgcolor= 'Aquamarine' align=center><B>Pass</B></td>"
                  }
               else
                  {
                  Write-Host $DC `t Replications Test Failed -ForegroundColor Red
                  Add-Content $report "<td bgcolor= 'Red' align=center><B>Fail</B></td>"
                  }
                }
               ########################################################
           ####################Services status##################
               add-type -AssemblyName microsoft.visualbasic
               $cmp = "microsoft.visualbasic.strings" -as [type]
               $sysvol = start-job -scriptblock {dcdiag /test:Services /s:$($args[0])} -ArgumentList $DC
               wait-job $sysvol -timeout $timeout
               if($sysvol.state -like "Running")
               {
               Write-Host $DC `t Services Test TimeOut -ForegroundColor Yellow
               Add-Content $report "<td bgcolor= 'Yellow' align=center><B>Timeout</B></td>"
               stop-job $sysvol
               }
               else
               {
               $sysvol1 = Receive-job $sysvol
               if($cmp::instr($sysvol1, "passed test Services"))
                  {
                  Write-Host $DC `t Services Test passed -ForegroundColor Green
                  Add-Content $report "<td bgcolor= 'Aquamarine' align=center><B>Pass</B></td>"
                  }
               else
                  {
                  Write-Host $DC `t Services Test Failed -ForegroundColor Red
                  Add-Content $report "<td bgcolor= 'Red' align=center><B>Fail</B></td>"
                  }
                }
               ########################################################
           ####################Advertising status##################
               add-type -AssemblyName microsoft.visualbasic
               $cmp = "microsoft.visualbasic.strings" -as [type]
               $sysvol = start-job -scriptblock {dcdiag /test:Advertising /s:$($args[0])} -ArgumentList $DC
               wait-job $sysvol -timeout $timeout
               if($sysvol.state -like "Running")
               {
               Write-Host $DC `t Advertising Test TimeOut -ForegroundColor Yellow
               Add-Content $report "<td bgcolor= 'Yellow' align=center><B>Timeout</B></td>"
               stop-job $sysvol
               }
               else
               {
               $sysvol1 = Receive-job $sysvol
               if($cmp::instr($sysvol1, "passed test Advertising"))
                  {
                  Write-Host $DC `t Advertising Test passed -ForegroundColor Green
                  Add-Content $report "<td bgcolor= 'Aquamarine' align=center><B>Pass</B></td>"
                  }
               else
                  {
                  Write-Host $DC `t Advertising Test Failed -ForegroundColor Red
                  Add-Content $report "<td bgcolor= 'Red' align=center><B>Fail</B></td>"
                  }
                }
               ########################################################
           ####################FSMOCheck status##################
               add-type -AssemblyName microsoft.visualbasic
               $cmp = "microsoft.visualbasic.strings" -as [type]
               $sysvol = start-job -scriptblock {dcdiag /test:FSMOCheck /s:$($args[0])} -ArgumentList $DC
               wait-job $sysvol -timeout $timeout
               if($sysvol.state -like "Running")
               {
               Write-Host $DC `t FSMOCheck Test TimeOut -ForegroundColor Yellow
               Add-Content $report "<td bgcolor= 'Yellow' align=center><B>Timeout</B></td>"
               stop-job $sysvol
               }
               else
               {
               $sysvol1 = Receive-job $sysvol
               if($cmp::instr($sysvol1, "passed test FsmoCheck"))
                  {
                  Write-Host $DC `t FSMOCheck Test passed -ForegroundColor Green
                  Add-Content $report "<td bgcolor= 'Aquamarine' align=center><B>Pass</B></td>"
                  }
               else
                  {
                  Write-Host $DC `t FSMOCheck Test Failed -ForegroundColor Red
                  Add-Content $report "<td bgcolor= 'Red' align=center><B>Fail</B></td>"
                  }
                }
                ########################################################
                ####################DfsrRep status##################
                #        Additional column added to Vika's script for my customizations.
                $DfsrLastUpdateJob = start-job -InitializationScript $DeclareFunctions -scriptblock {Get-DFSRLastUpdateDelta -ComputerName $args[0]} -ArgumentList $DC
                wait-job $DfsrLastUpdateJob -timeout $timeout
               
                if($DfsrLastUpdateJob.state -like "Running"){
                    Write-Host $DC `t DFSR Last Rep Test TimeOut -ForegroundColor Yellow
                    Add-Content $report "<td bgcolor= 'Yellow' align=center><B>Timeout</B></td>"
                    stop-job $DfsrLastUpdateJob
                }
                else{
                    $DfsrLastUpdateDelta = Receive-job $DfsrLastUpdateJob
                    If ($DfsrLastUpdateJob.state -eq "Failed"){$DfsrLastUpdateTestResults = "Fail (Unreadable)"}
                    ElseIf ($DfsrLastUpdateDelta.Hours -ge 23){$DfsrLastUpdateTestResults = ("Fail (" + $DfsrLastUpdateDelta.Minutes + " Min)")}
                    Else {$DfsrLastUpdateTestResults = ("Pass (" + $DfsrLastUpdateDelta.Minutes + " Min)")}
 
                    if($DfsrLastUpdateTestResults -notlike "Fail*") {
                            Write-Host $DC `t DFSR Last Rep Test passed -ForegroundColor Green
                            Add-Content $report "<td bgcolor= 'Aquamarine' align=center><B>$DfsrLastUpdateTestResults</B></td>"
                    }
                    else {
                            Write-Host $DC `t DFSR Last Rep Test Failed -ForegroundColor Red
                            Add-Content $report "<td bgcolor= 'Red' align=center><B>$DfsrLastUpdateTestResults</B></td>"
                    }
                }          
    }
    else {
    Write-Host $DC `t $DC `t Ping Fail -ForegroundColor Red
            Add-Content $report "<td bgcolor= 'GainsBoro' align=center>  <B> $Identity</B></td>"
                    Add-Content $report "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>"
            Add-Content $report "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>"
            Add-Content $report "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>"
            Add-Content $report "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>"
            Add-Content $report "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>"
            Add-Content $report "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>"
            Add-Content $report "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>"
            Add-Content $report "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>"
            Add-Content $report "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>"
    }            
}
 
Add-Content $report "</tr>"
############################################Close HTMl Tables###########################
 
 
Add-content $report  "</table>"
Add-Content $report "</body>"
Add-Content $report "</html>"
 
 
########################################################################################
#############################################Send Email#################################
$IsHealthy = Get-Content $reportpath | Select-String -Pattern "Fail|Stopped|Timeout"
If ($IsHealthy -ne $null)
{
    $subject = "Daily AD Health Check - UNHEALTHY"
    $body = Get-Content $reportpath
    $smtp= New-Object System.Net.Mail.SmtpClient $smtphost
    $msg = New-Object System.Net.Mail.MailMessage
    $msg.To.Add($email1)
    $msg.from = $from
    $msg.subject = $subject
    $msg.body = $body
    $msg.isBodyhtml = $true
    $smtp.send($msg)
}
 
########################################################################################
 
########################################################################################
       
Stop-Transcript
