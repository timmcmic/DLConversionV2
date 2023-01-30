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
            OnPremisesValue = $functionGroupType
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
            OnPremisesValue = $functionGroupType
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
            OnPremisesValue = $functionModerationFlags
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
            OnPremisesValue = $functionModerationFlags
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
            OnPremisesValue = $functionMemberJoinRestriction
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
            OnPremisesValue = $functionMemberJoinRestriction
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
            OnPremisesValue = $functionMemberDepartRestriction
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
            OnPremisesValue = $functionMemberJoinRestriction
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
            OnPremisesValue = $functionreportToOwner
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
            OnPremisesValue = $functionreportToOwner
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
            OnPremisesValue = $functionReportToOriginator
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
            OnPremisesValue = $functionReportToOriginator
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
            OnPremisesValue = $functionoofReplyToOriginator
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
            OnPremisesValue = $functionoofReplyToOriginator
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

    if ($onPremData.mailNickName -eq $azureData.mailNickName)
    {
        out-logfile -string "On premises mail nickname value = azure value."

        $functionObject = New-Object PSObject -Property @{
            Attribute = "Alias / MailNickName"
            OnPremisesValue = $onPremData.mailNickName
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
            OnPremisesValue = $onPremData.mailNickName
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
        $onPremData.extensionAttribute1 = ""
    }

    if ($onPremData.extensionAttribute2 -eq $NULL)
    {
        $onPremData.extensionAttribute2 = ""
    }

    if ($onPremData.extensionAttribute3 -eq $NULL)
    {
        $onPremData.extensionAttribute3 = ""
    }

    if ($onPremData.extensionAttribute4 -eq $NULL)
    {
        $onPremData.extensionAttribute4 = ""
    }

    if ($onPremData.extensionAttribute5 -eq $NULL)
    {
        $onPremData.extensionAttribute5 = ""
    }

    if ($onPremData.extensionAttribute6 -eq $NULL)
    {
        $onPremData.extensionAttribute6 = ""
    }

    if ($onPremData.extensionAttribute7 -eq $NULL)
    {
        $onPremData.extensionAttribute7 = ""
    }

    if ($onPremData.extensionAttribute8 -eq $NULL)
    {
        $onPremData.extensionAttribute8 = ""
    }

    if ($onPremData.extensionAttribute9 -eq $NULL)
    {
        $onPremData.extensionAttribute9 = ""
    }

    if ($onPremData.extensionAttribute10 -eq $NULL)
    {
        $onPremData.extensionAttribute10 = ""
    }

    if ($onPremData.extensionAttribute11 -eq $NULL)
    {
        $onPremData.extensionAttribute11 = ""
    }

    if ($onPremData.extensionAttribute12 -eq $NULL)
    {
        $onPremData.extensionAttribute12 = ""
    }

    if ($onPremData.extensionAttribute13 -eq $NULL)
    {
        $onPremData.extensionAttribute13 = ""
    }

    if ($onPremData.extensionAttribute14 -eq $NULL)
    {
        $onPremData.extensionAttribute14 = ""
    }

    if ($onPremData.extensionAttribute15 -eq $NULL)
    {
        $onPremData.extensionAttribute15 = ""
    }








    if ($onPremData.extensionAttribute1 -eq $office365Data.customAttribute1)
    {
        out-logfile -string "Blank"
    }

    Out-LogFile -string "END compare-recipientProperties"
    Out-LogFile -string "********************************************************************************"

    out-logfile $functionReturnArray

    return $functionReturnArray
}