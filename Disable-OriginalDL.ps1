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
            [Parameter(Mandatory = $true,ParamterSetName = "Exchange")]
            [string]$DN,
            [Parameter(Mandatory = $true,ParameterSetName = "AD")]
            [Parameter(Mandatory = $true,ParamterSetName = "Exchange")]
            [string]$globalCatalogServer,
            [Parameter(Mandatory = $false,ParameterSetName = "AD")]
            [array]$parameterSet,
            [Paramter(Mandatory = $false,ParamterSetName="Exchange")]
            [boolean]$useOnPremsiesExchange
        )

        #Declare function variables.

        $functionDLConfiguration=$NULL #Holds the return information for the group query.

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

            $functionDLConfiguration=Get-ADGroup -filter {mail -eq $groupSMTPAddress} -properties $parameterSet -server $globalCatalogServer -errorAction STOP

            #If the ad provider command cannot find the group - the variable is NULL.  An error is not thrown.

            if ($functionDLConfiguration -eq $NULL)
            {
                throw "The group cannot be found in Active Directory by email address."
            }

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