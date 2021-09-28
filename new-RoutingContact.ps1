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

    .OUTPUTS

    No return.

    .EXAMPLE

    Get-ADObjectConfiguration -powershellsessionname NAME -groupSMTPAddress Address

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
            $adCredential
        )

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN new-RoutingContact"
        Out-LogFile -string "********************************************************************************"

        #write out parameters utilized to log file.
        
        out-logfile -string ("Original DL Configuration = "+$originalDLConfiguration)
        out-logfile -string ("Office 365 DL Configuration = "+$office365DLConfiguration)
        out-logfile -string ("Global catalog server = "+$globalCatalogServer)
        out-logfile -string ("AD User Name = "+$adCredential.UserName)

        #Declare function variables and output to screen.

        [string]$functionCustomAttribute1="MigratedByScript"
        out-logfile -string ("Function Custom Attribute 1 = "+$functionCustomAttribute1)
        [string]$functionCustomAttribute2=$originalDLConfiguration.mail
        out-logfile -string ("Function Custom Attribute 2 = "+$functionCustomAttribute2)

        $tempOUSubstring = Get-OULocation -originalDLConfiguration $originalDLConfiguration

        [string]$functionOU=$tempOUSubstring
        out-logfile -string ("Function OU = "+$functionOU)

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

        out-logfile -string ("Function target address = "+$functionTargetAddress)

        [string]$functionDisplayName = $originalDLConfiguration.DisplayName+"-MigratedByScript"
        $functionDisplayName=$functionDisplayName.replace(' ','')
        [string]$functionCN=$originalDLConfiguration.CN+"-MigratedByScript"
        $functionCN=$functionCN.replace(' ','')
        [string]$functionName=$functionCN
        [string]$functionFirstName = $originalDLConfiguration.DisplayName
        $functionFirstName=$functionFirstName.replace(' ','')
        [string]$functionLastName = "MigratedByScript"
        [boolean]$functionHideFromAddressList=$true
        [string]$functionRecipientDisplayType="6"
        [array]$functionProxyAddressArray=$originalDLConfiguration.mail.split("@")
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
            out-Logfile -string $_ 
        }

        Out-LogFile -string "END new-RoutingContact"
        Out-LogFile -string "********************************************************************************"
    }