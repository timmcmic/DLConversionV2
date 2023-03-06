<#
    .SYNOPSIS

    This function gathers the group information from Azure Active Directory.

    .DESCRIPTION

    This function gathers the group information from Azure Active Directory.

    .PARAMETER office365DLConfiguration

    The Office 365 DL configuration for the group.

    .OUTPUTS

    Returns the information from the associated group from Azure AD>

    .EXAMPLE

    get-AzureADDLConfiguration -office365DLConfiguration $configuration

    #>
    Function get-msGraphDLConfiguration
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
            $functionDLConfiguration = get-mgGroup -groupID $office365DLConfiguration.externalDirectoryObjectID -errorAction STOP
        }
        catch {
            out-logfile -string $_
            out-logfile -string "Unable to obtain group configuration from Azure Active Directory"
        }

        Out-LogFile -string "END GET-AzureADDlConfiguration"
        Out-LogFile -string "********************************************************************************"
        
        #This function is designed to open local and remote powershell sessions.
        #If the session requires import - for example exchange - return the session for later work.
        #If not no return is required.
        
        return $functionDLConfiguration
    }