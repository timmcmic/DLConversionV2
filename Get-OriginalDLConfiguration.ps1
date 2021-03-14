<#
    .SYNOPSIS

    This function gets the original DL configuration for the on premises group using AD providers.

    .DESCRIPTION

    This function gets the original DL configuration for the on premises group using AD providers.

    .PARAMETER PowershellSessionName

    The name associated with the powershell session to the ad server to invoke the get command.

    .PARAMETER GroupSMTPAddress

    The mail attribute of the group to search.

    .OUTPUTS

    Returns the DL configuration from the LDAP / AD call to the calling function.

    .EXAMPLE

    get-originalDLConfiguration -powershellsessionname NAME -groupSMTPAddress Address

    #>
    Function Get-OriginalDLConfiguration
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$groupSMTPAddress,
            [Parameter(Mandatory = $true)]
            [string]$globalCatalogServer,
            [Parameter(Mandatory = $true)]
            [array]$parameterSet
        )

        #Declare function variables.

        $functionDLConfiguration=$NULL #Holds the return information for the group query.
        $globalCatalogServer=$globalCatalogServer+":3268"

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN GET-ORIGINALDLCONFIGURATION"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        Out-LogFile -string ("GroupSMTPAddress = "+$groupSMTPAddress)
        Out-LogFile -string ("GlobalCatalogServer = "+$globalCatalogServer)
        OUt-LogFile -string ("Parameter Set:")
        
        foreach ($parameterIncluded in $parameterSet)
        {
            Out-Logfile -string $parameterIncluded
        }

        #Get the group using LDAP / AD providers.
        
        try 
        {
            Out-LogFile -string "Using AD / LDAP provider to get original DL configuration"

            $functionDLConfiguration=Get-ADGroup -filter "mail -eq '$groupSMTPAddress'" -properties $parameterSet -server $globalCatalogServer -errorAction STOP

            Out-LogFile -string "Original DL configuration found and recorded."
        }
        catch 
        {
            Out-LogFile -string $_ -isError:$TRUE
        }

        Out-LogFile -string "END GET-ORIGINALDLCONFIGURATION"
        Out-LogFile -string "********************************************************************************"
        
        #This function is designed to open local and remote powershell sessions.
        #If the session requires import - for example exchange - return the session for later work.
        #If not no return is required.
        
        return $functionDLConfiguration
    }