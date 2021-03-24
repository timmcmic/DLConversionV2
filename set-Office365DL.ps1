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
            [string]$groupTypeOverride
        )

        #Declare function variables.

        $functionMemberDepartRestrictionType=$NULL #Holds the return information for the group query.
        $functionModerationFlags=$NULL
        $functionSendModerationNotifications=$NULL

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN SET-Office365DL"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        Out-LogFile -string ("OriginalDLConfiguration = ")
        out-logfile -string $originalDLConfiguration
        out-logfile -string ("Group Type Override = "+$groupTypeOverride)

        #If the group type was overridden from the default - the member join restriction has to be adjusted.

        if ( $groupTypeOverride -eq "Security" )
		{
			$functionMemberDepartRestriction = "Closed"

            out-logfile -string ("Function member depart restrictions = "+$functionMemberDepartRestriction)
		}
		else 
		{
			$functionMemberDepartRestriction = $originalDLConfiguration.msExchGroupDepartRestriction

            out-logfile -string ("Function member depart restrictions = "+$functionMemberDepartRestriction)
		}

        #The moderation settings a are a hash valued flag.

        #Create the distribution group in office 365.

        if (($originalDLConfiguration.msExchModerationFlags -eq "1") -or ($originalDLConfiguration.msExchModerationFlags -eq "3") -or ($originalDLConfiguration.msExchModerationFlags -eq "7") )
        {
            out-logfile -string ("The moderation flags are 1 / 3 / 7 - setting bypass nested moderation to TRUE"+$originalDLConfiguration.msExchModerationFlags)

            $functionModerationFlags=$TRUE

            out-logfile ("The function moderation flags are = "+$functionModerationFlags)
        }
        else 
        {
            $functionModerationFlags=$FALSE
        }

        if (($originalDLConfiguration.msExchModerationFlags -eq "0") -or ($originalDLConfiguration.msExchModerationFlags -eq "1")  )
        {
            out-logfile -string ("The moderation flags are 0 / 2 / 6 - setting bypass nested moderation to TRUE"+$originalDLConfiguration.msExchModerationFlags)

            $functionSendModerationNotifications="Never"

            out-logfile -string ("The function send moderations notifications is ="+$functionSendModerationNotifications)
        }
        elseif (($originalDLConfiguration.msExchModerationFlags -eq "2") -or ($originalDLConfiguration.msExchModerationFlags -eq "3")  )
        {
            out-logfile -string ("The moderation flags are 0 / 2 / 6 - setting bypass nested moderation to TRUE"+$originalDLConfiguration.msExchModerationFlags)

            $functionSendModerationNotifications="Internal"

            out-logfile -string ("The function send moderations notifications is ="+$functionSendModerationNotifications)

        }
        elseif (($originalDLConfiguration.msExchModerationFlags -eq "6") -or ($originalDLConfiguration.msExchModerationFlags -eq "7")  )
        {
            out-logfile -string ("The moderation flags are 0 / 2 / 6 - setting bypass nested moderation to TRUE"+$originalDLConfiguration.msExchModerationFlags)

            $functionSendModerationNotifications="Always"

            out-logfile -string ("The function send moderations notifications is ="+$functionSendModerationNotifications)
        }
        
        try 
        {
            out-logfile -string "Setting the single value settings for the distribution group."

            Set-O365DistributionGroup -Identity $originalDLConfiguration.mailNickName -BypassNestedModerationEnabled $functionModerationFlags -MemberJoinRestriction $originalDLConfiguration.msExchGroupJoinRestriction -MemberDepartRestriction $functionMemberDepartRestriction -ReportToManagerEnabled $originalDLConfiguration.reportToOwner -ReportToOriginatorEnabled $originalDLConfiguration.reportToOriginator -SendOofMessageToOriginatorEnabled $originalDLConfiguration.oofReplyToOriginator -Alias $originalDLConfiguration.mailNickName -CustomAttribute1 $originalDLConfiguration.extensionAttribute1 -CustomAttribute10 $originalDLConfiguration.extensionAttribute10 -CustomAttribute11 $originalDLConfiguration.extensionAttribute11 -CustomAttribute12 $originalDLConfiguration.extensionAttribute12 -CustomAttribute13 $originalDLConfiguration.extensionAttribute13 -CustomAttribute14 $originalDLConfiguration.extensionAttribute14 -CustomAttribute15 $originalDLConfiguration.extensionAttribute15 -CustomAttribute2 $originalDLConfiguration.extensionAttribute2 -CustomAttribute3 $originalDLConfiguration.extensionAttribute3 -CustomAttribute4 $originalDLConfiguration.extensionAttribute4 -CustomAttribute5 $originalDLConfiguration.extensionAttribute5 -CustomAttribute6 $originalDLConfiguration.extensionAttribute6 -CustomAttribute7 $originalDLConfiguration.extensionAttribute7 -CustomAttribute8 $originalDLConfiguration.extensionAttribute8 -CustomAttribute9 $originalDLConfiguration.extensionAttribute9 -ExtensionCustomAttribute1 $originalDLConfiguration.msExtensionCustomAttribute1 -ExtensionCustomAttribute2 $originalDLConfiguration.msExtensionCustomAttribute2 -ExtensionCustomAttribute3 $originalDLConfiguration.msExtensionCustomAttribute3 -ExtensionCustomAttribute4 $originalDLConfiguration.msExtensionCustomAttribute4 -ExtensionCustomAttribute5 $originalDLConfiguration.msExtensionCustomAttribute5 -DisplayName $originalDLConfiguration.DisplayName -HiddenFromAddressListsEnabled $originalDLConfiguration.msExchHideFromAddressLists -ModerationEnabled $originalDLConfiguration.msExchEnableModeration -RequireSenderAuthenticationEnabled $originalDLConfiguration.msExchRequireAuthToSendTo -SimpleDisplayName $originalDLConfiguration.DisplayNamePrintable -SendModerationNotifications $functionSendModerationNotification -WindowsEmailAddress $originalDLConfiguration.mail -MailTipTranslations $originalDLConfiguration.msExchSenderHintTranslations -Name $originalDLConfiguration.cn
        }
        catch 
        {
            Out-LogFile -string $_ -isError:$TRUE
        }

        Out-LogFile -string "END SET-Office365DL"
        Out-LogFile -string "********************************************************************************"
    }