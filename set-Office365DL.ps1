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

    set-Office365DL -originalDLConfiguration DLConfiguration -groupTypeOverride TYPEOVERRIDE.

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
            $office365DLConfigurationPostMigration
        )

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
        [boolean]$functionReportToOriginator=$NULL

        [boolean]$isTestError=$FALSE
        [array]$functionErrors=@()

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN SET-Office365DL"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        Out-LogFile -string ("OriginalDLConfiguration = ")
        out-logfile -string $originalDLConfiguration
        out-logfile -string ("Group Type Override = "+$groupTypeOverride)

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

        if ($originalDLConfiguration.mailNickName -ne $NULL)
        {
            $functionMailNickname = $originalDLConfiguration.mailNickName
        }
        else 
        {
            $functionMailNickName = $office365DLConfiguration.alias    
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
            out-logfile -string "Setting core single values for the distribution group."

            Set-O365DistributionGroup -Identity $office365DLConfigurationPostMigration.externalDirectoryObjectID -Alias $functionMailNickName -DisplayName $functionDisplayName -HiddenFromAddressListsEnabled $functionHiddenFromAddressList -RequireSenderAuthenticationEnabled $functionRequireAuthToSendTo -SimpleDisplayName $functionSimpleDisplayName -WindowsEmailAddress $originalDLConfiguration.mail -MailTipTranslations $originalDLConfiguration.msExchSenderHintTranslations -Name $originalDLConfiguration.cn -BypassSecurityGroupManagerCheck -errorAction STOP
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
                Attribute = "Cloud distribution list:  Alias / DisplayName / HiddenFromAddressList / RequireSenderAuthenticaiton / SimpleDisplayName / WindowsEmailAddress / MailTipTranslations / Name"
                ErrorMessage = "Error setting single valued attribute of the migrated distribution list."
                ErrorMessageDetail = $_
            }

            $functionErrors+=$isErrorObject
        }

        try 
        {
            out-logfile -string "Setting single valued moderation propeties for the group.."

            Set-O365DistributionGroup -Identity $functionMailNickName -BypassNestedModerationEnabled $functionModerationFlags -ModerationEnabled $functionModerationEnabled -SendModerationNotifications $functionSendModerationNotifications -BypassSecurityGroupManagerCheck -errorAction STOP
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
                Attribute = "Cloud distribution list:  BypassNedstedModerationEnabled / ModerationEnabled / SendModerationNotifications"
                ErrorMessage = "Error setting additional single valued attribute of the migrated distribution group."
                ErrorMessageDetail = $_
            }

            $functionErrors+=$isErrorObject
        }

        try 
        {
            out-logfile -string "Setting member join depart restritions on the group.."

            Set-O365DistributionGroup -Identity $functionMailNickName -MemberJoinRestriction $functionMemberJoinRestriction -MemberDepartRestriction $functionMemberDepartRestriction -BypassSecurityGroupManagerCheck -errorAction STOP
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
                Attribute = "Cloud distribution list:  MemberJoinRestriction / MemberDepartRestriction"
                ErrorMessage = "Error setting join or depart restrictions."
                ErrorMessageDetail = $_
            }

            $functionErrors+=$isErrorObject
        }

        try 
        {
            out-logfile -string "Setting the single valued report to settings.."

            Set-O365DistributionGroup -Identity $functionMailNickName -ReportToManagerEnabled $functionreportToOwner -ReportToOriginatorEnabled $functionReportToOriginator -SendOofMessageToOriginatorEnabled $functionoofReplyToOriginator -BypassSecurityGroupManagerCheck -errorAction STOP       
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
                Attribute = "Cloud distribution list:  ReportToManagerEnabled / ReportToOriginatorEnabled / SendOOFMessageToOriginatorEnabled"
                ErrorMessage = "Error setting report to attributes."
                ErrorMessageDetail = $_
            }

            $functionErrors+=$isErrorObject
        }

        try 
        {
            out-logfile -string "Setting the custom and extension attributes of the group."

            Set-O365DistributionGroup -Identity $functionMailNickName -CustomAttribute1 $originalDLConfiguration.extensionAttribute1 -CustomAttribute10 $originalDLConfiguration.extensionAttribute10 -CustomAttribute11 $originalDLConfiguration.extensionAttribute11 -CustomAttribute12 $originalDLConfiguration.extensionAttribute12 -CustomAttribute13 $originalDLConfiguration.extensionAttribute13 -CustomAttribute14 $originalDLConfiguration.extensionAttribute14 -CustomAttribute15 $originalDLConfiguration.extensionAttribute15 -CustomAttribute2 $originalDLConfiguration.extensionAttribute2 -CustomAttribute3 $originalDLConfiguration.extensionAttribute3 -CustomAttribute4 $originalDLConfiguration.extensionAttribute4 -CustomAttribute5 $originalDLConfiguration.extensionAttribute5 -CustomAttribute6 $originalDLConfiguration.extensionAttribute6 -CustomAttribute7 $originalDLConfiguration.extensionAttribute7 -CustomAttribute8 $originalDLConfiguration.extensionAttribute8 -CustomAttribute9 $originalDLConfiguration.extensionAttribute9 -ExtensionCustomAttribute1 $originalDLConfiguration.msExtensionCustomAttribute1 -ExtensionCustomAttribute2 $originalDLConfiguration.msExtensionCustomAttribute2 -ExtensionCustomAttribute3 $originalDLConfiguration.msExtensionCustomAttribute3 -ExtensionCustomAttribute4 $originalDLConfiguration.msExtensionCustomAttribute4 -ExtensionCustomAttribute5 $originalDLConfiguration.msExtensionCustomAttribute5 -BypassSecurityGroupManagerCheck -errorAction STOP        
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
                Attribute = "Cloud distribution list:  CustomAttributeX / ExtensionAttributeX"
                ErrorMessage = "Error setting custom or extension attributes."
                ErrorMessageDetail = $_
            }

            $functionErrors+=$isErrorObject
        }

        Out-LogFile -string "END SET-Office365DL"
        Out-LogFile -string "********************************************************************************"

        out-logfile -string ("The number of function errors is: "+$functionerrors.count )
        $global:postCreateErrors += $functionErrors
    }