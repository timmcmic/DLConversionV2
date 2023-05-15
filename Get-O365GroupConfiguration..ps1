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
    Function Get-o365GroupConfiguration
    {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$groupSMTPAddress,
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
        Out-LogFile -string "BEGIN GET-O365GroupCONFIGURATION"
        Out-LogFile -string "********************************************************************************"

        #Get the recipient using the exchange online powershell session.

        try
        {
            out-logfile -string "Obtaining Office 365 DL Configuration for evaluation."

            $functionRecipient = get-o365Group -identity $groupSMTPAddress -errorAction STOP

            out-logfile -string "Successfully obtained the Office 365 DL Configuration."
        }
        catch
        {
            out-logfile -string "Unable to obtain the Office 365 DL Configuration."
            out-logfile -string $_ -isError:$TRUE
        }

        out-logfile -string $functionRecipient
       
        Out-LogFile -string "END GET-O365GroupCONFIGURATION"
        Out-LogFile -string "********************************************************************************"
        
        #This function is designed to open local and remote powershell sessions.
        #If the session requires import - for example exchange - return the session for later work.
        #If not no return is required.
        
        return $functionRecipient
    }