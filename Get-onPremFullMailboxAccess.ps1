<#
    .SYNOPSIS

    This function locates any mailbox level permissions on the DL to be migrated.

    .DESCRIPTION

    This function locates any mailbox level permissions on the DL to be migrated.

    .PARAMETER originalDLConfiguration

    The mail attribute of the group to search.

    .OUTPUTS

    Returns a list of all objects with send-As rights and exports them.

    .EXAMPLE

    Get-onPremFullMailboxAccess -originalDLConfiguration DLConfig

    #>
    Function Get-onPremFullMailboxAccess
    {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $originalDLConfiguration,
            [Parameter(Mandatory = $false)]
            $collectedData=$NULL
        )

        #Declare function variables.

        [array]$functionPermissions=@()
        $functionRecipients=@()

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN Get-onPremFullMailboxAccess"
        Out-LogFile -string "********************************************************************************"

        if ($collectedData -eq $NULL)
        {
            #Start function processing.

            try {
                out-logfile -string "Gathering all on premises mailboxes."

                $functionRecipients = invoke-command {get-mailbox -resultsize unlimited}
            }
            catch {
                out-logfile -string "Error attempting to invoke command to gather all recipients."
                out-logfile -string $_ -isError:$TRUE
            }

            #We now have all the mailbox recipients.

            try {
                out-logfile -string "Test for mailbox permissions."

                $ProgressDelta = 100/($functionRecipients.count); $PercentComplete = 0; $MbxNumber = 0

                foreach ($recipient in $functionRecipients)
                {
                    $MbxNumber++

                    write-progress -activity "Processing Recipient" -status $recipient.primarySMTPAddress -PercentComplete $PercentComplete

                    $PercentComplete += $ProgressDelta

                    if ($functionCounter -gt 1000)
                    {
                        #Implement function counter for long running operations - pause for 5 seconds every 1000 queries.

                        out-logfile -string "Invoking 5 second sleep for powershell recovery."
                        start-sleep -seconds 5

                        $functionCounter=0
                    }
                    else 
                    {
                        $functionCounter++    
                    }

                    $functionPermissions+= invoke-command {Get-MailboxPermission -identity $args[0] -user $args[1]}-ArgumentList $recipient.identity,$originalDLConfiguration.samAccountName
                } 
            }
            catch {
                out-logfile -string "Error attempting to invoke command to gather all mailbox permissions."
                out-logfile -string $_ -isError:$TRUE
            }

            write-progress -activity "Processing Recipient" -completed
            
            #Start function processing.

            try {
                out-logfile -string "Gathering all on premises mailboxes."

                $functionRecipients = invoke-command {get-mailbox -resultsize unlimited}
            }
            catch {
                out-logfile -string "Error attempting to invoke command to gather all recipients."
                out-logfile -string $_ -isError:$TRUE
            }

            #We now have all the mailbox recipients.

            try {
                out-logfile -string "Test for mailbox permissions."

                $ProgressDelta = 100/($functionRecipients.count); $PercentComplete = 0; $MbxNumber = 0

                foreach ($recipient in $functionRecipients)
                {
                    $MbxNumber++

                    write-progress -activity "Processing Recipient" -status $recipient.primarySMTPAddress -PercentComplete $PercentComplete

                    $PercentComplete += $ProgressDelta

                    if ($functionCounter -gt 1000)
                    {
                        #Implement function counter for long running operations - pause for 5 seconds every 1000 queries.

                        out-logfile -string "Invoking 5 second sleep for powershell recovery."
                        start-sleep -seconds 5

                        $functionCounter=0
                    }
                    else 
                    {
                        $functionCounter++    
                    }

                    $functionPermissions+= invoke-command {Get-MailboxPermission -identity $args[0] -user $args[1]}-ArgumentList $recipient.identity,$originalDLConfiguration.samAccountName
                } 
            }
            catch {
                out-logfile -string "Error attempting to invoke command to gather all mailbox permissions."
                out-logfile -string $_ -isError:$TRUE
            }

            write-progress -activity "Processing Recipient" -completed  
        }
        elseif ($collectedData -ne $NULL)
        {
            try 
            {
                out-logfile -string "Testing for full mailbo access rights.."

                $ProgressDelta = 100/($collectedData.count); $PercentComplete = 0; $MbxNumber = 0

                foreach ($recipient in $collectedData)
                {
                    $MbxNumber++

                    write-progress -activity "Processing Recipient" -status $recipient.identity -PercentComplete $PercentComplete

                    $PercentComplete += $ProgressDelta

                    if ($recipient.user -notlike "*S-1-5-21*")
                    {
                        #Need to ignore anything that looks like a SID / orphaned entry.
                        $stringTest = $recipient.user.split("\")

                        if ($stringTest[1] -eq $originalDLConfiguration.samAccountName)
                        {
                            out-logfile -string ("Full mailbox access permission found - recording."+$recipient.identity)
                            $functionPermissions+=$recipient.identity
                        }
                    } 
                }
            }
            catch 
            {
                out-logfile -string "Error attempting to invoke command to gather all send as permissions."
                out-logfile -string $_ -isError:$TRUE
            }

            write-progress -Activity "Processing Recipient" -Completed
        }

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "END Get-onPremFullMailboxAccess"
        Out-LogFile -string "********************************************************************************" 

        
        if ($functionPermissions.count -gt 0)
        {
            return $functionPermissions
        }
    }