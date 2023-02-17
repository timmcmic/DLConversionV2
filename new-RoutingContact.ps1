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
            [boolean]$isRetry = $false,
            [Parameter(Mandatory = $false)]
            [string]$isRetryOU = $false,
            [Parameter(Mandatory = $false)]
            [string]$customRoutingDomain = $NULL
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN new-RoutingContact"
        Out-LogFile -string "********************************************************************************"

        #Declare function variables and output to screen.

        [string]$functionCustomAttribute1="MigratedByScript"
        out-logfile -string ("Function Custom Attribute 1 = "+$functionCustomAttribute1)


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

        if ($customRoutingDomain -eq $NULL)
        {
            foreach ($address in $office365DLConfiguration.emailAddresses)
            {
                out-logfile -string ("Testing address for remote routing address = "+$address)
    
                if ($address.contains("mail.onmicrosoft.com"))
                {
                    out-logfile -string ("The remote routing address was found = "+$address)
    
                    $functionTargetAddress=$address
                    $functionTargetAddress=$functionTargetAddress.toUpper()
                }
            }
        }
        else 
        {
            foreach ($address in $office365DLConfiguration.emailAddresses)
            {
                out-logfile -string ("Testing address for remote routing address = "+$address)
    
                if ($address.contains($customRoutingDomain))
                {
                    out-logfile -string ("The remote routing address was found = "+$address)
    
                    $functionTargetAddress=$address
                    $functionTargetAddress=$functionTargetAddress.toUpper()
                }
            }
        }

        
        if ($functionTargetAddress -eq $NULL)
        {
            out-logfile -string "Error - the group to have hybrid mail flow enabled does not have an address @domain.mail.onmicrosoft.com"
            out-logfile -string "Add an email address @domain.mail.onmicrosoft.com appropriate for your tenant in order to hybrid mail enable the list."
            out-logfile -string "Error enabling hybrid mail flow." -isError:$TRUE
        }
        else
        {
            out-logfile -string $functionTargetAddress
        }

        out-logfile -string ("Function target address = "+$functionTargetAddress)

        #This logic allows the code to be re-used when only the Office 365 information is available.

        if ($isRetry -eq $FALSE)
        {
            out-logfile -string "Operation is not retried - use on premsies value."
            [string]$functionCN=$originalDLConfiguration.CN+"-MigratedByScript"
        }
        else 
        {
            out-logfile -string "Operation is retried - use Office 365 value."
            [string]$functionCN=$originalDLConfiguration.alias+"-MigratedByScript"
        }
        
        $functionCN=$functionCN.replace(' ','')
        out-logfile -string ("Function Common Name:"+$functionCN)

        if ($isRetry -eq $FALSE)
        {
            out-logfile -string "Operation is not retried - use on premsies value."
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
            [string]$functionDisplayName = $originalDLConfiguration.DisplayName+"-MigratedByScript"
            $functionDisplayName=$functionDisplayName.replace(' ','')
        }
        else 
        {
            [string]$functionDisplayName = $office365DLConfiguration.DisplayName+"-MigratedByScript"
            $functionDisplayName=$functionDisplayName.replace(' ','')
        }
        
        [string]$functionName=$functionCN

        [string]$functionFirstName = $functionDisplayName

        [string]$functionLastName = "MigratedByScript"

        [boolean]$functionHideFromAddressList=$true

        [string]$functionRecipientDisplayType="6"

        [string]$functionMail=$functionProxyAddressArray[0]+"-MigratedByScript@"+$functionProxyAddressArray[1]

        [string]$functionProxyAddress="SMTP:"+$functionMail

        [string]$functionMailNickname=$functionProxyAddressArray[0]+"-MigratedByScript"

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
            new-adobject -server $globalCatalogServer -type "Contact" -name $functionName -displayName $functionDisplayName -description $functionDescription -path $functionOU -otherAttributes @{givenname=$functionFirstName;sn=$functionLastName;mail=$functionMail;extensionAttribute1=$functionCustomAttribute1;extensionAttribute2=$functionCustomAttribute2;targetAddress=$functionTargetAddress;msExchHideFromAddressLists=$functionHideFromAddressList;msExchRecipientDisplayType=$functionRecipientDisplayType;proxyAddresses=$functionProxyAddress;mailNickName=$functionMailNickname;msExchMasterAccountSid=$functionSelfAccountSid} -credential $adCredential -errorAction STOP
        }
        catch {
            out-Logfile -string $_ -isError:$TRUE
        }

        Out-LogFile -string "END new-RoutingContact"
        Out-LogFile -string "********************************************************************************"
    }