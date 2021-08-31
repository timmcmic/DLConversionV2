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

        $functionEmailAddress=$NULL

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN Enable-MailDyamicGroup"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        #Create the dynamic distribution group.
        #This is very import - the group is scoped to the OU where it was created and uses the two custom attributes.
        #If the mail contact is ever moved from the OU that the DL originally existed in - hybrid mail flow breaks.

        try{
            out-logfile -string "Creating dynamic group..."

            $tempOUSubstring = $originalDLConfiguration.distinguishedname.substring($originalDLConfiguration.distinguishedName.indexof(",OU="))
            out-logfile -string "Temp OU Substring = "
            out-logfile -string $tempOUSubstring
            $tempOUSubstring = $tempOUSubstring.substring($tempOUSubstring.indexOF("OU"))
            out-logfile -string "Temp OU Substring Substring ="
            out-logfile -string $tempOUSubstring

            new-dynamicDistributionGroup -name $originalDLConfiguration.name -alias $originalDLConfiguration.mailNickName -primarySMTPAddress $originalDLConfiguration.mail -organizationalUnit $tempOUSubstring -domainController $globalCatalogServer -includedRecipients AllRecipients -conditionalCustomAttribute1 $routingContactConfig.extensionAttribute1 -conditionalCustomAttribute2 $routingContactConfig.extensionAttribute2 -displayName $originalDLConfiguration.DisplayName
        }
        catch{
            out-logfile -string $_ -isError:$TRUE
        }

        #All of the email addresses that existed on the migrated group need to be stamped on the new group.

        foreach ($address in $originalDLConfiguration.proxyAddresses)
        {
            out-logfile -string ("Adding proxy address = "+$address)

            #If the address is not a mail.onmicrosoft.com address - stamp it.
            #Otherwise skip it - this is because the address is stamped on the mail contact already.

            if (!$address.contains("mail.onmicrosoft.com"))
            {
                out-logfile -string "Address is not a mail.onmicrosoft.com address."

                try{
                    set-dynamicdistributionGroup -identity $originalDLConfiguration.mail -emailAddresses @{add=$address} -domainController $globalCatalogServer
                }
                catch{
                    out-logfile -string $_ -isError:$TRUE
                }
            }
            else 
            {
                out-logfile -string "Address is a mail.onmicrosoft.com address - skipping."    
            }
        }

        #The legacy Exchange DN must now be added to the group.

        $functionEmailAddress = "x500:"+$originalDLConfiguration.legacyExchangeDN

        out-logfile -string $originalDLConfiguration.legacyExchangeDN
        out-logfile -string ("Calculated x500 Address = "+$functionEmailAddress)

        try{
            set-dynamicDistributionGroup -identity $originalDLConfiguration.mail -emailAddresses @{add=$functionEmailAddress} -domainController $globalCatalogServer
        }
        catch{
            out-logfile -string $_ -isError:$TRUE
        }

        #The script intentionally does not set any other restrictions on the DL.
        #It allows all restriction to be evaluated once the mail reaches office 365.
        #The only restriction I set it require sender authentication - this ensures that anonymous email can still use the DL if the source is on prem.

        
        if ($originalDLConfiguration.msExchRequireAuthToSendTo -eq $NULL)
        {
            out-logfile -string "The sender authentication setting was not set - maybe legacy version of Exchange."
            out-logfile -string "The sender authentication setting value FALSE in this instance."

            try {
                set-dynamicdistributionGroup -identity $originalDLConfiguration.mail -RequireSenderAuthenticationEnabled $FALSE -domainController $globalCatalogServer
            }
            catch {
                out-logfile -string $_ -isError:$TRUE
            }
        }
        else
        {
            out-logfile -string "Sender authentication setting is present - retaining setting as present."

            try {
                set-dynamicdistributionGroup -identity $originalDLConfiguration.mail -RequireSenderAuthenticationEnabled $originalDLConfiguration.msExchRequireAuthToSendTo -domainController $globalCatalogServer
            }
            catch {
                out-logfile -string $_ -isError:$TRUE
            }
        }

        #Evaluate hide from address book.

        if (($originalDLConfiguration.msExchHideFromAddressLists -eq $TRUE) -or ($originalDLConfiguration.msExchHideFromAddressLists -eq $FALSE))
        {
            out-logfile -string "Evaluating hide from address list."

            try {
                set-dynamicdistributionGroup -identity $originalDLConfiguration.mail -HiddenFromAddressListsEnabled $originalDLConfiguration.msExchHideFromAddressLists -domainController $globalCatalogServer
            }
            catch {
                out-logfile -string $_ -isError:$TRUE
            }
        }
        else
        {
            out-logfile -string "Hide from address list settings retained at default value - not set."
        }

        Out-LogFile -string "END Enable-MailDyamicGroup"
        Out-LogFile -string "********************************************************************************"
    }