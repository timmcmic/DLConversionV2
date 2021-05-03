<#
    .SYNOPSIS

    This function sets the multi valued attributes of the DL

    .DESCRIPTION

    This function sets the multi valued attributes of the DL.
    For each of use - I've combined these into a single function instead of splitting them out.dddd

    .PARAMETER originalDLConfiguration

    The original configuration of the DL on premises.

    .PARAMETER exchangeDLMembership

    The array of members of the group.

    .PARAMETER exchangeRejectMessages

    The array of objects with reject message permissions.

    .PARAMETER exchangeAcceptMessages

    The array of users with accept message permissions.

    .PARAMETER exchangeManagedBy

    The array of objects with managedBY permissions.

    .PARAMETER exchangeModeratedBy

    The array of moderators.

    .PARAMETER exchangeBypassModeration

    The list of users / groups that have bypass moderation rights.

    .PARAMETER exchangeFrantSendOnBehalfTo

    The list of objecst that have grant send on behalf to rights.

    .OUTPUTS

    None

    .EXAMPLE

    set-Office365DLMV -originalDLConfiguration -exchangeDLMembership -exchangeRejectMessage -exchangeAcceptMessage -exchangeManagedBy -exchangeModeratedBy -exchangeBypassMOderation -exchangeGrantSendOnBehalfTo.

    [array$exchangeDLMembershipSMTP=$NULL
    [array]$exchangeRejectMessagesSMTP=$NULL
    [array]$exchangeAcceptMessageSMTP=$NULL
    [array]$exchangeManagedBySMTP=$NULL
    [array]$exchangeModeratedBySMTP=
    [array]$exchangeBypassModerationSMTP=$NULL 
    [array]$exchangeGrantSendOnBehalfToSMTP



    #>
    Function set-Office365DLMV
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $originalDLConfiguration,
            [Parameter(Mandatory = $true)]
            [AllowEmptyCollection()]
            [array]$exchangeDLMembershipSMTP=$NULL,
            [Parameter(Mandatory = $true)]
            [AllowEmptyCollection()]
            [array]$exchangeRejectMessagesSMTP=$NULL,
            [Parameter(Mandatory = $true)]
            [AllowEmptyCollection()]
            [array]$exchangeAcceptMessageSMTP=$NULL,
            [Parameter(Mandatory = $true)]
            [AllowEmptyCollection()]
            [array]$exchangeManagedBySMTP=$NULL,
            [Parameter(Mandatory = $true)]
            [AllowEmptyCollection()]
            [array]$exchangeModeratedBySMTP=$NULL,
            [Parameter(Mandatory = $true)]
            [AllowEmptyCollection()]
            [array]$exchangeBypassModerationSMTP=$NULL,
            [Parameter(Mandatory = $true)]
            [AllowEmptyCollection()]
            [array]$exchangeGrantSendOnBehalfToSMTP=$NULL,
            [Parameter(Mandatory = $true)]
            [AllowEmptyCollection()]
            [array]$exchangeSendAsSMTP=$NULL,
            [Parameter(Mandatory=$true)]
            [string]$groupTypeOverride,
            [Parameter(Mandatory=$true)]
            $newDLPrimarySMTPAddress
        )

        #Declare function variables.

        [array]$functionDirectoryObjectID = $NULL
        $functionEmailAddress = $NULL
        [boolean]$routingAddressIsPresent=$FALSE
        [string]$hybridRemoteRoutingAddress=$NULL
        [string]$workingAddress=$NULL
        [array]$workingAddressArray=@()
        [int]$functionLoopCounter=0
        [boolean]$functionFirstRun=$TRUE
        [array]$functionRecipients=@()

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN SET-Office365DLMV"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        Out-LogFile -string ("OriginalDLConfiguration = ")
        out-logfile -string $originalDLConfiguration

        $newOffice365DLPrimarySMTPAddress = get-O365DistributionGroup -identity $originalDLConfiguration.mailNickname

        
        #This function implements an overall function loop counter.
        #For every 1000 set operations against Office 365 we will sleep for 5 seconds.
        #The counter does not reset for each configuration evaluation - but is rather global to this function.
        #This ensures appropriate time for powershell recharge rates should a distribution list have bulk operations.
        
        #At this time begin the iteraction through the arrays that have passed.

        Out-LogFile -string "Reset the DL proxy addresses to match original object."

        out-logfile -string "Reset just the primary SMTP Address first since the array contains SMTP and smtp"

        out-logfile -string $originalDLConfiguration.mail

        try {
            set-o365DistributionGroup -identity $originalDLConfiguration.mailnickname -primarySMTPAddress $originalDLConfiguration.mail -errorAction STOP
        }
        catch {
            out-logfile $_ -isError:$TRUE
        }

        $global:unDoStatus=$global:unDoStatus+1
    
        out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

        out-logfile -string "Processing on premises legacy ExchangeDN to X500"
        out-logfile -string $originalDLConfiguration.legacyExchangeDN

        $functionEmailAddress = "X500:"+$originalDLConfiguration.legacyExchangeDN

        out-logfile -string ("The x500 address to process = "+$functionEmailAddress)

        try {
            Set-O365DistributionGroup -identity $originalDLConfiguration.mailNickName -emailAddresses @{add=$functionEmailAddress} -errorAction STOP -BypassSecurityGroupManagerCheck
        }
        catch {
            out-logfile -string $_ -isError:$TRUE
        }

        $global:unDoStatus=$global:unDoStatus+1
    
        out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

        foreach ($address in $originalDLConfiguration.proxyAddresses)
        {   
            #Implement some protections for larger operations to ensure we do not exhaust our powershell budget.

            if ($functionLoopCounter -eq 1000)
            {
                out-logfile -string "Sleeping for 5 seconds - powershell refresh interval"
                start-sleep -seconds 5
                $functionLoopCounter = 0
            }
            else 
            {
                out-logfile -string ("Function Loop Counter = "+$functionLoopCounter)
                $functionLoopCounter++
            }

            out-Logfile -string "Processing address:"
            out-Logfile -string $address

            if ($address.contains("mail.onmicrosoft.com"))
            {
                out-logfile -string ("Hybrid remote routing address found.")
                out-logfile -string $address
                $routingAddressIsPresent=$TRUE
            }

            try {
                Set-O365DistributionGroup -identity $originalDLConfiguration.mailNickName -emailAddresses @{add=$address} -errorAction STOP -BypassSecurityGroupManagerCheck
            }
            catch {
                out-logfile -string $_ -isError:$TRUE
            }
        }

        $global:unDoStatus=$global:unDoStatus+1
    
        out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

        if ($routingAddressIsPresent -eq $FALSE)
        {
            out-logfile -string "A hybrid remote routing address was not present.  Adding hybrid remote routing address."
            $workingAddress=$newDLPrimarySMTPAddress.substring($newDLPrimarySMTPAddress.indexof("@"))
            $workingAddressArray=$workingaddress.split(".")
            $hybridRemoteRoutingAddress=$originalDLConfiguration.mailnickname+$workingAddressArray[0]+".mail."+$workingAddressArray[1]+"."+$workingAddressArray[2]

            out-logfile -string ("Hybrid remote routing address = "+$hybridRemoteRoutingAddress)

            try {
                Set-O365DistributionGroup -identity $originalDLConfiguration.mailNickName -emailAddresses @{add=$hybridRemoteRoutingAddress} -errorAction STOP -BypassSecurityGroupManagerCheck
            }
            catch {
                out-logfile -string $_ -isError:$TRUE
            }
        }

        $global:unDoStatus=$global:unDoStatus+1
    
        out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

        out-logFile -string "Evaluating exchangeDLMembershipSMTP"

        if ($exchangeDLMembershipSMTP -ne $NULL)
        {
            <# 
            foreach ($member in $exchangeDLMembershipSMTP)
            {
                
                #Implement some protections for larger operations to ensure we do not exhaust our powershell budget.

                if ($functionLoopCounter -eq 1000)
                {
                    out-logfile -string "Sleeping for 5 seconds - powershell refresh interval"
                    start-sleep -seconds 5
                    $functionLoopCounter = 0
                }
                else 
                {
                    out-logfile -string ("Function Loop Counter = "+$functionLoopCounter)
                    $functionLoopCounter++
                }

                #If the recipient type is a group - set error action to silientlyContinue.
                #This is required - if the group is retained we set the same custom attributes as the cross premises contact created.
                #Therefore there could be an exception that th member already exists.

                if ($member.RecipientType -eq "group")
                {
                    out-logfile -string "Member is a group - setting error action to continue."
                    $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Continue
                }
                else 
                {
                    out-logfile -string "Member is not a group - setting error action to stop."
                    $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
                }


                if ($member.externalDirectoryObjectID -ne $NULL)
                {
                    out-LogFile -string ("Processing member = "+$member.externalDirectoryObjectID)

                    $functionDirectoryObjectID=$member.externalDirectoryObjectID.Split("_")

                    out-LogFile -string ("Processing updated member = "+$functionDirectoryObjectID[1])

                    try {
                        add-O365DistributionGroupMember -identity $originalDLConfiguration.mailnickname -member $functionDirectoryObjectID[1] -BypassSecurityGroupManagerCheck
                    }
                    catch {
                        out-logfile -string "Unable to add member. "
                        out-logfile -string $member.externalDirectoryObjectID -isError:$TRUE
                    }
                }
                elseif ($member.primarySMTPAddressOrUPN -ne $NULL)
                {
                    out-LogFile -string ("Processing member = "+$member.PrimarySMTPAddressOrUPN)

                    try {
                        add-O365DistributionGroupMember -identity $originalDLConfiguration.mailNickName -member $member.primarySMTPAddressOrUPN -BypassSecurityGroupManagerCheck
                    }
                    catch {
                        out-logfile -string "Unable to add member. "
                        out-logfile -string $member.primarySMTPAddressOrUPN -isError:$TRUE
                    }
                }
                else 
                {
                    out-logfile -string "Invalid function object for recipient." -isError:$TRUE
                } 
            }
            #>
            
            
            #<#
            #Removing the original code that would iterate through each member and doing a bulk update
            #All of the members were previously verified as present - so no member should be gone by now unless removed.
            #This adds all members as a single operation.  Errors we silently continue.

            #Ensureing all addresses in the array are unique.

            foreach ($member in $exchangeDLMembershipSMTP)
            {
                if ($member.externalDirectoryObjectID -ne $NULL)
                {
                    out-logfile -string ("Processing directory ID: "+$member.ExternalDirectoryObjectID)
                    $functionDirectoryObjectID=$member.externalDirectoryObjectID.Split("_")
                    $functionRecipients+=$functionDirectoryObjectID[1]
                }
                else 
                {
                    out-logfile -string ("Processing SMTPAddress: "+$member.primarySMTPAddressOrUPN)  
                    $functionRecipients+=$member.primarySMTPAddressOrUPN    
                }
            }

            $functionRecipients = $functionRecipients | select-object -Unique

            out-logfile -string "Updating membership with unique values."
            out-logfile -string $functionRecipients
                
            update-o365DistributionGroupMember -identity $originalDLConfiguration.mailNickName -members $functionRecipients -BypassSecurityGroupManagerCheck -confirm:$FALSE -errorAction SilentlyContinue -verbose

            ##>
        }
        else 
        {
            Out-LogFile -string "There were no members to process."    
        }

        $global:unDoStatus=$global:unDoStatus+1
    
        out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

        out-logFile -string "Evaluating exchangeRejectMessagesSMTP"

        if ($exchangeRejectMessagesSMTP -ne $NULL)
        {
            foreach ($member in $exchangeRejectMessagesSMTP)
            {
                #Implement some protections for larger operations to ensure we do not exhaust our powershell budget.

                if ($functionLoopCounter -eq 1000)
                {
                    out-logfile -string "Sleeping for 5 seconds - powershell refresh interval"
                    start-sleep -seconds 5
                    $functionLoopCounter = 0
                }
                else 
                {
                    out-logfile -string ("Function Loop Counter = "+$functionLoopCounter)
                    $functionLoopCounter++
                }

                if ($member.externalDirectoryObjectID -ne $NULL)
                {
                    out-LogFile -string ("Processing member = "+$member.externalDirectoryObjectID)

                    $functionDirectoryObjectID=$member.externalDirectoryObjectID.Split("_")

                    out-LogFile -string ("Processing updated member = "+$functionDirectoryObjectID[1])

                    try {
                        set-o365DistributionGroup -identity $originalDLConfiguration.mailNickName -RejectMessagesFromSendersOrMembers @{Add=$functionDirectoryObjectID[1]} -errorAction STOP -BypassSecurityGroupManagerCheck
                    }
                    catch {
                        out-logfile -string "Unable to add member. "
                        out-logfile -string $member.externalDirectoryObjectID -isError:$TRUE
                    }
                }
                elseif ($member.primarySMTPAddressOrUPN -ne $NULL)
                {
                    out-LogFile -string ("Processing member = "+$member.PrimarySMTPAddressOrUPN)

                    try {
                        set-o365DistributionGroup -identity $originalDLConfiguration.mailNickName -RejectMessagesFromSendersOrMembers @{Add=$member.primarySMTPAddressOrUPN} -errorAction STOP -BypassSecurityGroupManagerCheck
                    }
                    catch {
                        out-logfile -string "Unable to add member. "
                        out-logfile -string $member.primarySMTPAddressOrUPN -isError:$TRUE
                    }
                }
                else 
                {
                    out-logfile -string "Invalid function object for recipient." -isError:$TRUE
                } 
            }
        }
        else 
        {
            Out-LogFile -string "There were no members to process."    
        }

        $global:unDoStatus=$global:unDoStatus+1
    
        out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

        out-logFile -string "Evaluating exchangeAcceptMessagesSMTP"

        if ($exchangeAcceptMessageSMTP -ne $NULL)
        {
            foreach ($member in $exchangeAcceptMessageSMTP)
            {
                #Implement some protections for larger operations to ensure we do not exhaust our powershell budget.

                if ($functionLoopCounter -eq 1000)
                {
                    out-logfile -string "Sleeping for 5 seconds - powershell refresh interval"
                    start-sleep -seconds 5
                    $functionLoopCounter = 0
                }
                else 
                {
                    out-logfile -string ("Function Loop Counter = "+$functionLoopCounter)
                    $functionLoopCounter++
                }

                if ($member.externalDirectoryObjectID -ne $NULL)
                {
                    out-LogFile -string ("Processing member = "+$member.externalDirectoryObjectID)

                    $functionDirectoryObjectID=$member.externalDirectoryObjectID.Split("_")

                    out-LogFile -string ("Processing updated member = "+$functionDirectoryObjectID[1])

                    try {
                        set-o365DistributionGroup -identity $originalDLConfiguration.mailNickName -AcceptMessagesOnlyFromSendersOrMembers @{Add=$functionDirectoryObjectID[1]} -errorAction STOP -BypassSecurityGroupManagerCheck
                    }
                    catch {
                        out-logfile -string "Unable to add member. "
                        out-logfile -string $member.externalDirectoryObjectID -isError:$TRUE
                    }
                }
                elseif ($member.primarySMTPAddressOrUPN -ne $NULL)
                {
                    out-LogFile -string ("Processing member = "+$member.PrimarySMTPAddressOrUPN)

                    try {
                        set-o365DistributionGroup -identity $originalDLConfiguration.mailNickName -AcceptMessagesOnlyFromSendersOrMembers @{Add=$member.primarySMTPAddressOrUPN} -errorAction STOP -BypassSecurityGroupManagerCheck
                    }
                    catch {
                        out-logfile -string "Unable to add member. "
                        out-logfile -string $member.primarySMTPAddressOrUPN -isError:$TRUE
                    }
                }
                else 
                {
                    out-logfile -string "Invalid function object for recipient." -isError:$TRUE
                } 
            }
        }
        else 
        {
            Out-LogFile -string "There were no members to process."    
        }

        $global:unDoStatus=$global:unDoStatus+1
    
        out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

        out-logFile -string "Evaluating exchangeManagedBySMTP"

        if ($exchangeManagedBySMTP -ne $NULL)
        {
            out-logfile -string ("Is this the first run for managed by = "+$functionFirstRun)

            foreach ($member in $exchangeManagedBySMTP)
            {
                #Implement some protections for larger operations to ensure we do not exhaust our powershell budget.

                if ($functionLoopCounter -eq 1000)
                {
                    out-logfile -string "Sleeping for 5 seconds - powershell refresh interval"
                    start-sleep -seconds 5
                    $functionLoopCounter = 0
                }
                else 
                {
                    out-logfile -string ("Function Loop Counter = "+$functionLoopCounter)
                    $functionLoopCounter++
                }

                if (($member.primarySMTPAddressOrUPN -eq $originalDLConfiguration.mail) -and ($groupTypeOverride -eq "Distribution"))
                {
                    out-logFile "The migrated DL has managed by permissions of iteself.  The administrator overrode the type to distribution."
                    out-logilfe "Security is required in order to manage a distribution group"
                    out-logfile "Skipping = "+$member.primarySMTPAddressOrUPN
                }
                elseif ($member.externalDirectoryObjectID -ne $NULL)
                {
                    out-LogFile -string ("Processing member = "+$member.externalDirectoryObjectID)

                    $functionDirectoryObjectID=$member.externalDirectoryObjectID.Split("_")

                    out-LogFile -string ("Processing updated member = "+$functionDirectoryObjectID[1])

                    try {
                        if ($functionFirstRun -eq $FALSE)
                        {
                            out-logfile -string "Not first manager of group - adding."

                            set-o365DistributionGroup -identity $originalDLConfiguration.mailNickName -ManagedBy @{Add=$functionDirectoryObjectID[1]} -errorAction STOP -BypassSecurityGroupManagerCheck
                        }
                        else 
                        {
                            out-logfile -string "First manager - resetting managed by list."

                            set-o365DistributionGroup -identity $originalDLConfiguration.mailNickName -ManagedBy $functionDirectoryObjectID[1] -errorAction STOP -BypassSecurityGroupManagerCheck  

                            $functionFirstRun = $FALSE
                        }
                    }
                    catch {
                        out-logfile -string "Unable to add member. "
                        out-logfile -string $member.externalDirectoryObjectID -isError:$TRUE
                    }
                }
                elseif ($member.primarySMTPAddressOrUPN -ne $NULL)
                {
                    out-LogFile -string ("Processing member = "+$member.PrimarySMTPAddressOrUPN)

                    try {
                        if ($functionFirstRun -ne $TRUE)
                        {
                            out-logfile -string "Not first manager of group - adding."

                            set-o365DistributionGroup -identity $originalDLConfiguration.mailNickName -ManagedBy @{Add=$member.primarySMTPAddressOrUPN} -errorAction STOP -BypassSecurityGroupManagerCheck
                        }
                        else 
                        {
                            out-logfile -string "First manager - resetting managed by list."

                            set-o365DistributionGroup -identity $originalDLConfiguration.mailNickName -ManagedBy $member.primarySMTPAddressOrUPN -errorAction STOP -BypassSecurityGroupManagerCheck

                            $functionFirstRun = $FALSE
                        }
                    }
                    catch {
                        out-logfile -string "Unable to add member. "
                        out-logfile -string $member.primarySMTPAddressOrUPN -isError:$TRUE
                    }
                }
                else 
                {
                    out-logfile -string "Invalid function object for recipient." -isError:$TRUE
                } 
            }
        }
        else 
        {
            Out-LogFile -string "There were no members to process."    
        }

        $global:unDoStatus=$global:unDoStatus+1
    
        out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

        out-logFile -string "Evaluating exchangeModeratedBy"

        if ($exchangeModeratedBySMTP -ne $NULL)
        {
            foreach ($member in $exchangeModeratedBySMTP)
            {
                #Implement some protections for larger operations to ensure we do not exhaust our powershell budget.

                if ($functionLoopCounter -eq 1000)
                {
                    out-logfile -string "Sleeping for 5 seconds - powershell refresh interval"
                    start-sleep -seconds 5
                    $functionLoopCounter = 0
                }
                else 
                {
                    out-logfile -string ("Function Loop Counter = "+$functionLoopCounter)
                    $functionLoopCounter++
                }

                if ($member.externalDirectoryObjectID -ne $NULL)
                {
                    out-LogFile -string ("Processing member = "+$member.externalDirectoryObjectID)

                    $functionDirectoryObjectID=$member.externalDirectoryObjectID.Split("_")

                    out-LogFile -string ("Processing updated member = "+$functionDirectoryObjectID[1])

                    try {
                        set-o365DistributionGroup -identity $originalDLConfiguration.mailNickName -ModeratedBy @{Add=$functionDirectoryObjectID[1]} -errorAction STOP -BypassSecurityGroupManagerCheck
                    }
                    catch {
                        out-logfile -string "Unable to add member. "
                        out-logfile -string $member.externalDirectoryObjectID -isError:$TRUE
                    }
                }
                elseif ($member.primarySMTPAddressOrUPN -ne $NULL)
                {
                    out-LogFile -string ("Processing member = "+$member.PrimarySMTPAddressOrUPN)

                    try {
                        set-o365DistributionGroup -identity $originalDLConfiguration.mailNickName -ModeratedBy @{Add=$member.primarySMTPAddressOrUPN} -errorAction STOP -BypassSecurityGroupManagerCheck
                    }
                    catch {
                        out-logfile -string "Unable to add member. "
                        out-logfile -string $member.primarySMTPAddressOrUPN -isError:$TRUE
                    }
                }
                else 
                {
                    out-logfile -string "Invalid function object for recipient." -isError:$TRUE
                } 
            }
        }
        else 
        {
            Out-LogFile -string "There were no members to process."    
        }

        $global:unDoStatus=$global:unDoStatus+1
    
        out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

        out-logFile -string "Evaluating exchangeBypassModerationSMTP"

        if ($exchangeBypassModerationSMTP -ne $NULL)
        {
            foreach ($member in $exchangeBypassModerationSMTP)
            {
                #Implement some protections for larger operations to ensure we do not exhaust our powershell budget.

                if ($functionLoopCounter -eq 1000)
                {
                    out-logfile -string "Sleeping for 5 seconds - powershell refresh interval"
                    start-sleep -seconds 5
                    $functionLoopCounter = 0
                }
                else 
                {
                    out-logfile -string ("Function Loop Counter = "+$functionLoopCounter)
                    $functionLoopCounter++
                }

                if ($member.externalDirectoryObjectID -ne $NULL)
                {
                    out-LogFile -string ("Processing member = "+$member.externalDirectoryObjectID)

                    $functionDirectoryObjectID=$member.externalDirectoryObjectID.Split("_")

                    out-LogFile -string ("Processing updated member = "+$functionDirectoryObjectID[1])

                    try {
                        set-o365DistributionGroup -identity $originalDLConfiguration.mailNickName -BypassModerationFromSendersOrMembers @{Add=$functionDirectoryObjectID[1]} -errorAction STOP -BypassSecurityGroupManagerCheck
                    }
                    catch {
                        out-logfile -string "Unable to add member. "
                        out-logfile -string $member.externalDirectoryObjectID -isError:$TRUE
                    }
                }
                elseif ($member.primarySMTPAddressOrUPN -ne $NULL)
                {
                    out-LogFile -string ("Processing member = "+$member.PrimarySMTPAddressOrUPN)

                    try {
                        set-o365DistributionGroup -identity $originalDLConfiguration.mailNickName -BypassModerationFromSendersOrMembers @{Add=$member.primarySMTPAddressOrUPN} -errorAction STOP -BypassSecurityGroupManagerCheck
                    }
                    catch {
                        out-logfile -string "Unable to add member. "
                        out-logfile -string $member.primarySMTPAddressOrUPN -isError:$TRUE
                    }
                }
                else 
                {
                    out-logfile -string "Invalid function object for recipient." -isError:$TRUE
                } 
            }
        }
        else 
        {
            Out-LogFile -string "There were no members to process."    
        }

        $global:unDoStatus=$global:unDoStatus+1
    
        out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

        out-logFile -string "Evaluating exchangeGrantSendOnBehalfToSMTP"

        if ($exchangeGrantSendOnBehalfToSMTP -ne $NULL)
        {
            foreach ($member in $exchangeGrantSendOnBehalfToSMTP)
            {
                #Implement some protections for larger operations to ensure we do not exhaust our powershell budget.

                if ($functionLoopCounter -eq 1000)
                {
                    out-logfile -string "Sleeping for 5 seconds - powershell refresh interval"
                    start-sleep -seconds 5
                    $functionLoopCounter = 0
                }
                else 
                {
                    out-logfile -string ("Function Loop Counter = "+$functionLoopCounter)
                    $functionLoopCounter++
                }

                if ($member.externalDirectoryObjectID -ne $NULL)
                {
                    out-LogFile -string ("Processing member = "+$member.externalDirectoryObjectID)

                    $functionDirectoryObjectID=$member.externalDirectoryObjectID.Split("_")

                    out-LogFile -string ("Processing updated member = "+$functionDirectoryObjectID[1])

                    try {
                        set-o365DistributionGroup -identity $originalDLConfiguration.mailNickName -GrantSendOnBehalfTo @{Add=$functionDirectoryObjectID[1]} -errorAction STOP -BypassSecurityGroupManagerCheck
                    }
                    catch {
                        out-logfile -string "Unable to add member. "
                        out-logfile -string $member.externalDirectoryObjectID -isError:$TRUE
                    }
                }
                elseif ($member.primarySMTPAddressOrUPN -ne $NULL)
                {
                    out-LogFile -string ("Processing member = "+$member.PrimarySMTPAddressOrUPN)

                    try {
                        set-o365DistributionGroup -identity $originalDLConfiguration.mailNickName -GrantSendOnBehalfTo @{Add=$member.primarySMTPAddressOrUPN} -errorAction STOP -BypassSecurityGroupManagerCheck
                    }
                    catch {
                        out-logfile -string "Unable to add member. "
                        out-logfile -string $member.primarySMTPAddressOrUPN -isError:$TRUE
                    }
                }
                else 
                {
                    out-logfile -string "Invalid function object for recipient." -isError:$TRUE
                } 
            }
        }
        else 
        {
            Out-LogFile -string "There were no members to process."    
        }

        $global:unDoStatus=$global:unDoStatus+1
    
        out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

        out-logFile -string "Evaluating exchangeSendAsSMTP"

        if ($exchangeSendAsSMTP -ne $NULL)
        {
            foreach ($member in $exchangeSendAsSMTP)
            {
                #Implement some protections for larger operations to ensure we do not exhaust our powershell budget.

                if ($functionLoopCounter -eq 1000)
                {
                    out-logfile -string "Sleeping for 5 seconds - powershell refresh interval"
                    start-sleep -seconds 5
                    $functionLoopCounter = 0
                }
                else 
                {
                    out-logfile -string ("Function Loop Counter = "+$functionLoopCounter)
                    $functionLoopCounter++
                }

                if ($member.externalDirectoryObjectID -ne $NULL)
                {
                    out-LogFile -string ("Processing member = "+$member.externalDirectoryObjectID)

                    $functionDirectoryObjectID=$member.externalDirectoryObjectID.Split("_")

                    out-LogFile -string ("Processing updated member = "+$functionDirectoryObjectID[1])

                    try {
                        add-o365RecipientPermission -Identity $originalDLConfiguration.mailNickName -Trustee $functionDirectoryObjectID[1] -AccessRights "SendAs" -confirm:$FALSE
                    }
                    catch {
                        out-logfile -string "Unable to add member. "
                        out-logfile -string $member.externalDirectoryObjectID -isError:$TRUE
                    }
                }
                elseif ($member.primarySMTPAddressOrUPN -ne $NULL)
                {
                    out-LogFile -string ("Processing member = "+$member.PrimarySMTPAddressOrUPN)

                    try {
                        add-o365RecipientPermission -Identity $originalDLConfiguration.mailNickName -Trustee $member.primarySMTPAddressOrUPN -AccessRights "SendAs" -confirm:$FALSE
                    }
                    catch {
                        out-logfile -string "Unable to add member. "
                        out-logfile -string $member.primarySMTPAddressOrUPN -isError:$TRUE
                    }
                }
                else 
                {
                    out-logfile -string "Invalid function object for recipient." -isError:$TRUE
                } 
            }
        }
        else 
        {
            Out-LogFile -string "There were no members to process."    
        }

        $global:unDoStatus=$global:unDoStatus+1
    
        out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

        Out-LogFile -string "END SET-Office365DLMV"
        Out-LogFile -string "********************************************************************************"
    }