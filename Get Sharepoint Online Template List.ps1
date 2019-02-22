function get-SPOnlineListTemplates {
    #variables that needs to be set before starting the script
    $siteURL = "https://domain.sharepoint.com/"
    $adminUrl = "https://domain-admin.sharepoint.com"
    $userName = "username@domain.com"
     
    # Let the user fill in their password in the PowerShell window
    $password = Read-Host "Please enter the password for $($userName)" -AsSecureString
     
    # set SharePoint Online credentials
    $SPOCredentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($userName, $password)
         
    # Creating client context object
    $context = New-Object Microsoft.SharePoint.Client.ClientContext($siteURL)
    $context.credentials = $SPOCredentials
 $listTemplates = $context.web.listtemplates
 $context.load($listTemplates)
     
    #send the request containing all operations to the server
    try{
        $context.executeQuery()
        write-host "info: Loaded list templates" -foregroundcolor green
    }
    catch{
        write-host "info: $($_.Exception.Message)" -foregroundcolor red
    }
      
 #List available templates
 $listTemplates | select baseType, Description, ListTemplateTypeKind | ft –wrap
}
get-SPOnlineListTemplates
