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
            [boolean]$isUnifiedGroup=$false
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Declare function variables.

        $functionDLConfiguration=$NULL #Holds the return information for the group query.
        $functionMailSecurity="MailUniversalSecurityGroup"
        $functionMailDistribution="MailUniversalDistributionGroup"

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN GET-O365DLCONFIGURATION"
        Out-LogFile -string "********************************************************************************"

        #Get the recipient using the exchange online powershell session.

        if ($isUnifiedGroup -eq $false)
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