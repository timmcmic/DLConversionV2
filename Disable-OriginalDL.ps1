<#
    .SYNOPSIS

    This function disabled the on premies distribution list - removing it from azure ad and exchange online.

    .DESCRIPTION

    This function disabled the on premies distribution list - removing it from azure ad and exchange online.

    .PARAMETER parameterSet

    These are the parameters that will be manually cleared from the object in AD mode.

    .PARAMETER DN

    The DN of the group to remove.

    .PARAMETER GlobalCatalog

    The global catalog server the operation should be performed on.

    .PARAMETER UseExchange

    If set to true disablement will occur using the exchange on premises powershell commands.

    .OUTPUTS

    No return.

    .EXAMPLE

    get-originalDLConfiguration -powershellsessionname NAME -groupSMTPAddress Address

    #>
    Function Disable-OriginalDL
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true,ParameterSetName = "AD")]
            [Parameter(Mandatory = $true,ParameterSetName = "Exchange")]
            [string]$DN,
            [Parameter(Mandatory = $true,ParameterSetName = "AD")]
            [Parameter(Mandatory = $true,ParameterSetName = "Exchange")]
            [string]$globalCatalogServer,
            [Parameter(Mandatory = $false,ParameterSetName = "AD")]
            [array]$parameterSet="None",
            [Parameter(Mandatory = $false,ParameterSetName="Exchange")]
            [boolean]$useOnPremsiesExchange=$FALSE
        )

        #Declare function variables.

        $functionDLConfiguration=$NULL #Holds the return information for the group query.

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN Disable-OriginalDLConfiguration"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        Out-LogFile -string ("DN = "+$DN)
        Out-LogFile -string ("GlobalCatalogServer = "+$globalCatalogServer)
        out-logfile -string ("Use Exchange On Premises ="+$useOnPremsiesExchange)

        OUt-LogFile -string ("Parameter Set:")
        
        foreach ($parameterIncluded in $parameterSet)
        {
            Out-Logfile -string $parameterIncluded
        }

        #Get the group using LDAP / AD providers.
        
        try 
        {
            Out-LogFile -string "Determine if exchange should be utilized to clear the DL."

            if ($useOnPremsiesExchange -eq $FALSE)
            {
                Out-LogFile -string "Using AD providers to clear the given attributes"

                set-adgroup -identity $DN -server $globalCatalogServer -clear $parameterSet
            }

            elseif ($useOnPremsiesExchange -eq $TRUE)
            {
                out-logfile -string "Using Exchange providers to clear the distribution list."

                disable-distributionGroup -identity $DN -confirm:$false -verbose
            }
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