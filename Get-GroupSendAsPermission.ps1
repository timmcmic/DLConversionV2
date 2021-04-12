<#
    .SYNOPSIS

    This function extracts the send as ACLs of the group to be migrated.
    
    .DESCRIPTION

    This function extracts the send as ACLs of the group to be migrated.

    .PARAMETER adGlobalCatalogPowershellSessionName

    The powershell session to invoke the get-ACL call remotely - ensures we use the specified DC.

    .PARAMETER globalCatalogServer

    The global catalog server to feed into the normalization command.

    .PARAMETER DN

    The DN of the object to pass to normalize.

    .PARAMETER adCredential

    The credential for the AD get operations.

    .OUTPUTS

    This returns the normalized list of SMTP addresses assigned send as permissions.

    .EXAMPLE

    get-GroupSendAsPermissions -DN DN -globalCatalog GC

    #>
    Function get-GroupSendAsPermissions
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$adGlobalCatalogPowershellSessionName,
            [Parameter(Mandatory = $true)]
            [string]$DN,
            [Parameter(Mandatory = $true)]
            [string]$globalCatalogServer,
            [Parameter(Mandatory = $true)]
            $adCredential
        )

        #Declare function variables.

        $functionPSSession = $null
        [array]$functionACLS = @()
        [array]$functionSendAsRight=@()
        [array]$functionSendAsRightName=@()
        [array]$functionSendAsRightDN=@()
        [array]$functionSendAsObjects=@()

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN GET-GroupSendAsPermissions"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        Out-LogFile -string ("GlobalCatalogServer = "+$globalCatalogServer)
        out-logFile -string ("ADGlobalCatalogPowershellSessionName = "+$adGlobalCatalogPowershellSessionName)
        OUt-LogFile -string ("DN Set = "+$DN)
        out-logfile -string ("Credential user name = "+$adCredential.UserName)
        
        #Getting the working powershell session for commands that do not support specifying domain controllers.

        try 
        {
            out-logfile -string "Obtaining remote powershell session for the global catalog server."

            $functionPSSession = Get-PSSession -Name $adGlobalCatalogPowershellSessionName
        }
        catch 
        {
            out-logfile -string "Unable to retrieve the global catalog remote powershell session."
            out-logfile -string $_ -isError:$TRUE
        }
        
        #Importing the active directory module.

        try 
        {
           out-logfile -string "Importing the active directory module within the powershell session."

           invoke-command -session $functionPSSession -ScriptBlock {Import-Module "ActiveDirectory"}
        }
        catch 
        {
            out-logfile -string "Unable to import the active directory module in the remote powershell session."
            out-logfile -string $_ -isError:$TRUE
        }
        
        #The powershell session to the GC was opened - set the location to AD for query.

        try 
        {
           out-logfile -string "Setting the location of the remote powershell command to AD:"

           invoke-command -session $functionPSSession -ScriptBlock {Set-Location "AD:"}
        }
        catch 
        {
            out-logfile -string "Unable to set the location of the command to AD:."
            out-logfile -string $_ -isError:$TRUE
        }

        #With the location set to active directory - we can then pull the ACLS off the object.

        try 
        {
            out-logfile -string ("Obtaining the ACLS on DN = "+$dn)

            $functionACLS = invoke-command -session $functionPSSession -ScriptBlock {(get-ACL $args).access} -ArgumentList $dn
        }
        catch 
        {
            out-logfile -string "Unable to retrieve the ACLs from object."
            out-logfile -string $_ -isError:$TRUE
        }

        #The ACLS object has been extracted.
        #We want all perms that are extended, allowed, and match the object type for send as.

        $functionSendAsRight = $functionACLS | ?{($_.ActiveDirectoryRights -eq "ExtendedRight") -and ($_.objectType -eq "ab721a54-1e2f-11d0-9819-00aa0040529b") -and ($_.AccessControlType -eq "Allow")}

        #At this time we have all of the function send as rights.  If the array is empty - there are no rights.
        #If a send as right is present - it is stored on the object as DOMAIN\NAME format.  This is not something that we can work with.
        #We need to normalize this list over to distinguished names.

        if ($functionSendAsRight.count -ne 0)
        {
            out-logfile -string "Send as rights were detected - normalizing identity."

            foreach ($sendAsRight in $functionSendAsRight)
            {
                out-logfile -string "Processing ACL"
                out-logfile -string $sendAsRight

                $functionSendAsRightName+=$sendAsRight.identityreference.tostring().split("\")[1]
            }
        }
        else 
        {
            out-logfile -string "There were no send as rights on the object - disregard identities."
        }

        #At this time we have an array of names that were split of the identity reference.
        #We now have to normalize those names over to distinguished names so we can then normalize them to SMTP addresses.

        if ($functionSendAsRightName.count -ne 0)
        {
            out-logfile -string "We have send as names that require distinguished names."

            foreach ($sendAsName in $functionSendAsRightName)
            {
                out-logfile -string ("Processing identity = "+$sendAsName)

                try 
                {
                    $functionSendAsRightDN+=(get-adobject -filter {SAMAccountName -eq $sendAsName} -server $globalCatalogServer -credential $adCredential).distinguishedName
                }
                catch 
                {
                    out-logfile -string "Unablet to retrive the object by name."
                    out-logfile -string $_ -isError:$TRUE
                }
            }
        }
        else 
        {
            out-logfile -string  "There are no send as rights DNs to process."   
        }

        #At this time we have an array of all the DNs.
        #The DNs need to be normalized as any of the other DNs we work with.

        if ($functionSendAsRightDN.count -ne 0)
        {
            out-logfile -string "There are DNs to be normalized."

            foreach ($dnToNormalize in $functionSendAsRightDN)
            {
                out-logfile -string ("Processing DN = "+$dnToNormalize)

                try 
                {
                    $functionSendAsObjects+=get-normalizedDN -globalCatalogServer $globalCatalogWithPort -DN $dnToNormalize -adCredential $activeDirectoryCredential -originalGroupDN $dn  -errorAction STOP
                }
                catch 
                {
                    out-logfile -string "Unable to normalize the DN to an object with SMTP."
                    out-logfile -string $_ -isError:$TRUE
                }
            }
        }
        else 
        {
            out-logfile -string "There were no DNs to process."    
        }

        if ($functionSendAsObjects -ne $NULL)
        {
            foreach ($object in $functionSendAsObjects)
            {
                out-logfile -string "This is an object to be returned."
                out-logfile -string $object
            }
        }

        Out-LogFile -string "END GET-GroupSendAsPermissions"
        Out-LogFile -string "********************************************************************************"

        return $functionSendAsObjects
        
        #This function is designed to open local and remote powershell sessions.
        #If the session requires import - for example exchange - return the session for later work.
        #If not no return is required.
    
    }