<#
    .SYNOPSIS

    This function utilizes exchange on premises and searches for all send as rights across all recipients.

    .DESCRIPTION

    This function utilizes exchange on premises and searches for all send as rights across all recipients.

    .PARAMETER originalDLConfiguration

    The mail attribute of the group to search.

    .OUTPUTS

    Returns a list of all objects with send-As rights and exports them.

    .EXAMPLE

    get-o365dlconfiguration -groupSMTPAddress Address

    #>
    Function Get-onPremSendAs
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $originalDLConfiguration,
            [Parameter(Mandatory=$false)]
            $collectedData=$NULL
        )

        #Declare function variables.

        [array]$functionSendAsRights=@()
        $functionRecipients=$NULL
        $functionQueryName=("*"+$originalDLConfiguration.sAMAccountName+"*")
        [array]$functionSendAsIdentities=@()
        [int]$functionCounter=0

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN Get-onPremSendAs"
        Out-LogFile -string "********************************************************************************"

        out-logfile -string ("DL query name = "+$functionQueryName)

        if ($collectedData -eq $NULL)
        {
            #Start function processing.

            try {
                out-logfile -string "Gathering all on premises recipients."

                $functionRecipients = invoke-command {get-recipient -resultsize unlimited}
            }
            catch {
                out-logfile -string "Error attempting to invoke command to gather all recipients."
                out-logfile -string $_ -isError:$TRUE
            }

            try {
                out-logfile -string "Test for send as rights."

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

                    $functionPercentComplete+=$functionProgress

                    $functionSendAsRights+= invoke-command {$blockName=$args[1];Get-ADPermission -identity $args[0] | Where-Object {($_.ExtendedRights -like "*send-as*") -and -not ($_.User -like "nt authority\self") -and ($_.isInherited -eq $false) -and ($_.user -like $blockName)}}-ArgumentList $recipient.identity,$functionQueryName
                    #$functionSendAsRights+= invoke-command {Get-ADPermission -identity $args[0] | Where-Object {($_.ExtendedRights -like "*send-as*") -and -not ($_.User -like "nt authority\self") -and ($_.isInherited -eq $false)}}-ArgumentList $recipient.identity,$functionQueryName
                } 
            }
            catch {
                out-logfile -string "Error attempting to invoke command to gather all send as permissions."
                out-logfile -string $_ -isError:$TRUE
            }

            #At this point we have a filter list of ACLs.
            #The query above uses a like for the user name - which means we need to validate for sure that we're talking about thes ame user.

            foreach ($sendAsRight in $functionSendAsRights)
            {
                #Since each permission is in domain\samAccountName format split the string.

                if ($sendAsRight.user -notlike "*S-1-5-21*")
                {
                    #Need to ignore anything that looks like a SID / orphaned entry.
                    $stringTest = $sendAsRight.user.split("\")
                }

                #Test the second half of the string for a direct eq to samAccountName.

                if ($stringTest[1] -eq $originalDLConfiguration.samAccountName)
                {
                    out-logfile -string ("Send as permission matching group found - recording."+$sendAsRight.identity)
                    $functionSendAsIdentities+=$sendAsRight.identity
                }
            }

            write-progress -activity "Processing Recipient" -completed
        }
        elseif ($collectedData -ne $NULL)
        {
            try {
                out-logfile -string "Test for send as rights."

                $ProgressDelta = 100/($collectedData.count); $PercentComplete = 0; $MbxNumber = 0

                foreach ($recipient in $collectedData)
                {
                    out-logfile -string $recipient
                    $MbxNumber++

                    write-progress -activity "Processing Recipient" -status "Something" -PercentComplete $PercentComplete

                    $PercentComplete += $ProgressDelta

                    $functionPercentComplete+=$functionProgress

                    if ($recipient.user -notlike "*S-1-5-21*")
                    {
                        #Need to ignore anything that looks like a SID / orphaned entry.
                        $stringTest = $sendAsRight.user.split("\")
                    }

                    if ($stringTest[1] -eq $originalDLConfiguration.samAccountName)
                    {
                        out-logfile -string ("Send as permission matching group found - recording."+$sendAsRight.identity)
                        $functionSendAsIdentities+=$sendAsRight.identity
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
        else 
        {
            out-logFile -string "The administrator has specified to use pre-collected data."    
        }

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "END Get-onPremSendAs"
        Out-LogFile -string "********************************************************************************" 

        if ($functionSendAsIdentities.count -gt 0)
        {
            return $functionSendAsIdentities
        }
    }