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
            [Parameter(Mandatory=$true)]
            [string]$groupTypeOverride,
            [Parameter(Mandatory=$true)]
            [string]$newDLPrimarySMTPAddress
        )

        #Declare function variables.

        [array]$functionDirectoryObjectID = $NULL
        $functionEmailAddress = $NULL
        [boolean]$routingAddressIsPresent=$FALSE
        [string]$hybridRemoteRoutingAddress=$NULL
        [string]$workingAddress=$NULL
        [array]$workingAddressArray=@()

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN SET-Office365DLMV"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        Out-LogFile -string ("OriginalDLConfiguration = ")
        out-logfile -string $originalDLConfiguration
        out-logfile -string ("Primary SMTP address of the DL")
        out-logfile -string $newDLPrimarySMTPAddress

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

        foreach ($address in $originalDLConfiguration.proxyAddresses)
        {         
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

        if ($routingAddressIsPresent -eq $FALSE)
        {
            out-logfile -string "A hybrid remote routing address was not present.  Adding hybrid remote routing address."
            $workingAddress=$newDLPrimarySMTPAddress.substring($newDLPrimarySMTPAddress.indexOf("@"))
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

        out-logFile -string "Evaluating exchangeDLMembershipSMTP"

        if ($exchangeDLMembershipSMTP -ne $NULL)
        {
            foreach ($member in $exchangeDLMembershipSMTP)
            {
                if ($member.externalDirectoryObjectID -ne $NULL)
                {
                    out-LogFile -string ("Processing member = "+$member.externalDirectoryObjectID)

                    $functionDirectoryObjectID=$member.externalDirectoryObjectID.Split("_")

                    out-LogFile -string ("Processing updated member = "+$functionDirectoryObjectID[1])

                    try {
                        add-O365DistributionGroupMember -identity $originalDLConfiguration.mailnickname -member $functionDirectoryObjectID[1] -errorAction STOP -BypassSecurityGroupManagerCheck
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
                        add-O365DistributionGroupMember -identity $originalDLConfiguration.mailNickName -member $member.primarySMTPAddressOrUPN -errorAction STOP -BypassSecurityGroupManagerCheck
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

        out-logFile -string "Evaluating exchangeRejectMessagesSMTP"

        if ($exchangeRejectMessagesSMTP -ne $NULL)
        {
            foreach ($member in $exchangeRejectMessagesSMTP)
            {
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

        out-logFile -string "Evaluating exchangeAcceptMessagesSMTP"

        if ($exchangeAcceptMessageSMTP -ne $NULL)
        {
            foreach ($member in $exchangeAcceptMessageSMTP)
            {
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

        out-logFile -string "Evaluating exchangeManagedBySMTP"

        if ($exchangeManagedBySMTP -ne $NULL)
        {
            foreach ($member in $exchangeManagedBySMTP)
            {
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
                        set-o365DistributionGroup -identity $originalDLConfiguration.mailNickName -ManagedBy @{Add=$functionDirectoryObjectID[1]} -errorAction STOP -BypassSecurityGroupManagerCheck
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
                        set-o365DistributionGroup -identity $originalDLConfiguration.mailNickName -ManagedBy @{Add=$member.primarySMTPAddressOrUPN} -errorAction STOP -BypassSecurityGroupManagerCheck
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

        out-logFile -string "Evaluating exchangeModeratedBy"

        if ($exchangeModeratedBySMTP -ne $NULL)
        {
            foreach ($member in $exchangeModeratedBySMTP)
            {
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

        out-logFile -string "Evaluating exchangeBypassModerationSMTP"

        if ($exchangeBypassModerationSMTP -ne $NULL)
        {
            foreach ($member in $exchangeBypassModerationSMTP)
            {
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

        out-logFile -string "Evaluating exchangeGrantSendOnBehalfToSMTP"

        if ($exchangeGrantSendOnBehalfToSMTP -ne $NULL)
        {
            foreach ($member in $exchangeGrantSendOnBehalfToSMTP)
            {
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

        Out-LogFile -string "END SET-Office365DLMV"
        Out-LogFile -string "********************************************************************************"
    }