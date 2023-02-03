function compare-recipientProperties
{
    param(
        [Parameter(Mandatory = $false)]
        $onPremData=$NULL,
        [Parameter(Mandatory = $false)]
        $azureData=$NULL,
        [Parameter(Mandatory = $false)]
        $office365Data=$NULL
    )

    $functionReturnArray=@()
    $functionGroupType = $NULL
    $functionModerationFlags = $NULL
    $functionMemberJoinRestriction=$NULL
    $functionreportToOwner=$NULL
    $functionReportToOriginator=$NULL
    $functionoofReplyToOriginator=$NULL
    $functionHiddenFromAddressListEnabled =$NULL


    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "BEGIN compare-recipientProperties"
    Out-LogFile -string "********************************************************************************"

    out-logfile -string "Begin compare group type."

    if (($onPremData.groupType -eq "-2147483640") -or ($onPremData.groupType -eq "-2147483646") -or ($onPremData.groupType -eq "-2147483644"))
    {
        out-logfile -string $onPremData.groupType
        $functionGroupType = "Universal, SecurityEnabled"
        out-logfile -string $functionGroupType
    }
    else 
    {
        $functionGroupType = "Universal"
    }

    if ($office365Data.groupType -eq $functionGroupType)
    {
        out-logfile -string "Group type valid."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "GroupType"
            onpremisesvalue = $functionGroupType
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.groupType            
            isValidInExchangeOnline = "True"
            IsValidMember = "TRUE"
            ErrorMessage = "N/A"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }
    else 
    {
        out-logfile -string "Group type invalid."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "GroupType"
            onpremisesvalue = $functionGroupType
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.groupType            
            isValidInExchangeOnline = "True"
            IsValidMember = "FALSE"
            ErrorMessage = "VALUE_ONPREMISES_NOT_EQUAL_OFFICE365_EXCEPTION"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    out-logfile -string "Evaluate bypass nested moderation enabled."

    if (($onPremData.msExchModerationFlags -eq "1") -or ($onPremData.msExchModerationFlags -eq "3") -or ($onPremData.msExchModerationFlags -eq "7") )
    {
        out-logfile -string $onPremData.msExchModerationFlags

        $functionModerationFlags = $TRUE

        out-logfile -string $functionModerationFlags
    }
    else 
    {
        out-logfile -string $onPremData.msExchModerationFlags

        $functionModerationFlags = $FALSE

        out-logfile -string $functionModerationFlags
    }

    if ($office365Data.BypassNestedModerationEnabled -eq $functionModerationFlags)
    {
        out-logfile -string "Bypass nested moderation enabled valid."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "BypassNestedModerationEnabled"
            onpremisesvalue = $functionModerationFlags
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.bypassNestedModerationEnabled           
            isValidInExchangeOnline = "True"
            IsValidMember = "TRUE"
            ErrorMessage = "N/A"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }
    else 
    {
        out-logfile -string "Bypass nested moderation enabled invalid."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "BypassNestedModerationEnabled"
            onpremisesvalue = $functionModerationFlags
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.bypassNestedModerationEnabled           
            isValidInExchangeOnline = "False"
            IsValidMember = "FALSE"
            ErrorMessage = "VALUE_ONPREMISES_NOT_EQUAL_OFFICE365_EXCEPTION"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    out-logfile -string "Evaluate member join restrictions."

    if ($onPremData.msExchGroupJoinRestriction -eq $NULL)
    {
        $functionMemberJoinRestriction="Closed"

        out-logfile -string $functionMemberJoinRestriction
    }
    elseif ($onPremData.msExchGroupJoinRestriction -eq 0)
    {
        out-logfile -string $onPremData.msExchGroupJoinRestriction

        $functionMemberJoinRestriction = "Closed"

        out-logfile -string $functionMemberJoinRestriction
    }
    else 
    {
        out-logfile -string $onPremData.msExchGroupJoinRestriction

        $functionMemberJoinRestriction = "ApprovalRequired"

        out-logfile -string $functionMemberJoinRestriction
    }

    if ($office365Data.MemberJoinRestriction -eq $functionMemberJoinRestriction)
    {
        out-logfile -string "Member join restriction is a valid value."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "MemberJoinRestriction"
            onpremisesvalue = $functionMemberJoinRestriction
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.MemberJoinRestriction          
            isValidInExchangeOnline = "True"
            IsValidMember = "TRUE"
            ErrorMessage = "N/A"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }
    else 
    {
        out-logfile -string "Member join restriction is a invalid value."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "MemberJoinRestriction"
            onpremisesvalue = $functionMemberJoinRestriction
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.MemberJoinRestriction          
            isValidInExchangeOnline = "False"
            IsValidMember = "FALSE"
            ErrorMessage = "VALUE_ONPREMISES_NOT_EQUAL_OFFICE365_EXCEPTION"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject    
    }

    out-logfile -string "Evaluate member depart restriction."

    if ($onPremData.msExchGroupDepartRestriction -eq $NULL)
    {
        $functionMemberDepartRestriction = "Closed"

        out-logfile -string $functionMemberDepartRestriction
    }
    elseif ($onPremData.msExchGroupDepartRestriction -eq 0)
    {
        out-logfile -string $onPremData.msExchGroupDepartRestriction

        $functionMemberDepartRestriction = "Closed"

        out-logfile -string $functionMemberDepartRestriction
    }
    else
    {
        out-logfile -string $onPremData.msExchGroupDepartRestriction

        $functionMemberDepartRestriction = "Open"

        out-logfile -string $functionMemberDepartRestriction
    }

    if ($office365Data.MemberDepartRestriction -eq $functionMemberDepartRestriction)
    {
        out-logfile -string "Member depart restriction value is valid."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "MemberDepartRestriction"
            onpremisesvalue = $functionMemberDepartRestriction
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.MemberDepartRestriction          
            isValidInExchangeOnline = "True"
            IsValidMember = "TRUE"
            ErrorMessage = "N/A"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }
    else
    {
        out-logfile -string "Member depart restriction value is not valid."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "MemberJoinRestriction"
            onpremisesvalue = $functionMemberJoinRestriction
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.MemberJoinRestriction          
            isValidInExchangeOnline = "False"
            IsValidMember = "FALSE"
            ErrorMessage = "VALUE_ONPREMISES_NOT_EQUAL_OFFICE365_EXCEPTION"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    out-logfile -string "Evaluate report to manager enabled."

    if ($onPremData.reportToOwner -eq $NULL)    
    {
        $functionreportToOwner = $FALSE

        out-logfile -string $functionreportToOwner
    }
    else 
    {
        out-logfile -string $onPremData.reportToOwner

        $functionReportToOwner = $onPremData.reportToOwner
    }

    if ($office365Data.ReportToManagerEnabled -eq $functionReportToOwner)
    {
        out-logfile -string "Report to manager enabled value is valid."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "ReportToManagerEnabled"
            onpremisesvalue = $functionreportToOwner
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.ReportToManagerEnabled          
            isValidInExchangeOnline = "True"
            IsValidMember = "TRUE"
            ErrorMessage = "N/A"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }
    else 
    {
        out-logfile -string "Report to manager enabled value is not valid."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "ReportToManagerEnabled"
            onpremisesvalue = $functionreportToOwner
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.ReportToManagerEnabled          
            isValidInExchangeOnline = "False"
            IsValidMember = "FALSE"
            ErrorMessage = "VALUE_ONPREMISES_NOT_EQUAL_OFFICE365_EXCEPTION"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    out-logfile -string "Evaluate report to originator enabled."

    if ($onPremData.reportToOriginator -eq $NULL)
    {
        $functionReportToOriginator = $FALSE

        out-logfile -string $functionReportToOriginator
    }
    else 
    {
        out-logfile -string $onPremData.reportToOriginator

        $functionReportToOriginator = $onPremData.reportToOriginator

        out-logfile -string $functionReportToOriginator
    }

    if ($office365Data.ReportToOriginatorEnabled -eq $functionReportToOriginator)
    {
        out-logfile -string "Report to originator enabled value is valid."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "ReportToOriginatorEnabled"
            onpremisesvalue = $functionReportToOriginator
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.ReportToOriginatorEnabled         
            isValidInExchangeOnline = "True"
            IsValidMember = "TRUE"
            ErrorMessage = "N/A"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }
    else 
    {
        out-logfile -string "Report to originator enabled value is invalid."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "ReportToOriginatorEnabled"
            onpremisesvalue = $functionReportToOriginator
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.ReportToOriginatorEnabled         
            isValidInExchangeOnline = "False"
            IsValidMember = "FALSE"
            ErrorMessage = "VALUE_ONPREMISES_NOT_EQUAL_OFFICE365_EXCEPTION"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    out-logfile -string "Evaluating OOF reply to originator."

    if ($onPremData.oofReplyToOriginator -eq $NULL)
    {
        $functionoofReplyToOriginator = $FALSE

        out-logfile -string $functionoofReplyToOriginator
    }
    else 
    {
        out-logfile -string $onPremData.oofReplyToOriginator

        $functionoofReplyToOriginator = $onPremData.oofReplyToOriginator

        out-logfile -string $functionoofReplyToOriginator
    }

    if ($office365Data.SendOofMessageToOriginatorEnabled -eq $functionoofReplyToOriginator)
    {
        out-logfile -string "Send OOF messages to originator enabled value is valid."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "SendOofMessageToOriginatorEnabled"
            onpremisesvalue = $functionoofReplyToOriginator
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.SendOofMessageToOriginatorEnabled        
            isValidInExchangeOnline = "True"
            IsValidMember = "TRUE"
            ErrorMessage = "N/A"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }
    else 
    {
        out-logfile -string "Send OOF messages to originator enabled value is not valid."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "SendOofMessageToOriginatorEnabled"
            onpremisesvalue = $functionoofReplyToOriginator
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.SendOofMessageToOriginatorEnabled        
            isValidInExchangeOnline = "False"
            IsValidMember = "FALSE"
            ErrorMessage = "VALUE_ONPREMISES_NOT_EQUAL_OFFICE365_EXCEPTION"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    out-logfile -string "Evaluating mail nickname / alias."

    if ($onPremData.MailNickName -eq $NULL)
    {
        $onPremData.mailNickName = "!*NotSet*!"
    }
    elseif($onPremData.mailnickname -eq "")
    {
        $onPremData.mailNickName = "!*NotSet*!"
    }

    if ($azureData.mailNickName -eq $NULL)
    {
        $azureData.mailNickName = "!*NotSet*!"
    }
    elseif ($azureData.mailNickName -eq "")
    {
        $azureData.mailNickName = "!*NotSet*!"
    }

    if ($office365Data.alias -eq $NULL)
    {
        $office365Data.alias = "!*NotSet*!"
    }
    elseif ($office365Data.alias -eq "")
    {
        $office365Data.alias = "!*NotSet*!"
    }

    if ($onPremData.mailNickName -eq $azureData.mailNickName)
    {
        out-logfile -string "On premises mail nickname value = azure value."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "Alias / MailNickName"
            onpremisesvalue = $onPremData.mailNickName
            AzureADValue = $azureData.mailNickName
            isValidInAzure = "True"
            ExchangeOnlineValue = "N/A"       
            isValidInExchangeOnline = "N/A"
            IsValidMember = "FALSE"
            ErrorMessage = "N/A"
        }

        if ($azureData.mailNickName -eq $office365Data.alias)
        {
            out-logfile -string "Azure AD mail nickname value = exchange online alias."

            $functionObject.exchangeOnlineValue = $office365Data.Alias
            $functionObject.isValidInExchangeOnline = "True"
            $functionObject.isValidMember = "TRUE"

            out-logfile -string $functionObject

            $functionReturnArray += $functionObject
        }
        else 
        {
            out-logfile -string "Azure AD mail nickname value not equal exchange online value."

            $functionObject.errorMessage = "VALUE_AZUREAD_NOT_EQUAL_OFFICE365_EXCEPTION"

            out-logfile -string $functionObject

            $functionReturnArray += $functionObject
        }
    }
    else
    {
        out-logfile -string "On premises mail nickname value not equal azure value."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "Alias / MailNickName"
            onpremisesvalue = $onPremData.mailNickName
            AzureADValue = $azureData.mailNickName
            isValidInAzure = "False"
            ExchangeOnlineValue = "N/A"       
            isValidInExchangeOnline = "N/A"
            IsValidMember = "FALSE"
            ErrorMessage = "VALUE_ONPREMISES_NOT_EQUAL_AZURE_EXCEPTION"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    Out-logfile -string "Evaluating extension attributes."

    if ($onPremData.extensionAttribute1 -eq $NULL)
    {
        $onPremData.extensionAttribute1 = "!*NotSet*!"
    }
    elseif ($onPremData.extensionAttribute1 -eq "")
    {
        $onPremData.extensionAttribute1 = "!*NotSet*!"
    }

    if ($onPremData.extensionAttribute2 -eq $NULL)
    {
        $onPremData.extensionAttribute2 = "!*NotSet*!"
    }
    elseif ($onPremData.extensionAttribute2 -eq "")
    {
        $onPremData.extensionAttribute2 = "!*NotSet*!"
    }

    if ($onPremData.extensionAttribute3 -eq $NULL)
    {
        $onPremData.extensionAttribute3 = "!*NotSet*!"
    }
    elseif ($onPremData.extensionAttribute3 -eq "")
    {
        $onPremData.extensionAttribute3 = "!*NotSet*!"
    }

    if ($onPremData.extensionAttribute4 -eq $NULL)
    {
        $onPremData.extensionAttribute4 = "!*NotSet*!"
    }
    elseif ($onPremData.extensionAttribute4 -eq "")
    {
        $onPremData.extensionAttribute4 = "!*NotSet*!"
    }

    if ($onPremData.extensionAttribute5 -eq $NULL)
    {
        $onPremData.extensionAttribute5 = "!*NotSet*!"
    }
    elseif ($onPremData.extensionAttribute5 -eq "")
    {
        $onPremData.extensionAttribute5 = "!*NotSet*!"
    }

    if ($onPremData.extensionAttribute6 -eq $NULL)
    {
        $onPremData.extensionAttribute6 = "!*NotSet*!"
    }
    elseif ($onPremData.extensionAttribute6 -eq "")
    {
        $onPremData.extensionAttribute6 = "!*NotSet*!"
    }

    if ($onPremData.extensionAttribute7 -eq $NULL)
    {
        $onPremData.extensionAttribute7 = "!*NotSet*!"
    }
    elseif ($onPremData.extensionAttribute7 -eq "")
    {
        $onPremData.extensionAttribute7 = "!*NotSet*!"
    }

    if ($onPremData.extensionAttribute8 -eq $NULL)
    {
        $onPremData.extensionAttribute8 = "!*NotSet*!"
    }
    elseif ($onPremData.extensionAttribute8 -eq "")
    {
        $onPremData.extensionAttribute8 = "!*NotSet*!"
    }

    if ($onPremData.extensionAttribute9 -eq $NULL)
    {
        $onPremData.extensionAttribute9 = "!*NotSet*!"
    }
    elseif ($onPremData.extensionAttribute9 -eq "")
    {
        $onPremData.extensionAttribute9 = "!*NotSet*!"
    }

    if ($onPremData.extensionAttribute10 -eq $NULL)
    {
        $onPremData.extensionAttribute10 = "!*NotSet*!"
    }
    elseif ($onPremData.extensionAttribute10 -eq "")
    {
        $onPremData.extensionAttribute10 = "!*NotSet*!"
    }

    if ($onPremData.extensionAttribute11 -eq $NULL)
    {
        $onPremData.extensionAttribute11 = "!*NotSet*!"
    }
    elseif ($onPremData.extensionAttribute11 -eq "")
    {
        $onPremData.extensionAttribute11 = "!*NotSet*!"
    }

    if ($onPremData.extensionAttribute12 -eq $NULL)
    {
        $onPremData.extensionAttribute12 = "!*NotSet*!"
    }
    elseif ($onPremData.extensionAttribute12 -eq "")
    {
        $onPremData.extensionAttribute12 = "!*NotSet*!"
    }

    if ($onPremData.extensionAttribute13 -eq $NULL)
    {
        $onPremData.extensionAttribute13 = "!*NotSet*!"
    }
    elseif ($onPremData.extensionAttribute13 -eq "")
    {
        $onPremData.extensionAttribute13 = "!*NotSet*!"
    }

    if ($onPremData.extensionAttribute14 -eq $NULL)
    {
        $onPremData.extensionAttribute14 = "!*NotSet*!"
    }
    elseif ($onPremData.extensionAttribute14 -eq "")
    {
        $onPremData.extensionAttribute14 = "!*NotSet*!"
    }

    if ($onPremData.extensionAttribute15 -eq $NULL)
    {
        $onPremData.extensionAttribute15 = "!*NotSet*!"
    }
    elseif ($onPremData.extensionAttribute15 -eq "")
    {
        $onPremData.extensionAttribute15 = "!*NotSet*!"
    }

    Out-logfile -string "Evaluating extension attributes."

    if ($office365Data.customAttribute1 -eq $NULL)
    {
        $office365Data.customAttribute1 = "!*NotSet*!"
    }
    elseif ($office365Data.customAttribute1 -eq "")
    {
        $office365Data.customAttribute1 = "!*NotSet*!"
    }

    if ($office365Data.customAttribute2 -eq $NULL)
    {
        $office365Data.customAttribute2 = "!*NotSet*!"
    }
    elseif ($office365Data.customAttribute2 -eq "")
    {
        $office365Data.customAttribute2 = "!*NotSet*!"
    }

    if ($office365Data.customAttribute3 -eq $NULL)
    {
        $office365Data.customAttribute3 = "!*NotSet*!"
    }
    elseif ($office365Data.customAttribute3 -eq "")
    {
        $office365Data.customAttribute3 = "!*NotSet*!"
    }

    if ($office365Data.customAttribute4 -eq $NULL)
    {
        $office365Data.customAttribute4 = "!*NotSet*!"
    }
    elseif ($office365Data.customAttribute4 -eq "")
    {
        $office365Data.customAttribute4 = "!*NotSet*!"
    }

    if ($office365Data.customAttribute5 -eq $NULL)
    {
        $office365Data.customAttribute5 = "!*NotSet*!"
    }
    elseif ($office365Data.customAttribute5 -eq "")
    {
        $office365Data.customAttribute5 = "!*NotSet*!"
    }

    if ($office365Data.customAttribute6 -eq $NULL)
    {
        $office365Data.customAttribute6 = "!*NotSet*!"
    }
    elseif ($office365Data.customAttribute6 -eq "")
    {
        $office365Data.customAttribute6 = "!*NotSet*!"
    }

    if ($office365Data.customAttribute7 -eq $NULL)
    {
        $office365Data.customAttribute7 = "!*NotSet*!"
    }
    elseif ($office365Data.customAttribute7 -eq "")
    {
        $office365Data.customAttribute7 = "!*NotSet*!"
    }

    if ($office365Data.customAttribute8 -eq $NULL)
    {
        $office365Data.customAttribute8 = "!*NotSet*!"
    }
    elseif ($office365Data.customAttribute8 -eq "")
    {
        $office365Data.customAttribute8 = "!*NotSet*!"
    }

    if ($office365Data.customAttribute9 -eq $NULL)
    {
        $office365Data.customAttribute9 = "!*NotSet*!"
    }
    elseif ($office365Data.customAttribute9 -eq "")
    {
        $office365Data.customAttribute9 = "!*NotSet*!"
    }

    if ($office365Data.customAttribute10 -eq $NULL)
    {
        $office365Data.customAttribute10 = "!*NotSet*!"
    }
    elseif ($office365Data.customAttribute10 -eq "")
    {
        $office365Data.customAttribute10 = "!*NotSet*!"
    }

    if ($office365Data.customAttribute11 -eq $NULL)
    {
        $office365Data.customAttribute11 = "!*NotSet*!"
    }
    elseif ($office365Data.customAttribute11 -eq "")
    {
        $office365Data.customAttribute11 = "!*NotSet*!"
    }

    if ($office365Data.customAttribute12 -eq $NULL)
    {
        $office365Data.customAttribute12 = "!*NotSet*!"
    }
    elseif ($office365Data.customAttribute12 -eq "")
    {
        $office365Data.customAttribute12 = "!*NotSet*!"
    }

    if ($office365Data.customAttribute13 -eq $NULL)
    {
        $office365Data.customAttribute13 = "!*NotSet*!"
    }
    elseif ($office365Data.customAttribute13 -eq "")
    {
        $office365Data.customAttribute13 = "!*NotSet*!"
    }

    if ($office365Data.customAttribute14 -eq $NULL)
    {
        $office365Data.customAttribute14 = "!*NotSet*!"
    }
    elseif ($office365Data.customAttribute14 -eq "")
    {
        $office365Data.customAttribute14 = "!*NotSet*!"
    }

    if ($office365Data.customAttribute15 -eq $NULL)
    {
        $office365Data.customAttribute15 = "!*NotSet*!"
    }
    elseif ($office365Data.customAttribute15 -eq "")
    {
        $office365Data.customAttribute15 = "!*NotSet*!"
    }

    if ($onPremData.extensionAttribute1 -eq $office365Data.customAttribute1)
    {
        out-logfile -string "On premises and exchange online value are valid.."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "CustomAttribute1"
            onpremisesvalue = $onPremData.extensionAttribute1
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.customAttribute1      
            isValidInExchangeOnline = "True"
            IsValidMember = "True"
            ErrorMessage = "N/A"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }
    else 
    {
        out-logfile -string "On premises and exchange online value are not valid.."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "CustomAttribute1"
            onpremisesvalue = $onPremData.extensionAttribute1
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.customAttribute1      
            isValidInExchangeOnline = "False"
            IsValidMember = "False"
            ErrorMessage = "VALUE_ONPREMISES_NOT_EQUAL_OFFICE365_EXCEPTION"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    if ($onPremData.extensionAttribute2 -eq $office365Data.customAttribute2)
    {
        out-logfile -string "On premises and exchange online value are valid.."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "CustomAttribute2"
            onpremisesvalue = $onPremData.extensionAttribute2
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.customAttribute2      
            isValidInExchangeOnline = "True"
            IsValidMember = "True"
            ErrorMessage = "N/A"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }
    else 
    {
        out-logfile -string "On premises and exchange online value are not valid.."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "CustomAttribute2"
            onpremisesvalue = $onPremData.extensionAttribute2
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.customAttribute2      
            isValidInExchangeOnline = "False"
            IsValidMember = "False"
            ErrorMessage = "VALUE_ONPREMISES_NOT_EQUAL_OFFICE365_EXCEPTION"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    if ($onPremData.extensionAttribute3 -eq $office365Data.customAttribute3)
    {
        out-logfile -string "On premises and exchange online value are valid.."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "CustomAttribute3"
            onpremisesvalue = $onPremData.extensionAttribute3
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.customAttribute3 
            isValidInExchangeOnline = "True"
            IsValidMember = "True"
            ErrorMessage = "N/A"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }
    else 
    {
        out-logfile -string "On premises and exchange online value are not valid.."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "CustomAttribute3"
            onpremisesvalue = $onPremData.extensionAttribute3
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.customAttribute3      
            isValidInExchangeOnline = "False"
            IsValidMember = "False"
            ErrorMessage = "VALUE_ONPREMISES_NOT_EQUAL_OFFICE365_EXCEPTION"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    if ($onPremData.extensionAttribute4 -eq $office365Data.customAttribute4)
    {
        out-logfile -string "On premises and exchange online value are valid.."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "CustomAttribute4"
            onpremisesvalue = $onPremData.extensionAttribute4
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.customAttribute4     
            isValidInExchangeOnline = "True"
            IsValidMember = "True"
            ErrorMessage = "N/A"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }
    else 
    {
        out-logfile -string "On premises and exchange online value are not valid.."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "CustomAttribute4"
            onpremisesvalue = $onPremData.extensionAttribute4
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.customAttribute4     
            isValidInExchangeOnline = "False"
            IsValidMember = "False"
            ErrorMessage = "VALUE_ONPREMISES_NOT_EQUAL_OFFICE365_EXCEPTION"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    
    if ($onPremData.extensionAttribute5 -eq $office365Data.customAttribute5)
    {
        out-logfile -string "On premises and exchange online value are valid.."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "CustomAttribute5"
            onpremisesvalue = $onPremData.extensionAttribute5
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.customAttribute5
            isValidInExchangeOnline = "True"
            IsValidMember = "True"
            ErrorMessage = "N/A"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }
    else 
    {
        out-logfile -string "On premises and exchange online value are not valid.."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "CustomAttribute5"
            onpremisesvalue = $onPremData.extensionAttribute5
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.customAttribute5
            isValidInExchangeOnline = "False"
            IsValidMember = "False"
            ErrorMessage = "VALUE_ONPREMISES_NOT_EQUAL_OFFICE365_EXCEPTION"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    if ($onPremData.extensionAttribute6 -eq $office365Data.customAttribute6)
    {
        out-logfile -string "On premises and exchange online value are valid.."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "CustomAttribute6"
            onpremisesvalue = $onPremData.extensionAttribute6
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.customAttribute6
            isValidInExchangeOnline = "True"
            IsValidMember = "True"
            ErrorMessage = "N/A"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }
    else 
    {
        out-logfile -string "On premises and exchange online value are not valid.."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "CustomAttribute6"
            onpremisesvalue = $onPremData.extensionAttribute6
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.customAttribute6
            isValidInExchangeOnline = "False"
            IsValidMember = "False"
            ErrorMessage = "VALUE_ONPREMISES_NOT_EQUAL_OFFICE365_EXCEPTION"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    if ($onPremData.extensionAttribute7 -eq $office365Data.customAttribute7)
    {
        out-logfile -string "On premises and exchange online value are valid.."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "CustomAttribute7"
            onpremisesvalue = $onPremData.extensionAttribute7
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.customAttribute7
            isValidInExchangeOnline = "True"
            IsValidMember = "True"
            ErrorMessage = "N/A"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }
    else 
    {
        out-logfile -string "On premises and exchange online value are not valid.."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "CustomAttribute7"
            onpremisesvalue = $onPremData.extensionAttribute7
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.customAttribute7
            isValidInExchangeOnline = "False"
            IsValidMember = "False"
            ErrorMessage = "VALUE_ONPREMISES_NOT_EQUAL_OFFICE365_EXCEPTION"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    if ($onPremData.extensionAttribute8 -eq $office365Data.customAttribute8)
    {
        out-logfile -string "On premises and exchange online value are valid.."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "CustomAttribute8"
            onpremisesvalue = $onPremData.extensionAttribute8
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.customAttribute8
            isValidInExchangeOnline = "True"
            IsValidMember = "True"
            ErrorMessage = "N/A"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }
    else 
    {
        out-logfile -string "On premises and exchange online value are not valid.."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "CustomAttribute8"
            onpremisesvalue = $onPremData.extensionAttribute8
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.customAttribute8
            isValidInExchangeOnline = "False"
            IsValidMember = "False"
            ErrorMessage = "VALUE_ONPREMISES_NOT_EQUAL_OFFICE365_EXCEPTION"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    if ($onPremData.extensionAttribute9 -eq $office365Data.customAttribute9)
    {
        out-logfile -string "On premises and exchange online value are valid.."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "CustomAttribute9"
            onpremisesvalue = $onPremData.extensionAttribute9
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.customAttribute9
            isValidInExchangeOnline = "True"
            IsValidMember = "True"
            ErrorMessage = "N/A"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }
    else 
    {
        out-logfile -string "On premises and exchange online value are not valid.."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "CustomAttribute9"
            onpremisesvalue = $onPremData.extensionAttribute9
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.customAttribute9
            isValidInExchangeOnline = "False"
            IsValidMember = "False"
            ErrorMessage = "VALUE_ONPREMISES_NOT_EQUAL_OFFICE365_EXCEPTION"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    if ($onPremData.extensionAttribute10 -eq $office365Data.customAttribute10)
    {
        out-logfile -string "On premises and exchange online value are valid.."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "CustomAttribute10"
            onpremisesvalue = $onPremData.extensionAttribute10
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.customAttribute10
            isValidInExchangeOnline = "True"
            IsValidMember = "True"
            ErrorMessage = "N/A"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }
    else 
    {
        out-logfile -string "On premises and exchange online value are not valid.."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "CustomAttribute10"
            onpremisesvalue = $onPremData.extensionAttribute10
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.customAttribute10
            isValidInExchangeOnline = "False"
            IsValidMember = "False"
            ErrorMessage = "VALUE_ONPREMISES_NOT_EQUAL_OFFICE365_EXCEPTION"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    if ($onPremData.extensionAttribute11 -eq $office365Data.customAttribute11)
    {
        out-logfile -string "On premises and exchange online value are valid.."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "CustomAttribute11"
            onpremisesvalue = $onPremData.extensionAttribute11
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.customAttribute11
            isValidInExchangeOnline = "True"
            IsValidMember = "True"
            ErrorMessage = "N/A"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }
    else 
    {
        out-logfile -string "On premises and exchange online value are not valid.."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "CustomAttribute11"
            onpremisesvalue = $onPremData.extensionAttribute11
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.customAttribute11
            isValidInExchangeOnline = "False"
            IsValidMember = "False"
            ErrorMessage = "VALUE_ONPREMISES_NOT_EQUAL_OFFICE365_EXCEPTION"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    if ($onPremData.extensionAttribute12 -eq $office365Data.customAttribute12)
    {
        out-logfile -string "On premises and exchange online value are valid.."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "CustomAttribute12"
            onpremisesvalue = $onPremData.extensionAttribute12
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.customAttribute12
            isValidInExchangeOnline = "True"
            IsValidMember = "True"
            ErrorMessage = "N/A"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }
    else 
    {
        out-logfile -string "On premises and exchange online value are not valid.."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "CustomAttribute12"
            onpremisesvalue = $onPremData.extensionAttribute12
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.customAttribute12
            isValidInExchangeOnline = "False"
            IsValidMember = "False"
            ErrorMessage = "VALUE_ONPREMISES_NOT_EQUAL_OFFICE365_EXCEPTION"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    if ($onPremData.extensionAttribute13 -eq $office365Data.customAttribute13)
    {
        out-logfile -string "On premises and exchange online value are valid.."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "CustomAttribute13"
            onpremisesvalue = $onPremData.extensionAttribute13
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.customAttribute13
            isValidInExchangeOnline = "True"
            IsValidMember = "True"
            ErrorMessage = "N/A"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }
    else 
    {
        out-logfile -string "On premises and exchange online value are not valid.."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "CustomAttribute13"
            onpremisesvalue = $onPremData.extensionAttribute13
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.customAttribute13
            isValidInExchangeOnline = "False"
            IsValidMember = "False"
            ErrorMessage = "VALUE_ONPREMISES_NOT_EQUAL_OFFICE365_EXCEPTION"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    if ($onPremData.extensionAttribute14 -eq $office365Data.customAttribute14)
    {
        out-logfile -string "On premises and exchange online value are valid.."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "CustomAttribute14"
            onpremisesvalue = $onPremData.extensionAttribute14
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.customAttribute14
            isValidInExchangeOnline = "True"
            IsValidMember = "True"
            ErrorMessage = "N/A"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }
    else 
    {
        out-logfile -string "On premises and exchange online value are not valid.."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "CustomAttribute14"
            onpremisesvalue = $onPremData.extensionAttribute14
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.customAttribute14
            isValidInExchangeOnline = "False"
            IsValidMember = "False"
            ErrorMessage = "VALUE_ONPREMISES_NOT_EQUAL_OFFICE365_EXCEPTION"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    if ($onPremData.extensionAttribute15 -eq $office365Data.customAttribute15)
    {
        out-logfile -string "On premises and exchange online value are valid.."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "CustomAttribute15"
            onpremisesvalue = $onPremData.extensionAttribute15
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.customAttribute15
            isValidInExchangeOnline = "True"
            IsValidMember = "True"
            ErrorMessage = "N/A"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }
    else 
    {
        out-logfile -string "On premises and exchange online value are not valid.."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "CustomAttribute15"
            onpremisesvalue = $onPremData.extensionAttribute15
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.customAttribute15
            isValidInExchangeOnline = "False"
            IsValidMember = "False"
            ErrorMessage = "VALUE_ONPREMISES_NOT_EQUAL_OFFICE365_EXCEPTION"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    if ($onPremData.msExchExtensionAttribute1 -ne $NULL)
    {
        $functionObject = New-Object PSObject -Property @{
            Attribute = "ExtensionCustomAttribte1"
            onpremisesvalue = $onPremData.msExchExtensionAttribute1
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = "N/A"
            isValidInExchangeOnline = "False"
            IsValidMember = "FALSE"
            ErrorMessage = "VALUE_NOT_REPLICATED_TO_OFFICE365"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    if ($onPremData.msExchExtensionAttribute2 -ne $NULL)
    {
        $functionObject = New-Object PSObject -Property @{
            Attribute = "ExtensionCustomAttribte1"
            onpremisesvalue = $onPremData.msExchExtensionAttribute2
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = "N/A"
            isValidInExchangeOnline = "False"
            IsValidMember = "FALSE"
            ErrorMessage = "VALUE_NOT_REPLICATED_TO_OFFICE365"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    if ($onPremData.msExchExtensionAttribute3 -ne $NULL)
    {
        $functionObject = New-Object PSObject -Property @{
            Attribute = "ExtensionCustomAttribte1"
            onpremisesvalue = $onPremData.msExchExtensionAttribute3
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = "N/A"
            isValidInExchangeOnline = "False"
            IsValidMember = "FALSE"
            ErrorMessage = "VALUE_NOT_REPLICATED_TO_OFFICE365"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    if ($onPremData.msExchExtensionAttribute4 -ne $NULL)
    {
        $functionObject = New-Object PSObject -Property @{
            Attribute = "ExtensionCustomAttribte1"
            onpremisesvalue = $onPremData.msExchExtensionAttribute4
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = "N/A"
            isValidInExchangeOnline = "False"
            IsValidMember = "FALSE"
            ErrorMessage = "VALUE_NOT_REPLICATED_TO_OFFICE365"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    if ($onPremData.msExchExtensionAttribute5 -ne $NULL)
    {
        $functionObject = New-Object PSObject -Property @{
            Attribute = "ExtensionCustomAttribte1"
            onpremisesvalue = $onPremData.msExchExtensionAttribute5
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = "N/A"
            isValidInExchangeOnline = "False"
            IsValidMember = "FALSE"
            ErrorMessage = "VALUE_NOT_REPLICATED_TO_OFFICE365"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    out-logfile -string "Evaluating display name."

    if ($onPremData.displayname -eq $NULL)
    {
        $onPremData.displayName = "!*NotSet*!"
    }
    elseif ($onPremData.displayName -eq "")
    {
        $onPremData.displayname = "!*NotSet*!"
    }

    if ($azureData.displayName -eq $NULL)
    {
        $azureData.displayname = "!*NotSet*!"
    }
    elseif ($azureData.displayName -eq "")
    {
        $azureData.displayName = "!*NotSet*!"
    }

    if ($office365Data.displayName -eq $NULL)
    {
        $office365Data.DisplayName = "!*NotSet*!"
    }
    elseif ($office365Data.displayName -eq "")
    {
        $office365Data.displayName = "!*NotSet*!"
    }

    if ($onPremData.displayName -eq $azureData.displayName)
    {
        out-logfile -string "On premises and azure value are valid.."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "DisplayName"
            onpremisesvalue = $onPremData.displayName
            AzureADValue = $azureData.displayName
            isValidInAzure = "True"
            ExchangeOnlineValue = "N/A"
            isValidInExchangeOnline = "N/A"
            IsValidMember = "False"
            ErrorMessage = "N/A"
        }

        if ($azureData.displayName -eq $office365Data.displayName)
        {
            out-logfile -string "Azure AD to Exchange Online values are valid."

            $functionObject.exchangeOnlineValue = $office365Data.displayName
            $functionObject.isValidInExchangeOnline = "True"
            $functionObject.isValidMember = "TRUE"

            out-logfile -string $functionObject

            $functionReturnArray += $functionObject
        }
        else 
        {
            out-logfile -string "Azure AD to Exchange Online values are not valid."

            $functionObject.errorMessage = "VALUE_ONPREMISES_NOT_EQUAL_OFFICE365_EXCEPTION"

            out-logfile -string $functionObject

            $functionReturnArray += $functionObject
        }
    }
    else 
    {
        out-logfile -string "On premsies and azure values are not valid."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "DisplayName"
            onpremisesvalue = $onPremData.displayName
            AzureADValue = $azureData.displayName
            isValidInAzure = "True"
            ExchangeOnlineValue = "N/A"
            isValidInExchangeOnline = "N/A"
            IsValidMember = "False"
            ErrorMessage = "VALUE_ONPREMISES_NOT_EQUAL_AZURE_EXCEPTION"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    out-logfile -string "Evaluating hidden from address list enabled."

    if ($onPremData.msExchHideFromAddressLists -eq $NULL)
    {
        [boolean]$functionHiddenFromAddressListEnabled = $FALSE

        out-logfile -string $functionHiddenFromAddressListEnabled
    }
    else
    {
        out-logfile -string $onPremData.msExchHideFromAddressLists

        [boolean]$functionHiddenFromAddressListEnabled = $onPremData.msExchHideFromAddressLists

        out-logfile -string $functionHiddenFromAddressListEnabled 
    }
    
    if ($office365Data.HiddenFromAddressListsEnabled -eq $functionHiddenFromAddressListEnabled)
    {
        out-logfile -string "On premises and exchange online value are valid."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "HiddenFromAddressListEnabled"
            onpremisesvalue = $functionHiddenFromAddressListEnabled
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.HiddenFromAddressListsEnabled
            isValidInExchangeOnline = "True"
            IsValidMember = "TRUE"
            ErrorMessage = "N/A"
        }


        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }
    else 
    {
        out-logfile -string "On premsies and office 365 values are not valid."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "HiddenFromAddressListEnabled"
            onpremisesvalue = $onPremData.hiddenFromAddressListEnabled
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.hiddenFromAddressListEnabled
            isValidInExchangeOnline = "False"
            IsValidMember = "FALSE"
            ErrorMessage = "VALUE_ONPREMISES_NOT_EQUAL_OFFICE365_EXCEPTION"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    out-logfile -string "Evaluating moderation enabled."

    if ($onPremData.msExchEnableModeration -eq $NULL)
    {
        $functionModerationEnabled = $FALSE

        out-logfile -string $functionModerationEnabled
    }
    else
    {
        out-logfile -string $onPremData.msExchEnableModeration

        $functionModerationEnabled = $onPremData.msExchEnableModeration

        out-logfile -string $functionModerationEnabled
    }

    if ($functionModerationEnabled -eq $office365Data.ModerationEnabled)
    {
        out-logfile -string "On premises and exchange online values are valid."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "ModerationEnabled"
            onpremisesvalue = $functionModerationEnabled
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.ModerationEnabled
            isValidInExchangeOnline = "True"
            IsValidMember = "TRUE"
            ErrorMessage = "N/A"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }
    else 
    {
        out-logfile -string "On premises and exchange online values are not valid."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "ModerationEnabled"
            onpremisesvalue = $functionModerationEnabled
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.ModerationEnabled
            isValidInExchangeOnline = "False"
            IsValidMember = "FALSE"
            ErrorMessage = "VALUE_ONPREMISES_NOT_EQUAL_OFFICE365_EXCEPTION"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    if ($onPremData.mail -eq $NULL)
    {
        $onPremData.mail = "!*NotSet*!"
    }
    elseif ($onPremData.mail -eq "")
    {
        $onPremData.mail = "!*NotSet*!"
    }

    if ($azureData.mail -eq $NULL)
    {
        $azureData.mail = "!*NotSet*!"
    }
    elseif ($azureData.mail -eq "")
    {
        $azureData.mail = "!*NotSet*!"
    }

    if ($office365Data.primarySMTPAddress -eq $NULL)
    {
        $office365Data.primarySMTPAddress = "!*NotSet*!"
    }
    elseif ($office365Data.primarySMTPAddress -eq "")
    {
        $office365Data.primarySMTPAddress = "!*NotSet*!"
    }

    out-logfile -string "Evaluation of primary SMTP address."

    if ($onPremData.mail -eq $azuredata.mail)
    {
        out-logfile -string "On premises mail matches azure ad mail."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "Mail / PrimarySMTPAddress"
            onpremisesvalue = $onPremData.mail
            AzureADValue = $azureData.mail
            isValidInAzure = "True"
            ExchangeOnlineValue = "N/A"
            isValidInExchangeOnline = "False"
            IsValidMember = "FALSE"
            ErrorMessage = "N/A"
        }

        if ($azureData.mail -eq $office365Data.primarySMTPAddress)
        {
            out-logfile "Azure mail attribute matches office 365 primary smtp address."

            $functionObject.exchangeOnlineValue = $office365Data.primarySMTPAddress
            $functionObject.isValidInExchangeOnline = "True"
            $functionObject.isValidMember = "TRUE"

            out-logfile -string $functionObject

            $functionReturnArray += $functionObject
        }
        else
        {
            $functionObject.errorMessage = "VALUE_AZURE_NOT_EQUAL_OFFICE365_EXCEPTION"

            out-logfile -string $functionObject

            $functionReturnArray += $functionObject
        }
    }
    else
    {
        out-logfile -string "On premises mail attribute does not match azure mail attribute."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "Mail / PrimarySMTPAddress"
            onpremisesvalue = $onPremData.mail
            AzureADValue = $azureData.mail
            isValidInAzure = "True"
            ExchangeOnlineValue = "N/A"
            isValidInExchangeOnline = "False"
            IsValidMember = "FALSE"
            ErrorMessage = "VALUE_ONPREMISES_NOT_EQUAL_AZURE_EXCEPTION"
        }
    }

    out-logfile -string "Evaluate require sender authentication."

    if ($onPremData.msExchRequireAuthToSendTo -eq $NULL)
    {
        $functionRequireAuthToSendTo = $FALSE

        out-logfile -string $functionRequireAuthToSendTo
    }
    else
    {
        out-logfile -string $onPremData.msExchRequireAuthToSendTo

        $functionRequireAuthToSendTo = $onPremData.msExchRequireAuthToSendTo

        out-logfile -string $functionRequireAuthToSendTo
    }

    if ($office365Data.RequireSenderAuthenticationEnabled -eq $functionRequireAuthToSendTo)
    {
        out-logfile -string "Require authentication matches between on premises and exchange online."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "RequireSenderAuthenticationEnabled"
            onpremisesvalue = $functionRequireAuthToSendTo
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.RequireSenderAuthenticationEnabled
            isValidInExchangeOnline = "True"
            IsValidMember = "TRUE"
            ErrorMessage = "N/A"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }
    else
    {
        out-logfile -string "Require authentication does not match between on premsies and office 365."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "RequireSenderAuthenticationEnabled"
            onpremisesvalue = $functionRequireAuthToSendTo
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.RequireSenderAuthenticationEnabled
            isValidInExchangeOnline = "False"
            IsValidMember = "FALSE"
            ErrorMessage = "VALUE_ONPREMISES_NOT_EQUAL_OFFICE365_EXCEPTION"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    out-logfile -string "Evaluate simple display name."

    if ($onPremData.displayNamePrintable -eq $NULL)
    {
        $onPremData.displayNamePrintable = "!*NotSet*!"
    }
    elseif ($onPremData.displayNamePrintable -eq "")
    {
        $onPremData.displayNamePrintable = "!*NotSet*!"
    }

    if ($office365Data.simpleDisplayName -eq $NULL)
    {
        $office365Data.simpleDisplayName = "!*NotSet*!"
    }
    elseif ($office365Data.simpleDisplayName -eq "")
    {
        $office365Data.simpleDisplayName = "!*NotSet*!"
    }

    if ($onPremData.DisplayNamePrintable -eq $office365Data.simpleDisplayName)
    {
        out-logfile -string "Simple display name matches between on premies and exchange online."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "SimpleDisplayName"
            onpremisesvalue = $onPremData.DisplayNamePrintable
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.simpledisplayname
            isValidInExchangeOnline = "True"
            IsValidMember = "TRUE"
            ErrorMessage = "N/A"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }
    else 
    {
        out-logfile -string "Simple display name does not match between on premies and exchange online."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "SimpleDisplayName"
            onpremisesvalue = $onPremData.simpleDisplayNamePrintable
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.simpledisplayname
            isValidInExchangeOnline = "False"
            IsValidMember = "FALSE"
            ErrorMessage = "VALUE_ONPREMISES_NOT_EQUAL_OFFICE365_EXCEPTION"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    out-logfile -string "Evaluating send moderation notifications."

    if (($onPremData.msExchModerationFlags -eq "0") -or ($onPremData.msExchModerationFlags -eq "1")  )
    {
        out-logfile -string ("The moderation flags are 0 / 2 / 6 - send notifications to never."+$onPremData.msExchModerationFlags)

        $functionSendModerationNotifications="Never"

        out-logfile -string ("The function send moderations notifications is = "+$functionSendModerationNotifications)
    }
    elseif (($onPremData.msExchModerationFlags -eq "2") -or ($onPremData.msExchModerationFlags -eq "3")  )
    {
        out-logfile -string ("The moderation flags are 0 / 2 / 6 - setting send notifications to internal."+$onPremData.msExchModerationFlags)

        $functionSendModerationNotifications="Internal"

        out-logfile -string ("The function send moderations notifications is = "+$functionSendModerationNotifications)

    }
    elseif (($onPremData.msExchModerationFlags -eq "6") -or ($onPremData.msExchModerationFlags -eq "7")  )
    {
        out-logfile -string ("The moderation flags are 0 / 2 / 6 - setting send notifications to always."+$onPremData.msExchModerationFlags)

        $functionSendModerationNotifications="Always"

        out-logfile -string ("The function send moderations notifications is = "+$functionSendModerationNotifications)
    }
    else 
    {
        out-logFile -string ("The moderation flags are not set.  Setting to default of always.")
        
        $functionSendModerationNotifications="Always"

        out-logFile -string ("The function send moderation notification is = "+$functionSendModerationNotifications)
    }

    if ($functionSendModerationNotifications -eq $office365Data.SendModerationNotifications)
    {
        out-logfile -string "Send moderation notifications matches between on premises and exchange online."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "SendMOderationNotifications"
            onpremisesvalue = $functionSendModerationNotifications
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.SendModerationNotifications
            isValidInExchangeOnline = "True"
            IsValidMember = "TRUE"
            ErrorMessage = "N/A"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }
    else
    {
        out-logfile -string "Send moderation notifications does not match between on premises and office 365."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "SendMOderationNotifications"
            onpremisesvalue = $functionSendModerationNotifications
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.SendModerationNotifications
            isValidInExchangeOnline = "False"
            IsValidMember = "FALSE"
            ErrorMessage = "VALUE_ONPREMISES_NOT_EQUAL_OFFICE365_EXCEPTION"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    if ($onPremData.msExchSenderHintTranslations.count -eq $office365Data.MailtipTranslations.count)
    {
        out-logfile -string "Count of mail tips is good - assume values are the same."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "MailTipTranslations"
            onpremisesvalue = "ManuallyVerify"
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = "ManuallyVerify"
            isValidInExchangeOnline = "True"
            IsValidMember = "TRUE"
            ErrorMessage = "N/A"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }
    elseif ($onPremData.msExchSenderHintTranslations.count -eq $office365Data.MailtipTranslations.count)
    {
        out-logfile -string "Count of mail tips is good - assume values are the same."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "MailTipTranslations"
            onpremisesvalue = "ManuallyVerify"
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = "ManuallyVerify"
            isValidInExchangeOnline = "True"
            IsValidMember = "FALSE"
            ErrorMessage = "VALUE_COUNT_EQUAL_MANUAL_VERIFICATION_REQUIRED"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }
    else {
        out-logfile -string "Mail tip translation counts are not the same - assume out of sync error."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "MailTipTranslations"
            onpremisesvalue = "ManuallyVerify"
            AzureADValue = "N/A"
            isValidInAzure = "N/A"
            ExchangeOnlineValue = "ManuallyVerify"
            isValidInExchangeOnline = "True"
            IsValidMember = "FALSE"
            ErrorMessage = "VALUE_COUNT_NOT_EQUAL_MANUAL_VERIFICATION_REQUIRED"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    Out-LogFile -string "END compare-recipientProperties"
    Out-LogFile -string "********************************************************************************"

    out-logfile $functionReturnArray

    return $functionReturnArray
}