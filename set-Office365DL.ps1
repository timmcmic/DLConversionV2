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
    Function set-Office365DL
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $originalDLConfiguration,
            [Parameter(Mandatory = $true)]
            $office365DLConfiguration,
            [Parameter(Mandatory = $true)]
            [string]$groupTypeOverride,
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
            out-logfile -string "This is not the first pass - set attribute that may collid with the original group."

            try 
            {
                out-logfile -string "Setting distribution group name for the migrated group."
                
                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID -name $originalDLConfiguration.cn -errorAction STOP -BypassSecurityGroupManagerCheck
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
                    Attribute = "Cloud distribution list:  Name"
                    ErrorMessage = "Error setting name on the migrated distribution group.  Administrator action required."
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

            try 
            {
                out-logfile -string "Setting distribution windows email address."
                
                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID -WindowsEmailAddress $originalDLConfiguration.mail -errorAction STOP -BypassSecurityGroupManagerCheck
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
                    Attribute = "Cloud distribution list:  WindowsEmailAddress"
                    ErrorMessage = "Error setting windows email address on the migrated distribution group.  Administrator action required."
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

        }
        else 
        {
            out-logfile -string "This is the first pass set attribute that would not collid with the original group."

            #There are several flags of a DL that are either calculated hashes <or> booleans not set by default.
            #The exchange commandlets abstract this by performing a conversion or filling the values in.
            #Since we use ldap to get these values now - we must reverse engineer these and / or set them.

            #If the group type was overridden from the default - the member join restriction has to be adjusted.
            #If the group tyoe was not overriden - check to see if depart is NULL and set to closed which is default.
            #Otherwise take the value from the string.

            if ( $groupTypeOverride -eq "Security" )
            {
                out-logfile -string "Group type overriden to Security by administrator.  This requires depart restriction closed."

                $functionMemberDepartRestriction = "Closed"

                out-logfile -string ("Function member depart restrictions = "+$functionMemberDepartRestriction)
            }
            elseif ($originalDLConfiguration.msExchGroupDepartRestriction -eq $NULL)
            {
                out-logFile -string ("Member depart restriction is NULL.")

                $functionMemberDepartRestriction="Closed"

                out-LogFile -string ("The member depart restriction is now = "+$functionMemberDepartRestriction)
            }
            elseif (($originalDLConfiguration.groupType -eq "-2147483640") -or ($originalDLConfiguration.groupType -eq "-2147483646") -or ($originalDLConfiguration.groupType -eq "-2147483644"))
            {
                Out-logfile -string ("Group type is security - ensuring member depart restriction CLOSED")

                $functionMemberDepartRestriction="Closed"
            }
            else 
            {
                $functionMemberDepartRestriction = $originalDLConfiguration.msExchGroupDepartRestriction

                out-logfile -string ("Function member depart restrictions = "+$functionMemberDepartRestriction)
            }

            #The moderation settings a are a hash valued flag.
            #This test looks to see if bypass nested moderation is enabled from the hash.

            if (($originalDLConfiguration.msExchModerationFlags -eq "1") -or ($originalDLConfiguration.msExchModerationFlags -eq "3") -or ($originalDLConfiguration.msExchModerationFlags -eq "7") )
            {
                out-logfile -string ("The moderation flags are 1 / 3 / 7 - setting bypass nested moderation to TRUE - "+$originalDLConfiguration.msExchModerationFlags)

                $functionModerationFlags=$TRUE

                out-logfile ("The function moderation flags are = "+$functionModerationFlags)
            }
            else 
            {
                out-logfile -string ("The moderation flags are NOT 1 / 3 / 7 - setting bypass nested moderation to FALSE - "+$originalDLConfiguration.msExchModerationFlags)

                $functionModerationFlags=$FALSE

                out-logfile ("The function moderation flags is = "+$functionModerationFlags)
            }

            #Test now to see if the moderation settings are always, internal, or none.  This uses the same hash.

            if (($originalDLConfiguration.msExchModerationFlags -eq "0") -or ($originalDLConfiguration.msExchModerationFlags -eq "1")  )
            {
                out-logfile -string ("The moderation flags are 0 / 2 / 6 - send notifications to never."+$originalDLConfiguration.msExchModerationFlags)

                $functionSendModerationNotifications="Never"

                out-logfile -string ("The function send moderations notifications is = "+$functionSendModerationNotifications)
            }
            elseif (($originalDLConfiguration.msExchModerationFlags -eq "2") -or ($originalDLConfiguration.msExchModerationFlags -eq "3")  )
            {
                out-logfile -string ("The moderation flags are 0 / 2 / 6 - setting send notifications to internal."+$originalDLConfiguration.msExchModerationFlags)

                $functionSendModerationNotifications="Internal"

                out-logfile -string ("The function send moderations notifications is = "+$functionSendModerationNotifications)

            }
            elseif (($originalDLConfiguration.msExchModerationFlags -eq "6") -or ($originalDLConfiguration.msExchModerationFlags -eq "7")  )
            {
                out-logfile -string ("The moderation flags are 0 / 2 / 6 - setting send notifications to always."+$originalDLConfiguration.msExchModerationFlags)

                $functionSendModerationNotifications="Always"

                out-logfile -string ("The function send moderations notifications is = "+$functionSendModerationNotifications)
            }
            else 
            {
                out-logFile -string ("The moderation flags are not set.  Setting to default of always.")
                
                $functionSendModerationNotifications="Always"

                out-logFile -string ("The function send moderation notification is = "+$functionSendModerationNotifications)
            }

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

            #Evaluate oofReplyToOriginator

            if ($originalDLConfiguration.oofReplyToOriginator -eq $NULL)
            {
                out-logfile -string "The oofReplyToOriginator is null."

                $functionoofReplyToOriginator = $FALSE

                out-logfile -string ("The oofReplyToOriginator is now = "+$functionoofReplyToOriginator)
            }
            else 
            {
                out-logFile -string "The oofReplyToOriginator was set on premises."
                
                $functionoofReplyToOriginator=$originalDLConfiguration.oofReplyToOriginator

                out-logfile -string ("The function oofReplyToOriginator = "+$functionoofReplyToOriginator)
            }

            #Evaluate reportToOwner

            if ($originalDLConfiguration.reportToOwner -eq $NULL)
            {
                out-logfile -string "The reportToOwner is null."

                $functionreportToOwner = $FALSE

                out-logfile -string ("The reportToOwner is now = "+$functionreportToOwner)
            }
            else 
            {
                out-logfile -string "The reportToOwner was set on premises." 
                
                $functionReportToOwner = $originalDLConfiguration.reportToOwner

                out-logfile -string ("The function reportToOwner = "+$functionreportToOwner)
            }

            if ($originalDLConfiguration.reportToOriginator -eq $NULL)
            {
                out-logfile -string "The report to originator is NULL."

                $functionReportToOriginator = $FALSE
            }
            else 
            {
                $functionReportToOriginator = $originalDLConfiguration.reportToOriginator    
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

            #Evaluate member join restrictions.

            if ($originalDLConfiguration.msExchGroupJoinRestriction -eq $NULL)
            {
                out-Logfile -string ("Member join restriction is NULL.")

                $functionMemberJoinRestriction="Closed"

                out-logfile -string ("The member join restriction is now = "+$functionMemberJoinRestriction)
            }
            else 
            {
                $functionMemberJoinRestriction = $originalDLConfiguration.msExchGroupJoinRestriction

                out-logfile -string ("The function member join restriction is: "+$functionMemberJoinRestriction)
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
                out-logfile -string "On premsies group does not have alias / mail nick name -> using Office 365 value."

                $functionMailNickName = $office365DLConfiguration.alias

                out-logfile -string ("Office 365 alias used for group creation: "+$functionMailNickName)
            }
            else 
            {
                out-logfile -string "On premises group has a mail nickname specified - using on premsies value."
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

            if ($originalDLConfiguration.simpleDisplayNamePrintable -ne $NULL)
            {
                $functionSimpleDisplayName = $originalDLConfiguration.simpleDisplayNamePrintable
            }
            else 
            {
                $functionSimpleDisplayName = $office365DLConfiguration.simpleDisplayName    
            }
            
            try 
            {
                out-logfile -string "Setting distribution group alias."
                
                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID -Alias $functionMailNickName -errorAction STOP -BypassSecurityGroupManagerCheck
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
                
                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID -DisplayName $functionDisplayName -errorAction STOP -BypassSecurityGroupManagerCheck
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
                
                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID -HiddenFromAddressListsEnabled $functionHiddenFromAddressList -errorAction STOP -BypassSecurityGroupManagerCheck
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
                
                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID -RequireSenderAuthenticationEnabled $functionRequireAuthToSendTo -errorAction STOP -BypassSecurityGroupManagerCheck
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
                out-logfile -string "Setting distribution group simple display name."
                
                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID -SimpleDisplayName $functionSimpleDisplayName -errorAction STOP -BypassSecurityGroupManagerCheck
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
                    Attribute = "Cloud distribution list:  SimpleDisplayName"
                    ErrorMessage = "Error setting simple display name on the migrated distribution group.  Administrator action required."
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

            try 
            {
                out-logfile -string "Setting mail tip translations."
                
                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID -MailTipTranslations $originalDLConfiguration.msExchSenderHintTranslations -errorAction STOP -BypassSecurityGroupManagerCheck
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

            out-logfile -string "Setting single valued moderation propeties for the group."

            try 
            {
                out-logfile -string "Setting bypass nested moderation enabled."

                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID -BypassNestedModerationEnabled $functionModerationFlags -errorAction STOP -BypassSecurityGroupManagerCheck
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
                    Attribute = "Cloud distribution list:  BypassNestedModerationEnabled"
                    ErrorMessage = "Error setting bypass nested moderation enabled on the migrated distribution group.  Administrator action required."
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

            try 
            {
                out-logfile -string "Setting moderation enabled for the group."

                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID -ModerationEnabled $functionModerationEnabled -errorAction STOP -BypassSecurityGroupManagerCheck
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

            try 
            {
                out-logfile -string "Setting send moderation notifications for the group."

                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID -SendModerationNotifications $functionSendModerationNotifications -errorAction STOP -BypassSecurityGroupManagerCheck
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
                    Attribute = "Cloud distribution list:  SendModerationNotifications"
                    ErrorMessage = "Error setting send moderation notifications on the migrated distribution group.  Administrator action required."
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

            out-logfile -string "Setting member join and depart restrictions on the group."

            try 
            {
                out-logfile -string "Setting member join restritions on the group.."

                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID -MemberJoinRestriction $functionMemberJoinRestriction -errorAction STOP -BypassSecurityGroupManagerCheck
            }
            catch 
            {
                out-logfile "Error encountered setting member join depart restritions on the group...."

                out-logfile -string $_

                $isErrorObject = new-Object psObject -property @{
                    PrimarySMTPAddressorUPN = $originalDLConfiguration.mail
                    ExternalDirectoryObjectID = $originalDLConfiguration.'msDS-ExternalDirectoryObjectId'
                    Alias = $functionMailNickName
                    Name = $originalDLConfiguration.name
                    Attribute = "Cloud distribution list:  MemberJoinRestriction"
                    ErrorMessage = "Error setting member join restriction on the group.  Administrator action required"
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

            try 
            {
                out-logfile -string "Setting member depart restritions on the group.."

                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID -MemberDepartRestriction $functionMemberDepartRestriction -errorAction STOP -BypassSecurityGroupManagerCheck
            }
            catch 
            {
                out-logfile "Error encountered setting member join depart restritions on the group...."

                out-logfile -string $_

                $isErrorObject = new-Object psObject -property @{
                    PrimarySMTPAddressorUPN = $originalDLConfiguration.mail
                    ExternalDirectoryObjectID = $originalDLConfiguration.'msDS-ExternalDirectoryObjectId'
                    Alias = $functionMailNickName
                    Name = $originalDLConfiguration.name
                    Attribute = "Cloud distribution list:  MemberDepartRestriction"
                    ErrorMessage = "Error setting member depart restriction on the group.  Administrator action required"
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

            out-logfile -string "Setting the single valued report to settings.."

            try 
            {
                out-logfile -string "Setting the report to manager enabled.."

                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID -ReportToManagerEnabled $functionreportToOwner -BypassSecurityGroupManagerCheck -errorAction STOP       
            }
            catch 
            {
                out-logfile "Error encountered setting single valued report to settings on the group...."

                out-logfile -string $_

                $isErrorObject = new-Object psObject -property @{
                    PrimarySMTPAddressorUPN = $originalDLConfiguration.mail
                    ExternalDirectoryObjectID = $originalDLConfiguration.'msDS-ExternalDirectoryObjectId'
                    Alias = $functionMailNickName
                    Name = $originalDLConfiguration.name
                    Attribute = "Cloud distribution list:  ReportToManagerEnabled"
                    ErrorMessage = "Error setting report to manager enabled.  Administrator action required."
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

            try 
            {
                out-logfile -string "Setting the report to originator enabled.."

                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID -ReportToOriginatorEnabled $functionReportToOriginator -BypassSecurityGroupManagerCheck -errorAction STOP       
            }
            catch 
            {
                out-logfile "Error encountered setting single valued report to settings on the group...."

                out-logfile -string $_

                $isErrorObject = new-Object psObject -property @{
                    PrimarySMTPAddressorUPN = $originalDLConfiguration.mail
                    ExternalDirectoryObjectID = $originalDLConfiguration.'msDS-ExternalDirectoryObjectId'
                    Alias = $functionMailNickName
                    Name = $originalDLConfiguration.name
                    Attribute = "Cloud distribution list:  ReporToOriginatorEnabled"
                    ErrorMessage = "Error setting report to originator enabled.  Administrator action required."
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

            try 
            {
                out-logfile -string "Setting the send oof messages to originator enabled.."

                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID -SendOofMessageToOriginatorEnabled $functionoofReplyToOriginator -BypassSecurityGroupManagerCheck -errorAction STOP       
            }
            catch 
            {
                out-logfile "Error encountered setting single valued report to settings on the group...."

                out-logfile -string $_

                $isErrorObject = new-Object psObject -property @{
                    PrimarySMTPAddressorUPN = $originalDLConfiguration.mail
                    ExternalDirectoryObjectID = $originalDLConfiguration.'msDS-ExternalDirectoryObjectId'
                    Alias = $functionMailNickName
                    Name = $originalDLConfiguration.name
                    Attribute = "Cloud distribution list:  SendOOFMessagesToOriginatorEnabled"
                    ErrorMessage = "Error setting send off messages to originator enabled.  Administrator action required."
                    ErrorMessageDetail = $_
                }

                $functionErrors+=$isErrorObject
            }

            out-logfile -string "Setting the custom and extension attributes of the group."

            try 
            {
                out-logfile -string "Setting extension attribute 1 of the group."

                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID -CustomAttribute1 $originalDLConfiguration.extensionAttribute1 -BypassSecurityGroupManagerCheck -errorAction STOP        
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

                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID -CustomAttribute10 $originalDLConfiguration.extensionAttribute10 -BypassSecurityGroupManagerCheck -errorAction STOP        
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

                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID  -CustomAttribute11 $originalDLConfiguration.extensionAttribute11  -BypassSecurityGroupManagerCheck -errorAction STOP        
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

                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID -CustomAttribute12 $originalDLConfiguration.extensionAttribute12  -BypassSecurityGroupManagerCheck -errorAction STOP        
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

                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID -CustomAttribute13 $originalDLConfiguration.extensionAttribute13  -BypassSecurityGroupManagerCheck -errorAction STOP        
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

                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID -CustomAttribute14 $originalDLConfiguration.extensionAttribute14  -BypassSecurityGroupManagerCheck -errorAction STOP        
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
                out-logfile -string "Setting extension attribute 1 of the group."

                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID -CustomAttribute15 $originalDLConfiguration.extensionAttribute15  -BypassSecurityGroupManagerCheck -errorAction STOP        
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

                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID -CustomAttribute2 $originalDLConfiguration.extensionAttribute2   -BypassSecurityGroupManagerCheck -errorAction STOP        
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

                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID -CustomAttribute3 $originalDLConfiguration.extensionAttribute3   -BypassSecurityGroupManagerCheck -errorAction STOP        
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

                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID -CustomAttribute4 $originalDLConfiguration.extensionAttribute4   -BypassSecurityGroupManagerCheck -errorAction STOP        
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

                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID  -CustomAttribute5 $originalDLConfiguration.extensionAttribute5   -BypassSecurityGroupManagerCheck -errorAction STOP        
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

                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID  -CustomAttribute6 $originalDLConfiguration.extensionAttribute6   -BypassSecurityGroupManagerCheck -errorAction STOP        
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

                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID  -CustomAttribute7 $originalDLConfiguration.extensionAttribute7   -BypassSecurityGroupManagerCheck -errorAction STOP        
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

                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID  -CustomAttribute8 $originalDLConfiguration.extensionAttribute8   -BypassSecurityGroupManagerCheck -errorAction STOP        
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

                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID -CustomAttribute9 $originalDLConfiguration.extensionAttribute9   -BypassSecurityGroupManagerCheck -errorAction STOP        
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

                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID -ExtensionCustomAttribute1 $originalDLConfiguration.msExchExtensionCustomAttribute1   -BypassSecurityGroupManagerCheck -errorAction STOP        
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

                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID -ExtensionCustomAttribute2 $originalDLConfiguration.msExchExtensionCustomAttribute2   -BypassSecurityGroupManagerCheck -errorAction STOP        
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

                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID -ExtensionCustomAttribute3 $originalDLConfiguration.msExchExtensionCustomAttribute3   -BypassSecurityGroupManagerCheck -errorAction STOP        
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

                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID -ExtensionCustomAttribute4 $originalDLConfiguration.msExchExtensionCustomAttribute4   -BypassSecurityGroupManagerCheck -errorAction STOP        
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

                Set-O365DistributionGroup -Identity $functionExternalDirectoryObjectID -ExtensionCustomAttribute5 $originalDLConfiguration.msExchExtensionCustomAttribute5  -BypassSecurityGroupManagerCheck -errorAction STOP        
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