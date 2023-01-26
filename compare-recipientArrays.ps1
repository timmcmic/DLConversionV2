function compare-recipientArrays
{
    param(
        [Parameter(Mandatory = $false)]
        [System.Collections.ArrayList]$onPremData=$NULL,
        [Parameter(Mandatory = $false)]
        [System.Collections.ArrayList]$azureData=$NULL,
        [Parameter(Mandatory = $false)]
        [System.Collections.ArrayList]$office365Data=$NULL
    )

    [array]$functionReturnArray = @()
    $functionExternalDirectoryObjectID = @()
    $functionAzureIndex = 0

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "BEGIN compare-recipientArrays"
    Out-LogFile -string "********************************************************************************"

    out-logfile -string "Determine if we are comparing on premises and Azure <or> on premises and Exchange Online"

    if (($onPremData -ne $NULL) -and ($azureData -ne $NULL))
    {
        out-logfile -string "This is a comparison of on premises and Azure AD data."

        for ($i = ($onPremData.count-1); $i -ge 0 ; $i--)
        {
            out-logfile -string $i.toString()
            #Group members come in different flavors.
            #The first is a user type that is either mail enabled or not.  Any user object has this attribute - we search that first.
            #The second is a group type.  Regardless of group type the group SID is replicated into the original group sid in azure.  We search there next.
            #Lastly are objects that have neither a SID or external directory object ID then we search for mail.

            if ($onPremData[$i].externalDirectoryObjectID -ne $NULL)
            {
                out-logfile -string "The object has an external directory object id - test based on this."
                out-logfile -string $onPremData[$i].externalDirectoryObjectID

                $functionExternalDirectoryObjectID = $onPremData[$i].externalDirectoryObjectID.split("_")

                if ($azureData.objectID -contains $functionExternalDirectoryObjectID[1])
                {
                    out-logfile -string "Member found in Azure."

                    $onPremData.RemoveAt($i)

                    $functionAzureIndex = $azureData.objectID.indexOf($functionDirectoryObjectID[1])

                    $azureData.RemoveAt($functionAzureIndex)
                }
            }
            elseif ($onPremData[$i].objectSID -ne $NULL)
            {
                out-logfile -string "The object has an objectSID - if we reached here it is not a user - assume group."
                
                if ($azureData.OnPremisesSecurityIdentifier -contains $onPremData[$i].objectSID)
                {
                    out-logfile -string "Member found in Azure."

                    $onPremData.RemoveAt($i)
                }
            }
            elseif ($onPremData[$i].primarySMTPAddress -ne $null)
            {
                out-logfile -string "The object has a mail address - if we reached here it is not a user and does not have a SID - assume contact."

                if ($azureData.mail -contains $onPremData[$i].primarySMTPAddress)
                {
                    out-logfile -string "Member found in Azure."

                    $onPremData.RemoveAt($i)
                }
            }

            out-logfile -string $azuredata.Count
        }
    }

    Out-LogFile -string "END compare-recipientArrays"
    Out-LogFile -string "********************************************************************************"
}