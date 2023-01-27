function compare-recipientArrays
{
    param(
        [Parameter(Mandatory = $false)]
        $onPremData=$NULL,
        [Parameter(Mandatory = $false)]
        $azureData=$NULL,
        [Parameter(Mandatory = $false)]
        $office365Data=$NULL
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

        for ($i = ($onPremData.count-1) ; $i -ge 0 ; $i--)
        {
            out-logfile -string ("On Prem Data Count: "+$onPremData.count)
            out-logfile -string ("Azure Data Count: "+$azureData.count)
            out-logfile -string ("Evaluating on prem array id: "+$i)
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

                    out-logfile -string "Removing object from azure array..."

                    $functionAzureObject = $azureData | where-object {$_.objectID -eq $functionExternalDirectoryObjectID[1]}

                    $azureData = @($azureData | where-object {$_.objectID -ne $functionAzureObject.objectID})

                    $functionObject = New-Object PSObject -Property @{
                        Name = $onPremData[$i].name
                        PrimarySMTPAddress = $onPremData[$i].primarySMTPAddress
                        UserPrincipalName = $onPremData[$i].userPrincipalName
                        ExternalDirectoryObjectID = $onPremData[$i].externalDirectoryObjectID
                        ObjectSID = $onPremData[$i].objectSID
                        IsValidMember = "TRUE"
                        ErrorMessage = "N/A"
                    }

                    out-logfile -string "Removing object from on premises array..."

                    $onPremData = @($onPremData | where-object {$_.externalDirectoryObjectID -ne $onPremData[$i].externalDirectoryObjectID})

                    $functionReturnArray += $functionObject
                }
                else 
                {
                    out-logfile -string "Member not found in Azure"
                }
            }
            elseif ($onPremData[$i].objectSID -ne $NULL)
            {
                out-logfile -string "The object has an objectSID - if we reached here it is not a user - assume group."

                out-logfile -string $onPremData[$i].objectSID.value
                
                if ($azureData.OnPremisesSecurityIdentifier -contains $onPremData[$i].objectSID.value)
                {
                    out-logfile -string "Member found in Azure."

                    out-logfile -string "Removing object from azure array..."

                    $functionAzureObject = $azureData | where-object {$_.OnPremisesSecurityIdentifier -eq $onPremData[$i].objectSID.value}

                    $azureData = @($azureData | where-object {$_.OnPremisesSecurityIdentifier -ne $functionAzureObject.OnPremisesSecurityIdentifier})
    
                    $functionObject = New-Object PSObject -Property @{
                        Name = $onPremData[$i].name
                        PrimarySMTPAddress = $onPremData[$i].primarySMTPAddress
                        UserPrincipalName = $onPremData[$i].userPrincipalName
                        ExternalDirectoryObjectID = $onPremData[$i].externalDirectoryObjectID
                        ObjectSID = $onPremData[$i].objectSID
                        IsValidMember = "TRUE"
                        ErrorMessage = "N/A"
                    }

                    out-logfile -string "Removing object from on premises array..."

                    $onPremData = @($onPremData | where-object {$_.objectSid.Value -ne $onPremData[$i].objectSID.value})

                    $functionReturnArray += $functionObject
                }
                else {
                    out-logfile -string "Object not found in Azure."
                }
            }
            elseif ($onPremData[$i].primarySMTPAddress -ne $null)
            {
                out-logfile -string "The object has a mail address - if we reached here it is not a user and does not have a SID - assume contact."
                out-logfile -string $onPremData[$i].primarySMTPAddress

                if ($azureData.mail -contains $onPremData[$i].primarySMTPAddress)
                {
                    out-logfile -string "Member found in Azure."

                    out-logfile -string "Removing object from azure array..."

                    $azureData = @($azureData | where-object {$_.mail -ne $onPremData[$i].primarySMTPAddress})

                    $functionObject = New-Object PSObject -Property @{
                        Name = $onPremData[$i].name
                        PrimarySMTPAddress = $onPremData[$i].primarySMTPAddress
                        UserPrincipalName = $onPremData[$i].userPrincipalName
                        ExternalDirectoryObjectID = $onPremData[$i].externalDirectoryObjectID
                        ObjectSID = $onPremData[$i].objectSID
                        IsValidMember = "TRUE"
                        ErrorMessage = "N/A"
                    }

                    out-logfile -string "Removing object from on premises array..."

                    $onPremData = @($onPremData | where-object {$_.primarySMTPAddress -ne $onPremData[$i].primarySMTPAddress})

                    $functionReturnArray += $functionObject
                }
                else {
                    out-logfile -string "Object not found in Azure."
                }
            }
        }

        if ($OnPremData.count -lt 1)
        {
            out-logfile -string "No on prem users left for evaluation - all found."
            $onPremData = @()
        }
        else {
            out-logfile -string "On prem array contains data - suspect missing member."

            foreach ($member in $onPremData)
            {
                $functionObject = New-Object PSObject -Property @{
                    Name = $member.name
                    PrimarySMTPAddress = $member.primarySMTPAddress
                    UserPrincipalName = $member.userPrincipalName
                    ExternalDirectoryObjectID = $member.externalDirectoryObjectID
                    ObjectSID = $member.objectSID
                    IsValidMember = "FALSE"
                    ErrorMessage = "MEMBER_ONPREM_NOT_IN_AZURE_EXCEPTION"
                }

                $functionReturnArray += $functionObject
            }
        }
        
        if ($azureData.count -lt 1)
        {
            out-logfile -string "No azure users left for evaluation - all found."
            $azureData = @()
        }
        else
        {
            out-logfile -string "Azure array contains data - suspect missing member."

            foreach ($member in $onPremData)
            {
                $functionObject = New-Object PSObject -Property @{
                    Name = $member.displayName
                    PrimarySMTPAddress = $member.mail
                    UserPrincipalName = $member.userPrincipalName
                    ExternalDirectoryObjectID = $member.objectID
                    ObjectSID = $member.OnPremisesSecurityIdentifier
                    IsValidMember = "FALSE"
                    ErrorMessage = "MEMBER_IN_AZURE_NOT_ONPREM_EXCEPTION"
                }

                $functionReturnArray += $functionObject
            }
        }
    }
    else 
    {
        out-logfile -string "No data to be evaluated by the on prem / azure loop."
    }

    if (($azureData -ne $NULL) -and ($office365Data -ne $NULL))
    {
        out-logfile -string "This is an Office 365 to Azure evaluation."

        for ($i = ($office365Data.count - 1) ; $i -ge 0 ; $i--)
        {
            if ($office365Data[$i].externalDirectoryObjectID -notcontains "_")
            {
                out-logfile -string "ExternalDirectoryObjectID provided by Office 365."

                $functionExternalDirectoryObjectID = $office365Data[$i].externalDirectoryObjectID
            }
            else
            {
                out-logfile -string "ExternalDirectoryObjectID calculated by normalized Office 365 object."

                $functionExternalDirectoryObjectID = $office365Data[$i].split["_"]
                $functionExternalDirectoryObjectID = $functionExternalDirectoryObjectID[1]
            }

            out-logfile -string ("ExternalDirectoryObjectID: "+$functionExternalDirectoryObjectID)

            if ($azureData.objectID -contains $functionExternalDirectoryObjectID)
            {
                out-logfile -string "Member found in Azure."

                out-logfile -string "Removing object from azure array..."

                $functionAzureObject = $azureData | where-object {$_.objectID -eq $functionExternalDirectoryObjectID}

                $functionObject = New-Object PSObject -Property @{
                    Name = $functionAzureObject.displayName
                    PrimarySMTPAddress = $functionAzureObject.mail
                    UserPrincipalName = $functionAzureObject.userprincipalname
                    ExternalDirectoryObjectID = $functionAzureObject.objectID
                    ObjectSID = $functionAzureObject.OnPremisesSecurityIdentifier
                    IsValidMember = "TRUE"
                    ErrorMessage = "N/A"
                }

                $azureData = @($azureData | where-object {$_.objectID -ne $functionAzureObject.objectID})

                out-logfile -string "Removing object from on premises array..."

                $office365Data = @($office365Data | where-object {$_.externalDirectoryObjectID -ne $functionExternalDirectoryObjectID})

                $functionReturnArray += $functionObject
            }
            else 
            {
                out-logfile -string "Member not found in Azure"
            }
        }

        if ($office365Data.count -lt 1)
        {
            out-logfile -string "No on prem users left for evaluation - all found."
            $onPremData = @()
        }
        else {
            out-logfile -string "On prem array contains data - suspect missing member."

            foreach ($member in $onPremData)
            {
                $functionObject = New-Object PSObject -Property @{
                    Name = $member.DisplayName
                    PrimarySMTPAddress = $member.primarySMTPAddress
                    UserPrincipalName = $null
                    ExternalDirectoryObjectID = $member.externalDirectoryObjectID
                    ObjectSID = $null
                    IsValidMember = "FALSE"
                    ErrorMessage = "MEMBER_IN_OFFICE365_NOT_IN_AZURE_EXCEPTION"
                }

                $functionReturnArray += $functionObject
            }
        }
        
        if ($azureData.count -lt 1)
        {
            out-logfile -string "No azure users left for evaluation - all found."
            $azureData = @()
        }
        else
        {
            out-logfile -string "Azure array contains data - suspect missing member."

            foreach ($member in $onPremData)
            {
                $functionObject = New-Object PSObject -Property @{
                    Name = $member.displayName
                    PrimarySMTPAddress = $member.mail
                    UserPrincipalName = $member.userPrincipalName
                    ExternalDirectoryObjectID = $member.objectID
                    ObjectSID = $member.OnPremisesSecurityIdentifier
                    IsValidMember = "FALSE"
                    ErrorMessage = "MEMBER_IN_AZURE_NOT_IN_OFFICE365_EXCEPTION"
                }

                $functionReturnArray += $functionObject
            }
        }
    }
    else 
    {
        out-logfile -string "No data to be evaluated by the Office 365 / Azure loop."
    }

    if (($onPremData -ne $NULL) -and ($office365Data -ne $NULL))
    {
        out-logfile -string "Comparing on premises to Office 365 values."

        for ( $i = ($onPremData.count - 1); $i -ge 0 ; $i --)
        {
            if ($onPremData[$i].externalDirectoryObjectID -ne $NULL)
            {
                out-logfile -string "Testing based on external directory object id."
            }
            elseif ($onPremData[$i].primarySTMPAddressOrUPN -ne $NULL)
            {
                out-logfile -string "Testing based on primary SMTP address."
            }
        }
    }


    Out-LogFile -string "END compare-recipientArrays"
    Out-LogFile -string "********************************************************************************"

    out-logfile $functionReturnArray

    return $functionReturnArray
}