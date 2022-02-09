<#
    .SYNOPSIS

    This function sets the multi valued attributes of the DL

    .DESCRIPTION

    This function sets the multi valued attributes of the DL.
    For each of use - I've combined these into a single function instead of splitting them out.

    .PARAMETER allSendAs

    All of the send as permissions for other objects in Office 365.

    .PARAMETER allFullMailboxAccess

    All of the full mailbox access permissions for other objects in Office 365.

    .OUTPUTS

    None

    .EXAMPLE

    set-Office365DLPermissions -allSendAs SENDAS -allFullMailboxAccess FULLMAILBOXACCESS

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

        #Declare function variables.

        #Start processing the recipient permissions.
       
        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "START set-OnPremDLPermissions"
        Out-LogFile -string "********************************************************************************"

        #Determine if send as is populated and if so reset permissiosn.

        if ($allOnPremSendAs -ne $NULL)
        {
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
                    out-logfile -string $_ -isError:$TRUE
                }
            }
        }
        else 
        {
            out-logfile -string "There are no send as permissions to process."    
        }

        
    
        

        if ($allOnPremFullMailboxAccess -ne $NULL)
        {
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
                out-logfile -string $_ -isError:$TRUE
            }
        }
        else 
        {
            out-logfile -string "There are no full mailbox access permissions to process."    
        }
        
        
    
        

        if ($allOnPremFolderPermissions -ne $NULL)
        {
            out-logfile -string "Processing mailbox folder permissions in Office 365."

            foreach ($permission in $allOnPremFolderPermissions)
            {
                try {
                    out-logfile -string ("Processing permission identity = "+$permission.identity)
                    out-logfile -string ("Processing permission trustee = "+$permission.user)
                    out-logfile -string ("Processing permissions folder = "+$permission.folderName)
                    out-logfile -string ("Processing permission access rights = "+$permission.AccessRights)

                    add-MailboxFolderPermission -identity $permission.identity -user $permission.user -accessRights $permission.AccessRights -confirm:$FALSE -errorAction Stop
                }
                catch {
                    out-logFile -string "Unable to add the full mailbox access permission in Office 365."
                    out-logfile -string $_ -isError:$TRUE
                }
            }
        }
        else 
        {
            out-logfile -string "There are no full mailbox access permissions to process."  
        }

        Out-LogFile -string "END set-OnPremDLPermissions"
        Out-LogFile -string "********************************************************************************"
    }