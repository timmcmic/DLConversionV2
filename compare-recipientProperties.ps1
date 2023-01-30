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
            isPresentInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.groupType            
            isPresentInExchangeOnline = "True"
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
            isPresentInAzure = "N/A"
            ExchangeOnlineValue = $office365Data.groupType            
            isPresentInExchangeOnline = "True"
            IsValidMember = "FALSE"
            ErrorMessage = "VALUE_ONPREMISES_NOT_EQUAL_OFFICE365_EXCEPTION"
        }

        out-logfile -string $functionObject

        $functionReturnArray += $functionObject
    }
    
    Out-LogFile -string "END compare-recipientProperties"
    Out-LogFile -string "********************************************************************************"

    out-logfile $functionReturnArray

    return $functionReturnArray
}