<#
    .SYNOPSIS

    This function obtains the DL membership of the Office 365 distribution group.

    .DESCRIPTION

    This function obtains the DL membership of the Office 365 distribution group.

    .PARAMETER GroupSMTPAddress

    The mail attribute of the group to search.

    .OUTPUTS

    Returns the membership array of the DL in Office 365.

    .EXAMPLE

    get-o365dlMembership -groupSMTPAddress Address

    #>
    Function Get-o365DLMembership
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$groupSMTPAddress,
            [Parameter(Mandatory = $false)]
            [boolean]$isUnifiedGroup=$false,
            [Parameter(Mandatory = $false)]
            [boolean]$getUnifiedMembers=$false,
            [Parameter(Mandatory = $false)]
            [boolean]$getUnifiedOwners=$false,
            [Parameter(Mandatory = $false)]
            [boolean]$getUnifiedSubscribers=$false,
            [Parameter(Mandatory = $false)]
            [boolean]$isHealthReport=$false
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Declare function variables.

        $functionDLMembership=$NULL #Holds the return information for the group query.
        $functionMembersLinkType = "Members"
        $functionOwnersLinkType = "Owners"
        $functionSubscribersLinkType = "Subscribers"

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN GET-O365DLMEMBERSHIP"
        Out-LogFile -string "********************************************************************************"

        #Get the recipient using the exchange online powershell session.

        if ($isUnifiedGroup -eq $FALSE)
        {
            if ($isHealthReport -eq $FALSE)
            {
                Out-LogFile -string "Using Exchange Online to obtain the group membership."

                $functionDLMembership=@(get-O365DistributionGroupMember -identity $groupSMTPAddress -resultsize unlimited -errorAction STOP)
                
                Out-LogFile -string "Distribution group membership recorded."
            }
            else 
            {
                Out-LogFile -string "Using Exchange Online to obtain the group membership."

                $functionDLMembership=@(get-O365DistributionGroupMember -identity $groupSMTPAddress -resultsize unlimited -errorAction STOP | select-object Identity,Alias,ExternalDirectoryObjectId,EmailAddresses,ExternalEmailAddress,DisplayName,RecipientType,RecipientTypeDetails,ExchangeGuid)
                
                Out-LogFile -string "Distribution group membership recorded."
            }
        }
        else 
        {
            out-logfile -string "Using Exchange Online to obtain unified group member properties."

            if ($getUnifiedMembers -eq $TRUE)
            {
                Out-LogFile -string "Using Exchange Online to obtain the unified group membership membership."

                $functionDLMembership=@(get-O365UnifiedGroupLinks -identity $groupSMTPAddress -linkType $functionMembersLinkType -resultsize unlimited -errorAction STOP)
                
                Out-LogFile -string "Distribution group membership recorded."
            }
            else
            {
                out-logfile -string "Call is not for unified group members."
            }

            if ($getUnifiedOwners -eq $TRUE)
            {
                Out-LogFile -string "Using Exchange Online to obtain the unified group owners membership."

                $functionDLMembership=@(get-O365UnifiedGroupLinks -identity $groupSMTPAddress -linkType $functionOwnersLinkType -resultsize unlimited -errorAction STOP)
                
                Out-LogFile -string "Distribution group owners recorded."
            }
            else
            {
                out-logfile -string "Call is not for unified group owners."
            }

            if ($getUnifiedSubscribers -eq $TRUE)
            {
                Out-LogFile -string "Using Exchange Online to obtain the unified group subscribers membership."

                $functionDLMembership=@(get-O365UnifiedGroupLinks -identity $groupSMTPAddress -linkType $functionSubscribersLinkType -resultsize unlimited -errorAction STOP)
                
                Out-LogFile -string "Distribution group subscribers recorded."
            }
            else
            {
                out-logfile -string "Call is not for unified group subscribers."
            }
        }
        
        Out-LogFile -string "END GET-O365DLMEMBERSHIP"
        Out-LogFile -string "********************************************************************************"
        
        #Return the membership to the caller.
        
        return $functionDLMembership
    }