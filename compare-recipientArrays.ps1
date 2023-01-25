function compare-recipientArrays
{
    params(
        [Parameter(Mandatory = $false)]
        $onPremData=$NULL,
        [Parameter(Mandatory = $false)]
        $azureData=$NULL,
        [Parameter(Mandatory = $false)]
        $office365Data=$NULL
    )

    [array]$functionReturnArray = @()
    $functionExternalDirectoryObjectID = @()

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "BEGIN compare-recipientArrays"
    Out-LogFile -string "********************************************************************************"

    out-logfile -string "Determine if we are comparing on premises and Azure <or> on premises and Exchange Online"

    if (($onPremData -ne $NULL) -and ($azureData -ne $NULL))
    {
        out-logfile -string "This is a comparison of on premises and Azure AD data."

        foreach ($member in $onPremData)
        {
            out-logfile -string ("Evaluating: "+$member.primarySMTPAddressOrUPN)

            $functionExternalDirectoryObjectID = $member.externalDirectoryObjectID.split("_")

            
        }
    }

   
    Out-LogFile -string "END compare-recipientArrays"
    Out-LogFile -string "********************************************************************************"
}