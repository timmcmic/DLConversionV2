function compare-recipientArrays
{
    param(
        [Parameter(Mandatory = $true,ParameterSetName = 'ProxyAddresses')]
        [Parameter(Mandatory = $true,ParameterSetName = 'AllTest')]
        [Parameter(Mandatory = $true,ParameterSetName = 'AttributeTest')]
        $onPremData=$NULL,
        [Parameter(Mandatory = $true,ParameterSetName = 'ProxyAddresses')]
        [Parameter(Mandatory = $true,ParameterSetName = 'AllTest')]
        $azureData=$NULL,
        [Parameter(Mandatory = $true,ParameterSetName = 'ProxyAddresses')]
        [Parameter(Mandatory = $true,ParameterSetName = 'AllTest')]
        [Parameter(Mandatory = $true,ParameterSetName = 'AttributeTest')]
        $office365Data=$NULL,
        [Parameter(Mandatory = $true,ParameterSetName = 'ProxyAddresses')]
        $isProxyTest=$false,
        [Parameter(Mandatory = $true,ParameterSetName = 'AllTest')]
        $isAllTest=$false,
        [Parameter(Mandatory = $true,ParameterSetName = 'AttributeTest')]
        $isAttributeTest=$false
    )

    [array]$functionReturnArray = @()
    $blogURL = "https://timmcmic.wordpress.com"

    $memberOnPremNotInOffice365Exception = "MEMBER_ONPREM_NOT_IN_OFFICE365_EXCEPTION"
    $valueErrorMessageNotApplicable = "N/A"
    $valueExceptionOnPremisesProxyMissingExchangeOnline="EXCEPTION_ONPREMSIES_PROXY_MISSING_EXCHANGE_ONLINE"
    $valueExceptionONPremisesProxyMissingAzureActiveDirectory = "EXCEPTION_ONPREMSIES_PROXY_MISSING_AZURE_ACTIVE_DIRECTORY"
    $valueExceptionOffice365ProxyMissingOnPremisesDirectoryException = "EXCEPTION_OFFICE365_PROXY_MISSING_ONPREMISES_DIRECTORY"
    $valueExceptionOffice365ProxyMissingAzureActiveDirectory = "EXCEPTION_OFFICE365_PROXY_MISSING_AZURE_ACTIVE_DIRECTORY"
    $valueMemberOffice365NotInAzureException = "MEMBER_OFFICE365_NOT_IN_AZURE_EXCEPTION"

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "BEGIN compare-recipientArrays"
    Out-LogFile -string "********************************************************************************"
 

    #===========================================================================================

    $createOnPremLists={
        $onPremDataBySID = New-Object "System.Collections.Generic.Dictionary``2[System.String, System.Object]"
        $onPremDataByPrimarySMTPAddress = New-Object "System.Collections.Generic.Dictionary``2[System.String, System.Object]"
        $onPremDataByExternalDirectoryObjectID = New-Object "System.Collections.Generic.Dictionary``2[System.String, System.Object]"

        foreach ($onPremObject in $onPremData)
        {
            if ($onPremObject.externalDirectoryObjectID -ne $NULL)
            {
                out-logfile -string ("On Prem External Directory Object ID: "+$onPremObject.externalDirectoryObjectID)
                $onPremDataByExternalDirectoryObjectID.Add($onPremObject.externalDirectoryObjectID, $onPremObject)
            }
            
            elseif ($onPremObject.objectSID -ne $NULL)
            {
                out-logfile -string ("On Prem Object SID: "+$onPremObject.objectSID)
                $onPremDataBySID.Add($onPremObject.ObjectSID, $onPremObject)
            }

            elseif ($onPremObject.primarySMTPAddress -ne $NULL)
            {
                out-logfile -string ("On Prem Primary SMTP Address: "+$onPremObject.primarySMTPAddress)
                $onPremDataByPrimarySMTPAddress.add($onPremObject.primarySMTPAddress,$onPremObject)
            }
        }
    }

    #===========================================================================================

    #===========================================================================================

    $createAzureLists={
        
        $azureDataByObjectId = New-Object "System.Collections.Generic.Dictionary``2[System.String, System.Object]"
        $azureDataBySID = New-Object "System.Collections.Generic.Dictionary``2[System.String, System.Object]"
        $azureDataByMail = New-Object "System.Collections.Generic.Dictionary``2[System.String, System.Object]"


        foreach ($azureObject in $azureData)
        {
            out-logfile -string ("Azure Data Object ID: "+$azureObject.ID)
            $azureDataByObjectId.Add($azureObject.ID, $azureObject)

            if ($azureObject.AdditionalProperties.onPremisesSecurityIdentifier -ne $NULL)
            {
                out-logfile -string ("Azure Data Object SID: "+$azureObject.AdditionalProperties.onPremisesSecurityIdentifier)
                $azureDataBySID.Add($azureObject.AdditionalProperties.onPremisesSecurityIdentifier, $azureObject)
            }

            if ($azureObject.AdditionalProperties.Mail -ne $NULL)
            {
                out-logfile -string ("Azure Data Object SID: "+$azureObject.AdditionalProperties.Mail)
                $azureDataByMail.Add($azureObject.AdditionalProperties.mail, $azureObject)
            }
        }
    }

    #===========================================================================================

    #===========================================================================================
    
    $createOffice365Lists=
    {
        $office365DataByExternalDirectoryObjectID = New-Object "System.Collections.Generic.Dictionary``2[System.String, System.Object]"
        $office365DataByExternalSMTPAddress = New-Object "System.Collections.Generic.Dictionary``2[System.String, System.Object]"


        foreach ($office365Object in $office365Data)
        {
            out-logfile -string ("Office 365 Data External Directory Object ID: "+$office365Object.externalDirectoryObjectID)
            $office365DataByExternalDirectoryObjectID.Add($office365Object.externalDirectoryObjectID, $office365Object)

            if ($office365Object.externalEmailAddress -ne $NULL)
            {
                out-logfile -string ("Office 365 Data Primary SMTP Address: "+$office365Object.externalEmailAddress)
                $office365DataByExternalSMTPAddress.add($office365Object.externalEmailAddress.split(":")[1],$office365Object)
            }
        }
    }

    #===========================================================================================

    #===========================================================================================
    
    $createArrayLists ={
        
        .$createAzureLists

        .$createOnPremLists

        .$createOffice365Lists
    }

    #===========================================================================================

    if($isProxyTest -eq $TRUE)
    {
        out-logfile -string "Comparing data from all three directories - this has to be proxy addresses."

        out-logfile -string "Start comparing on premises to AzureAD to Office 365."

        foreach ($member in $onPremData)
        {
            out-logfile -string "Testing azure for presence of proxy address."
            out-logfile -string $member

            if ($azureData -contains $member)
            {
                $functionObject = New-Object PSObject -Property @{
                    ProxyAddress = $member
                    isPresentOnPremises = "Source"
                    isPresentInAzure = "True"
                    isPresentInExchangeOnline = "False"
                    isValidMember = "N/A"
                    ErrorMessage = $valueErrorMessageNotApplicable
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
                    $functionObject.errorMessage = "<a href='$blogUrl' rel=noopener noreferrer>$valueExceptionOnPremisesProxyMissingExchangeOnline</a>"
                }
            }
            else 
            {
                out-logfile -string "Proxy address not present in Azure AD.  No further testing required."

                $functionObject = New-Object PSObject -Property @{
                    ProxyAddress = $member
                    isPresentOnPremises = "Source"
                    isPresentInAzure = "False"
                    isPresentInExchangeOnline = "False"
                    isValidMember = "False"
                    ErrorMessage = "<a href='$blogUrl' rel=noopener noreferrer>'$valueExceptionONPremisesProxyMissingAzureActiveDirectory'</a>"
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
                    ProxyAddress = $member
                    isPresentOnPremises = "False"
                    isPresentInAzure = "True"
                    isPresentInExchangeOnline = "Source"
                    isValidMember = "N/A"
                    ErrorMessage = $valueErrorMessageNotApplicable
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
                    $functionObject.errorMessage = "<a href='$blogUrl' rel=noopener noreferrer>'$valueExceptionOffice365ProxyMissingOnPremisesDirectoryException'</a>"
                }
            }
            else 
            {
                out-logfile -string "Proxy address not present in Azure AD.  No further testing required."

                $functionObject = New-Object PSObject -Property @{
                    ProxyAddress = $member
                    isPresentOnPremises = "False"
                    isPresentInAzure = "False"
                    isPresentInExchangeOnline = "Source"
                    isValidMember = "False"
                    ErrorMessage = "<a href='$blogUrl' rel=noopener noreferrer>'$valueExceptionOffice365ProxyMissingAzureActiveDirectory'</a>"
                }
            }

            $functionReturnArray += $functionObject
        }
    }
    elseif ($isAllTest -eq $TRUE)
    {
        out-logfile -string "Calling function to create the array lists."

        .$createArrayLists

        out-logfile -string "Comparing data from all three directories - this has to be membership."

        out-logfile -string "Starting the comparison in the reverse order - compare Exchange Online -> Azure -> On Premises."

        foreach ($member in $office365Data)
        {
            out-logfile -string ("Evaluating member: "+$member.externalDirectoryObjectID)
            out-logfile -string $member

            out-logfile -string "In this case start comparison by external directory object id - all Office 365 objects have it unless it's a room distribution list."
            out-logfile -string "Starting Exchange Online -> Azure Evaluation"

            out-logfile -string "Determining if the object has a primary SMTP address or only an external address.  Guest users <or> mail contacts may have external addresses."

            if ($member.primarySMTPAddress.length -gt 0)
            {
                out-logfile -string "Primary SMTP Address is present - length greater than 0"

                $functionPrimarySMTPAddress = $member.primarySMTPAddress

                out-logfile -string $functionPrimarySMTPAddress
            }
            elseif ($member.externalEmailAddress -ne $NULL) 
            {
                out-logfile -string "External email address is present."
                out-logfile -string $member.externalEmailAddress

                out-logfile -string $member

                $functionPrimarySMTPAddress = $member.externalEmailAddress.split(":")

                $functionPrimarySMTPAddress = $functionPrimarySMTPAddress[1]

                out-logfile -string $functionPrimarySMTPAddress
            }
            else 
            {
                out-logfile -string "Object does not have a proxy address - consider a synced security group?"

                $functionPrimarySMTPAddress = "N/A"
            }

            if ($azureDataByObjectID.ContainsKey($member.externalDirectoryObjectID))
            {
                out-logfile -string "The object was found in Azure AD. -> GOOD"
                out-logfile -string "Capture the azure object so that we can build the output object with it's attributes."

                $functionAzureObject = $azureDataByObjectID[$member.externalDirectoryObjectID]

                out-logfile -string $functionAzureObject
                out-logfile -string $functionAzureObject.AdditionalProperties

                out-logfile -string "Attempt to obtain a user principal name."

                if ($functionAzureObject.AdditionalProperties.userPrincipalName -ne $NULL)
                {
                    out-logfile -string "Object has a user principal name."
                    $functionUserPrincipalName = $functionAzureObject.AdditionalProperties.userPrincipalName
                }
                else 
                {
                    out-logfile -string "Object does not have a user principal name."
                    $functionUserPrincipalName = "N/A"
                }

                out-logfile -string $functionUserPrincipalName

                out-logfile -string "Determine if the object is a security identifier - log on premises security ID."

                if ($functionAzureObject.AdditionalProperties.onPremisesSecurityIdentifier -ne $NULL)
                {
                    out-logfile -string "Object has an on premsies object SID - add to the object."
                    $functionOnPremisesObjectSID = $functionAzureObject.AdditionalProperties.onPremisesSecurityIdentifier
                }
                else 
                {
                    out-logfile -string "Object does not have an on premsies object sid."
                    $functionOnPremisesObjectSID = "N/A"
                }

                out-logfile -string $functionOnPremisesObjectSID

                $functionObject = New-Object PSObject -Property @{
                    Name = $member.name
                    DisplayName = $member.displayName
                    PrimarySMTPAddress = $functionPrimarySMTPAddress
                    UserPrincipalName = $functionUserPrincipalName
                    ExternalDirectoryObjectID = $member.externalDirectoryObjectID
                    OnPremObjectSID = $functionOnPremisesObjectSID
                    isPresentOnPremises = "False"
                    isPresentInAzure = "True"
                    isPresentInExchangeOnline = "Source"
                    IsValidMember = "FALSE"
                    ErrorMessage = $valueErrorMessageNotApplicable
                }

                out-logfile -string $functionObject

                out-logfile -string "Being Office 365 -> On premises evaluation."
                out-logfile -string "The objects are matched either by external directory object id, object sid, or primary SMTP address."

                $functionExternalDirectoryObjectID = ("User_"+$member.externalDirectoryObjectID)

                out-logfile -string $functionExternalDirectoryObjectID

                if ($onPremDataByExternalDirectoryObjectID.ContainsKey($functionExternalDirectoryObjectID))
                {
                    out-logfile -string ("Found object on premises by external directory object id. "+$functionExternalDirectoryObjectID)

                    $functionObject.isPresentOnPremises = "True"
                    $functionObject.isValidMember = "TRUE"

                    out-logfile -string $functionObject

                    $functionReturnArray += $functionObject

                    $functionOnPremObject = $onPremDataByExternalDirectoryObjectID[$functionExternalDirectoryObjectID]

                    $functionObject = New-Object PSObject -Property @{
                        Name = $functionOnPremObject.name
                        DisplayName = $functionOnPremObject.displayName
                        PrimarySMTPAddress = $functionOnPremObject.primarySMTPAddress
                        UserPrincipalName = $functionOnPremObject.userPrincipalName
                        ExternalDirectoryObjectID = $functionOnPremObject.externalDirectoryObjectID
                        ObjectSID =$functionOnPremObject.objectSID
                        isPresentOnPremises = "Source"
                        isPresentInAzure = "True"
                        isPresentInExchangeOnline = "True"
                        IsValidMember = "TRUE"
                        ErrorMessage = $valueErrorMessageNotApplicable
                    }

                    $functionReturnArray += $functionObject

                    out-logfile -string $functionObject

                    $onPremDataByExternalDirectoryObjectID.remove($functionExternalDirectoryObjectID)
                }
                elseif ($onPremDataBySID.ContainsKey($functionObject.OnPremObjectSID ))
                {
                    out-logfile -string ("The object was located by object SID: "+$functionObject.objectSID)
                    $functionObject.isPresentOnPremises = "True"
                    $functionObject.isValidMember = "TRUE"

                    out-logfile -string $functionObject

                    $functionReturnArray += $functionObject

                    $functionOnPremObject = $onPremDataBySID[$functionObject.OnPremObjectSID ]

                    $functionObject = New-Object PSObject -Property @{
                        Name = $functionOnPremObject.name
                        DisplayName = $functionOnPremObject.displayName
                        PrimarySMTPAddress = $functionOnPremObject.primarySMTPAddress
                        UserPrincipalName = $functionOnPremObject.userPrincipalName
                        ExternalDirectoryObjectID = $functionOnPremObject.externalDirectoryObjectID
                        ObjectSID =$functionOnPremObject.objectSID
                        isPresentOnPremises = "Source"
                        isPresentInAzure = "True"
                        isPresentInExchangeOnline = "True"
                        IsValidMember = "TRUE"
                        ErrorMessage = $valueErrorMessageNotApplicable
                    }

                    $functionReturnArray += $functionObject

                    out-logfile -string $functionObject

                    $onPremDataBySID.remove($functionObject.objectSID)
                }
                
                elseif ($onPremDataByPrimarySMTPAddress.ContainsKey($functionPrimarySMTPAddress))
                {
                    out-logfile -string ("The object was located by primary SMTP Address: "+$functionPrimarySMTPAddress)

                    $functionObject.isPresentOnPremises = "True"
                    $functionObject.isValidMember = "TRUE"

                    out-logfile -string $functionObject

                    $functionReturnArray += $functionObject

                    $functionOnPremObject = $onPremDataByPrimarySMTPAddress[$functionPrimarySMTPAddress]

                    $functionObject = New-Object PSObject -Property @{
                        Name = $functionOnPremObject.name
                        DisplayName = $functionOnPremObject.displayName
                        PrimarySMTPAddress = $functionOnPremObject.primarySMTPAddress
                        UserPrincipalName = $functionOnPremObject.userPrincipalName
                        ExternalDirectoryObjectID = $functionOnPremObject.externalDirectoryObjectID
                        ObjectSID =$functionOnPremObject.objectSID
                        isPresentOnPremises = "Source"
                        isPresentInAzure = "True"
                        isPresentInExchangeOnline = "True"
                        IsValidMember = "TRUE"
                        ErrorMessage = $valueErrorMessageNotApplicable
                    }

                    $functionReturnArray += $functionObject

                    out-logfile -string $functionObject

                    $onPremDataByPrimarySMTPAddress.remove($functionPrimarySMTPAddress)
                }
                else 
                {
                    out-logfile -string "The object was not located in the on premises membership - NOT GOOD."

                    $functionObject.ErrorMessage = "<a href='$blogUrl' rel=noopener noreferrer>MEMBER_OFFICE365_NOT_IN_ONPREMISES_EXCEPTION</a>"

                    out-logfile -string $functionObject

                    $functionReturnArray += $functionObject
                }
            }
            else
            {
                out-logfile -string "The object was not found in Azure AD -> BAD"

                $functionObject = New-Object PSObject -Property @{
                    Name = $member.name
                    DisplayName = $member.displayName
                    PrimarySMTPAddress = $member.primarySMTPAddress
                    UserPrincipalName = "N/A"
                    ExternalDirectoryObjectID = $member.externalDirectoryObjectID
                    ObjectSID ="N/A"
                    isPresentOnPremises = "False"
                    isPresentInAzure = "False"
                    isPresentInExchangeOnline = "Source"
                    IsValidMember = "FALSE"
                    ErrorMessage = "<a href='$blogUrl' rel=noopener noreferrer>'$valueMemberOffice365NotInAzureException'</a>"
                }

                out-logfile -string $functionObject

                $functionReturnArray += $functionObject
            }
        }

        out-logfile -string "If the on premises data dictionaries contain any more users - these users were not also present in Office 365."
        out-logfile -string "Test only to see if the users are in Azure.  If they are not in Azure that's the issue - if not it's between Azure and Exchange Online."

        if ($onPremDataByExternalDirectoryObjectID.count -gt 0)
        {
            out-logfile -string "On premises by external directory object id remain for processing - process those users."

            foreach ($member in $onPremDataByExternalDirectoryObjectID.Values)
            {
                $functionExternalDirectoryObjectID = $member.externalDirectoryObjectID.split("_")[1]

                if ($azureDataByObjectID.ContainsKey($functionExternalDirectoryObjectID))
                {
                    out-logfile -string "The object was not found in Azure AD -> BAD"

                    $functionObject = New-Object PSObject -Property @{
                        Name = $member.name
                        DisplayName = $member.displayName
                        PrimarySMTPAddress = $member.primarySMTPAddress
                        UserPrincipalName = $member.userPrincipalName
                        ExternalDirectoryObjectID = $member.externalDirectoryObjectID
                        ObjectSID =$member.ObjectSID
                        isPresentOnPremises = "Source"
                        isPresentInAzure = "True"
                        isPresentInExchangeOnline = "False"
                        IsValidMember = "FALSE"
                        ErrorMessage = "MEMBER_ONPREMISES_NOT_IN_OFFICE365_EXCEPTION"
                    }

                    out-logfile -string $functionObject

                    $functionReturnArray += $functionObject
                }
                else 
                {
                    out-logfile -string "The object was not found in Azure AD -> BAD"

                    $functionObject = New-Object PSObject -Property @{
                        Name = $member.name
                        DisplayName = $member.displayName
                        PrimarySMTPAddress = $member.primarySMTPAddress
                        UserPrincipalName = $member.userPrincipalName
                        ExternalDirectoryObjectID = $member.externalDirectoryObjectID
                        ObjectSID =$member.ObjectSID
                        isPresentOnPremises = "Source"
                        isPresentInAzure = "False"
                        isPresentInExchangeOnline = "False"
                        IsValidMember = "FALSE"
                        ErrorMessage = "MEMBER_ONPREMISES_NOT_IN_AZURE_EXCEPTION"
                    }

                    out-logfile -string $functionObject

                    $functionReturnArray += $functionObject
                }
            }
        }

        if ($onPremDataBySID.count -gt 0)
        {
            out-logfile -string "On premises by SID remain for processing - process those users."

            foreach ($member in $onPremDataBySID.Values)
            {
                if($azureDataBySID.ContainsKey($member.objectSID))
                {
                    out-logfile -string "The object was not found in Exchange Online -> BAD"

                    $functionObject = New-Object PSObject -Property @{
                        Name = $member.name
                        DisplayName = $member.displayName
                        PrimarySMTPAddress = $member.primarySMTPAddress
                        UserPrincipalName = $member.userPrincipalName
                        ExternalDirectoryObjectID = $member.externalDirectoryObjectID
                        ObjectSID =$member.ObjectSID
                        isPresentOnPremises = "Source"
                        isPresentInAzure = "True"
                        isPresentInExchangeOnline = "False"
                        IsValidMember = "FALSE"
                        ErrorMessage = "MEMBER_ONPREMISES_NOT_IN_OFFICE365_EXCEPTION"
                    }

                    out-logfile -string $functionObject

                    $functionReturnArray += $functionObject
                }
                else 
                {
                    out-logfile -string "The object was not found in Azure AD -> BAD"

                    $functionObject = New-Object PSObject -Property @{
                        Name = $member.name
                        DisplayName = $member.displayName
                        PrimarySMTPAddress = $member.primarySMTPAddress
                        UserPrincipalName = $member.userPrincipalName
                        ExternalDirectoryObjectID = $member.externalDirectoryObjectID
                        ObjectSID =$member.ObjectSID
                        isPresentOnPremises = "Source"
                        isPresentInAzure = "False"
                        isPresentInExchangeOnline = "False"
                        IsValidMember = "FALSE"
                        ErrorMessage = "MEMBER_ONPREMISES_NOT_IN_AZURE_EXCEPTION"
                    }

                    out-logfile -string $functionObject

                    $functionReturnArray += $functionObject
                }
            }
        }

        if ($onPremDataByPrimarySMTPAddress.count -gt 0)
        {
            out-logfile -string "On premises by primary SMTP remain for processing - process those users."

            foreach ($member in $onPremDataByPrimarySMTPAddress.Values)
            {
                if($azureDataByMail.ContainsKey($member.primarySMTPAddress))
                {
                    out-logfile -string "The object was not found in Exchange Online -> BAD"

                    $functionObject = New-Object PSObject -Property @{
                        Name = $member.name
                        DisplayName = $member.displayName
                        PrimarySMTPAddress = $member.primarySMTPAddress
                        UserPrincipalName = $member.userPrincipalName
                        ExternalDirectoryObjectID = $member.externalDirectoryObjectID
                        ObjectSID =$member.ObjectSID
                        isPresentOnPremises = "Source"
                        isPresentInAzure = "True"
                        isPresentInExchangeOnline = "False"
                        IsValidMember = "FALSE"
                        ErrorMessage = "MEMBER_ONPREMISES_NOT_IN_OFFICE365_EXCEPTION"
                    }

                    out-logfile -string $functionObject

                    $functionReturnArray += $functionObject
                }
                else 
                {
                    out-logfile -string "The object was not discovered by primary SMTP address - this may not necessarily be incorrect since contacts may not have a primary SMTP in Azure."
                    out-logfile -string "Search the Office 365 data for the primary SMTP address assume the objects are the same."

                    if ($office365DataByExternalSMTPAddress.ContainsKey($member.primarySMTPAddress))
                    {
                        out-logfile -string "The object is most likely a contact with an external mail address not represented in azure with a primary proxy address."

                        $functionObject = New-Object PSObject -Property @{
                        Name = $member.name
                        DisplayName = $member.displayName
                        PrimarySMTPAddress = $member.primarySMTPAddress
                        UserPrincipalName = $member.userPrincipalName
                        ExternalDirectoryObjectID = $member.externalDirectoryObjectID
                        ObjectSID =$member.ObjectSID
                        isPresentOnPremises = "Source"
                        isPresentInAzure = "True"
                        isPresentInExchangeOnline = "True"
                        IsValidMember = "TRUE"
                        ErrorMessage = $valueErrorMessageNotApplicable
                        }

                        out-logfile -string $functionObject

                        $functionReturnArray += $functionObject
                    }
                    else 
                    {
                        out-logfile -string "The object was not found in Azure AD -> BAD"

                        $functionObject = New-Object PSObject -Property @{
                            Name = $member.name
                            DisplayName = $member.displayName
                            PrimarySMTPAddress = $member.primarySMTPAddress
                            UserPrincipalName = $member.userPrincipalName
                            ExternalDirectoryObjectID = $member.externalDirectoryObjectID
                            ObjectSID =$member.ObjectSID
                            isPresentOnPremises = "Source"
                            isPresentInAzure = "False"
                            isPresentInExchangeOnline = "False"
                            IsValidMember = "FALSE"
                            ErrorMessage = "MEMBER_ONPREMISES_NOT_IN_AZURE_EXCEPTION"
                        }
                    }
                    
                    out-logfile -string $functionObject

                    $functionReturnArray += $functionObject
                }
            }
        }    
    }
    elseif ($isAttributeTest -eq $TRUE)
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
                    out-logfile -string "Member found in Office 365."

                    out-logfile -string "Removing object from office 365 array..."

                    $office365Data = @($office365Data | where-object {$_.ExternalDirectoryObjectID -ne $onPremData[$i].externalDirectoryObjectID})

                    out-logfile -string "Removing object from on premises array."

                    #$functionAzureObject = $azureData | where-object {$_.objectID -eq $functionExternalDirectoryObjectID}

                    $functionObject = New-Object PSObject -Property @{
                        Name = $onPremData[$i].name
                        DisplayName = $onPremData[$i].displayName
                        PrimarySMTPAddress = $onPremData[$i].primarySMTPAddress
                        UserPrincipalName = $onPremData[$i].userPrincipalName
                        ExternalDirectoryObjectID = $onPremData[$i].externalDirectoryObjectID
                        ObjectSID = $onPremData[$i].objectSID
                        isPresentOnPremises = "True"
                        isPresentInAzure = "N/A"
                        isPresentInExchangeOnline = "True"
                        IsValidMember = "TRUE"
                        ErrorMessage = $valueErrorMessageNotApplicable
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
                        DisplayName = $onPremData[$i].displayName
                        PrimarySMTPAddress = $onPremData[$i].primarySMTPAddress
                        UserPrincipalName = $onPremData[$i].userPrincipalName
                        ExternalDirectoryObjectID = $onPremData[$i].externalDirectoryObjectID
                        ObjectSID = $onPremData[$i].objectSID
                        isPresentOnPremises = "True"
                        isPresentInAzure = "N/A"
                        isPresentInExchangeOnline = "True"
                        IsValidMember = "TRUE"
                        ErrorMessage = $valueErrorMessageNotApplicable
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
                        DisplayName = $onPremData[$i].displayName
                        PrimarySMTPAddress = $onPremData[$i].primarySMTPAddress
                        UserPrincipalName = $onPremData[$i].userPrincipalName
                        ExternalDirectoryObjectID = $onPremData[$i].externalDirectoryObjectID
                        ObjectSID = $onPremData[$i].objectSID
                        isPresentOnPremises = "True"
                        isPresentInAzure = "N/A"
                        isPresentInExchangeOnline = "True"
                        IsValidMember = "TRUE"
                        ErrorMessage = $valueErrorMessageNotApplicable
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
                    DisplayName = $memeber.displayName
                    PrimarySMTPAddress = $member.primarySMTPAddress
                    UserPrincipalName = $member.userPrincipalName
                    ExternalDirectoryObjectID = $member.externalDirectoryObjectID
                    ObjectSID = $member.objectSID
                    isPresentOnPremises = "True"
                    isPresentInAzure = "N/A"
                    isPresentInExchangeOnline = "False"
                    IsValidMember = "FALSE"
                    ErrorMessage = "<a href='$blogUrl' rel=noopener noreferrer>'$memberOnPremNotInOffice365Exception'</a>"
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
                        DisplayName = $memeber.displayName
                        PrimarySMTPAddress = $member.primarySMTPAddress
                        UserPrincipalName = "N/A"
                        ExternalDirectoryObjectID = $member.externalDirectoryObjectID
                        ObjectSID = "N/A"
                        isPresentOnPremises = "False"
                        isPresentInAzure = "N/A"
                        isPresentInExchangeOnline = "True"
                        IsValidMember = "FALSE"
                        ErrorMessage = "AMBIGUOUS_MEMBER_IN_OFFICE365_NOT_ONPREM_EXCEPTION"
                    }
                }
                else {
                    $functionObject = New-Object PSObject -Property @{
                        Name = $member.displayName
                        DisplayName = $memeber.displayName
                        PrimarySMTPAddress = $member.primarySMTPAddress
                        UserPrincipalName = "N/A"
                        ExternalDirectoryObjectID = $member.externalDirectoryObjectID
                        ObjectSID = "N/A"
                        isPresentOnPremises = "False"
                        isPresentInAzure = "N/A"
                        isPresentInExchangeOnline = "True"
                        IsValidMember = "FALSE"
                        ErrorMessage = "MEMBER_IN_OFFICE365_NOT_ONPREM_EXCEPTION"
                    }
                }

                $functionReturnArray += $functionObject
            }
        }
    }
    else 
    {
        out-logfile -string "Something went wrong on this comparison call and we did not do anything."
    }

    Out-LogFile -string "END compare-recipientArrays"
    Out-LogFile -string "********************************************************************************"

    out-logfile $functionReturnArray

    return $functionReturnArray
}