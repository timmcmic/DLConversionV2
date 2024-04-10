<#
    .SYNOPSIS

    This function uses the exchange online powershell session to gather the office 365 distribution list configuration.

    .DESCRIPTION

    This function uses the exchange online powershell session to gather the office 365 distribution list configuration.

    .PARAMETER GroupSMTPAddress

    The mail attribute of the group to search.

    .OUTPUTS

    Returns the PS object associated with the recipient from get-o365recipient

    .EXAMPLE

    get-o365dlconfiguration -groupSMTPAddress Address -groupTypeOverride 

    #>
    Function Get-o365DLConfiguration
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$groupSMTPAddress,
            [Parameter(Mandatory = $false)]
            [string]$groupTypeOverride="",
            [Parameter(Mandatory = $false)]
            [boolean]$isUnifiedGroup=$false,
            [Parameter(Mandatory = $false)]
            [boolean]$isFirstPass=$false
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Declare function variables.

        $functionDLConfiguration=$NULL #Holds the return information for the group query.
        $functionMailSecurity="MailUniversalSecurityGroup"
        $functionMailDistribution="MailUniversalDistributionGroup"
        $functionGroupType = "GroupMailbox"

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN GET-O365DLCONFIGURATION"
        Out-LogFile -string "********************************************************************************"

        #Get the recipient using the exchange online powershell session.

        try
        {
            out-logfile -string "Obtaining Office 365 DL Configuration for evaluation."

            $functionRecipient = get-o365Recipient -identity $groupSMTPAddress -errorAction STOP

            out-logfile -string "Successfully obtained the Office 365 DL Configuration."
        }
        catch
        {
            out-logfile -string "Unable to obtain the Office 365 DL Configuration."
            out-logfile -string $_ -isError:$TRUE
        }

        $functionRecipient = get-o365Recipient -identity $groupSMTPAddress

        out-logfile -string $functionRecipient

        out-logfile -string "Testing if this is the first pass for DL validation."

        if ($isFirstPass -eq $TRUE)
        {
            out-logfile -string "This is the first pass."

            if ($functionRecipient.RecipientTypeDetails -eq $functionGroupType)
            {
                out-logfile -string "Office 365 Recipient found is already an Office 365 Unified Group - exit." -isError:$TRUE
            }
            elseif (($functionRecipient.RecipientType -ne $functionMailSecurity) -and ($functionRecipient.RecipientType -ne $functionMailDistribution)) 
            {
                out-logfile -string "Office 365 Recipient found was not a mail universal distribution or mail universal security group - exit." -isError:$TRUE
            }
            else 
            {
                out-logfile -string "Proceed with further group evaluation - group object located in Office 365."
            }
    
        }
        else 
        {
            out-logfile -string "This is not the first pass."
        }

        if (($isUnifiedGroup -eq $false) -and ($functionRecipient.recipientTypeDetails -ne $functionGroupType))
        {
            out-logfile -string "Group is not unified use standard DL commands."

            try 
            {
                if ($groupTypeOverride -eq "")
                {
                    Out-LogFile -string "Using Exchange Online to capture the distribution group."

                    $functionDLConfiguration=get-O365DistributionGroup -identity $groupSMTPAddress -errorAction STOP
                
                    Out-LogFile -string "Original DL configuration found and recorded."
                }
                elseif ($groupTypeOverride -eq "Security")
                {
                    Out-logfile -string "Using Exchange Online to capture distribution group with filter security"

                    $functionDLConfiguration=get-o365DistributionGroup -identity $groupSMTPAddress -RecipientTypeDetails $functionMailSecurity -errorAction STOP

                    out-logfile -string "Original DL configuration found and recorded by filter security."
                }
                elseif ($groupTypeOverride -eq "Distribution")
                {
                    out-logfile -string "Using Exchange Online to capture distribution group with filter distribution."

                    $functionDLConfiguration=get-o365DistributionGroup -identity $groupSMTPAddress -RecipientTypeDetails $functionMailDistribution

                    out-logfile -string "Original DL configuration found and recorded by filter distribution."
                }
                
            }
            catch 
            {
                Out-LogFile -string $_ -isError:$TRUE
            }
        }
        else
        {
            out-logfile -string "Group is unified use unified group commands."

            try
            {
                $functionDLConfiguration = get-o365UnifiedGroup -identity $groupSMTPAddress -includeAllProperties -errorAction STOP
            }
            catch
            {
                out-logfile -string $_ -isError:$TRUE
            }
        }
        
        
        Out-LogFile -string "END GET-O365DLCONFIGURATION"
        Out-LogFile -string "********************************************************************************"
        
        #This function is designed to open local and remote powershell sessions.
        #If the session requires import - for example exchange - return the session for later work.
        #If not no return is required.
        
        return $functionDLConfiguration
    }