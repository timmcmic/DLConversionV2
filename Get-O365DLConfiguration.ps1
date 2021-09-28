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

    get-o365dlconfiguration -groupSMTPAddress Address

    #>
    Function Get-o365DLConfiguration
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$groupSMTPAddress
        )

        #Declare function variables.

        $functionDLConfiguration=$NULL #Holds the return information for the group query.

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN GET-O365DLCONFIGURATION"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        Out-LogFile -string ("GroupSMTPAddress = "+$groupSMTPAddress)

        #Get the recipient using the exchange online powershell session.
        
        try 
        {
            Out-LogFile -string "Using Exchange Online to capture the distribution group."

            $functionDLConfiguration=get-O365DistributionGroup -identity $groupSMTPAddress -errorAction STOP
            
            Out-LogFile -string "Original DL configuration found and recorded."
        }
        catch 
        {
            Out-LogFile -string $_ 
        }

        Out-LogFile -string "END GET-O365DLCONFIGURATION"
        Out-LogFile -string "********************************************************************************"
        
        #This function is designed to open local and remote powershell sessions.
        #If the session requires import - for example exchange - return the session for later work.
        #If not no return is required.
        
        return $functionDLConfiguration
    }