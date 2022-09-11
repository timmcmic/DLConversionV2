<#
    .SYNOPSIS

    This function sets the multi valued attributes of the DL

    .DESCRIPTION

    This function sets the multi valued attributes of the DL.
    For each of use - I've combined these into a single function instead of splitting them out.dddd

    .PARAMETER allSendAs

    All of the send as permissions for other objects in Office 365.

    .PARAMETER allFullMailboxAccess

    All of the full mailbox access permissions for other objects in Office 365.

    .OUTPUTS

    None

    .EXAMPLE

    set-Office365DLPermissions -allSendAs SENDAS -allFullMailboxAccess FULLMAILBOXACCESS

    #>
    Function set-Office365DLPermissions
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [AllowEmptyCollection()]
            [array]$allSendAs=@(),
            [Parameter(Mandatory = $true)]
            [AllowEmptyCollection()]
            [array]$allOnPremSendAs=@(),
            [Parameter(Mandatory = $true)]
            [AllowEmptyCollection()]
            [array]$allFullMailboxAccess=@(),
            [Parameter(Mandatory = $true)]
            [AllowEmptyCollection()]
            [array]$allFolderPermissions=@(),
            [Parameter(Mandatory = $false)]
            [string]$originalGroupPrimarySMTPAddress=""
        )

        out-logfile -string "Output bound parameters..."

        foreach ($paramName in $MyInvocation.MyCommand.Parameters.Keys)
        {
            $bound = $PSBoundParameters.ContainsKey($paramName)

            $parameterObject = New-Object PSObject -Property @{
                ParameterName = $paramName
                ParameterValue = if ($bound) { $PSBoundParameters[$paramName] }
                                else { Get-Variable -Scope Local -ErrorAction Ignore -ValueOnly $paramName }
                Bound = $bound
            }

            out-logfile -string $parameterObject
        }

        $isTestError="No"

        #Declare function variables.

        #Start processing the recipient permissions.
       
        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "START set-Office365DLPermissions"
        Out-LogFile -string "********************************************************************************"

        #Determine if any dir synced groups on premises has send as set.  If so reset in service so migrated group continues to work.

        if ($allOnPremSendAs.count -gt 0)
        {
            out-logfile -string "The migrated group has send as rights on premises for groups that are directory synced."
            out-logfile -string "Adding the send as right to the cloud for the migrated distribution group."

            foreach ($permission in $allOnPremSendAs)
            {
                $isTestError="No" #Reset error tracking.
                $accessRight="SendAs"

                out-logfile -string ("Processing permission identity = "+$permission.primarySMTPAddressorUPN)
                out-logfile -string ("Processing permission trustee = "+$originalGroupPrimarySMTPAddress)
                out-logfile -string ("Processing permission access rights = "+$accessRight)

                try {
                    add-o365RecipientPermission -identity $permission.primarySMTPAddressOrUPN -trustee $originalGroupPrimarySMTPAddress -accessRights $accessRight -confirm:$FALSE -errorAction STOP
                }
                catch {
                    out-logfile -string "Unable to add the recipient permission in office 365."
                    out-logfile -string $_

                    $errorMessageDetail=$_
                    $isTestError="Yes"
                }

                if ($isTestError -eq "Yes")
                {
                    out-logfile -string "Error adding mirgated distribution list to send as permission of cloud only group.."
    
                    $isErrorObject = new-Object psObject -property @{
                        permissionIdentity = $permission.primarySMTPAddressorUPN
                        attribute = "SendAs Permission"
                        errorMessage = "Migrated DL has send as permissions on directory synced group.  Attempt to mirror permission in cloud failed.  Manaul add required."
                        errorMessageDetail = $errorMessageDetail
                    }
    
                    out-logfile -string $isErrorObject
    
                    $global:office365ReplacePermissionsErrors+=$isErrorObject
                }
            }
        }
        else 
        {
            out-logfile -string "There are no send as permissions to process."    
        }

        #Determine if send as is populated and if so reset permissiosn.

        if ($allSendAs.count -gt 0)
        {
            out-logfile -string "There are objects that have send as rights - processing."

            foreach ($permission in $allSendAs)
            {
                $isTestError="No" #Reset error tracking.

                out-logfile -string ("Processing permission identity = "+$permission.identity)
                out-logfile -string ("Processing permission trustee = "+$permission.trustee)
                out-logfile -string ("Processing permission access rights = "+$permission.AccessRights)

                try {
                    add-o365RecipientPermission -identity $permission.identity -trustee $permission.trustee -accessRights $permission.accessRights -confirm:$FALSE -errorAction STOP
                }
                catch {
                    out-logfile -string "Unable to add the recipient permission in office 365."
                    out-logfile -string $_

                    $errorMessageDetail=$_
                    $isTestError="Yes"
                }

                if ($isTestError -eq "Yes")
                {
                    out-logfile -string "Error adding migrated DL to on premises DL send as on cloud object.."
    
                    $isErrorObject = new-Object psObject -property @{
                        permissionIdentity = $permission.Identity
                        attribute = "SendAs Permission"
                        errorMessage = "Unable to add the migrated distribution list with send as permissions to resource.  Manaul add required."
                        errorMessageDetail = $errorMessageDetail
                    }
    
                    out-logfile -string $isErrorObject
    
                    $global:office365ReplacePermissionsErrors+=$isErrorObject
                }
            }
        }
        else 
        {
            out-logfile -string "There are no send as permissions to process."    
        }

        
    
        

        if ($allFullMailboxAccess.count -gt 0)
        {
            out-logfile -string "There are objects that have full mailbox access rights - processing."

            try {
                foreach ($permission in $allFullMailboxAccess)
                {
                    $isTestError="No" #Reset error tracking.

                    out-logfile -string ("Processing permission identity = "+$permission.identity)
                    out-logfile -string ("Processing permission trustee = "+$permission.user)
                    out-logfile -string ("Processing permission access rights = "+$permission.AccessRights)

                    add-o365MailboxPermission -identity $permission.identity -user $permission.user -accessRights $permission.accessRights -confirm:$FALSE -errorAction STOP
                }
            }
            catch {
                out-logFile -string "Unable to add the full mailbox access permission in Office 365."
                out-logfile -string $_
                $errorMessageDetail=$_
                $isTestError="Yes"
            }

            if ($isTestError -eq "Yes")
                {
                    out-logfile -string "Unable to add the full mailbox access permission in Office 365."
    
                    $isErrorObject = new-Object psObject -property @{
                        permissionIdentity = $permission.Identity
                        attribute = "FullMailboxAccess Permission"
                        errorMessage = "Unable to add the migrated distribution list with full mailbox access permissions to resource.  Manaul add required."
                        errorMessageDetail = $errorMessageDetail
                    }
    
                    out-logfile -string $isErrorObject
    
                    $global:office365ReplacePermissionsErrors+=$isErrorObject
                }
        }
        else 
        {
            out-logfile -string "There are no full mailbox access permissions to process."    
        }
        
        
    
        

        if ($allFolderPermissions.count -gt 0)
        {
            out-logfile -string "Removing existing mailbox permission in Office 365 to avoid ambiguity."

            foreach ($permission in $allFolderPermissions)
            {
                $isTestError="No"

                try {
                    out-logfile -string ("Processing permission identity = "+$permission.identity)
                    out-logfile -string ("Processing permission trustee = "+$permission.user.userPrincipalName)

                    remove-o365MailboxFolderPermission -identity $permission.identity -user $permission.user.userPrincipalName -confirm:$FALSE -errorAction STOP
                }
                catch {
                    out-logFile -string "Unable to remove the existing folder permission in Office 365."
                    out-logfile -string $_
                    $errorMessageDetail=$_

                    $isTestError="Yes"
                }

                if ($isTestError -eq "Yes")
                {
                    out-logfile -string "Unable to remove the existing folder permission in Office 365."
    
                    $isErrorObject = new-Object psObject -property @{
                        permissionIdentity = $permission.Identity
                        attribute = "Mailbox Folder Permission"
                        errorMessage = "Unable to remove the migrated distribution list with mailbox folder permissions to resource.  Manaul add required."
                        errorMessageDetail = $errorMessageDetail
                    }
    
                    out-logfile -string $isErrorObject
    
                    $global:office365ReplacePermissionsErrors+=$isErrorObject
                }
            }

            foreach ($permission in $allFolderPermissions)
            {
                $isTestError="No"

                try {
                    out-logfile -string ("Processing permission identity = "+$permission.identity)
                    out-logfile -string ("Processing permission trustee = "+$permission.user)
                    out-logfile -string ("Processing permission access rights = "+$permission.AccessRights)
                    out-logfile -string ("Processing permission sharing flags = "+$permission.sharingPermissionFlags)

                    add-o365MailboxFolderPermission -identity $permission.identity -user $permission.user.userPrincipalName -accessRights $permission.AccessRights -sharingPermissionFlags $permission.sharingPermissionFlags -confirm:$FALSE -errorAction STOP
                }
                catch {
                    out-logFile -string "Unable to add the folder access permission in Office 365."
                    out-logfile -string $_
                    $errorMessageDetail=$_

                    $isTestError="Yes"
                }

                if ($isTestError -eq "Yes")
                {
                    out-logfile -string "Unable to add the folder access permission in Office 365."
    
                    $isErrorObject = new-Object psObject -property @{
                        permissionIdentity = $permission.Identity
                        attribute = "Mailbox Folder Permission"
                        errorMessage = "Unable to add the migrated distribution list with mailbox folder permissions to resource.  Manaul add required."
                        errorMessageDetail = $errorMessageDetail
                    }
    
                    out-logfile -string $isErrorObject
    
                    $global:office365ReplacePermissionsErrors+=$isErrorObject
                }
            }
        }
        else 
        {
            out-logfile -string "There are no full mailbox access permissions to process."  
        }

        Out-LogFile -string "END set-Office365DLPermissions"
        Out-LogFile -string "********************************************************************************"
        
    }