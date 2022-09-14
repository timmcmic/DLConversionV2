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
            [Parameter(Mandatory = $true)]
            $originalDLConfiguration,
            [Parameter(Mandatory = $true)]
            [string]$globalCatalogServer,
            [Parameter(Mandatory = $false)]
            [array]$parameterSet="None",
            [Parameter(Mandatory = $false)]
            [boolean]$useOnPremisesExchange=$FALSE,
            [Parameter(Mandatory = $true)]
            $adCredential
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Declare function variables.

        $functionDLConfiguration=$NULL #Holds the return information for the group query.

        $functionVariables = @{
            functionCustomAttribute1 =@{ "Value" = "MigratedByScript" ; "Description" = "Custom attribute 1 is migrated by script on mail contacts for migrated DLs"}
            functionCustomAttribute2 = @{ "Value" = $originalDLConfiguration.mail ; "Description" = "Custom attribute 2 is the migrated DL primary SMTP Address"}
        }
        
        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN Disable-OriginalDLConfiguration"
        Out-LogFile -string "********************************************************************************"

        write-HasTable -hasTable $functionVariables

        #Get the group using LDAP / AD providers.
        
        try 
        {
            set-adgroup -identity $originalDLConfiguration.distinguishedName -server $globalCatalogServer -clear $parameterSet -credential $adCredential

        }
        catch 
        {
            Out-LogFile -string $_ -isError:$TRUE
        }

        #Now that the DL is disabled - use this oppurtunity to write the custom attributes to show it's been migrated.

        out-logfile -string "The group has been migrated and is retained - set custom attributes with original information for other migration dependencies."
        
        try {
            set-adgroup -identity $originalDLConfiguration.distinguishedName -add @{extensionAttribute1=$functionVariables.functionCustomAttribute1.value;extensionAttribute2=$functionVariables.functionCustomAttribute2.value} -server $globalCatalogServer -credential $adCredential
        }
        catch {
            out-logfile -string $_ -isError:$TRUE
        }

        Out-LogFile -string "END Disable-OriginalDLConfiguration"
        Out-LogFile -string "********************************************************************************"
    }