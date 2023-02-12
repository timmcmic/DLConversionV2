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


    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "BEGIN compare-recipientArrays"
    Out-LogFile -string "********************************************************************************"

    out-logfile -string "Preparing array to array list conversion for work in this function."

    $onPremDataList = New-Object -TypeName "System.Collections.ArrayList"
    $azureDataList = New-Object -TypeName "System.Collections.ArrayList"
    $office365DataList = New-Object -TypeName "System.Collections.ArrayList"

    out-logfile -string "Creating the split lists of Azure Data."

    $functionAzureDataList1 = New-Object -TypeName "System.Collections.ArrayList"
    $functionAzureDataList2 = New-Object -TypeName "System.Collections.ArrayList" 
    $functionAzureDataList3 = New-Object -TypeName "System.Collections.ArrayList" 
    $functionAzureDataList4 = New-Object -TypeName "System.Collections.ArrayList" 
    $functionAzureDataList5 = New-Object -TypeName "System.Collections.ArrayList" 
    $functionAzureDataList6 = New-Object -TypeName "System.Collections.ArrayList" 
    $functionAzureDataList7 = New-Object -TypeName "System.Collections.ArrayList" 
    $functionAzureDataList8 = New-Object -TypeName "System.Collections.ArrayList" 
    $functionAzureDataList9 = New-Object -TypeName "System.Collections.ArrayList" 
    $functionAzureDataListA = New-Object -TypeName "System.Collections.ArrayList" 
    $functionAzureDataListC = New-Object -TypeName "System.Collections.ArrayList" 
    $functionAzureDataListD = New-Object -TypeName "System.Collections.ArrayList" 
    $functionAzureDataListE = New-Object -TypeName "System.Collections.ArrayList" 
    $functionAzureDataListF = New-Object -TypeName "System.Collections.ArrayList"  
    $functionAzureDataListOrig1 = New-Object -TypeName "System.Collections.ArrayList"
    $functionAzureDataListOrig2 = New-Object -TypeName "System.Collections.ArrayList" 
    $functionAzureDataListOrig3 = New-Object -TypeName "System.Collections.ArrayList" 
    $functionAzureDataListOrig4 = New-Object -TypeName "System.Collections.ArrayList" 
    $functionAzureDataListOrig5 = New-Object -TypeName "System.Collections.ArrayList" 
    $functionAzureDataListOrig6 = New-Object -TypeName "System.Collections.ArrayList" 
    $functionAzureDataListOrig7 = New-Object -TypeName "System.Collections.ArrayList" 
    $functionAzureDataListOrig8 = New-Object -TypeName "System.Collections.ArrayList" 
    $functionAzureDataListOrig9 = New-Object -TypeName "System.Collections.ArrayList" 
    $functionAzureDataListOrigA = New-Object -TypeName "System.Collections.ArrayList" 
    $functionAzureDataListOrigC = New-Object -TypeName "System.Collections.ArrayList" 
    $functionAzureDataListOrigD = New-Object -TypeName "System.Collections.ArrayList" 
    $functionAzureDataListOrigE = New-Object -TypeName "System.Collections.ArrayList" 
    $functionAzureDataListOrigF = New-Object -TypeName "System.Collections.ArrayList"

    $functionAzureData = New-Object -TypeName "System.Collections.ArrayList"

    #===========================================================================================
    function createOnPremLists
    {
    
    }

    #===========================================================================================

    #===========================================================================================
    function createAzureLists
    {
        out-logfile -string "Initialize the azure data lists with values."

        $functionAzureDataList1 = [System.Collections.ArrayList]@($azureDataList | where-object {$_.objectID.startsWith("1")} | sort-object -property objectID)
        $functionAzureDataList2 = [System.Collections.ArrayList]@($azureDataList | where-object {$_.objectID.startsWith("2")} | sort-object -property objectID)
        $functionAzureDataList3 = [System.Collections.ArrayList]@($azureDataList | where-object {$_.objectID.startsWith("3")} | sort-object -property objectID)
        $functionAzureDataList4 = [System.Collections.ArrayList]@($azureDataList | where-object {$_.objectID.startsWith("4")} | sort-object -property objectID)
        $functionAzureDataList5 = [System.Collections.ArrayList]@($azureDataList | where-object {$_.objectID.startsWith("5")} | sort-object -property objectID)
        $functionAzureDataList6 = [System.Collections.ArrayList]@($azureDataList | where-object {$_.objectID.startsWith("6")} | sort-object -property objectID)
        $functionAzureDataList7 = [System.Collections.ArrayList]@($azureDataList | where-object {$_.objectID.startsWith("7")} | sort-object -property objectID)
        $functionAzureDataList8 = [System.Collections.ArrayList]@($azureDataList | where-object {$_.objectID.startsWith("8")} | sort-object -property objectID)
        $functionAzureDataList9 = [System.Collections.ArrayList]@($azureDataList | where-object {$_.objectID.startsWith("9")} | sort-object -property objectID)
        $functionAzureDataListA = [System.Collections.ArrayList]@($azureDataList | where-object {$_.objectID.startsWith("a")} | sort-object -property objectID)
        $functionAzureDataListB = [System.Collections.ArrayList]@($azureDataList | where-object {$_.objectID.startsWith("b")} | sort-object -property objectID)
        $functionAzureDataListC = [System.Collections.ArrayList]@($azureDataList | where-object {$_.objectID.startsWith("c")} | sort-object -property objectID)
        $functionAzureDataListD = [System.Collections.ArrayList]@($azureDataList | where-object {$_.objectID.startsWith("d")} | sort-object -property objectID)
        $functionAzureDataListE = [System.Collections.ArrayList]@($azureDataList | where-object {$_.objectID.startsWith("e")} | sort-object -property objectID)
        
        out-logfile -string "Serialize the data into new array lists since this data set is evaluated twice in the all evaluation."

        $serialData = [System.Management.Automation.PSSerializer]::Serialize($functionAzureDataList1)
        $functionAzureDataList1Orig = [System.Collections.ArrayList]@(([System.Management.Automation.PSSerializer]::Deserialize($serialData)) | sort-object -property objectID)
        $serialData = [System.Management.Automation.PSSerializer]::Serialize($functionAzureDataList2)
        $functionAzureDataList2Orig = [System.Collections.ArrayList]@(([System.Management.Automation.PSSerializer]::Deserialize($serialData)) | sort-object -property objectID)
        $serialData = [System.Management.Automation.PSSerializer]::Serialize($functionAzureDataList3)
        $functionAzureDataList3Orig = [System.Collections.ArrayList]@(([System.Management.Automation.PSSerializer]::Deserialize($serialData)) | sort-object -property objectID)
        $serialData = [System.Management.Automation.PSSerializer]::Serialize($functionAzureDataList4)
        $functionAzureDataList4Orig = [System.Collections.ArrayList]@(([System.Management.Automation.PSSerializer]::Deserialize($serialData)) | sort-object -property objectID)
        $serialData = [System.Management.Automation.PSSerializer]::Serialize($functionAzureDataList5)
        $functionAzureDataList5Orig = [System.Collections.ArrayList]@(([System.Management.Automation.PSSerializer]::Deserialize($serialData)) | sort-object -property objectID)
        $serialData = [System.Management.Automation.PSSerializer]::Serialize($functionAzureDataList6)
        $functionAzureDataList6Orig = [System.Collections.ArrayList]@(([System.Management.Automation.PSSerializer]::Deserialize($serialData)) | sort-object -property objectID)
        $serialData = [System.Management.Automation.PSSerializer]::Serialize($functionAzureDataList7)
        $functionAzureDataList7Orig = [System.Collections.ArrayList]@(([System.Management.Automation.PSSerializer]::Deserialize($serialData)) | sort-object -property objectID)
        $serialData = [System.Management.Automation.PSSerializer]::Serialize($functionAzureDataList8)
        $functionAzureDataList8Orig = [System.Collections.ArrayList]@(([System.Management.Automation.PSSerializer]::Deserialize($serialData)) | sort-object -property objectID)
        $serialData = [System.Management.Automation.PSSerializer]::Serialize($functionAzureDataList9)
        $functionAzureDataList9Orig = [System.Collections.ArrayList]@(([System.Management.Automation.PSSerializer]::Deserialize($serialData)) | sort-object -property objectID)
        $serialData = [System.Management.Automation.PSSerializer]::Serialize($functionAzureDataListA)
        $functionAzureDataListAOrig = [System.Collections.ArrayList]@(([System.Management.Automation.PSSerializer]::Deserialize($serialData)) | sort-object -property objectID)
        $serialData = [System.Management.Automation.PSSerializer]::Serialize($functionAzureDataListB)
        $functionAzureDataListBOrig = [System.Collections.ArrayList]@(([System.Management.Automation.PSSerializer]::Deserialize($serialData)) | sort-object -property objectID)
        $serialData = [System.Management.Automation.PSSerializer]::Serialize($functionAzureDataListC)
        $functionAzureDataListCOrig = [System.Collections.ArrayList]@(([System.Management.Automation.PSSerializer]::Deserialize($serialData)) | sort-object -property objectID)
        $serialData = [System.Management.Automation.PSSerializer]::Serialize($functionAzureDataListD)
        $functionAzureDataListDOrig = [System.Collections.ArrayList]@(([System.Management.Automation.PSSerializer]::Deserialize($serialData)) | sort-object -property objectID)
        $serialData = [System.Management.Automation.PSSerializer]::Serialize($functionAzureDataListE)
        $functionAzureDataListEOrig = [System.Collections.ArrayList]@(([System.Management.Automation.PSSerializer]::Deserialize($serialData)) | sort-object -property objectID)

        out-logfile -string "Output azure array list counts for debugging."

        out-logfile -string ("Azure Function Data List 1: "+$functionAzureDataList1.count)
        out-logfile -string ("Azure Function Data List Original 1: "+$functionAzureDataList1Orig.count)
        out-logfile -string ("Azure Function Data List 2: "+$functionAzureDataList2.count)
        out-logfile -string ("Azure Function Data List Original 2: "+$functionAzureDataList2Orig.count)
        out-logfile -string ("Azure Function Data List 3: "+$functionAzureDataList3.count)
        out-logfile -string ("Azure Function Data List Original 3: "+$functionAzureDataList3Orig.count)
        out-logfile -string ("Azure Function Data List 4: "+$functionAzureDataList4.count)
        out-logfile -string ("Azure Function Data List Original 4: "+$functionAzureDataList4Orig.count)
        out-logfile -string ("Azure Function Data List 5: "+$functionAzureDataList5.count)
        out-logfile -string ("Azure Function Data List Original 5: "+$functionAzureDataList5Orig.count)
        out-logfile -string ("Azure Function Data List 6: "+$functionAzureDataList6.count)
        out-logfile -string ("Azure Function Data List Original 6: "+$functionAzureDataList6Orig.count)
        out-logfile -string ("Azure Function Data List 7: "+$functionAzureDataList7.count)
        out-logfile -string ("Azure Function Data List Original 7: "+$functionAzureDataList7Orig.count)
        out-logfile -string ("Azure Function Data List 8: "+$functionAzureDataList8.count)
        out-logfile -string ("Azure Function Data List Original 8: "+$functionAzureDataList8Orig.count)
        out-logfile -string ("Azure Function Data List 9: "+$functionAzureDataList9.count)
        out-logfile -string ("Azure Function Data List Original 9: "+$functionAzureDataList9Orig.count)
        out-logfile -string ("Azure Function Data List A: "+$functionAzureDataListA.count)
        out-logfile -string ("Azure Function Data List Original A: "+$functionAzureDataListAOrig.count)
        out-logfile -string ("Azure Function Data List B: "+$functionAzureDataListB.count)
        out-logfile -string ("Azure Function Data List Original B: "+$functionAzureDataListBOrig.count)
        out-logfile -string ("Azure Function Data List C: "+$functionAzureDataListC.count)
        out-logfile -string ("Azure Function Data List Original C: "+$functionAzureDataListCOrig.count)
        out-logfile -string ("Azure Function Data List D: "+$functionAzureDataListD.count)
        out-logfile -string ("Azure Function Data List Original D: "+$functionAzureDataListDOrig.count)
        out-logfile -string ("Azure Function Data List E: "+$functionAzureDataListE.count)
        out-logfile -string ("Azure Function Data List Original E: "+$functionAzureDataListEOrig.count)
    }

    #===========================================================================================

    #===========================================================================================
    function createOffice365Lists
    {
    
    }

    #===========================================================================================

    #===========================================================================================
    function createArrayLists
    {
        out-logfile -string "Moving the array information into array lists for manipulation."

        $onPremDataList = [System.Collections.ArrayList]@($onPremData)
        $azureDataList = [System.Collections.ArrayList]@($azureData)
        $office365DataList = [System.Collections.ArrayList]@($office365Data)

        out-logfile -string "Record count comparisons for evaluation / debugging"

        out-logfile -string ("On Prem Array Count: "+$onPremData.count)
        out-logfile -string ("On Prem List Count: "+$onPremDataList.count)
        out-logfile -string ("Azure Data Array Count: "+$azureData.count)
        out-logfile -string ("Azure Data List Count: "+$azureDataList.count)
        out-logfile -string ("Office 365 Data Array Count: "+$office365Data.count)
        out-logfile -string ("Office 365 Data List Count: "+$office365DataList.count)

        createAzureLists
    }

    #===========================================================================================

    if($isProxyTest -eq $TRUE)
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
                    ProxyAdDress = $member
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
                    ProxyAddress = $member
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
                    ProxyAddress = $member
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
                    ProxyAddress = $member
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
    elseif ($isAllTest -eq $TRUE)
    {
        out-logfile -string "Calling function to create the array lists."

        createArrayLists

        out-logfile -string "Comparing data from all three directories - this has to be membership."

        out-logfile -string "Starting the comparison in the reverse order - compare Exchange Online -> Azure -> On Premises."

        foreach ($member in $office365Data)
        {
            out-logfile -string ("Evaluating member: "+$member.externalDirectoryObjectID)

            out-logfile -string "In this case start comparison by external directory oubject id - all Office 365 objects have it unless it's a room distribution list."
            out-logfile -string "Starting Exchange Online -> Azure Evaluation"

            out-logfile -string "Determining if the object has a primary SMTP address or only an external address.  Guest users <or> mail contacts may have external addresses."

            if ($member.primarySMTPAddress -ne $null)
            {
                out-logfile -string "Primary SMTP Address is present."

                $functionPrimarySMTPAddress = $member.primarySMTPAddress

                out-logfile -string $functionPrimarySMTPAddress
            }
            elseif ($member.externalEmailAddress -ne $null) 
            {
                out-logfile -string "External email address is present."
                out-logfile -string $member.externalEmailAddress

                $functionPrimarySMTPAddress = $member.externalEmailAddress.split(":")

                $functionPrimarySMTPAddress = $functionPrimarySMTPAddress[1]

                out-logfile -string $functionPrimarySMTPAddress
            }
            else 
            {
                out-logfile -string "Object does not have a proxy address - consider a synced security group?"

                $functionPrimarySMTPAddress = "N/A"
            }

            out-logfile -string "Determine which subset of Azure data we should be querying against."

            $switchTest = $member.externalDirectoryObjectID[0]
            out-logfile -string ("Testing: "+$switchTest)

            switch ($switchTest)
            {
                "1" {out-logfile -string "Matched Azure Data Set 1" ; $functionAzureData = [System.Collections.ArrayList]@($functionAzureDataList1)}
                "2" {out-logfile -string "Matched Azure Data Set 2" ; $functionAzureData = [System.Collections.ArrayList]@($functionAzureDataList2)}
                "3" {out-logfile -string "Matched Azure Data Set 3" ; $functionAzureData = [System.Collections.ArrayList]@($functionAzureDataList3)}
                "4" {out-logfile -string "Matched Azure Data Set 4" ; $functionAzureData = [System.Collections.ArrayList]@($functionAzureDataList4)}
                "5" {out-logfile -string "Matched Azure Data Set 5" ; $functionAzureData = [System.Collections.ArrayList]@($functionAzureDataList5)}
                "6" {out-logfile -string "Matched Azure Data Set 6" ; $functionAzureData = [System.Collections.ArrayList]@($functionAzureDataList6)}
                "7" {out-logfile -string "Matched Azure Data Set 7" ; $functionAzureData = [System.Collections.ArrayList]@($functionAzureDataList7)}
                "8" {out-logfile -string "Matched Azure Data Set 8" ; $functionAzureData = [System.Collections.ArrayList]@($functionAzureDataList8)}
                "9" {out-logfile -string "Matched Azure Data Set 9" ; $functionAzureData = [System.Collections.ArrayList]@($functionAzureDataList9)}
                "a" {out-logfile -string "Matched Azure Data Set A" ; $functionAzureData = [System.Collections.ArrayList]@($functionAzureDataListA)}
                "b" {out-logfile -string "Matched Azure Data Set B" ; $functionAzureData = [System.Collections.ArrayList]@($functionAzureDataListB)}
                "c" {out-logfile -string "Matched Azure Data Set C" ; $functionAzureData = [System.Collections.ArrayList]@($functionAzureDataListC)}
                "d" {out-logfile -string "Matched Azure Data Set D" ; $functionAzureData = [System.Collections.ArrayList]@($functionAzureDataListD)}
                "e" {out-logfile -string "Matched Azure Data Set E" ; $functionAzureData = [System.Collections.ArrayList]@($functionAzureDataListE)}
            }

            out-logfile -string $functionAzureDataList2
            out-logfile -string $functionAzureData
            
            exit

            if ($functionAzureData.objectID -contains $member.externalDirectoryObjectID)
            {
                out-logfile -string "The object was found in Azure AD. -> GOOD"
                out-logfile -string "Capture the azure object so that we can build the output object with it's attributes."

                $functionAzureObject = $functionAzureData | where {$_.objectID -eq $member.externalDirectoryObjectID}

                if ($functionAzureObject.OnPremisesSecurityIdentifier -ne $NULL)
                {
                    out-logfile -string "Determined that the azure object was on premises security principal."

                    $functionObject = New-Object PSObject -Property @{
                        Name = $member.name
                        PrimarySMTPAddress = $functionPrimarySMTPAddress
                        UserPrincipalName = "N/A"
                        ExternalDirectoryObjectID = $member.externalDirectoryObjectID
                        ObjectSID =$functionAzureObject.OnPremisesSecurityIdentifier
                        isPresentOnPremises = "False"
                        isPresentInAzure = "True"
                        isPresentInExchangeOnline = "Source"
                        IsValidMember = "FALSE"
                        ErrorMessage = "N/A"
                    }

                    out-logfile -string "Determine if the security principal was a user with a upn."

                    if ($functionAzureObject.userPrincipalName -ne $NULL)
                    {
                        out-logfile -string "Object was a security principal with user principal name."

                        $functionObject.userprincipalName = $functionAzureObject.userPrincipalName
                    }
                    else 
                    {
                        out-logfile -string "Object was security principal without a user principal name - do nothing."
                    }
                }
                else 
                {
                    out-logfile -string "Azure object is not an on premsies security principal therefore no sid or user principal"

                    $functionObject = New-Object PSObject -Property @{
                        Name = $member.name
                        PrimarySMTPAddress = $functionPrimarySMTPAddress
                        UserPrincipalName = "N/A"
                        ExternalDirectoryObjectID = $member.externalDirectoryObjectID
                        ObjectSID ="N/A"
                        isPresentOnPremises = "False"
                        isPresentInAzure = "True"
                        isPresentInExchangeOnline = "Source"
                        IsValidMember = "FALSE"
                        ErrorMessage = "N/A"
                    }
                }

                out-logfile -string "Removing object from azure data subset."
                out-logfile -string ("Azure Data Count Pre-Remove: "+$functionAzureData.count)
                $functionAzureData.remove($functionAzureObject)
                out-logfile -string ("Azure Data Count Post-Remove: "+$functionAzureData.count)

                out-logfile -string "Being Office 365 -> On premises evaluation."
                out-logfile -string "The objects are matched either by external directory object id, object sid, or primary SMTP address."

                $functionExternalDirectoryObjectID = ("User_"+$member.externalDirectoryObjectID)

                out-logfile -string $functionExternalDirectoryObjectID
                
                if ($onPremData.externalDirectoryObjectID -contains $functionExternalDirectoryObjectID)
                {
                    out-logfile -string ("Found object on premises by external directory object id. "+$functionExternalDirectoryObjectID)

                    $functionObject.isPresentOnPremises = "True"
                    $functionObject.isValidMember = "TRUE"

                    out-logfile -string $functionObject

                    $functionReturnArray += $functionObject
                }
                elseif ($onPremData.objectSID -contains $functionObject.objectSID)
                {
                    out-logfile -string ("The object was located by object SID: "+$functionObject.objectSID)
                    $functionObject.isPresentOnPremises = "True"
                    $functionObject.isValidMember = "TRUE"

                    out-logfile -string $functionObject

                    $functionReturnArray += $functionObject

                    $functionIndexValue = $onPremData.objectSid.indexof($functionObject.objectSID)

                    $onPremData[$functionIndexValue].externalDirectoryObjectID = ("User_"+$functionObject.externalDirectoryObjectID)

                    out-logfile -string "Updating on premises external directory object ID value with matching azure values."

                    out-logfile -string $onPremData[$functionIndexValue].externalDirectoryObjectID
                }
                elseif ($onPremData.primarySMTPAddress -contains $functionPrimarySMTPAddress)
                {
                    out-logfile -string ("The object was located by primary SMTP Address: "+$functionPrimarySMTPAddress)

                    $functionObject.isPresentOnPremises = "True"
                    $functionObject.isValidMember = "TRUE"

                    out-logfile -string $functionObject

                    $functionReturnArray += $functionObject

                    $functionIndexvalue = $onPremData.primarySMTPAddress.indexof($functionPrimarySMTPAddress)

                    $onPremData[$functionIndexValue].externalDirectoryObjectID = ("User_"+$functionObject.externalDirectoryObjectID)

                    out-logfile -string "Updating on premises external directory object ID value with matching azure values."

                    out-logfile -string $onPremData[$functionIndexValue].externalDirectoryObjectID
                }
                else 
                {
                    out-logfile -string "The object was not located in the on premises membership - NOT GOOD."

                    $functionObject.ErrorMessage = "MEMBER_OFFICE365_NOT_IN_ONPREMISES_EXCEPTION"

                    out-logfile -string $functionObject

                    $functionReturnArray += $functionObject
                }
            }
            else
            {
                out-logfile -string "The object was not found in Azure AD -> BAD"

                $functionObject = New-Object PSObject -Property @{
                    Name = $member.name
                    PrimarySMTPAddress = $member.primarySMTPAddress
                    UserPrincipalName = $member.userPrincipalName
                    ExternalDirectoryObjectID = $member.externalDirectoryObjectID
                    ObjectSID ="N/A"
                    isPresentOnPremises = "False"
                    isPresentInAzure = "False"
                    isPresentInExchangeOnline = "Source"
                    IsValidMember = "FALSE"
                    ErrorMessage = "MEMBER_OFFICE365_NOT_IN_AZURE_EXCEPTION"
                }

                out-logfile -string $functionObject

                $functionReturnArray += $functionObject
            }
        }

        out-logfile -string "Start by comparing the on premises data to Azure data to Exchange Online data - the first place membership lands."

        foreach ($member in $onPremData)
        {
            #First - determine if we are tracking the on premsies user by external directory object id.

            if ($member.externalDirectoryObjectID -ne $NULL)
            {
                out-logfile -string ("Processing external directory object ID: "+$member.externalDirectoryObjectID)

                $functionExternalDirectoryObjectID = $member.externalDirectoryObjectID.split("_")

                foreach ($functionExternalDirectoryObjectIDMember in $functionExternalDirectoryObjecctID)
                {
                    out-logfile -string $functionExternalDirectoryObjectIDMember
                }

                $functionExternalDirectoryObjectID = $functionExternalDirectoryObjectID[1]

                out-logfile -string $functionExternalDirectoryObjectID

                out-logfile -string "Search Azure Member data for external directory object ID."

                if ($azureData.objectID -contains $functionExternalDirectoryObjectID)
                {
                    out-logfile -string "Member found in Azure."

                    $functionObject = New-Object PSObject -Property @{
                        Name = $member.name
                        PrimarySMTPAddress = $member.primarySMTPAddress
                        UserPrincipalName = $member.userPrincipalName
                        ExternalDirectoryObjectID = $member.externalDirectoryObjectID
                        ObjectSID =$member.objectSID
                        isPresentOnPremises = "Source"
                        isPresentInAzure = "True"
                        isPresentInExchangeOnline = "False"
                        IsValidMember = "FALSE"
                        ErrorMessage = "N/A"
                    }

                    out-logfile -string "Member found in Azure evaluate Exchange Online."

                    if ($office365Data.externalDirectoryObjectID -contains $functionExternalDirectoryObjectID)
                    {
                        out-logfile -string "Member found in Exchange Online - GOOD"

                        $functionObject.isPresentInExchangeOnline="True"
                        $functionObject.isValidMember = "TRUE"

                        out-logfile -string $functionObject

                        $functionReturnArray += $functionObject
                    }
                    else 
                    {
                        out-logfile -string "Member not found in Exchange Online - NOT GOOD"

                        $functionObject.errorMessage = "MEMBER_ONPREMISES_NOT_IN_OFFICE365_EXCEPTION"

                        out-logfile -string $functionObject

                        $functionReturnArray += $functionObject
                    }
                }
                else 
                {
                    out-logfile -string "Member not found in Azure - NOT GOOD"

                    $functionObject = New-Object PSObject -Property @{
                        Name = $member.name
                        PrimarySMTPAddress = $member.primarySMTPAddress
                        UserPrincipalName = $member.userPrincipalName
                        ExternalDirectoryObjectID = $member.externalDirectoryObjectID
                        ObjectSID =$member.objectSID
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
            elseif ($member.objectSID -ne $NULL)
            {
                out-logfile -string ("Processing objectSID: "+$member.ObjectSID)

                out-logfile -string "Search Azure AD data for object sid."

                if ($azureData.OnPremisesSecurityIdentifier -contains $member.objectSID.value)
                {
                    out-logfile -string "Azure AD object located by object SID - GOOD."

                    $functionExternalDirectoryObjectID = $azureData | where {$_.OnPremisesSecurityIdentifier -eq $member.objectSID.value}

                    out-logfile -string ("Calculated object id for Exchange Online search: "+$functionExternalDirectoryObjectID.objectID)

                    $functionObject = New-Object PSObject -Property @{
                        Name = $member.name
                        PrimarySMTPAddress = $member.primarySMTPAddress
                        UserPrincipalName = $member.userPrincipalName
                        ExternalDirectoryObjectID = $functionExternalDirectoryObjectID.objectID
                        ObjectSID =$member.objectSID
                        isPresentOnPremises = "Source"
                        isPresentInAzure = "True"
                        isPresentInExchangeOnline = "False"
                        IsValidMember = "FALSE"
                        ErrorMessage = "N/A"
                    }

                    out-logfile -string "Search for Azure AD Object in Exchange Online."

                    if ($office365Data.externalDirectoryObjectID -contains $functionObject.externalDirectoryObjectID)
                    {
                        out-logfile -string "Azure AD object located in Exchange Online - GOOD."

                        $functionObject.isPresentInExchangeOnline = "True"
                        $functionObject.isValidMember = "TRUE"

                        out-logfile -string $functionObject

                        $functionReturnArray += $functionObject
                    }
                    else 
                    {
                        out-logfile -string "Azure AD object not located in Exchange Online - NOT GOOD."

                        $functionObject.errorMessage = "MEMBER_ONPREMISES_NOT_IN_OFFICE365_EXCEPTION"
                    }
                }
                else 
                {
                    out-logfile -string "Azure AD object no located by object SID - NOT GOOD."

                    $functionObject = New-Object PSObject -Property @{
                        Name = $member.name
                        PrimarySMTPAddress = $member.primarySMTPAddress
                        UserPrincipalName = $member.userPrincipalName
                        ExternalDirectoryObjectID = $member.externalDirectoryObjectID
                        ObjectSID =$member.objectSID
                        isPresentOnPremises = "Source"
                        isPresentInAzure = "False"
                        isPresentInExchangeOnline = "False"
                        IsValidMember = "FALSE"
                        ErrorMessage = "MEMBER_ONPREMISES_NOT_IN_AZURE_EXCEPTION"
                    }

                    out-logfile -string $functionObject

                    $functionReturnArray +=$functionObject
                }
            }
            elseif ($member.primarySMTPAddress -ne $NULL)
            {
                out-logfile ("Testing via primary SMTP address: "+$member.primarySMTPAddress)

                if ($azureData.mail -contains $member.primarySMTPAddress)
                {
                    out-logfile -string "Member found in Azure AD via proxy address."

                    $functionObject = New-Object PSObject -Property @{
                        Name = $member.name
                        PrimarySMTPAddress = $member.primarySMTPAddress
                        UserPrincipalName = $member.userPrincipalName
                        ExternalDirectoryObjectID = $member.externalDirectoryObjectID
                        ObjectSID =$member.objectSID
                        isPresentOnPremises = "Source"
                        isPresentInAzure = "True"
                        isPresentInExchangeOnline = "False"
                        IsValidMember = "FALSE"
                        ErrorMessage = "N/A"
                    }

                    out-logfile -string "Member found in Azure AD now evaluate Exchange Online"

                    if ($office365Data.primarySMTPAddress -contains $member.primarySMTPAddress)
                    {
                        out-logfile -string "Member found in Exchange Online - GOOD."

                        $functionObject.isPresentInExchangeOnline = "True"
                        $functionObject.isValidMember = "TRUE"

                        out-logfile -string $functionObject

                        $functionReturnArray += $functionObject
                    }
                    else 
                    {
                        out-logfile -string "Member not found in Exchange Online - NOT GOOD."

                        $functionObject.errorMessage = "MEMBER_ONPREMISES_NOT_IN_OFFICE365_EXCEPTION"

                        out-logfile -string $functionObject

                        $functionReturnArray += $functionObject
                    }
                }
                else 
                {
                    out-logfile -string "Azure AD object no located by proxy address - NOT GOOD."

                    $functionObject = New-Object PSObject -Property @{
                        Name = $member.name
                        PrimarySMTPAddress = $member.primarySMTPAddress
                        UserPrincipalName = $member.userPrincipalName
                        ExternalDirectoryObjectID = $member.externalDirectoryObjectID
                        ObjectSID =$member.objectSID
                        isPresentOnPremises = "Source"
                        isPresentInAzure = "False"
                        isPresentInExchangeOnline = "False"
                        IsValidMember = "FALSE"
                        ErrorMessage = "MEMBER_ONPREMISES_NOT_IN_AZURE_EXCEPTION"
                    }

                    out-logfile -string $functionObject

                    $functionReturnArray +=$functionObject
                }
            }
        }
    }
    <#
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
    #>
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
                        PrimarySMTPAddress = $onPremData[$i].primarySMTPAddress
                        UserPrincipalName = $onPremData[$i].userPrincipalName
                        ExternalDirectoryObjectID = $onPremData[$i].externalDirectoryObjectID
                        ObjectSID = $onPremData[$i].objectSID
                        isPresentOnPremises = "True"
                        isPresentInAzure = "N/A"
                        isPresentInExchangeOnline = "True"
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
                        isPresentOnPremises = "True"
                        isPresentInAzure = "N/A"
                        isPresentInExchangeOnline = "True"
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
                        isPresentOnPremises = "True"
                        isPresentInAzure = "N/A"
                        isPresentInExchangeOnline = "True"
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
                    isPresentOnPremises = "True"
                    isPresentInAzure = "N/A"
                    isPresentInExchangeOnline = "False"
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