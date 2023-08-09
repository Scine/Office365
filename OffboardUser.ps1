Connect-ExchangeOnline
connect-azuread
connect-msolservice


$upn = read-Host 'Offboarding Office 365 Username:'
$Delegate = read-Host 'Username of who is going to be having access to shared mailbox'

$User = Get-AzureADUser -ObjectId $upn
Remove-AzureADUserManager -ObjectId $User.ObjectId

#.\Remove_User_All_Groups.ps1 $upn -verbose -includeaadsecuritygroups


#---------------------------------------------------------[Declarations]--------------------------------------------------------
# Arrays for capturing the actions
$owned      = @()
$memberof   = @()

#---------------------------------------------------------[Execution]--------------------------------------------------------
# Get all of the Office 365 groups
$azgroups = Get-AzureADMSGroup -Filter "groupTypes/any(c:c eq 'Unified')" -All:$true
Write-Output "$($azgroups.Count) Office 365 groups were found"

# Get info for departing user
$AZuser     = Get-AzureADUser -SearchString $upn

# Get info for delegate

$AZdelegate = Get-AzureADUser -SearchString $delegate

# Check each group for the user
foreach ($group in $azgroups) {
    $members = (Get-AzureADGroupMember -ObjectId $group.id).UserPrincipalName
    If ($members -contains $upn) {
        Remove-AzureADGroupMember -ObjectId $group.Id -MemberId $AZuser.ObjectId 
        Write-Output "$upn was removed from $($group.DisplayName)"
        $memberof += $group

        $owners  = Get-AzureADGroupOwner -ObjectId $group.id
        foreach ($owner in $owners) {
            If ($upn -eq $owner.UserPrincipalName) {
                # Add a new owner to prevent orphaned
                Write-Output "$delegate was added as a new owner"
                Add-AzureADGroupOwner -ObjectId $group.Id -RefObjectId $AZdelegate.ObjectId
                
                # Now we can remove the user
                Write-Output "$upn was removed as ownerof $($group.DisplayName)"
                Remove-AzureADGroupOwner -ObjectId $group.Id -OwnerId $AZuser.ObjectId

                $owned += $group
            }
        }
    }
}

# Groups that the user owned:
Write-Output "$upn was removed as Owner of:"
$owned | Select-Object DisplayName, Id

#Groups that the user was a member of:
Write-Output "$upn was removed as Member of:"
$memberof | Select-Object DisplayName, Id


$Password = [system.web.security.membership]::GeneratePassword(10,2)
$Results = write-host "New password is:    $Password"

Set-MSOLUserPassword -UserPrincipalName "$upn" -ForceChangePassword $false -NewPassword '$Password'

Revoke-AzureADUserAllRefreshToken -ObjectId $upn

#Set-AzureADUser -ObjectID $upn -AccountEnabled $false

Set-Mailbox $upn -Type shared

start-sleep -s 90

set-mailbox $upn -MessageCopyForSentAsEnabled $True
set-mailbox $upn -MessageCopyForSendOnBehalfEnabled $True
Set-Mailbox -Identity $upn -HiddenFromAddressListsEnabled $true

#Set-MailboxAutoReplyConfiguration -Identity $upn -AutoReplyState Enabled -InternalMessage "$upn is no longer with COMPANY.  Your email has been forwarded to $delegate and will be handled by them.  Please update your contact information accordingly.  If you have any questions or issues, please feel free to call us at NUMBER" -ExternalMessage "$upn is no longer with COMPANY.  Your email has been forwarded to $delegate and will be handled by them.  Please update your contact information accordingly.  If you have any questions or issues, please feel free to call us at NUMBER"

Set-Mailbox -Identity $upn -DeliverToMailboxAndForward $true -ForwardingSMTPAddress $Delegate

Add-MailboxPermission -Identity $upn -User $Delegate -AccessRights FullAccess

Write-host "Completed.  Password changed to $Password for account $EmailAddress"

$DistributionGroups= Get-DistributionGroup | where { (Get-DistributionGroupMember $_.Name | foreach {$_.PrimarySmtpAddress}) -contains "$upn"}
$DistributionGroups


# Get all mail-enabled security groups
$SecurityGroups = Get-DistributionGroup -ResultSize Unlimited -Filter {RecipientTypeDetails -eq "MailUniversalSecurityGroup"}

# Remove the user from each security group
foreach ($Group in $SecurityGroups) {
    Write-Host "Removing user $($UserDisplayName) from $($Group.DisplayName)..."
    Remove-DistributionGroupMember -Identity $Group.Identity -Member $upn -Confirm:$false
}

# Reprocess licenses for each security group
foreach ($Group in $SecurityGroups) {
    Write-Host "Reprocessing licenses for $($Group.DisplayName)..."
    Set-DistributionGroup -Identity $Group.Identity -ForceUpgrade
}

Set-AzureADUser -ObjectID $upn -AccountEnabled $false


$UserToRemove = "$upn"
 
Try {

 
    #Get the user
    $User = Get-AzureADuser -ObjectId $UserToRemove
 
    #Get All Security Groups of the user
    $GroupMemberships = Get-AzureADUserMembership -ObjectId $User.ObjectId -All $true | Where {$_.ObjectType -eq "Group" -and $_.SecurityEnabled -eq $true -and $_.MailEnabled -eq $false}
 
    #Loop through each security group
    ForEach($Group in $GroupMemberships)
    { 
        Try { 
            Remove-AzureADGroupMember -ObjectId $Group.ObjectID -MemberId $User.ObjectId -erroraction Stop 
            Write-host "Removed user from Group: $($Group.DisplayName)"
        }
        catch {
            #Remove-DistributionGroupMember -identity $group.mail -member $userid -BypassSecurityGroupManagerCheck # -Confirm:$false
            write-host -f Red "Error:" $_.Exception.Message
        }
    }
}
Catch {
    write-host -f Red "Error:" $_.Exception.Message
}