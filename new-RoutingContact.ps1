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
            $adCredential,
            [Parameter(Mandatory = $false)]
            [boolean]$isRetry = $false,
            [Parameter(Mandatory = $false)]
            [string]$isRetryOU = $false
        )

        out-logfile -string "Output bound parameters..."

        foreach ($paramName in $MyInvocation.MyCommand.Parameters.Keys)
        {
            $bound = $PSBoundParameters.ContainsKey($paramName)

            $parameterObject = New-Object PSObject -Property @{
                ParameterName = $paramName
                ParameterValue = if ($bound) { $PSBoundParameters[$paramName] }
                                else { Get-Variable -Scope Local -ErrorAction Ignore -ValueOnly $paramName }
                Bound = $bound
            }

            out-logfile -string $parameterObject
        }

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN new-RoutingContact"
        Out-LogFile -string "********************************************************************************"

        #write out parameters utilized to log file.
        
        out-logfile -string ("Original DL Configuration = "+$originalDLConfiguration)
        out-logfile -string ("Office 365 DL Configuration = "+$office365DLConfiguration)
        out-logfile -string ("Global catalog server = "+$globalCatalogServer)
        out-logfile -string ("AD User Name = "+$adCredential.UserName)
        out-logfile -string ("Is Retry Status = "+$isRetry)
        out-logfile -string ("Is Retry OU = "+$isRetryOU)

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
            out-logfile -string ("DL Configuration based off Office 365 - use windowsEmailAddress attribute.")
            [string]$functionCustomAttribute2=$office365DLConfiguration.WindowsEmailAddress
            out-logfile -string ("Function Custom Attribute 2 = "+$functionCustomAttribute2)
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
            [array]$functionProxyAddressArray=$originalDLConfiguration.windowsEmailAddress.split("@")
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