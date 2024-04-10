<#
    .SYNOPSIS

    This function sets the single value attributes of the group created in Office 365.

    .DESCRIPTION

    This function sets the single value attributes of the group created in Office 365.

    .PARAMETER originalDLConfiguration

    The original configuration of the DL on premises.

    .PARAMETER groupTypeOverride

    Submits the group type override of specified by the administrator at run time.

    .OUTPUTS

    None

    .EXAMPLE

    set-Office365DL -originalDLConfiguration DLConfiguration -groupTypeOverride TYPEOVERRIDE -office365DLConfigurationPostMigration OFFICE365DLCONFIGURATION

    #>
    Function set-Office365Group
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $originalDLConfiguration,
            [Parameter(Mandatory = $true)]
            $office365DLConfiguration,
            [Parameter(Mandatory = $true)]
            $office365DLConfigurationPostMigration,
            [Parameter(Mandatory=$FALSE)]
            [boolean]$isFirstAttempt=$false
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Declare function variables.

        $functionModerationFlags=$NULL
        $functionSendModerationNotifications=$NULL
        $functionModerationEnabled=$NULL
        $functionoofReplyToOriginator=$NULL
        $functionreportToOwner=$NULL
        $functionHiddenFromAddressList=$NULL
        $functionMemberJoinRestriction=$NULL
        $functionMemberDepartRestriction=$NULL
        $functionRequireAuthToSendTo=$NULL

        [string]$functionMailNickName=""
        [string]$functionDisplayName=""
        [string]$functionSimpleDisplayName=""
        [string]$functionWindowsEmailAddress=""
        [boolean]$functionReportToOriginator=$FALSE
        [string]$functionExternalDirectoryObjectID = ""

        [boolean]$isTestError=$FALSE
        [array]$functionErrors=@()

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN SET-Office365DL"
        Out-LogFile -string "********************************************************************************"

        if ($office365DLConfigurationPostMigration.externalDirectoryObjectID -eq "")
        {
            $functionExternalDirectoryObjectID = $office365DLConfigurationPostMigration.GUID
        }
        else
        {
            $functionExternalDirectoryObjectID = $office365DLConfigurationPostMigration.externalDirectoryObjectID
        }

        out-logfile -string "Setting core single values for the distribution group."

        out-logfile -string "Determining if this is the first pass on attribute setting."

        if ($isFirstAttempt -eq $FALSE)
        {
            out-logfile -string "This is not the first pass - set attribute that may collide with the original group."
        }
        else 
        {
            out-logfile -string "This is the first pass set attribute that would not collide with the original group."

            #There are several flags of a DL that are either calculated hashes <or> booleans not set by default.
            #The exchange commandlets abstract this by performing a conversion or filling the values in.
            #Since we use ldap to get these values now - we must reverse engineer these and / or set them.

            #Evaluate moderation enabled.

            if ($originalDLConfiguration.msExchEnableModeration -eq $NULL)
            {
                out-logfile -string "The moderation enabled setting is null."

                $functionModerationEnabled=$FALSE

                out-logfile -string ("The updated moderation enabled flag is = "+$functionModerationEnabled)
            }
            else 
            {
                out-logfile -string "The moderation setting was set on premises."
                
                $functionModerationEnabled=$originalDLConfiguration.msExchEnableModeration

                out-Logfile -string ("The function moderation setting is "+$functionModerationEnabled)
            }

            #Evaluate hidden from address list.

            if ($originalDLConfiguration.msExchHideFromAddressLists -eq $NULL)
            {
                out-logfile -string ("Hidden from adddress list is null.")

                $functionHiddenFromAddressList=$FALSE

                out-logfile -string ("The hidden from address list is now = "+$functionHiddenFromAddressList)
            }
            else 
            {
                out-logFile -string ("Hidden from address list is not null.")
                
                $functionHiddenFromAddressList=$originalDLConfiguration.msExchHideFromAddressLists
            }

            #Evaluate require auth to send to DL.  If the DL is open to everyone - the value may not be present.

            if ($originalDLConfiguration.msExchRequireAuthToSendTo -eq $NULL)
            {
                out-logfile -string ("Require auth to send to is not set.")

                $functionRequireAuthToSendTo = $FALSE

                out-logfile -string ("The new require auth to sent to is: "+$functionRequireAuthToSendTo)
            }
            else 
            {
                out-logfile -string ("Require auth to send to is set - retaining value. "+ $originalDLConfiguration.msExchRequireAuthToSendTo)
                
                $functionRequireAuthToSendTo = $originalDLConfiguration.msExchRequireAuthToSendTo
            }

            #It is possible that the group is not fully mail enabled.
            #Groups may now be represented as mail enabled if only MAIL is populated.
            #If on premsies attributes are not specified - use the attributes that were obtained from office 365.

            if ($originalDLConfiguration.mailNickName -eq $NULL)
            {
                out-logfile -string "On premises group does not have alias / mail nick name -> using Office 365 value."

                $functionMailNickName = $office365DLConfiguration.alias

                out-logfile -string ("Office 365 alias used for group creation: "+$functionMailNickName)
            }
            else 
            {
                out-logfile -string "On premises group has a mail nickname specified - using on premises value."
                $functionMailNickName = $originalDLConfiguration.mailNickName
                out-logfile -string $functionMailNickName    
            }

            if ($originalDLConfiguration.displayName -ne $NULL)
            {
                $functionDisplayName = $originalDLConfiguration.displayName
            }
            else 
            {
                $functionDisplayName = $office365DLConfiguration.displayName    
            }

            try 
            {
                out-logfile -string "Setting distribution group alias."
                
                Set-O365UnifiedGroup -Identity $functionExternalDirectoryObjectID -Alias $functionMailNickName -errorAction STOP 
            }
            catch 
            {
                out-logfile "Error encountered setting core single valued attributes."

                out-logfile -string $_

                $isErrorObject = new-Object psObject -property @{
                    PrimarySMTPAddressorUPN = $originalDLConfiguration.mail
                    ExternalDirectoryObjectID = $originalDLConfiguration.'msDS-ExternalDirectoryObjectId'
                    Alias = $functionMailNickName
                    Name = $originalDLConfiguration.name
                    Attribute = "Cloud distribution list:  Alias"
                    ErrorMessage = "Error setting alias on the migrated distribution group.  Administrator action required."
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

            try 
            {
                out-logfile -string "Setting distribution group display name."
                
                Set-O365UnifiedGroup -Identity $functionExternalDirectoryObjectID -DisplayName $functionDisplayName -errorAction STOP
            }
            catch 
            {
                out-logfile "Error encountered setting core single valued attributes."

                out-logfile -string $_

                $isErrorObject = new-Object psObject -property @{
                    PrimarySMTPAddressorUPN = $originalDLConfiguration.mail
                    ExternalDirectoryObjectID = $originalDLConfiguration.'msDS-ExternalDirectoryObjectId'
                    Alias = $functionMailNickName
                    Name = $originalDLConfiguration.name
                    Attribute = "Cloud distribution list:  DisplayName"
                    ErrorMessage = "Error setting display name on the migrated distribution group.  Administrator action required."
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

            try 
            {
                out-logfile -string "Setting distribution group hidden from address list."
                
                Set-O365UnifiedGroup -Identity $functionExternalDirectoryObjectID -HiddenFromAddressListsEnabled $functionHiddenFromAddressList -errorAction STOP 
            }
            catch 
            {
                out-logfile "Error encountered setting core single valued attributes."

                out-logfile -string $_

                $isErrorObject = new-Object psObject -property @{
                    PrimarySMTPAddressorUPN = $originalDLConfiguration.mail
                    ExternalDirectoryObjectID = $originalDLConfiguration.'msDS-ExternalDirectoryObjectId'
                    Alias = $functionMailNickName
                    Name = $originalDLConfiguration.name
                    Attribute = "Cloud distribution list:  HiddenFromAddressListsEnabled"
                    ErrorMessage = "Error setting hide from address book on the migrated distribution group.  Administrator action required."
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

            try 
            {
                out-logfile -string "Setting distribution group require sender authentication enabled."
                
                Set-O365UnifiedGroup -Identity $functionExternalDirectoryObjectID -RequireSenderAuthenticationEnabled $functionRequireAuthToSendTo -errorAction STOP 
            }
            catch 
            {
                out-logfile "Error encountered setting core single valued attributes."

                out-logfile -string $_

                $isErrorObject = new-Object psObject -property @{
                    PrimarySMTPAddressorUPN = $originalDLConfiguration.mail
                    ExternalDirectoryObjectID = $originalDLConfiguration.'msDS-ExternalDirectoryObjectId'
                    Alias = $functionMailNickName
                    Name = $originalDLConfiguration.name
                    Attribute = "Cloud distribution list:  RequireAuthenticationEnabled"
                    ErrorMessage = "Error setting require sender authentication on the migrated distribution group.  Administrator action required."
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

            try 
            {
                out-logfile -string "Setting mail tip translations."
                
                Set-O365UnifiedGroup -Identity $functionExternalDirectoryObjectID -MailTipTranslations $originalDLConfiguration.msExchSenderHintTranslations -errorAction STOP 
            }
            catch 
            {
                out-logfile "Error encountered setting core single valued attributes."

                out-logfile -string $_

                $isErrorObject = new-Object psObject -property @{
                    PrimarySMTPAddressorUPN = $originalDLConfiguration.mail
                    ExternalDirectoryObjectID = $originalDLConfiguration.'msDS-ExternalDirectoryObjectId'
                    Alias = $functionMailNickName
                    Name = $originalDLConfiguration.name
                    Attribute = "Cloud distribution list:  MailTipTranslations"
                    ErrorMessage = "Error setting mail tip translations on the migrated distribution group.  Administrator action required."
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

            try 
            {
                out-logfile -string "Setting moderation enabled for the group."

                Set-O365UnifiedGroup -Identity $functionExternalDirectoryObjectID -ModerationEnabled $functionModerationEnabled -errorAction STOP 
            }
            catch 
            {
                out-logfile "Error encountered setting moderation properties of the group...."

                out-logfile -string $_

                $isErrorObject = new-Object psObject -property @{
                    PrimarySMTPAddressorUPN = $originalDLConfiguration.mail
                    ExternalDirectoryObjectID = $originalDLConfiguration.'msDS-ExternalDirectoryObjectId'
                    Alias = $functionMailNickName
                    Name = $originalDLConfiguration.name
                    Attribute = "Cloud distribution list:  ModerationEnabled"
                    ErrorMessage = "Error setting moderation enabled on the migrated distribution group.  Administrator action required."
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }
            
            out-logfile -string "Setting the custom and extension attributes of the group."

            try 
            {
                out-logfile -string "Setting extension attribute 1 of the group."

                Set-O365UnifiedGroup -Identity $functionExternalDirectoryObjectID -CustomAttribute1 $originalDLConfiguration.extensionAttribute1  -errorAction STOP        
            }
            catch 
            {
                out-logfile "Error encountered setting custom and extension attributes of the group...."

                out-logfile -string $_

                $isErrorObject = new-Object psObject -property @{
                    PrimarySMTPAddressorUPN = $originalDLConfiguration.mail
                    ExternalDirectoryObjectID = $originalDLConfiguration.'msDS-ExternalDirectoryObjectId'
                    Alias = $functionMailNickName
                    Name = $originalDLConfiguration.name
                    Attribute = "Cloud distribution list:  CustomAttribute1"
                    ErrorMessage = "Error setting custom attribute 1.  Administrator action required"
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

            try 
            {
                out-logfile -string "Setting extension attribute 10 of the group."

                Set-O365UnifiedGroup -Identity $functionExternalDirectoryObjectID -CustomAttribute10 $originalDLConfiguration.extensionAttribute10  -errorAction STOP        
            }
            catch 
            {
                out-logfile "Error encountered setting custom and extension attributes of the group...."

                out-logfile -string $_

                $isErrorObject = new-Object psObject -property @{
                    PrimarySMTPAddressorUPN = $originalDLConfiguration.mail
                    ExternalDirectoryObjectID = $originalDLConfiguration.'msDS-ExternalDirectoryObjectId'
                    Alias = $functionMailNickName
                    Name = $originalDLConfiguration.name
                    Attribute = "Cloud distribution list:  CustomAttribute10"
                    ErrorMessage = "Error setting custom attribute 10.  Administrator action required"
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

            try 
            {
                out-logfile -string "Setting extension attribute 11 of the group."

                Set-O365UnifiedGroup -Identity $functionExternalDirectoryObjectID  -CustomAttribute11 $originalDLConfiguration.extensionAttribute11   -errorAction STOP        
            }
            catch 
            {
                out-logfile "Error encountered setting custom and extension attributes of the group...."

                out-logfile -string $_

                $isErrorObject = new-Object psObject -property @{
                    PrimarySMTPAddressorUPN = $originalDLConfiguration.mail
                    ExternalDirectoryObjectID = $originalDLConfiguration.'msDS-ExternalDirectoryObjectId'
                    Alias = $functionMailNickName
                    Name = $originalDLConfiguration.name
                    Attribute = "Cloud distribution list:  CustomAttribute11"
                    ErrorMessage = "Error setting custom attribute 11.  Administrator action required"
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

            try 
            {
                out-logfile -string "Setting extension attribute 12 of the group."

                Set-O365UnifiedGroup -Identity $functionExternalDirectoryObjectID -CustomAttribute12 $originalDLConfiguration.extensionAttribute12   -errorAction STOP        
            }
            catch 
            {
                out-logfile "Error encountered setting custom and extension attributes of the group...."

                out-logfile -string $_

                $isErrorObject = new-Object psObject -property @{
                    PrimarySMTPAddressorUPN = $originalDLConfiguration.mail
                    ExternalDirectoryObjectID = $originalDLConfiguration.'msDS-ExternalDirectoryObjectId'
                    Alias = $functionMailNickName
                    Name = $originalDLConfiguration.name
                    Attribute = "Cloud distribution list:  CustomAttribute12"
                    ErrorMessage = "Error setting custom attribute 12.  Administrator action required"
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

            try 
            {
                out-logfile -string "Setting extension attribute 13 of the group."

                Set-O365UnifiedGroup -Identity $functionExternalDirectoryObjectID -CustomAttribute13 $originalDLConfiguration.extensionAttribute13   -errorAction STOP        
            }
            catch 
            {
                out-logfile "Error encountered setting custom and extension attributes of the group...."

                out-logfile -string $_

                $isErrorObject = new-Object psObject -property @{
                    PrimarySMTPAddressorUPN = $originalDLConfiguration.mail
                    ExternalDirectoryObjectID = $originalDLConfiguration.'msDS-ExternalDirectoryObjectId'
                    Alias = $functionMailNickName
                    Name = $originalDLConfiguration.name
                    Attribute = "Cloud distribution list:  CustomAttribute13"
                    ErrorMessage = "Error setting custom attribute 13.  Administrator action required"
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

            try 
            {
                out-logfile -string "Setting extension attribute 14 of the group."

                Set-O365UnifiedGroup -Identity $functionExternalDirectoryObjectID -CustomAttribute14 $originalDLConfiguration.extensionAttribute14   -errorAction STOP        
            }
            catch 
            {
                out-logfile "Error encountered setting custom and extension attributes of the group...."

                out-logfile -string $_

                $isErrorObject = new-Object psObject -property @{
                    PrimarySMTPAddressorUPN = $originalDLConfiguration.mail
                    ExternalDirectoryObjectID = $originalDLConfiguration.'msDS-ExternalDirectoryObjectId'
                    Alias = $functionMailNickName
                    Name = $originalDLConfiguration.name
                    Attribute = "Cloud distribution list:  CustomAttribute14"
                    ErrorMessage = "Error setting custom attribute 14.  Administrator action required"
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

            try 
            {
                out-logfile -string "Setting extension attribute 15 of the group."

                Set-O365UnifiedGroup -Identity $functionExternalDirectoryObjectID -CustomAttribute15 $originalDLConfiguration.extensionAttribute15   -errorAction STOP        
            }
            catch 
            {
                out-logfile "Error encountered setting custom and extension attributes of the group...."

                out-logfile -string $_

                $isErrorObject = new-Object psObject -property @{
                    PrimarySMTPAddressorUPN = $originalDLConfiguration.mail
                    ExternalDirectoryObjectID = $originalDLConfiguration.'msDS-ExternalDirectoryObjectId'
                    Alias = $functionMailNickName
                    Name = $originalDLConfiguration.name
                    Attribute = "Cloud distribution list:  CustomAttribute15"
                    ErrorMessage = "Error setting custom attribute 15.  Administrator action required"
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

            try 
            {
                out-logfile -string "Setting extension attribute 2 of the group."

                Set-O365UnifiedGroup -Identity $functionExternalDirectoryObjectID -CustomAttribute2 $originalDLConfiguration.extensionAttribute2    -errorAction STOP        
            }
            catch 
            {
                out-logfile "Error encountered setting custom and extension attributes of the group...."

                out-logfile -string $_

                $isErrorObject = new-Object psObject -property @{
                    PrimarySMTPAddressorUPN = $originalDLConfiguration.mail
                    ExternalDirectoryObjectID = $originalDLConfiguration.'msDS-ExternalDirectoryObjectId'
                    Alias = $functionMailNickName
                    Name = $originalDLConfiguration.name
                    Attribute = "Cloud distribution list:  CustomAttribute2"
                    ErrorMessage = "Error setting custom attribute 2.  Administrator action required"
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

            try 
            {
                out-logfile -string "Setting extension attribute 3 of the group."

                Set-O365UnifiedGroup -Identity $functionExternalDirectoryObjectID -CustomAttribute3 $originalDLConfiguration.extensionAttribute3    -errorAction STOP        
            }
            catch 
            {
                out-logfile "Error encountered setting custom and extension attributes of the group...."

                out-logfile -string $_

                $isErrorObject = new-Object psObject -property @{
                    PrimarySMTPAddressorUPN = $originalDLConfiguration.mail
                    ExternalDirectoryObjectID = $originalDLConfiguration.'msDS-ExternalDirectoryObjectId'
                    Alias = $functionMailNickName
                    Name = $originalDLConfiguration.name
                    Attribute = "Cloud distribution list:  CustomAttribute3"
                    ErrorMessage = "Error setting custom attribute 3.  Administrator action required"
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

            try 
            {
                out-logfile -string "Setting extension attribute 4 of the group."

                Set-O365UnifiedGroup -Identity $functionExternalDirectoryObjectID -CustomAttribute4 $originalDLConfiguration.extensionAttribute4    -errorAction STOP        
            }
            catch 
            {
                out-logfile "Error encountered setting custom and extension attributes of the group...."

                out-logfile -string $_

                $isErrorObject = new-Object psObject -property @{
                    PrimarySMTPAddressorUPN = $originalDLConfiguration.mail
                    ExternalDirectoryObjectID = $originalDLConfiguration.'msDS-ExternalDirectoryObjectId'
                    Alias = $functionMailNickName
                    Name = $originalDLConfiguration.name
                    Attribute = "Cloud distribution list:  CustomAttribute4"
                    ErrorMessage = "Error setting custom attribute 4.  Administrator action required"
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

            try 
            {
                out-logfile -string "Setting extension attribute 5 of the group."

                Set-O365UnifiedGroup -Identity $functionExternalDirectoryObjectID  -CustomAttribute5 $originalDLConfiguration.extensionAttribute5    -errorAction STOP        
            }
            catch 
            {
                out-logfile "Error encountered setting custom and extension attributes of the group...."

                out-logfile -string $_

                $isErrorObject = new-Object psObject -property @{
                    PrimarySMTPAddressorUPN = $originalDLConfiguration.mail
                    ExternalDirectoryObjectID = $originalDLConfiguration.'msDS-ExternalDirectoryObjectId'
                    Alias = $functionMailNickName
                    Name = $originalDLConfiguration.name
                    Attribute = "Cloud distribution list:  CustomAttribute5"
                    ErrorMessage = "Error setting custom attribute 5.  Administrator action required"
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

            try 
            {
                out-logfile -string "Setting extension attribute 6 of the group."

                Set-O365UnifiedGroup -Identity $functionExternalDirectoryObjectID  -CustomAttribute6 $originalDLConfiguration.extensionAttribute6    -errorAction STOP        
            }
            catch 
            {
                out-logfile "Error encountered setting custom and extension attributes of the group...."

                out-logfile -string $_

                $isErrorObject = new-Object psObject -property @{
                    PrimarySMTPAddressorUPN = $originalDLConfiguration.mail
                    ExternalDirectoryObjectID = $originalDLConfiguration.'msDS-ExternalDirectoryObjectId'
                    Alias = $functionMailNickName
                    Name = $originalDLConfiguration.name
                    Attribute = "Cloud distribution list:  CustomAttribute6"
                    ErrorMessage = "Error setting custom attribute 6.  Administrator action required"
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

            try 
            {
                out-logfile -string "Setting extension attribute 7 of the group."

                Set-O365UnifiedGroup -Identity $functionExternalDirectoryObjectID  -CustomAttribute7 $originalDLConfiguration.extensionAttribute7    -errorAction STOP        
            }
            catch 
            {
                out-logfile "Error encountered setting custom and extension attributes of the group...."

                out-logfile -string $_

                $isErrorObject = new-Object psObject -property @{
                    PrimarySMTPAddressorUPN = $originalDLConfiguration.mail
                    ExternalDirectoryObjectID = $originalDLConfiguration.'msDS-ExternalDirectoryObjectId'
                    Alias = $functionMailNickName
                    Name = $originalDLConfiguration.name
                    Attribute = "Cloud distribution list:  CustomAttribute7"
                    ErrorMessage = "Error setting custom attribute 7.  Administrator action required"
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

            try 
            {
                out-logfile -string "Setting extension attribute 8 of the group."

                Set-O365UnifiedGroup -Identity $functionExternalDirectoryObjectID  -CustomAttribute8 $originalDLConfiguration.extensionAttribute8    -errorAction STOP        
            }
            catch 
            {
                out-logfile "Error encountered setting custom and extension attributes of the group...."

                out-logfile -string $_

                $isErrorObject = new-Object psObject -property @{
                    PrimarySMTPAddressorUPN = $originalDLConfiguration.mail
                    ExternalDirectoryObjectID = $originalDLConfiguration.'msDS-ExternalDirectoryObjectId'
                    Alias = $functionMailNickName
                    Name = $originalDLConfiguration.name
                    Attribute = "Cloud distribution list:  CustomAttribute8"
                    ErrorMessage = "Error setting custom attribute 8.  Administrator action required"
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

            try 
            {
                out-logfile -string "Setting extension attribute 9 of the group."

                Set-O365UnifiedGroup -Identity $functionExternalDirectoryObjectID -CustomAttribute9 $originalDLConfiguration.extensionAttribute9    -errorAction STOP        
            }
            catch 
            {
                out-logfile "Error encountered setting custom and extension attributes of the group...."

                out-logfile -string $_

                $isErrorObject = new-Object psObject -property @{
                    PrimarySMTPAddressorUPN = $originalDLConfiguration.mail
                    ExternalDirectoryObjectID = $originalDLConfiguration.'msDS-ExternalDirectoryObjectId'
                    Alias = $functionMailNickName
                    Name = $originalDLConfiguration.name
                    Attribute = "Cloud distribution list:  CustomAttribute9"
                    ErrorMessage = "Error setting custom attribute 9.  Administrator action required"
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }
            
            try 
            {
                out-logfile -string "Setting extension custom attribute 1 of the group."

                Set-O365UnifiedGroup -Identity $functionExternalDirectoryObjectID -ExtensionCustomAttribute1 $originalDLConfiguration.msExchExtensionCustomAttribute1    -errorAction STOP        
            }
            catch 
            {
                out-logfile "Error encountered setting custom and extension attributes of the group...."

                out-logfile -string $_

                $isErrorObject = new-Object psObject -property @{
                    PrimarySMTPAddressorUPN = $originalDLConfiguration.mail
                    ExternalDirectoryObjectID = $originalDLConfiguration.'msDS-ExternalDirectoryObjectId'
                    Alias = $functionMailNickName
                    Name = $originalDLConfiguration.name
                    Attribute = "Cloud distribution list:  ExtensionCustomAttribute1"
                    ErrorMessage = "Error setting extension custom attribute 1.  Administrator action required"
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

            try 
            {
                out-logfile -string "Setting extension custom attribute 2 of the group."

                Set-O365UnifiedGroup -Identity $functionExternalDirectoryObjectID -ExtensionCustomAttribute2 $originalDLConfiguration.msExchExtensionCustomAttribute2    -errorAction STOP        
            }
            catch 
            {
                out-logfile "Error encountered setting custom and extension attributes of the group...."

                out-logfile -string $_

                $isErrorObject = new-Object psObject -property @{
                    PrimarySMTPAddressorUPN = $originalDLConfiguration.mail
                    ExternalDirectoryObjectID = $originalDLConfiguration.'msDS-ExternalDirectoryObjectId'
                    Alias = $functionMailNickName
                    Name = $originalDLConfiguration.name
                    Attribute = "Cloud distribution list:  ExtensionCustomAttribute2"
                    ErrorMessage = "Error setting extension custom attribute 2.  Administrator action required"
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

            try 
            {
                out-logfile -string "Setting extension custom attribute 3 of the group."

                Set-O365UnifiedGroup -Identity $functionExternalDirectoryObjectID -ExtensionCustomAttribute3 $originalDLConfiguration.msExchExtensionCustomAttribute3    -errorAction STOP        
            }
            catch 
            {
                out-logfile "Error encountered setting custom and extension attributes of the group...."

                out-logfile -string $_

                $isErrorObject = new-Object psObject -property @{
                    PrimarySMTPAddressorUPN = $originalDLConfiguration.mail
                    ExternalDirectoryObjectID = $originalDLConfiguration.'msDS-ExternalDirectoryObjectId'
                    Alias = $functionMailNickName
                    Name = $originalDLConfiguration.name
                    Attribute = "Cloud distribution list:  ExtensionCustomAttribute3"
                    ErrorMessage = "Error setting extension custom attribute 3.  Administrator action required"
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

            try 
            {
                out-logfile -string "Setting extension custom attribute 4 of the group."

                Set-O365UnifiedGroup -Identity $functionExternalDirectoryObjectID -ExtensionCustomAttribute4 $originalDLConfiguration.msExchExtensionCustomAttribute4    -errorAction STOP        
            }
            catch 
            {
                out-logfile "Error encountered setting custom and extension attributes of the group...."

                out-logfile -string $_

                $isErrorObject = new-Object psObject -property @{
                    PrimarySMTPAddressorUPN = $originalDLConfiguration.mail
                    ExternalDirectoryObjectID = $originalDLConfiguration.'msDS-ExternalDirectoryObjectId'
                    Alias = $functionMailNickName
                    Name = $originalDLConfiguration.name
                    Attribute = "Cloud distribution list:  ExtensionCustomAttribute4"
                    ErrorMessage = "Error setting extension custom attribute 4.  Administrator action required"
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

            try 
            {
                out-logfile -string "Setting extension custom attribute 5 of the group."

                Set-O365UnifiedGroup -Identity $functionExternalDirectoryObjectID -ExtensionCustomAttribute5 $originalDLConfiguration.msExchExtensionCustomAttribute5   -errorAction STOP        
            }
            catch 
            {
                out-logfile "Error encountered setting custom and extension attributes of the group...."

                out-logfile -string $_

                $isErrorObject = new-Object psObject -property @{
                    PrimarySMTPAddressorUPN = $originalDLConfiguration.mail
                    ExternalDirectoryObjectID = $originalDLConfiguration.'msDS-ExternalDirectoryObjectId'
                    Alias = $functionMailNickName
                    Name = $originalDLConfiguration.name
                    Attribute = "Cloud distribution list:  ExtensionCustomAttribute5"
                    ErrorMessage = "Error setting extension custom attribute 5.  Administrator action required"
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }
        }

        Out-LogFile -string "END SET-Office365DL"
        Out-LogFile -string "********************************************************************************"

        out-logfile -string ("The number of function errors is: "+$functionerrors.count )
        $global:postCreateErrors += $functionErrors
    }