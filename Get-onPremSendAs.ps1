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
            $originalDLConfiguration
        )

        #Declare function variables.

        [array]$functionSendAsRights=@()
        $functionRecipients=$NULL
        $functionQueryName=("*"+$originalDLConfiguration.sAMAccountName+"*")
        [array]$functionSendAsIdentities=@()

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN Get-onPremSendAs"
        Out-LogFile -string "********************************************************************************"

        out-logfile -string ("DL query name = "+$functionQueryName)

        #Start function processing.

        try {
            out-logfile -string "Gathering all on premises recipients."

            $functionRecipients = invoke-command {get-distributionGroup SendAsOnPre* -resultsize unlimited}
        }
        catch {
            out-logfile -string "Error attempting to invoke command to gather all recipients."
            out-logfile -string $_ -isError:$TRUE
        }

        try {
            out-logfile -string "Test for send as rights."
            foreach ($recipient in $functionRecipients)
            {
                $functionSendAsRights+= invoke-command {$blockName=$args[1];Get-ADPermission -identity $args[0] | Where-Object {($_.ExtendedRights -like "*send-as*") -and -not ($_.User -like "nt authority\self") -and ($_.isInherited -eq $false) -and ($_.user -like $blockName)}}-ArgumentList $recipient.identity,$functionQueryName
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

            $stringTest = $sendAsRight.user.split("\")

            #Test the second half of the string for a direct eq to samAccountName.

            if ($stringTest[1] -eq $originalDLConfiguration.samAccountName)
            {
                out-logfile -string ("Send as permission matching group found - recording."+$sendAsRight.identity)
                $functionSendAsIdentities+=$sendAsRight.identity
            }
        }

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "END Get-onPremSendAs"
        Out-LogFile -string "********************************************************************************" 

        return $functionSendAsIdentities
    }