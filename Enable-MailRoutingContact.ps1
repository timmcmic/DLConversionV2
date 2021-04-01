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
            $routingContactConfig
        )

        #Declare function variables.

        $functionGroup=$NULL
        $functionRemoteRoutingAddress=$NULL

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN enable-mailRoutingContact"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        #Updated the mail contact so that it has full mail attributes.

        try{
            out-logfile -string "Updating the mail contact..."

            update-recipient -identity $routingContactConfig.mailNickName -domainController $globalCatalogServer -errorAction STOP
        }
        catch{
            out-logfile -string $_ -isError:$TRUE
        }

        #Obtain the mail contact configuration into a temporary variable now that it's a full recipient.

        try{
            out-logfile -string "Gathering the mail contact configuration..."

            $functionGroup=get-mailContact -identity $routingContactConfig.mailNickName -domainController $globalCatalogServer -errorAction STOP
        }
        catch{
            out-logfile -string $_ -isError:$TRUE
        }

        #The mail contact may need upgrade to the "latest version."

        try{
            out-logfile -string "Forcing upgrade to contact - necessary in order to provision."

            set-mailcontact -identity $functionGroup.alias -ForceUpgrade
        }
        catch{
            out-logfile -string $_ -isError:$TRUE
        }

        #The mail contact may need upgrade to the "latest version."

        try{
            out-logfile -string "Setting email address policy enabled to $FALSE - stop further automatic email addressing."

            set-mailcontact -identity $functionGroup.alias -EmailAddressPolicyEnabled:$FALSE -forceUpgrade -confirm:$FALSE
        }
        catch{
            out-logfile -string $_ -isError:$TRUE
        }

        #When a mail contact has a target address - it is added as a proxy address.
        #This has to be removed or you'll have a proxy address conflict with the migrated group.

        <#out-logfile -string "Searching for the remote routing address as a proxy address."

        foreach ($address in $functiongroup.emailaddresses)
        {
            if ($address.contains($routingContactConfig.targetAddress))
            {
                out-logfile -string ("Remote routing address found = "+$address)

                $functionRemoteRoutingAddress=$address

                out-logfile -string ("Function routing address = "+$functionRemoteRoutingAddress)
            }
        }
        #>

        try{
            out-logfile -string "Removing the remote routing address..."

            set-mailContact -identity $routingContactConfig.mailNickName -emailaddresses @{remove=$routingContactConfig.targetAddress} -domainController $globalCatalogServer -forceUpgrade -confirm:$FALSE -errorAction STOP
        }
        catch{
            out-logfile -string $_ -isError:$TRUE
        }

        Out-LogFile -string "END enable-mailRoutingContact"
        Out-LogFile -string "********************************************************************************"
    }