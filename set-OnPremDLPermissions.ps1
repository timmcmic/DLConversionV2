<#
    .SYNOPSIS

    Resets the permissions for the on premises DL.

    .DESCRIPTION

    Resets the permissions for the on premises DL.

    .PARAMETER allOnPremSendAs

    All of the send as permissions for other objects on prem.

    .PARAMETER allOnPremFullMailboxAccess

    All of the full mailbox access permissions for other objects on prem.

    .PARAMETER allOnPremFolderPermissions

    All of the mailbox folder permissions.

    .PARAMETER all

    .OUTPUTS

    None

    .EXAMPLE

    set-onPremDLPermissions -allOnPremSendAs $onPremSendAs -allOnPremFullMailboxAccess $onPremFullMailboxAccess -allOnPremFolderPermissions $folderPermissions

    #>
    Function set-OnPremDLPermissions
    {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [AllowEmptyCollection()]
            [array]$allOnPremSendAs=$NULL,
            [Parameter(Mandatory = $true)]
            [AllowEmptyCollection()]
            [array]$allOnPremFullMailboxAccess=$NULL,
            [Parameter(Mandatory = $true)]
            [AllowEmptyCollection()]
            [array]$allOnPremFolderPermissions=$NULL,
            [Parameter(Mandatory = $TRUE)]
            [string]$groupSMTPAddress
        )

       #Output all parameters bound or unbound and their associated values.

       write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        [string]$isTestError="No"

        #Declare function variables.

        #Start processing the recipient permissions.
       
        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "START set-OnPremDLPermissions"
        Out-LogFile -string "********************************************************************************"

        #Determine if send as is populated and if so reset permissiosn.

        if ($allOnPremSendAs -ne $NULL)
        {
            $isTestError = "No"
            out-logfile -string "There are objects that have send as rights - processing."

            foreach ($permission in $allOnPremSendAs)
            {
                out-logfile -string ("Processing permission identity = "+$permission.identity)
                out-logfile -string ("Processing permission trustee = "+$permission.user)

                try {
                    add-adPermission -identity $permission.identity -user $permission.user -AccessRights ExtendedRight -ExtendedRights "Send As" -confirm:$FALSE -errorAction Stop
                }
                catch {
                    out-logfile -string "Unable to add the recipient permission send as on premises."
                    $isTestError = "Yes"
                    out-logfile -string $_
                    $errorMessageDetail = $_
                }
            }

            if ($isTestError -eq "Yes")
            {
                out-logfile -string "Error adding migrated mail contact to send as permissions on premises."

                $isErrorObject = new-Object psObject -property @{
                    permissionIdentity = $permission.Identity
                    attribute = "Send As Permission"
                    errorMessage = "Unable to add the migrated distribution list mail contact with send as permissions to groups sourced on onPremRecipientSendAs."
                    errorMessageDetail = $errorMessageDetail
                }
    
                out-logfile -string $isErrorObject
    
                $global:OnPremReplacePermissionsErrors+=$isErrorObject
            }
            elseif ($isTestError -eq "No")
            {
                out-logfile -string "Administrator Notice:  The mitrated mail contact was sucessfully added but the permission is not effective."
                out-logfile -string "Mail contacts are not security principals therefore the permission will not continue to work on premises."
                out-logfile -string "Mail contact added only to faciliate the migration of other distribution lists that may depend on the discovery of this object."

                $isErrorObject = new-Object psObject -property @{
                    permissionIdentity = $permission.Identity
                    attribute = "Send As Permission"
                    errorMessage = "Administrator Notice:  The mitrated mail contact was sucessfully added but the permission is not effective." 
                    errorMessageDetail = "Mail contacts are not security principals therefore the permission will not continue to work on premises. Mail contact added only to faciliate the migration of other distribution lists that may depend on the discovery of this object."
                }
    
                out-logfile -string $isErrorObject
    
                $global:OnPremReplacePermissionsErrors+=$isErrorObject
            }
        }
        else 
        {
            out-logfile -string "There are no send as permissions to process."    
        }

        
    
        

        if ($allOnPremFullMailboxAccess -ne $NULL)
        {
            $isTestError = "No"

            out-logfile -string "There are objects that have full mailbox access rights - processing."

            try {
                foreach ($permission in $allOnPremFullMailboxAccess)
                {
                    out-logfile -string ("Processing permission identity = "+$permission.identity)
                    out-logfile -string ("Processing permission trustee = "+$permission.user)
                    out-logfile -string ("Processing permission access rights = "+$permission.AccessRights)

                    add-MailboxPermission -identity $permission.identity -user $permission.user -accessRights $permission.accessRights -confirm:$FALSE -errorAction Stop
                }
            }
            catch {
                out-logFile -string "Unable to add the full mailbox access permission in Office 365."
                out-logfile -string $_
                $isTestError="Yes"
                $errorMessageDetail=$_
            }

            if ($isTestError -eq "Yes")
            {
                out-logfile -string "Error processing full mailbox access rights on premises (migrated mail contact) for migrated DL."

                $isErrorObject = new-Object psObject -property @{
                    permissionIdentity = $permission.Identity
                    attribute = "Full Mailbox Access Permission"
                    errorMessage = "Unable to add the migrated distribution list with full mailbox access permissions to resource.  Manaul add required."
                    errorMessageDetail = $errorMessageDetail
                }

                out-logfile -string $isErrorObject

                $global:onPremReplacePermissionsErrors+=$isErrorObject
            }
            elseif ($isTestError -eq "No")
            {
                out-logfile -string "Administrator Notice:  The mitrated mail contact was sucessfully added but the permission is not effective."
                out-logfile -string "Mail contacts are not security principals therefore the permission will not continue to work on premises."
                out-logfile -string "Mail contact added only to faciliate the migration of other distribution lists that may depend on the discovery of this object."

                $isErrorObject = new-Object psObject -property @{
                    permissionIdentity = $permission.Identity
                    attribute = "Full Mailbox Access Permission"
                    errorMessage = "Administrator Notice:  The mitrated mail contact was sucessfully added but the permission is not effective." 
                    errorMessageDetail = "Mail contacts are not security principals therefore the permission will not continue to work on premises. Mail contact added only to faciliate the migration of other distribution lists that may depend on the discovery of this object."
                }
    
                out-logfile -string $isErrorObject
    
                $global:OnPremReplacePermissionsErrors+=$isErrorObject
            }
        }
        else 
        {
            out-logfile -string "There are no full mailbox access permissions to process."    
        }

        if ($allOnPremFolderPermissions -ne $NULL)
        {
            out-logfile -string "Processing mailbox folder permissions on Premises."

            foreach ($permission in $allOnPremFolderPermissions)
            {
                $isTestError = "No"
                
                try {
                    out-logfile -string ("Processing permission identity = "+$permission.identity)
                    out-logfile -string ("Processing permission trustee = "+$permission.user)
                    out-logfile -string ("Processing permissions folder = "+$permission.folderName)
                    out-logfile -string ("Processing permission access rights = "+$permission.AccessRights)

                    add-MailboxFolderPermission -identity $permission.identity -user $permission.user -accessRights $permission.AccessRights -confirm:$FALSE -errorAction Stop
                }
                catch {
                    out-logFile -string "Unable to add mailbox folder permissions on premises for migrated mail contact."
                    out-logfile -string $_
                    $isTestError="Yes"
                    $errorMessageDetail=$_
                }
            }

            if ($isTestError -eq "Yes")
            {
                out-logfile -string "Unable to add mailbox folder permissions on premises for migrated mail contact.."

                $isErrorObject = new-Object psObject -property @{
                    permissionIdentity = $permission.Identity
                    attribute = "Mailbox Folder Permission"
                    errorMessage = "Unable to add the migrated distribution list with mailbox folder permissions to resource.  Manaul add required."
                    errorMessageDetail = $errorMessageDetail
                }

                out-logfile -string $isErrorObject

                $global:onPremReplacePermissionsErrors+=$isErrorObject
            }
            elseif ($isTestError -eq "No")
            {
                out-logfile -string "Administrator Notice:  The mitrated mail contact was sucessfully added but the permission is not effective."
                out-logfile -string "Mail contacts are not security principals therefore the permission will not continue to work on premises."
                out-logfile -string "Mail contact added only to faciliate the migration of other distribution lists that may depend on the discovery of this object."

                $isErrorObject = new-Object psObject -property @{
                    permissionIdentity = $permission.Identity
                    attribute = "Mailbox Folder Permission"
                    errorMessage = "Administrator Notice:  The mitrated mail contact was sucessfully added but the permission is not effective." 
                    errorMessageDetail = "Mail contacts are not security principals therefore the permission will not continue to work on premises. Mail contact added only to faciliate the migration of other distribution lists that may depend on the discovery of this object."
                }
    
                out-logfile -string $isErrorObject
    
                $global:OnPremReplacePermissionsErrors+=$isErrorObject
            }
        }
        else 
        {
            out-logfile -string "There are no full mailbox access permissions to process."  
        }

        Out-LogFile -string "END set-OnPremDLPermissions"
        Out-LogFile -string "********************************************************************************"
    }