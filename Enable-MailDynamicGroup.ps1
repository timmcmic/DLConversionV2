<#
    .SYNOPSIS

    This function enables the dynamic group for hybird mail flow.
    
    .DESCRIPTION

    This function enables the dynamic group for hybird mail flow.

    .PARAMETER GlobalCatalogServer

    The global catalog to make the query against.

    .PARAMETER routingContactConfig

    The original DN of the object.

    .PARAMETER originalDLConfiguration

    The original DN of the object.

    .OUTPUTS

    None

    .EXAMPLE

    enable-mailDynamicGroup -globalCatalogServer GC -routingContactConfig contactConfiguration -originalDLConfiguration DLConfiguration

    #>
    Function Enable-MailDyamicGroup
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$globalCatalogServer,
            [Parameter(Mandatory = $true)]
            $routingContactConfig,
            [Parameter(Mandatory = $true)]
            $originalDLConfiguration
        )

        #Declare function variables.

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN Enable-MailDyamicGroup"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        #Create the dynamic distribution group.

        try{
            new-dynamicDistributionGroup -name $originalDLConfiguration.name -alias $originalDLConfiguration.mailNickName -primarySMTPAddress $originalDLConfiguration.mail -organizationalUnit $originalDLConfiguration.distinguishedName.substring($originalDLConfiguration.distinguishedname.indexof("OU")) -domainController $globalCatalogServer -includedRecipients AllRecipients -conditionalCustomAttribute1 $routingContactConfig.extensionAttribute1 -conditionalCustomAttribute2 $routingContactConfig.extensionAttribute2 -displayName $originalDLConfiguration.DisplayName
        }
        catch{
            out-logfile -string $_ -isError:$TRUE
        }

        Out-LogFile -string "END Enable-MailDyamicGroup"
        Out-LogFile -string "********************************************************************************"
    }