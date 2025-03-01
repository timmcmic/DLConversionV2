<#
    .SYNOPSIS

    This function creates the routing contact that will be utilized later if hybrid mail flow is enabled <and> to track attribute membership.

    .DESCRIPTION

    This function creates the routing contact that will be utilized later if hybrid mail flow is enabled <and> to track attribute membership.
    
    .PARAMETER originalDLConfiguration

    This is the original DL configuration from on premises.

    .PARAMETER office365DLConfiguration

    The configuration of the DL from Office 365.

    .PARAMETER GlobalCatalog

    The global catalog server the operation should be performed on.

    .PARAMETER adCredential

    The active directory credential.

    .PARAMETER isRetry

    Determines if this operation is being retried.

    .PARAMETER isRetryOU

    The OU that will be utilized when the operation is retried.

    .OUTPUTS

    No return.

    .EXAMPLE

    new-routingContact -originalDLConfiguration $config -office365DLConfiguration $configo365 -globalCatalogServer $GC -adCredential $cred

    #>
    Function new-routingContact
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $originalDLConfiguration,
            [Parameter(Mandatory = $true)]
            $office365DLConfiguration,
            [Parameter(Mandatory = $true)]
            $globalCatalogServer,
            [Parameter(Mandatory = $true)]
            $adCredential,
            [Parameter(Mandatory = $false)]
            [ValidateSet("Basic","Negotiate")]
            $activeDirectoryAuthenticationMethod="Negotiate",
            [Parameter(Mandatory = $false)]
            [boolean]$isRetry = $false,
            [Parameter(Mandatory = $false)]
            [string]$isRetryOU = $false,
            [Parameter(Mandatory = $false)]
            [string]$customRoutingDomain = ""
        )

        #Define function variables.

        [string]$functionMigratedByScript = "-MigratedByScript"
        [string]$functionMigratedByScriptShort = "MigratedByScript"
        [int]$functionMaxLength = 64
        [string]$functionNameTest = ""

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN new-RoutingContact"
        Out-LogFile -string "********************************************************************************"

        #Declare function variables and output to screen.

        [string]$functionCustomAttribute1="MigratedByScript"
        out-logfile -string ("Function Custom Attribute 1 = "+$functionCustomAttribute1)

        [string]$functionCustomAttribute2=$office365DLConfiguration.externalDirectoryObjectID
        out-logfile -string ("Function Custom Attribute 2 = "+$functionCustomAttribute2)

        <#

        if ($originalDLConfiguration.mail -ne $NULL)
        {
            out-logfile -string "DL Configuration Contains Mail = use mail attribute."
            [string]$functionCustomAttribute2=$originalDLConfiguration.mail
            out-logfile -string ("Function Custom Attribute 2 = "+$functionCustomAttribute2)
        }
        else 
        {
            if ($office365DLConfiguration.recipientTypeDetails -ne "GroupMailbox")
            {
                out-logfile -string "Group is standard - use windows email address."
                out-logfile -string ("DL Configuration based off Office 365 - use windowsEmailAddress attribute.")
                [string]$functionCustomAttribute2=$office365DLConfiguration.WindowsEmailAddress
                out-logfile -string ("Function Custom Attribute 2 = "+$functionCustomAttribute2)
            }
            else
            {
                out-logfile -string "Group is universal use primary SMTP address."
                out-logfile -string ("DL Configuration based off Office 365 - use windowsEmailAddress attribute.")
                [string]$functionCustomAttribute2=$office365DLConfiguration.primarySMTPAddress
                out-logfile -string ("Function Custom Attribute 2 = "+$functionCustomAttribute2)
            }

        }

        #>

        out-logfile -string "Evaluate OU location to utilize."

        if ($isRetry -eq $FALSE)
        {
            out-logfile -string "Operation is not retried - using on premises value."
            [string]$functionOU=Get-OULocation -originalDLConfiguration $originalDLConfiguration
        }
        else 
        {
            out-logfile -string "Operation is being retried - use administrator supplied value."
            $functionOU = $isRetryOU
        }

        out-logfile -string ("Function OU = "+$functionOU)

        if ($customRoutingDomain -eq "")
        {
            foreach ($address in $office365DLConfiguration.emailAddresses)
            {
                out-logfile -string ("Testing address for remote routing address = "+$address)
    
                if (($address.tolower()).contains("mail.onmicrosoft.com"))
                {
                    out-logfile -string ("The remote routing address was found = "+$address)
    
                    $functionTargetAddress=$address
                    $functionTargetAddress=$functionTargetAddress.toUpper()
                }
                elseif (($address.tolower()).contains("microsoftonline.com"))
                {
                    out-logfile -string ("The remote routing domain based on legacy address was found = "+$address)

                    $functionTargetAddress = $address
                    $functionTargetAddress = $functionTargetAddress.toUpper()
                }
            }
        }
        else 
        {
            out-logfile -string "Testing based on the custom remote routing address."
            foreach ($address in $office365DLConfiguration.emailAddresses)
            {
                out-logfile -string ("Testing address for remote routing address = "+$address)
    
                if (($address.tolower()).contains($customRoutingDomain.tolower()))
                {
                    out-logfile -string ("The remote routing address was found = "+$address)
    
                    $functionTargetAddress=$address
                    $functionTargetAddress=$functionTargetAddress.toUpper()
                }
            }
        }

        
        if ($functionTargetAddress -eq $NULL)
        {
            #This code was kinda cheap - essentailly there was no valid address for a target address.
            #This really should not just fail - we should create and set one.

            out-logfile -string "Group does not have a mail.onmicrosoft.com address or address at the custom routing domain - one must be calculated."

            out-logfile -string ("Domain that will be utilized for the remote routing domain: "+$customRoutingDomain)

            out-logfile -string ("Utilize the alias of the group to build the new onmicrosoft.com address: "+$office365DLConfiguration.alias)

            $usefulRoutingAddress = $office365DLConfiguration.alias + "@"
            out-logfile -string $usefulRoutingAddress
            $usefulRoutingAddress = $usefulRoutingAddress + $customRoutingDomain
            out-logfile -string $usefulRoutingAddress

            out-logfile -string "Test to ensure that calcluated address is not present in Office 365."

            if (get-o365Recipient -identity $usefulRoutingAddress)
            {
                out-logfile -string "The address was found - at this point use something random."

                $newAddressOK = $false

                do {
                    $newAlias = ((Get-Random)+(Get-Random)+(Get-Random))
                    out-logfile -string ("New alias calculated: "+$newAlias)
                    $usefulRoutingAddress = $usefulRoutingAddress.replace($office365DLConfiguration.alias,$newAlias)
                    out-logfile -string $usefulRoutingAddress 

                    if (-not (get-o365Recipient -identity $usefulRoutingAddress))
                    {
                        out-logfile -string "Random address is not present in Office 365 - proceed."
                        $newAddressOK = $true
                    }
                    else 
                    {
                        out-logfile -string "Random address is present in Office 365 - do it again."
                        $newAddressOK = $false                        
                    }
                } until (
                    $newAddressOK -eq $true
                )
            }
            else 
            {
                out-logfile -string "The address was not found - allow to be target address."
            }

            $functionTargetAddress = "smtp:"+$usefulRoutingAddress
            out-logfile -string $functionTargetAddress
            $functionTargetAddress = $functionTargetAddress.ToUpper()
            out-logfile -string $functionTargetAddress

            out-logfile -string "Setting the target address on the Office 365 distribution group."

            if ($office365DLConfiguration.recipientTypeDetails -ne "GroupMailbox")
            {
                out-logfile -string "Group type is distribution - set email address with distribution."

                try {
                    set-o365DistributionGroup -identity $office365DLConfiguration.externalDirectoryObjectID -emailAddresses @{add=$functionTargetAddress.toLower()} -errorAction STOP -bypassSecurityGroupManagerCheck
                }
                catch {
                    out-logfile -string $_
                    out-logfile -string "Unable to add the calculated routing address to the distribution group." -isError:$TRUE
                }
            }
            else
            {
                out-logfile -string "Group type is unified - set email address with unified."

                try {
                    set-o365UnifiedGroup -identity $office365DLConfiguration.externalDirectoryObjectID -emailAddresses @{add=$functionTargetAddress.toLower()} -errorAction STOP
                }
                catch {
                    out-logfile -string $_
                    out-logfile -string "Unable to add the calculated routing address to the unified group." -isError:$TRUE
                }
            }

            out-logfile -string "New remote routing address calculated and stamped - moving on to creating contact."
        }
        else
        {
            out-logfile -string $functionTargetAddress
        }

        out-logfile -string ("Function target address = "+$functionTargetAddress)

        #This logic allows the code to be re-used when only the Office 365 information is available.

        if (($isRetry -eq $FALSE) -and ($originalDLConfiguration.cn.length -gt 0))
        {
            out-logfile -string "Operation is not retried - use on premises value."
            [string]$functionCN=$originalDLConfiguration.CN.replace(' ','')+$functionMigratedByScript

            if ($functionCN.length -gt $functionMaxLength)
            {
                out-logfile -string "CalculatedCN is greater than 64 characters."

                $functionCN = (($originalDLConfiguration.CN.substring(0,($originalDLConfiguration.cn.length - $functionMigratedByScript.Length)))+$functionMigratedByScript)

                out-logfile -string ("Updated function CN: "+$functionCN)
            }
        }
        else 
        {
            out-logfile -string "Operation is retried - use Office 365 value."
            [string]$functionCN=$office365DLConfiguration.alias.replace(' ','')+$functionMigratedByScript

            if ($functionCN.length -gt $functionMaxLength)
            {
                out-logfile -string "CalculatedCN is greater than 64 characters."

                (($office365DLConfiguration.CN.substring(0,($office365DLConfiguration.alias.length - $functionMigratedByScript.Length)))+$functionMigratedByScript)

                out-logfile -string ("Updated function CN: "+$functionCN)
            }
        }

        if (($isRetry -eq $FALSE) -and ($originalDLConfiguration.mail.length -gt 0))
        {
            out-logfile -string "Operation is not retried - use on premises value."
            [array]$functionProxyAddressArray=$originalDLConfiguration.mail.split("@")
        }
        else 
        {
            out-logfile -string "Operation is retried - use Office 365 value."

            if ($office365DLConfiguration.recipientTypeDetails -ne "GroupMailbox")
            {
                out-logfile -string "Office 365 group is normal - use windows email address."

                [array]$functionProxyAddressArray=$office365DLConfiguration.windowsEmailAddress.split("@")
            }
            else
            {
                out-logfile -string "Office 365 group is unified - use primary SMTP address."

                [array]$functionProxyAddressArray=$office365DLConfiguration.primarySMTPAddress.split("@")
            }
        }
        
        foreach ($member in $functionProxyAddressArray)
        {
            out-logfile -string $member
        }

        if ($originalDLConfiguration.displayName -ne $NULL)
        {
            [string]$functionDisplayName = $originalDLConfiguration.DisplayName+$functionMigratedByScript
            $functionDisplayName=$functionDisplayName.replace(' ','')
        }
        else 
        {
            [string]$functionDisplayName = $office365DLConfiguration.DisplayName+$functionMigratedByScript
            $functionDisplayName=$functionDisplayName.replace(' ','')
        }
        
        [string]$functionName=$functionCN

        if ($originalDLConfiguration.name -ne $NULL)
        {
            [string]$functionFirstName = $originalDLConfiguration.Name
            out-logfile -string ("Function First Name: "+$functionFirstName)
        }
        else {
            [string]$functionFirstName = $office365DLConfiguration.Name
            out-logfile -string ("Function First Name: "+$functionFirstName)
        }

        [string]$functionLastName = $functionMigratedByScriptShort

        [boolean]$functionHideFromAddressList=$true

        [string]$functionRecipientDisplayType="6"

        [string]$functionMail=$functionProxyAddressArray[0]+$functionMigratedByScript+"@"+$functionProxyAddressArray[1]

        [string]$functionProxyAddress="SMTP:"+$functionMail

        if (($isRetry -eq $FALSE) -and ($originalDLConfiguration.mailNickName.length -gt 0))
        {
            out-logfile -string "Operation is not retried - use on premises value."
            [string]$functionMailNickName=$originalDLConfiguration.mailNickName.replace(' ','')+$functionMigratedByScript

            if ($functionMailNickName.length -gt $functionMaxLength)
            {
                out-logfile -string "Calculated mail nickname is greater than 64 characters."

                $functionMailNickName = (($originalDLConfiguration.mailNickName.substring(0,($originalDLConfiguration.mailNickName.length - $functionMigratedByScript.Length)))+$functionMigratedByScript)

                out-logfile -string ("Updated function mail nickname: "+$functionMailNickName)
            }
        }
        else 
        {
            out-logfile -string "Operation is retried - use Office 365 value."
            [string]$functionMailNickName=$office365DLConfiguration.alias.replace(' ','')+$functionMigratedByScript

            if ($functionMailNickName.length -gt $functionMaxLength)
            {
                out-logfile -string "Calculated mail nick name is greater than 64 characters."

                (($office365DLConfiguration.alias.substring(0,($office365DLConfiguration.alias.length - $functionMigratedByScript.Length)))+$functionMigratedByScript)

                out-logfile -string ("Updated function mail nick name: "+$functionMailNickName)
            }
        }

        [string]$functionDescription="This is the mail contact created post migration to allow non-migrated DLs to retain memberships and permissions settings.  DO NOT DELETE"

        [string]$functionSelfAccountSid = "S-1-5-10"

        out-logfile -string ("Function display name = "+$functionDisplayName)
        out-logfile -string ("Function Name = "+$functionName)
        out-logfile -string ("Function First Name = "+$functionFirstName)
        out-logfile -string ("Function Last Name = "+$functionLastName)
        out-logfile -string ("Function hide from address list = "+$functionHideFromAddressList)
        out-logfile -string ("Function recipient display type = "+$functionRecipientDisplayType)
        out-logfile -string ("Function proxy address = "+$functionProxyAddress)
        out-logfile -string ("Function mail nickname = "+$functionMailNickname)
        out-logfile -string ("Function description = "+$functionDescription)
        out-logfile -string ("Function mail address = "+$functionMail)

        #Provision the routing contact.
        #When the contact is provisioned we add the master account sid of self.  This tricks exchange commands into allowing us to assign permissions that are reserved for security principals.

        try {
            new-adobject -server $globalCatalogServer -type "Contact" -name $functionName -displayName $functionDisplayName -description $functionDescription -path $functionOU -otherAttributes @{givenname=$functionFirstName;sn=$functionLastName;mail=$functionMail;extensionAttribute1=$functionCustomAttribute1;extensionAttribute2=$functionCustomAttribute2;targetAddress=$functionTargetAddress;msExchHideFromAddressLists=$functionHideFromAddressList;msExchRecipientDisplayType=$functionRecipientDisplayType;proxyAddresses=$functionProxyAddress;mailNickName=$functionMailNickname;msExchMasterAccountSid=$functionSelfAccountSid} -credential $adCredential -authType $activeDirectoryAuthenticationMethod -errorAction STOP
        }
        catch {
            out-Logfile -string $_ -isError:$TRUE
        }

        Out-LogFile -string "END new-RoutingContact"
        Out-LogFile -string "********************************************************************************"
    }