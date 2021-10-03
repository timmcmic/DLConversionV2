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
        [array]$functionEmailAddresses=@()

        [string]$isError="NO"
        [array]$errors=@()

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN SET-Office365DLMV"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        Out-LogFile -string ("OriginalDLConfiguration = ")
        out-logfile -string $originalDLConfiguration

        out-logfile -string "Resetting all SMTP addresses on the object to match on premises."

        foreach ($address in $originalDLConfiguration.proxyAddresses)
        {
            if ($address.contains("mail.onmicrosoft.com"))
            {
                out-logfile -string ("Hybrid remote routing address found.")
                out-logfile -string $address
                $routingAddressIsPresent=$TRUE
            }

            out-logfile -string $address
            $functionEmailAddresses+=$address.tostring()
        }

        try {
            Set-O365DistributionGroup -identity $originalDLConfiguration.mailNickName -emailAddresses $functionEmailAddresses -errorAction STOP -BypassSecurityGroupManagerCheck
        }
        catch {
            out-logfile -string "Error bulk updating email addresses on distribution group."
            $isError="Yes"
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

            #Becuase groups could have been mirgated and retained - this ensures that all SMTP addresses and GUIDs in the array are unique.

            $functionRecipients = $functionRecipients | select-object -Unique

            out-logfile -string "Updating membership with unique values."
            out-logfile -string $functionRecipients

            #Using update to reset the entire membership of the DL to the unique array.
            #Alberto Larrinaga for the suggestion.
                
            update-o365DistributionGroupMember -identity $originalDLConfiguration.mailNickName -members $functionRecipients -BypassSecurityGroupManagerCheck -confirm:$FALSE -errorAction SilentlyContinue -verbose

            ##>
        }
        else 
        {
            Out-LogFile -string "There were no members to process."    
        }

        $global:unDoStatus=$global:unDoStatus+1
    
        out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

        $functionRecipients=@() #Reset the test array.

        out-logFile -string "Evaluating exchangeRejectMessagesSMTP"

        if ($exchangeRejectMessagesSMTP -ne $NULL)
        {
            foreach ($member in $exchangeRejectMessagesSMTP)
            {
                #Implement some protections for larger operations to ensure we do not exhaust our powershell budget.

                if ($member.externalDirectoryObjectID -ne $NULL)
                {
                    out-LogFile -string ("Processing member = "+$member.externalDirectoryObjectID)

                    $functionDirectoryObjectID=$member.externalDirectoryObjectID.Split("_")

                    out-LogFile -string ("Processing updated member = "+$functionDirectoryObjectID[1])

                    $functionRecipients+=$functionDirectoryObjectID[1]
                }
                elseif ($member.primarySMTPAddressOrUPN -ne $NULL)
                {
                    out-LogFile -string ("Processing member = "+$member.PrimarySMTPAddressOrUPN)

                    $functionRecipients+=$member.primarySMTPAddressOrUPN    
                }
                else 
                {
                    out-logfile -string "Invalid function object for recipient." -isError:$TRUE
                } 
            }

            #Becuase groups could have been mirgated and retained - this ensures that all SMTP addresses and GUIDs in the array are unique.

            $functionRecipients = $functionRecipients | select-object -Unique

            out-logfile -string "Updating reject messages SMTP with unique values."
            out-logfile -string $functionRecipients

            set-o365DistributionGroup -identity $originalDLConfiguration.mailNickName -RejectMessagesFromSendersOrMembers $functionRecipients -errorAction STOP -BypassSecurityGroupManagerCheck
        }
        else 
        {
            Out-LogFile -string "There were no members to process."    
        }

        $global:unDoStatus=$global:unDoStatus+1
    
        out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

        $functionRecipients=@() #Reset the test array.

        out-logFile -string "Evaluating exchangeAcceptMessagesSMTP"

        if ($exchangeAcceptMessageSMTP -ne $NULL)
        {
            foreach ($member in $exchangeAcceptMessageSMTP)
            {
                #Implement some protections for larger operations to ensure we do not exhaust our powershell budget.

                if ($member.externalDirectoryObjectID -ne $NULL)
                {
                    out-LogFile -string ("Processing member = "+$member.externalDirectoryObjectID)

                    $functionDirectoryObjectID=$member.externalDirectoryObjectID.Split("_")

                    out-LogFile -string ("Processing updated member = "+$functionDirectoryObjectID[1])

                    $functionRecipients+=$functionDirectoryObjectID[1]
                }
                elseif ($member.primarySMTPAddressOrUPN -ne $NULL)
                {
                    out-LogFile -string ("Processing member = "+$member.PrimarySMTPAddressOrUPN)

                    $functionRecipients+=$member.primarySMTPAddressOrUPN    
                }
                else 
                {
                    out-logfile -string "Invalid function object for recipient." -isError:$TRUE
                } 
            }

            #Becuase groups could have been mirgated and retained - this ensures that all SMTP addresses and GUIDs in the array are unique.

            $functionRecipients = $functionRecipients | select-object -Unique

            out-logfile -string "Updating accept messages SMTP with unique values."
            out-logfile -string $functionRecipients

            set-o365DistributionGroup -identity $originalDLConfiguration.mailNickName -AcceptMessagesOnlyFromSendersOrMembers $functionRecipients -errorAction STOP -BypassSecurityGroupManagerCheck
        }
        else 
        {
            Out-LogFile -string "There were no members to process."    
        }

        $global:unDoStatus=$global:unDoStatus+1
    
        out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

        $functionRecipients=@() #Reset the test array.

        out-logFile -string "Evaluating exchangeManagedBySMTP"

        if ($exchangeManagedBySMTP -ne $NULL)
        {
            foreach ($member in $exchangeManagedBySMTP)
            {
                #Implement some protections for larger operations to ensure we do not exhaust our powershell budget.

                if ($member.externalDirectoryObjectID -ne $NULL)
                {
                    out-LogFile -string ("Processing member = "+$member.externalDirectoryObjectID)

                    $functionDirectoryObjectID=$member.externalDirectoryObjectID.Split("_")

                    out-LogFile -string ("Processing updated member = "+$functionDirectoryObjectID[1])

                    $functionRecipients+=$functionDirectoryObjectID[1]
                }
                elseif ($member.primarySMTPAddressOrUPN -ne $NULL)
                {
                    out-LogFile -string ("Processing member = "+$member.PrimarySMTPAddressOrUPN)

                    $functionRecipients+=$member.primarySMTPAddressOrUPN    
                }
                else 
                {
                    out-logfile -string "Invalid function object for recipient." -isError:$TRUE
                } 
            }

            #Becuase groups could have been mirgated and retained - this ensures that all SMTP addresses and GUIDs in the array are unique.

            $functionRecipients = $functionRecipients | select-object -Unique

            out-logfile -string "Updating managed by SMTP with unique values."
            out-logfile -string $functionRecipients

            set-o365DistributionGroup -identity $originalDLConfiguration.mailNickName -managedBy $functionRecipients -errorAction STOP -BypassSecurityGroupManagerCheck
        }
        else 
        {
            Out-LogFile -string "There were no members to process."    
        }

        $global:unDoStatus=$global:unDoStatus+1
    
        out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

        $functionRecipients=@() #Reset the test array.

        out-logFile -string "Evaluating exchangeModeratedBy"

        if ($exchangeModeratedBySMTP -ne $NULL)
        {
            foreach ($member in $exchangeModeratedBySMTP)
            {
                #Implement some protections for larger operations to ensure we do not exhaust our powershell budget.

                if ($member.externalDirectoryObjectID -ne $NULL)
                {
                    out-LogFile -string ("Processing member = "+$member.externalDirectoryObjectID)

                    $functionDirectoryObjectID=$member.externalDirectoryObjectID.Split("_")

                    out-LogFile -string ("Processing updated member = "+$functionDirectoryObjectID[1])

                    $functionRecipients+=$functionDirectoryObjectID[1]
                }
                elseif ($member.primarySMTPAddressOrUPN -ne $NULL)
                {
                    out-LogFile -string ("Processing member = "+$member.PrimarySMTPAddressOrUPN)

                    $functionRecipients+=$member.primarySMTPAddressOrUPN    
                }
                else 
                {
                    out-logfile -string "Invalid function object for recipient." -isError:$TRUE
                } 
            }

            #Becuase groups could have been mirgated and retained - this ensures that all SMTP addresses and GUIDs in the array are unique.

            $functionRecipients = $functionRecipients | select-object -Unique

            out-logfile -string "Updating moderated by SMTP with unique values."
            out-logfile -string $functionRecipients

            set-o365DistributionGroup -identity $originalDLConfiguration.mailNickName -moderatedBy $functionRecipients -errorAction STOP -BypassSecurityGroupManagerCheck
        }
        else 
        {
            Out-LogFile -string "There were no members to process."    
        }

        $global:unDoStatus=$global:unDoStatus+1
    
        out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

        $functionRecipients=@() #Reset the test array.

        out-logFile -string "Evaluating exchangeBypassModerationSMTP"

        if ($exchangeBypassModerationSMTP -ne $NULL)
        {
            foreach ($member in $exchangeBypassModerationSMTP)
            {
                #Implement some protections for larger operations to ensure we do not exhaust our powershell budget.

                if ($member.externalDirectoryObjectID -ne $NULL)
                {
                    out-LogFile -string ("Processing member = "+$member.externalDirectoryObjectID)

                    $functionDirectoryObjectID=$member.externalDirectoryObjectID.Split("_")

                    out-LogFile -string ("Processing updated member = "+$functionDirectoryObjectID[1])

                    $functionRecipients+=$functionDirectoryObjectID[1]
                }
                elseif ($member.primarySMTPAddressOrUPN -ne $NULL)
                {
                    out-LogFile -string ("Processing member = "+$member.PrimarySMTPAddressOrUPN)

                    $functionRecipients+=$member.primarySMTPAddressOrUPN    
                }
                else 
                {
                    out-logfile -string "Invalid function object for recipient." -isError:$TRUE
                } 
            }

            #Becuase groups could have been mirgated and retained - this ensures that all SMTP addresses and GUIDs in the array are unique.

            $functionRecipients = $functionRecipients | select-object -Unique

            out-logfile -string "Updating bypass moderation from senders or members SMTP with unique values."
            out-logfile -string $functionRecipients

            set-o365DistributionGroup -identity $originalDLConfiguration.mailNickName -BypassModerationFromSendersOrMembers $functionRecipients -errorAction STOP -BypassSecurityGroupManagerCheck
        }
        else 
        {
            Out-LogFile -string "There were no members to process."    
        }

        $global:unDoStatus=$global:unDoStatus+1
    
        out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

        $functionRecipients=@() #Reset the test array.

        out-logFile -string "Evaluating exchangeGrantSendOnBehalfToSMTP"

        if ($exchangeGrantSendOnBehalfToSMTP -ne $NULL)
        {
            foreach ($member in $exchangeGrantSendOnBehalfToSMTP)
            {
                #Implement some protections for larger operations to ensure we do not exhaust our powershell budget.

                if ($member.externalDirectoryObjectID -ne $NULL)
                {
                    out-LogFile -string ("Processing member = "+$member.externalDirectoryObjectID)

                    $functionDirectoryObjectID=$member.externalDirectoryObjectID.Split("_")

                    out-LogFile -string ("Processing updated member = "+$functionDirectoryObjectID[1])

                    $functionRecipients+=$functionDirectoryObjectID[1]
                }
                elseif ($member.primarySMTPAddressOrUPN -ne $NULL)
                {
                    out-LogFile -string ("Processing member = "+$member.PrimarySMTPAddressOrUPN)

                    $functionRecipients+=$member.primarySMTPAddressOrUPN    
                }
                else 
                {
                    out-logfile -string "Invalid function object for recipient." -isError:$TRUE
                } 
            }

            #Becuase groups could have been mirgated and retained - this ensures that all SMTP addresses and GUIDs in the array are unique.

            $functionRecipients = $functionRecipients | select-object -Unique

            out-logfile -string "Updating grant send on behalf to SMTP with unique values."
            out-logfile -string $functionRecipients

            set-o365DistributionGroup -identity $originalDLConfiguration.mailNickName -GrantSendOnBehalfTo $functionRecipients -errorAction STOP -BypassSecurityGroupManagerCheck
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