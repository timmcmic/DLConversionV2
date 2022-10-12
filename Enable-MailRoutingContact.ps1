<#
    .SYNOPSIS

    This function mail enables mail routing contact for hybrid mail flow.
    
    .DESCRIPTION

    This function mail enables mail routing contact for hybrid mail flow.

    .PARAMETER GlobalCatalogServer

    The global catalog to make the query against.

    .PARAMETER routingContactConfig

    The original DN of the object.

    .OUTPUTS

    None

    .EXAMPLE

    enable-mailRoutingContact -globalCatalogServer GC -routingContactConfig contactConfiguration.

    #>
    Function Enable-MailRoutingContact
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$globalCatalogServer,
            [Parameter(Mandatory = $true)]
            $routingContactConfig,
            [Parameter(Mandatory = $true)]
            $routingXMLFile
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        $isTestError="No"

        #Declare function variables.

        $functionGroup=$NULL
        $functionOutputGroup=$NULL
        $functionRemoteRoutingAddress=$NULL

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN enable-mailRoutingContact"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        #Updated the mail contact so that it has full mail attributes.

        try{
            out-logfile -string "Updating the mail contact..."

            update-recipient -identity $routingContactConfig.distinguishsedName -domainController $globalCatalogServer -errorAction STOP
        }
        catch{
            out-logfile -string $_
            $isTestError="Yes"
            return $isTestError
        }

        #Obtain the mail contact configuration into a temporary variable now that it's a full recipient.

        try{
            out-logfile -string "Gathering the mail contact configuration..."

            $functionGroup=get-mailContact -identity $routingContactConfig.distinguishedName -domainController $globalCatalogServer -errorAction STOP
        }
        catch{
            out-logfile -string $_
            $isTestError="Yes"
            return $isTestError
        }

        #Write the updated recipient out.

        try
        {
            out-xmlFile -itemToExport $functionGroup -itemNameTOExport (($routingXMLFile)+"-UpdateRecipient")
        }
        catch {
            out-logfile -string "Unable to output to XML file."
            out-logfile -string $_ -isError:$TRUE
        }

        #The mail contact may need upgrade to the "latest version."

        try{
            out-logfile -string "Forcing upgrade to contact - necessary in order to provision."

            set-mailcontact -identity $functionGroup.distinguishedName -domainController $globalCatalogServer -ForceUpgrade
        }
        catch{
            out-logfile -string $_
            $isTestError="Yes"
            return $isTestError
        }

        #Obtain the mail contact configuration into a temporary variable now that it's a full recipient.

        try{
            out-logfile -string "Gathering the mail contact configuration..."

            $functionOutputGroup=get-mailContact -identity $routingContactConfig.distinguishedName -domainController $globalCatalogServer -errorAction STOP
        }
        catch{
            out-logfile -string $_
            $isTestError="Yes"
            return $isTestError
        }

        #Write the updated recipient out.

        try
        {
            out-xmlFile -itemToExport $functionOutputGroup -itemNameTOExport (($routingXMLFile)+"-UpgradedRecipient")
        }
        catch {
            out-logfile -string "Unable to output to XML file."
            out-logfile -string $_ -isError:$TRUE
        }

        #The mail contact may need upgrade to the "latest version."

        try{
            out-logfile -string "Setting email address policy enabled to $FALSE - stop further automatic email addressing."

            set-mailcontact -identity $functionGroup.distinguishedName -EmailAddressPolicyEnabled:$FALSE -domainController $globalCatalogServer -forceUpgrade -confirm:$FALSE
        }
        catch{
            out-logfile -string $_
            $isTestError="Yes"
            return $isTestError
        }

        #Obtain the mail contact configuration into a temporary variable now that it's a full recipient.

        try{
            out-logfile -string "Gathering the mail contact configuration..."

            $functionOutputGroup=get-mailContact -identity $routingContactConfig.distinguishedName -domainController $globalCatalogServer -errorAction STOP
        }
        catch{
            out-logfile -string $_
            $isTestError="Yes"
            return $isTestError
        }

        #Write the updated recipient out.

        try
        {
            out-xmlFile -itemToExport $functionOutputGroup -itemNameTOExport (($routingXMLFile)+"-DisableEmailPolicy")
        }
        catch {
            out-logfile -string "Unable to output to XML file."
            out-logfile -string $_ -isError:$TRUE
        }

        try{
            out-logfile -string "Removing the remote routing address..."

            set-mailContact -identity $routingContactConfig.distinguishedName -primarySMTPAddress $routingContactConfig.mail -domainController $globalCatalogServer -forceUpgrade -confirm:$FALSE -errorAction STOP
        }
        catch{
            out-logfile -string $_ -isError:$TRUE
        }

        #Obtain the mail contact configuration into a temporary variable now that it's a full recipient.

        try{
            out-logfile -string "Gathering the mail contact configuration..."

            $functionOutputGroup=get-mailContact -identity $routingContactConfig.distinguishedName -domainController $globalCatalogServer -errorAction STOP
        }
        catch{
            out-logfile -string $_
            $isTestError="Yes"
            return $isTestError
        }

        #Write the updated recipient out.

        try
        {
            out-xmlFile -itemToExport $functionOutputGroup -itemNameTOExport (($routingXMLFile)+"-MailUpdate")
        }
        catch {
            out-logfile -string "Unable to output to XML file."
            out-logfile -string $_ -isError:$TRUE
        }


        #Removee the target address from the list of proxy addresses so it does not collide with the migrated group.

        try{
            out-logfile -string "Removing the remote routing address..."

            set-mailContact -identity $routingContactConfig.distinguishedName -emailaddresses @{remove=$routingContactConfig.targetAddress} -domainController $globalCatalogServer -forceUpgrade -confirm:$FALSE -errorAction STOP
        }
        catch{
            out-logfile -string $_
            $isTestError="Yes"
            return $isTestError
        }

        #Obtain the mail contact configuration into a temporary variable now that it's a full recipient.

        try{
            out-logfile -string "Gathering the mail contact configuration..."

            $functionOutputGroup=get-mailContact -identity $routingContactConfig.distinguishedName -domainController $globalCatalogServer -errorAction STOP
        }
        catch{
            out-logfile -string $_
            $isTestError="Yes"
            return $isTestError
        }

        #Write the updated recipient out.

        try
        {
            out-xmlFile -itemToExport $functionOutputGroup -itemNameTOExport (($routingXMLFile)+"-RemoteTargetAddress")
        }
        catch {
            out-logfile -string "Unable to output to XML file."
            out-logfile -string $_ -isError:$TRUE
        }


        Out-LogFile -string "END enable-mailRoutingContact"
        Out-LogFile -string "********************************************************************************"
    }