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

    Get-ADObjectConfiguration -powershellsessionname NAME -groupSMTPAddress Address

    #>
    Function Disable-OriginalDL
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true,ParameterSetName = "AD")]
            [Parameter(Mandatory = $true,ParameterSetName = "Exchange")]
            $originalDLConfiguration,
            [Parameter(Mandatory = $true,ParameterSetName = "AD")]
            [Parameter(Mandatory = $true,ParameterSetName = "Exchange")]
            [string]$globalCatalogServer,
            [Parameter(Mandatory = $false,ParameterSetName = "AD")]
            [array]$parameterSet="None",
            [Parameter(Mandatory = $false,ParameterSetName="Exchange")]
            [boolean]$useOnPremsiesExchange=$FALSE,
            [Parameter(Mandatory = $true)]
            $adCredential
        )

        #Declare function variables.

        $functionDLConfiguration=$NULL #Holds the return information for the group query.
        $functionCustomAttribute1="MigratedByScript"
        $functionCustomAttribute2=$originalDLConfiguration.mail



        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN Disable-OriginalDLConfiguration"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        Out-LogFile -string ("OriginalDLConfiguration = "+$originalDLConfiguration)
        Out-LogFile -string ("GlobalCatalogServer = "+$globalCatalogServer)
        out-logfile -string ("Use Exchange On Premises ="+$useOnPremsiesExchange)
        out-logfile -string ("DN of object to modify / disable "+$originalDLConfiguration.distinguishedName)

        OUt-LogFile -string ("Parameter Set:")
        
        foreach ($parameterIncluded in $parameterSet)
        {
            Out-Logfile -string $parameterIncluded
        }

        out-logfile -string ("Disalbed DL Custom Attribute 1 = "+$functionCustomAttribute1)
        out-logfile -string ("Disabled DL Custom Attribute 2 = "+$functionCustomAttribute2)

        #Get the group using LDAP / AD providers.
        
        try 
        {
            Out-LogFile -string "Determine if exchange should be utilized to clear the DL."

            if ($useOnPremsiesExchange -eq $FALSE)
            {
                Out-LogFile -string "Using AD providers to clear the given attributes"

                set-adgroup -identity $originalDLConfiguration.distinguishedName -server $globalCatalogServer -clear $parameterSet -credential $adCredential
            }

            elseif ($useOnPremsiesExchange -eq $TRUE)
            {
                out-logfile -string "Using Exchange providers to clear the distribution list."

                disable-distributionGroup -identity $originalDLConfiguration.distinguishedName -domainController $globalCatalogServer -confirm:$false -verbose
            }
        }
        catch 
        {
            Out-LogFile -string $_ -isError:$TRUE
        }

        #Now that the DL is disabled - use this oppurtunity to write the custom attributes to show it's been migrated.

        out-logfile -string "The group has been migrated and is retained - set custom attributes with original information for other migration dependencies."
        
        try {
            set-adgroup -identity $originalDLConfiguration.distinguishedName -add @{extensionAttribute1=$functionCustomAttribute1;extensionAttribute2=$functionCustomAttribute2}
        }
        catch {
            out-logfile -string $_ -isError:$TRUE
        }

        Out-LogFile -string "END Disable-OriginalDLConfiguration"
        Out-LogFile -string "********************************************************************************"
    }