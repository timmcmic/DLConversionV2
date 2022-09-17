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
    Function Get-AzureADDLConfiguration
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $office365DLConfiguration
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN GET-AZUREADDLCONFIGURATION"
        Out-LogFile -string "********************************************************************************"

        #Get the recipient using the exchange online powershell session.
        
        try{
            $functionDLConfiguration = get-AzureADGroup -objectID $office365DLConfiguration.externalDirectoryObjectID -errorAction STOP
        }
        try {
            out-logfile -string $_
            out-logfile -string "Unable to obtain group configuration from Azure Active Directory"
        }
        catch {
            {1:<#Do this if a terminating exception happens#>}
        }

        Out-LogFile -string "END GET-AzureADDlConfiguration"
        Out-LogFile -string "********************************************************************************"
        
        #This function is designed to open local and remote powershell sessions.
        #If the session requires import - for example exchange - return the session for later work.
        #If not no return is required.
        
        return $functionDLConfiguration
    }