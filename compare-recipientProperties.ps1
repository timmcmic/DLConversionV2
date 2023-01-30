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
            ErrorMessage = "N/A"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }

    out-logfile -string "Evaluate member join restrictions."

    if ($onPremData.msExchGroupJoinRestriction -eq $NULL)
    {
        out-logfile -string $onPremData.msExchGroupJoinRestriction

        $functionMemberJoinRestriction="Closed"

        out-logfile -string $functionMemberJoinRestriction
    }
    else 
    {
        out-logfile -string $onPremData.msExchGroupJoinRestriction

        $functionMemberJoinRestriction = $onPremData.msExchGroupJoinRestriction

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
            IsValidMember = "True"
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
            ErrorMessage = "N/A"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject    
    }

    Out-LogFile -string "END compare-recipientProperties"
    Out-LogFile -string "********************************************************************************"

    out-logfile $functionReturnArray

    return $functionReturnArray
}