function compare-recipientArrays
{
    param(
        [Parameter(Mandatory = $false)]
        $onPremData=$NULL,
        [Parameter(Mandatory = $false)]
        $azureData=$NULL,
        [Parameter(Mandatory = $false)]
        $office365Data=$NULL,
        [Parameter(Mandatory = $false)]
        $isProxyTest=$false
    )

    [array]$functionReturnArray = @()
    $functionExternalDirectoryObjectID = @()
    $functionAzureIndex = 0

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "BEGIN compare-recipientArrays"
    Out-LogFile -string "********************************************************************************"

    if (($onPremData -ne $null) -and ($azureData -ne $null) -and ($office365Data -ne $null) -and ($isProxyTest -eq $TRUE))
    {
        out-logfile -string "Comparing data from all three directories - this has to be proxy addresses."

        out-logfile -string "Start comparing on premsies to AzureAD to Office 365."

        foreach ($member in $onPremData)
        {
            out-logfile -string "Testing azure for presence of proxy address."
            out-logfile -string $member

            if ($azureData -contains $member)
            {
                $functionObject = New-Object PSObject -Property @{
                    ProxyAdress = $member
                    isPresentOnPremises = "Source"
                    isPresentInAzure = "True"
                    isPresentInExchangeOnline = "False"
                    isValidMember = "N/A"
                    ErrorMessage = "N/A"
                }

                out-logfile -string "Address present in Azure.  Testing Exchange Online"

                if ($office365Data -contains $member)
                {
                    out-logfile -string "Email address is present in Exchange Online - this is good."
                    $functionObject.isPresentInExchangeOnline = "True"
                    $functionObject.isValidMember = "True"
                }
                else 
                {
                    out-logfile -string "Email address is not present in Exchange Online - this is bad."
                    $functionObject.isValidMember = "False"
                    $functionObject.errorMessage = "EXCEPTION_ONPREMSIES_PROXY_MISSING_EXCHANGE_ONLINE"
                }
            }
            else 
            {
                out-logfile -string "Proxy address not present in Azure AD.  No further testing required."

                $functionObject = New-Object PSObject -Property @{
                    ProxyAdress = $member
                    isPresentOnPremises = "Source"
                    isPresentInAzure = "False"
                    isPresentInExchangeOnline = "False"
                    isValidMember = "False"
                    ErrorMessage = "EXCEPTION_ONPREMSIES_PROXY_MISSING_AZURE_ACTIVE_DIRECTORY"
                }
            }

            $functionReturnArray += $functionObject
        }

        out-logfile -string "Start comparing Exchange Online to Azure AD to On premises."

        foreach ($member in $office365Data)
        {
            out-logfile -string $member

            if ($azureData -contains $member)
            {
                $functionObject = New-Object PSObject -Property @{
                    ProxyAdress = $member
                    isPresentOnPremises = "False"
                    isPresentInAzure = "True"
                    isPresentInExchangeOnline = "Source"
                    isValidMember = "N/A"
                    ErrorMessage = "N/A"
                }

                out-logfile -string "Address present in Azure.  Testing on premises..."

                if ($onPremData -contains $member)
                {
                    out-logfile -string "Email address is present in onPremises directory - this is good."
                    $functionObject.isPresentOnPremises = "True"
                    $functionObject.isValidMember = "True"
                }
                else 
                {
                    out-logfile -string "Email address is not present in on premises directory - this is bad."
                    $functionObject.isValidMember = "False"
                    $functionObject.errorMessage = "EXCEPTION_OFFICE365_PROXY_MISSING_ONPREMISES_DIRECTORY"
                }
            }
            else 
            {
                out-logfile -string "Proxy address not present in Azure AD.  No further testing required."

                $functionObject = New-Object PSObject -Property @{
                    ProxyAdress = $member
                    isPresentOnPremises = "False"
                    isPresentInAzure = "False"
                    isPresentInExchangeOnline = "Source"
                    isValidMember = "False"
                    ErrorMessage = "EXCEPTION_OFFICE365_PROXY_MISSING_AZURE_ACTIVE_DIRECTORY"
                }
            }

            $functionReturnArray += $functionObject
        }
    }
    elseif (($onPremData -ne $null) -and ($azureData -ne $null) -and ($office365Data -ne $null) -and ($isProxyTest -eq $FALSE))
    {
        out-logfile -string "Comparing data from all three directories - this has to be membership."
    }
    elseif (($onPremData -ne $NULL) -and ($azureData -ne $NULL))
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
    elseif (($azureData -ne $NULL) -and ($office365Data -ne $NULL))
    {
        out-logfile -string "This is an Office 365 to Azure evaluation."

        for ($i = ($office365Data.count - 1) ; $i -ge 0 ; $i--)
        {
            out-logfile -string ("Office 365 Data Count: "+$office365Data.count)
            out-logfile -string ("Azure Data Count: "+$azureData.count)
            out-logfile -string ("Evaluating on prem array id: "+$i)

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
    elseif (($onPremData -ne $NULL) -and ($office365Data -ne $NULL))
    {
        out-logfile -string "Comparing on premises to Office 365 values."

        for ( $i = ($onPremData.count - 1); $i -ge 0 ; $i--)
        {
            out-logfile -string ("On Prem Data Count: "+$onPremData.count)
            out-logfile -string ("Office 365 Data Count: "+$office365Data.count)
            out-logfile -string ("Evaluating on prem array id: "+$i)

            if ($onPremData[$i].externalDirectoryObjectID -ne $NULL)
            {
                out-logfile -string "Testing based on external directory object id."
                out-logfile -string $onPremData[$i].externalDirectoryObjectID

                if ($office365Data.externalDirectoryObjectID -contains $onPremData[$i].externalDirectoryObjectID)
                {
                    out-logfile -string "Member found in Azure."

                    out-logfile -string "Removing object from office 365 array..."

                    $office365Data = @($office365Data | where-object {$_.ExternalDirectoryObjectID -ne $onPremData[$i].externalDirectoryObjectID})

                    out-logfile -string "Removing object from on premises array."

                    #$functionAzureObject = $azureData | where-object {$_.objectID -eq $functionExternalDirectoryObjectID}

                    $functionObject = New-Object PSObject -Property @{
                        Name = $onPremData[$i].name
                        PrimarySMTPAddress = $onPremData[$i].primarySMTPAddress
                        UserPrincipalName = $onPremData[$i].userPrincipalName
                        ExternalDirectoryObjectID = $onPremData[$i].externalDirectoryObjectID
                        ObjectSID = $onPremData[$i].objectSID
                        IsValidMember = "TRUE"
                        ErrorMessage = "N/A"
                    }

                    $onPremData = @($onPremData | where-object {$_.externalDirectoryObjectID -ne $onPremData[$i].externalDirectoryObjectID})

                    $functionReturnArray += $functionObject
                }
                else 
                {
                    out-logfile -string "On premises external directory object id not found in Office 365 data."
                }
            }
            elseif (($onPremData[$i].PrimarySMTPAddress -ne $NULL) -and ($onPremData[$i].recipientOrUser -ne "User"))
            {
                out-logfile -string "Testing based on primary SMTP address."

                out-logfile -string $onPremData[$i].primarySMTPAddress

                if ($office365Data.PrimarySMTPAddressOrUPN -contains $onPremData[$i].primarySMTPAddress)
                {
                    out-logfile -string "Member found in Azure."

                    out-logfile -string "Removing object from Office 365 array..."

                    $office365Data = @($office365Data | where-object {$_.PrimarySMTPAddressOrUPN -ne $onPremData[$i].primarySMTPAddress})

                    out-logfile -string "Removing object from on premises array..."

                    #$functionAzureObject = $azureData | where-object {$_.objectID -eq $functionExternalDirectoryObjectID}

                    $functionObject = New-Object PSObject -Property @{
                        Name = $onPremData[$i].name
                        PrimarySMTPAddress = $onPremData[$i].primarySMTPAddress
                        UserPrincipalName = $onPremData[$i].userPrincipalName
                        ExternalDirectoryObjectID = $onPremData[$i].externalDirectoryObjectID
                        ObjectSID = $onPremData[$i].objectSID
                        IsValidMember = "TRUE"
                        ErrorMessage = "N/A"
                    }

                    $onPremData = @($onPremData | where-object {$_.primarySMTPAddress -ne $onPremData[$i].primarySMTPAddress})

                    $functionReturnArray += $functionObject
                }
                else {
                    out-logfile -string "On premises primary SMTP address not found in Office 365 data."
                }
            }
            elseif ($onPremData[$i].userPrincipalName -ne $NULL)
            {
                out-logfile -string "Testing based on user principal name"

                out-logfile -string $onPremData[$i].userPrincipalName

                if ($office365Data.primarySMTPAddressOrUPN -contains $onPremData[$i].userPrincipalName)
                {
                    out-logfile -string "Member found in Azure."

                    out-logfile -string "Removing object from Office 365 array..."

                    $office365Data = @($office365Data | where-object {$_.primarySMTPAddressOrUPN -ne $onPremData[$i].userPrincipalName})

                    out-logfile -string "Removing object from on premises array..."

                    #$functionAzureObject = $azureData | where-object {$_.objectID -eq $functionExternalDirectoryObjectID}

                    $functionObject = New-Object PSObject -Property @{
                        Name = $onPremData[$i].name
                        PrimarySMTPAddress = $onPremData[$i].primarySMTPAddress
                        UserPrincipalName = $onPremData[$i].userPrincipalName
                        ExternalDirectoryObjectID = $onPremData[$i].externalDirectoryObjectID
                        ObjectSID = $onPremData[$i].objectSID
                        IsValidMember = "TRUE"
                        ErrorMessage = "N/A"
                    }

                    $onPremData = @($onPremData | where-object {$_.primarySMTPAddress -ne $onPremData[$i].userPrincipalName})

                    $functionReturnArray += $functionObject
                }
                else {
                    out-logfile -string "On premises user principal name not found in Office 365 data."
                }
            }
            else {
                out-logfile "Did not fit what we expected to find."
            }
        }

        if ($onPremData.count -gt 0)
        {
            out-logfile -string "Issues with on premises members."

            foreach ($member in $onPremData)
            {
                $functionObject = New-Object PSObject -Property @{
                    Name = $member.name
                    PrimarySMTPAddress = $member.primarySMTPAddress
                    UserPrincipalName = $member.userPrincipalName
                    ExternalDirectoryObjectID = $member.externalDirectoryObjectID
                    ObjectSID = $member.objectSID
                    IsValidMember = "FALSE"
                    ErrorMessage = "MEMBER_ONPREM_NOT_IN_OFFICE365_EXCEPTION"
                }

                $functionReturnArray += $functionObject
            }

            
        }

        if ($office365Data.count -gt 0)
        {
            out-logfile -string "Issues with Office 365 members."

            foreach ($member in $office365Data)
            {
                if ($member.isAmbiguous -eq $TRUE)
                {
                    out-logfile -string "Member is ambiguous - record different exception."
                    
                    $functionObject = New-Object PSObject -Property @{
                        Name = $member.displayName
                        PrimarySMTPAddress = $member.primarySMTPAddress
                        UserPrincipalName = "N/A"
                        ExternalDirectoryObjectID = $member.externalDirectoryObjectID
                        ObjectSID = "N/A"
                        IsValidMember = "FALSE"
                        ErrorMessage = "AMBIGUOUS_MEMBER_IN_OFFICE365_NOT_ONPREM_EXCEPTION"
                    }
                }
                else {
                    $functionObject = New-Object PSObject -Property @{
                        Name = $member.displayName
                        PrimarySMTPAddress = $member.primarySMTPAddress
                        UserPrincipalName = "N/A"
                        ExternalDirectoryObjectID = $member.externalDirectoryObjectID
                        ObjectSID = "N/A"
                        IsValidMember = "FALSE"
                        ErrorMessage = "MEMBER_IN_OFFICE365_NOT_ONPREM_EXCEPTION"
                    }
                }

                $functionReturnArray += $functionObject
            }
        }
    }

    Out-LogFile -string "END compare-recipientArrays"
    Out-LogFile -string "********************************************************************************"

    out-logfile $functionReturnArray

    return $functionReturnArray
}