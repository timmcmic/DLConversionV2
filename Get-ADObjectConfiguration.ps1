<#
    .SYNOPSIS

    This function gets the original DL configuration for the on premises group using AD providers.

    .DESCRIPTION

    This function gets the original DL configuration for the on premises group using AD providers.

    .PARAMETER parameterSet

    These are the parameters that the GET will gather from AD for the DL.  This should be the full map.

    .PARAMETER GroupSMTPAddress

    The mail attribute of the group to search.

    .PARAMETER GlobalCatalog

    The global catalog to utilize for the query.

    .OUTPUTS

    Returns the DL configuration from the LDAP / AD call to the calling function.

    .EXAMPLE

    Get-ADObjectConfiguration -powershellsessionname NAME -groupSMTPAddress Address

    #>
    Function Get-ADObjectConfiguration
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true,ParameterSetName = "BySMTPAddress")]
            [string]$groupSMTPAddress="None",
            [Parameter(Mandatory = $true,ParameterSetName = "ByDN")]
            [string]$dn="None",
            [Parameter(Mandatory = $true,ParameterSetName = "BySMTPAddress")]
            [Parameter(Mandatory = $true,ParameterSetName = "ByDN")]
            [string]$globalCatalogServer,
            [Parameter(Mandatory = $true,ParameterSetName = "BySMTPAddress")]
            [Parameter(Mandatory = $true,ParameterSetName = "ByDN")]
            [array]$parameterSet,
            [Parameter(Mandatory = $TRUE,ParameterSetName = "BySMTPAddress")]
            [Parameter(Mandatory = $true,ParameterSetName = "ByDN")]
            $adCredential
        )

        #Declare function variables.

        $functionDLConfiguration=$NULL #Holds the return information for the group query.

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN Get-ADObjectConfiguration"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        Out-LogFile -string ("GroupSMTPAddress = "+$groupSMTPAddress)
        Out-LogFile -string ("GlobalCatalogServer = "+$globalCatalogServer)
        OUt-LogFile -string ("Parameter Set:")
        
        foreach ($parameterIncluded in $parameterSet)
        {
            Out-Logfile -string $parameterIncluded
        }

        out-logfile -string ("Credential user name = "+$adCredential.UserName)

        #Get the group using LDAP / AD providers.
        
        try 
        {
            Out-LogFile -string "Using AD / LDAP provider to get original DL configuration"

            if ($groupSMTPAddress -ne "None")
            {
                out-logfile -string ("Searching by mail address "+$groupSMTPAddress)

                $functionDLConfiguration=Get-ADObject -filter {mail -eq $groupSMTPAddress} -properties $parameterSet -server $globalCatalogServer -credential $adCredential -errorAction STOP
            }
            elseif ($DN -ne "None")
            {
                out-logfile -string ("Searching by distinguished name "+$dn)

                $functionDLConfiguration=get-adObject -identity $DN -properties $parameterSet -server $globalCatalogServer -credential $adCredential
            }
            else 
            {
                out-logfile -string "No value query found for local object." -isError:$TRUE    
            }
            

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

        Out-LogFile -string "END Get-ADObjectConfiguration"
        Out-LogFile -string "********************************************************************************"
        
        #This function is designed to open local and remote powershell sessions.
        #If the session requires import - for example exchange - return the session for later work.
        #If not no return is required.
        
        return $functionDLConfiguration
    }