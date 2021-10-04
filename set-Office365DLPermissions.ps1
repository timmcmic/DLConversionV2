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
            [array]$allSendAs=$NULL,
            [Parameter(Mandatory = $true)]
            [AllowEmptyCollection()]
            [array]$allFullMailboxAccess=$NULL,
            [Parameter(Mandatory = $true)]
            [AllowEmptyCollection()]
            [array]$allFolderPermissions=$NULL
        )

        $isTestError="No"
        $permissionsErrors=@()

        #Declare function variables.

        #Start processing the recipient permissions.
       
        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "START set-Office365DLPermissions"
        Out-LogFile -string "********************************************************************************"

        #Determine if send as is populated and if so reset permissiosn.

        if ($allSendAs -ne $NULL)
        {
            out-logfile -string "There are objects that have send as rights - processing."

            foreach ($permission in $allSendAs)
            {
                $isTestError="No" #Reset error tracking.

                out-logfile -string ("Processing permission identity = "+$permission.identity)
                out-logfile -string ("Processing permission trustee = "+$permission.trustee)
                out-logfile -string ("Processing permission access rights = "+$permission.AccessRights)

                try {
                    add-o365RecipientPermission -identity $permission.identity -trustee $permission.trustee -accessRights $permission.accessRights -confirm:$FALSE
                }
                catch {
                    out-logfile -string "Unable to add the recipient permission in office 365."
                    out-logfile -string $_

                    $isTestError="Yes"
                }

                if ($isTestError -eq "Yes")
                {
                    out-logfile -string "Error adding routing contact to Office 365 Distribution List."
    
                    $isErrorObject = new-Object psObject -property @{
                        permissionIdentity = $permission.Identity
                        attribute = "SendAs Permission"
                        errorMessage = "Unable to add the migrated distribution list with send as permissions to resource.  Manaul add required."
                    }
    
                    out-logfile -string $isErrorObject
    
                    $permissionsErrors+=$isErrorObject
                }
            }
        }
        else 
        {
            out-logfile -string "There are no send as permissions to process."    
        }

        
    
        

        if ($allFullMailboxAccess -ne $NULL)
        {
            out-logfile -string "There are objects that have full mailbox access rights - processing."

            try {
                foreach ($permission in $allFullMailboxAccess)
                {
                    $isTestError="No" #Reset error tracking.

                    out-logfile -string ("Processing permission identity = "+$permission.identity)
                    out-logfile -string ("Processing permission trustee = "+$permission.user)
                    out-logfile -string ("Processing permission access rights = "+$permission.AccessRights)

                    add-o365MailboxPermission -identity $permission.identity -user $permission.user -accessRights $permission.accessRights -confirm:$FALSE
                }
            }
            catch {
                out-logFile -string "Unable to add the full mailbox access permission in Office 365."
                out-logfile -string $_
                $isTestError="Yes"
            }

            if ($isTestError -eq "Yes")
                {
                    out-logfile -string "Error adding routing contact to Office 365 Distribution List."
    
                    $isErrorObject = new-Object psObject -property @{
                        permissionIdentity = $permission.Identity
                        attribute = "FullMailboxAccess Permission"
                        errorMessage = "Unable to add the migrated distribution list with full mailbox access permissions to resource.  Manaul add required."
                    }
    
                    out-logfile -string $isErrorObject
    
                    $permissionsErrors+=$isErrorObject
                }
        }
        else 
        {
            out-logfile -string "There are no full mailbox access permissions to process."    
        }
        
        
    
        

        if ($allFolderPermissions -ne $NULL)
        {
            out-logfile -string "Processing mailbox folder permissions in Office 365."

            foreach ($permission in $allFolderPermissions)
            {
                $isTestError="No"

                try {
                    out-logfile -string ("Processing permission identity = "+$permission.identity)
                    out-logfile -string ("Processing permission trustee = "+$permission.user)
                    out-logfile -string ("Processing permission access rights = "+$permission.AccessRights)

                    add-o365MailboxFolderPermission -identity $permission.identity -user $permission.user -accessRights $permission.AccessRights -confirm:$FALSE
                }
                catch {
                    out-logFile -string "Unable to add the full mailbox access permission in Office 365."
                    out-logfile -string $_

                    $isTestError="Yes"
                }

                if ($isTestError -eq "Yes")
                {
                    out-logfile -string "Error adding routing contact to Office 365 Distribution List."
    
                    $isErrorObject = new-Object psObject -property @{
                        permissionIdentity = $permission.Identity
                        attribute = "Mailbox Folder Permission"
                        errorMessage = "Unable to add the migrated distribution list with mailbox folder permissions to resource.  Manaul add required."
                    }
    
                    out-logfile -string $isErrorObject
    
                    $permissionsErrors+=$isErrorObject
                }
            }
        }
        else 
        {
            out-logfile -string "There are no full mailbox access permissions to process."  
        }

        
    
        

        Out-LogFile -string "END set-Office365DLPermissions"
        Out-LogFile -string "********************************************************************************"

        return $permissionsErrors
    }