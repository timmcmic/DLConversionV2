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
 

    #===========================================================================================

    $createOnPremLists={
        out-logfile -string "Creating the split lists of On Premises Data."

        $functonOnPremDataList0 = New-Object -TypeName "System.Collections.ArrayList"
        $functonOnPremDataList1 = New-Object -TypeName "System.Collections.ArrayList"
        $functonOnPremDataList2 = New-Object -TypeName "System.Collections.ArrayList" 
        $functonOnPremDataList3 = New-Object -TypeName "System.Collections.ArrayList" 
        $functonOnPremDataList4 = New-Object -TypeName "System.Collections.ArrayList" 
        $functonOnPremDataList5 = New-Object -TypeName "System.Collections.ArrayList" 
        $functonOnPremDataList6 = New-Object -TypeName "System.Collections.ArrayList" 
        $functonOnPremDataList7 = New-Object -TypeName "System.Collections.ArrayList" 
        $functonOnPremDataList8 = New-Object -TypeName "System.Collections.ArrayList" 
        $functonOnPremDataList9 = New-Object -TypeName "System.Collections.ArrayList" 
        $functonOnPremDataListA = New-Object -TypeName "System.Collections.ArrayList" 
        $functonOnPremDataListC = New-Object -TypeName "System.Collections.ArrayList" 
        $functonOnPremDataListD = New-Object -TypeName "System.Collections.ArrayList" 
        $functonOnPremDataListE = New-Object -TypeName "System.Collections.ArrayList" 
        $functonOnPremDataListF = New-Object -TypeName "System.Collections.ArrayList"  
        $functonOnPremDataListSID = New-Object -TypeName "System.Collections.ArrayList"  
        $functonOnPremDataListSMTP = New-Object -TypeName "System.Collections.ArrayList" 

        $functionOnPremData = New-Object -TypeName "System.Collections.ArrayList"

        out-logfile -string "Prepare the on premises split array list data."

        $functionOnPremDataList0.add($onPremDataList | where-object {($_.externalDirectoryObjectID -ne $NULL) -and ($_.externalDirectoryObjectID.startsWith("User_0"))} | sort-object -property externalDirectoryObjectID)
        $functionOnPremDataList1 = $onPremDataList | where-object {($_.externalDirectoryObjectID -ne $NULL) -and ($_.externalDirectoryObjectID.startsWith("User_1"))} | sort-object -property externalDirectoryObjectID
        $functionOnPremDataList2 = $onPremDataList | where-object {($_.externalDirectoryObjectID -ne $NULL) -and ($_.externalDirectoryObjectID.startsWith("User_2"))} | sort-object -property externalDirectoryObjectID
        $functionOnPremDataList3 = $onPremDataList | where-object {($_.externalDirectoryObjectID -ne $NULL) -and ($_.externalDirectoryObjectID.startsWith("User_3"))} | sort-object -property externalDirectoryObjectID
        $functionOnPremDataList4 = $onPremDataList | where-object {($_.externalDirectoryObjectID -ne $NULL) -and ($_.externalDirectoryObjectID.startsWith("User_4"))} | sort-object -property externalDirectoryObjectID
        $functionOnPremDataList5 = $onPremDataList | where-object {($_.externalDirectoryObjectID -ne $NULL) -and ($_.externalDirectoryObjectID.startsWith("User_5"))} | sort-object -property externalDirectoryObjectID
        $functionOnPremDataList6 = $onPremDataList | where-object {($_.externalDirectoryObjectID -ne $NULL) -and ($_.externalDirectoryObjectID.startsWith("User_6"))} | sort-object -property externalDirectoryObjectID
        $functionOnPremDataList7 = $onPremDataList | where-object {($_.externalDirectoryObjectID -ne $NULL) -and ($_.externalDirectoryObjectID.startsWith("User_7"))} | sort-object -property externalDirectoryObjectID
        $functionOnPremDataList8 = $onPremDataList | where-object {($_.externalDirectoryObjectID -ne $NULL) -and ($_.externalDirectoryObjectID.startsWith("User_8"))} | sort-object -property externalDirectoryObjectID
        $functionOnPremDataList9 = $onPremDataList | where-object {($_.externalDirectoryObjectID -ne $NULL) -and ($_.externalDirectoryObjectID.startsWith("User_9"))} | sort-object -property externalDirectoryObjectID
        $functionOnPremDataListA = $onPremDataList | where-object {($_.externalDirectoryObjectID -ne $NULL) -and ($_.externalDirectoryObjectID.startsWith("User_a"))} | sort-object -property externalDirectoryObjectID
        $functionOnPremDataListB = $onPremDataList | where-object {($_.externalDirectoryObjectID -ne $NULL) -and ($_.externalDirectoryObjectID.startsWith("User_b"))} | sort-object -property externalDirectoryObjectID
        $functionOnPremDataListC = $onPremDataList | where-object {($_.externalDirectoryObjectID -ne $NULL) -and ($_.externalDirectoryObjectID.startsWith("User_c"))} | sort-object -property externalDirectoryObjectID
        $functionOnPremDataListD = $onPremDataList | where-object {($_.externalDirectoryObjectID -ne $NULL) -and ($_.externalDirectoryObjectID.startsWith("User_d"))} | sort-object -property externalDirectoryObjectID
        $functionOnPremDataListE = $onPremDataList | where-object {($_.externalDirectoryObjectID -ne $NULL) -and ($_.externalDirectoryObjectID.startsWith("User_e"))} | sort-object -property externalDirectoryObjectID
        $functionOnPremDataListF = $onPremDataList | where-object {($_.externalDirectoryObjectID -ne $NULL) -and ($_.externalDirectoryObjectID.startsWith("User_f"))} | sort-object -property externalDirectoryObjectID
        $functionOnPremDataListSID = $onPremDataList | where-object {($_.externalDirectoryObjectID -eq $NULL) -and ($_.objectSID -ne $NULL)} | sort-object -property objectSID
        $functionOnPremDataListSMTP = $onPremDataList | where-object {($_.externalDirectoryObjectID -eq $NULL) -and ($_.objectSID -eq $NULL) -and ($_.primarySMTPAddress -ne $NULL)} | sort-object -property objectSID

        out-logfile -string "Record counts of objects for debugging."

        out-logfile -string ("OnPrem Function Data List 1: "+$functionOnPremDataList0.count)
        out-logfile -string ("OnPrem Function Data List 1: "+$functionOnPremDataList1.count)
        out-logfile -string ("OnPrem Function Data List 2: "+$functionOnPremDataList2.count)
        out-logfile -string ("OnPrem Function Data List 3: "+$functionOnPremDataList3.count)
        out-logfile -string ("OnPrem Function Data List 4: "+$functionOnPremDataList4.count)
        out-logfile -string ("OnPrem Function Data List 5: "+$functionOnPremDataList5.count)
        out-logfile -string ("OnPrem Function Data List 6: "+$functionOnPremDataList6.count)
        out-logfile -string ("OnPrem Function Data List 7: "+$functionOnPremDataList7.count)
        out-logfile -string ("OnPrem Function Data List 8: "+$functionOnPremDataList8.count)
        out-logfile -string ("OnPrem Function Data List 9: "+$functionOnPremDataList9.count)
        out-logfile -string ("OnPrem Function Data List A: "+$functionOnPremDataListA.count)
        out-logfile -string ("OnPrem Function Data List B: "+$functionOnPremDataListB.count)
        out-logfile -string ("OnPrem Function Data List C: "+$functionOnPremDataListC.count)
        out-logfile -string ("OnPrem Function Data List D: "+$functionOnPremDataListD.count)
        out-logfile -string ("OnPrem Function Data List E: "+$functionOnPremDataListE.count)
        out-logfile -string ("On Prem Function Data List SID: "+$functionOnPremDataListSID.count)
        out-logfile -string ("On Prem Function Data List SMTP: "+$functionOnPremDataListSMTP.count)
        
        $functionOnPremDataListCount = $functionOnPremDataList0.count+$functionOnPremDataList1.count+$functionOnPremDataList2.count+$functionOnPremDataList3.count+$functionOnPremDataList4.count+$functionOnPremDataList5.count+$functionOnPremDataList6.count+$functionOnPremDataList7.count+$functionOnPremDataList8.count+$functionOnPremDataList9.count+$functionOnPremDataListA.count+$functionOnPremDataListB.count+$functionOnPremDataListC.count+$functionOnPremDataListD.count+$functionOnPremDataListE.count+$functionOnPremDataListSID.count+$functionOnPremDataListSMTP.count

        out-logfile -string ("Total array data count validation: "+$functionOnPremDataListCount.tostring())
    }

    #===========================================================================================

    #===========================================================================================

    $createAzureLists={
        out-logfile -string "Creating the split lists of Azure Data."

        $functionAzureDataList0 = New-Object -TypeName "System.Collections.ArrayList"
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
        $functionAzureDataList0Orig = New-Object -TypeName "System.Collections.ArrayList"
        $functionAzureDataList1Orig = New-Object -TypeName "System.Collections.ArrayList"
        $functionAzureDataList2Orig = New-Object -TypeName "System.Collections.ArrayList" 
        $functionAzureDataList3Orig = New-Object -TypeName "System.Collections.ArrayList" 
        $functionAzureDataList4Orig = New-Object -TypeName "System.Collections.ArrayList" 
        $functionAzureDataList5Orig = New-Object -TypeName "System.Collections.ArrayList" 
        $functionAzureDataList6Orig = New-Object -TypeName "System.Collections.ArrayList" 
        $functionAzureDataList7Orig = New-Object -TypeName "System.Collections.ArrayList" 
        $functionAzureDataList8Orig = New-Object -TypeName "System.Collections.ArrayList" 
        $functionAzureDataList9Orig = New-Object -TypeName "System.Collections.ArrayList" 
        $functionAzureDataListAOrig = New-Object -TypeName "System.Collections.ArrayList" 
        $functionAzureDataListBOrig = New-Object -TypeName "System.Collections.ArrayList" 
        $functionAzureDataListCOrig = New-Object -TypeName "System.Collections.ArrayList" 
        $functionAzureDataListDOrig = New-Object -TypeName "System.Collections.ArrayList" 
        $functionAzureDataListEOrig = New-Object -TypeName "System.Collections.ArrayList"

        $functionAzureData = New-Object -TypeName "System.Collections.ArrayList"

        out-logfile -string "Initialize the azure data lists with values."

        $functionAzureDataList0 = [System.Collections.ArrayList]@($azureDataList | where-object {$_.objectID.startsWith("0")} | sort-object -property objectID)
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
        $functionAzureDataListF = [System.Collections.ArrayList]@($azureDataList | where-object {$_.objectID.startsWith("f")} | sort-object -property objectID)

        
        out-logfile -string "Serialize the data into new array lists since this data set is evaluated twice in the all evaluation."

        $serialData = [System.Management.Automation.PSSerializer]::Serialize($functionAzureDataList0)
        $functionAzureDataList0Orig = [System.Collections.ArrayList]@(([System.Management.Automation.PSSerializer]::Deserialize($serialData)) | sort-object -property objectID)
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
        $serialData = [System.Management.Automation.PSSerializer]::Serialize($functionAzureDataListF)
        $functionAzureDataListFOrig = [System.Collections.ArrayList]@(([System.Management.Automation.PSSerializer]::Deserialize($serialData)) | sort-object -property objectID)
        $serialData = [System.Management.Automation.PSSerializer]::Serialize($azureDataList)
        $functionAzureDataListOrig = [System.Collections.ArrayList]@(([System.Management.Automation.PSSerializer]::Deserialize($serialData)) | sort-object -property objectID)

        out-logfile -string "Output azure array list counts for debugging."

        out-logfile -string ("Azure Function Data List 0: "+$functionAzureDataList0.count)
        out-logfile -string ("Azure Function Data List Original 0: "+$functionAzureDataList0Orig.count)
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

        $functionAzureDataListCount=$functionAzureDataList0.count+$functionAzureDataList1.count+$functionAzureDataList2.count+$functionAzureDataList3.count+$functionAzureDataList4.count+$functionAzureDataList5.count+$functionAzureDataList6.count+$functionAzureDataList7.count+$functionAzureDataList8.count+$functionAzureDataList9.count+$functionAzureDataListA.count+$functionAzureDataListB.count+$functionAzureDataListC.count+$functionAzureDataListD.count+$functionAzureDataListE.count

        out-logfile -string ("Total array data count validation: "+$functionAzureDataListCount.tostring())
    }

    #===========================================================================================

    #===========================================================================================
    
    $createOffice365Lists=
    {
        out-logfile -string "Creating the split lists of On Premises Data."

        $functionOffice365DataList0 = New-Object -TypeName "System.Collections.ArrayList"
        $functionOffice365DataList1 = New-Object -TypeName "System.Collections.ArrayList"
        $functionOffice365DataList2 = New-Object -TypeName "System.Collections.ArrayList" 
        $functionOffice365DataList3 = New-Object -TypeName "System.Collections.ArrayList" 
        $functionOffice365DataList4 = New-Object -TypeName "System.Collections.ArrayList" 
        $functionOffice365DataList5 = New-Object -TypeName "System.Collections.ArrayList" 
        $functionOffice365DataList6 = New-Object -TypeName "System.Collections.ArrayList" 
        $functionOffice365DataList7 = New-Object -TypeName "System.Collections.ArrayList" 
        $functionOffice365DataList8 = New-Object -TypeName "System.Collections.ArrayList" 
        $functionOffice365DataList9 = New-Object -TypeName "System.Collections.ArrayList" 
        $functionOffice365DataListA = New-Object -TypeName "System.Collections.ArrayList" 
        $functionOffice365DataListC = New-Object -TypeName "System.Collections.ArrayList" 
        $functionOffice365DataListD = New-Object -TypeName "System.Collections.ArrayList" 
        $functionOffice365DataListE = New-Object -TypeName "System.Collections.ArrayList" 
        $functionOffice365DataListF = New-Object -TypeName "System.Collections.ArrayList"  

        $functionOffice365Data = New-Object -TypeName "System.Collections.ArrayList"

        out-logfile -string "Prepare the on premises split array list data."

        $functionOffice365DataList0 = [System.Collections.ArrayList]@($office365DataList | where-object {($_.externalDirectoryObjectID -ne $NULL) -and ($_.externalDirectoryObjectID.startsWith("0"))} | sort-object -property externalDirectoryObjectID)
        $functionOffice365DataList1 = [System.Collections.ArrayList]@($office365DataList | where-object {($_.externalDirectoryObjectID -ne $NULL) -and ($_.externalDirectoryObjectID.startsWith("1"))} | sort-object -property externalDirectoryObjectID)
        $functionOffice365DataList2 = [System.Collections.ArrayList]@($office365DataList | where-object {($_.externalDirectoryObjectID -ne $NULL) -and ($_.externalDirectoryObjectID.startsWith("2"))} | sort-object -property externalDirectoryObjectID)
        $functionOffice365DataList3 = [System.Collections.ArrayList]@($office365DataList | where-object {($_.externalDirectoryObjectID -ne $NULL) -and ($_.externalDirectoryObjectID.startsWith("3"))} | sort-object -property externalDirectoryObjectID)
        $functionOffice365DataList4 = [System.Collections.ArrayList]@($office365DataList | where-object {($_.externalDirectoryObjectID -ne $NULL) -and ($_.externalDirectoryObjectID.startsWith("4"))} | sort-object -property externalDirectoryObjectID)
        $functionOffice365DataList5 = [System.Collections.ArrayList]@($office365DataList | where-object {($_.externalDirectoryObjectID -ne $NULL) -and ($_.externalDirectoryObjectID.startsWith("5"))} | sort-object -property externalDirectoryObjectID)
        $functionOffice365DataList6 = [System.Collections.ArrayList]@($office365DataList | where-object {($_.externalDirectoryObjectID -ne $NULL) -and ($_.externalDirectoryObjectID.startsWith("6"))} | sort-object -property externalDirectoryObjectID)
        $functionOffice365DataList7 = [System.Collections.ArrayList]@($office365DataList | where-object {($_.externalDirectoryObjectID -ne $NULL) -and ($_.externalDirectoryObjectID.startsWith("7"))} | sort-object -property externalDirectoryObjectID)
        $functionOffice365DataList8 = [System.Collections.ArrayList]@($office365DataList | where-object {($_.externalDirectoryObjectID -ne $NULL) -and ($_.externalDirectoryObjectID.startsWith("8"))} | sort-object -property externalDirectoryObjectID)
        $functionOffice365DataList9 = [System.Collections.ArrayList]@($office365DataList | where-object {($_.externalDirectoryObjectID -ne $NULL) -and ($_.externalDirectoryObjectID.startsWith("9"))} | sort-object -property externalDirectoryObjectID)
        $functionOffice365DataListA = [System.Collections.ArrayList]@($office365DataList | where-object {($_.externalDirectoryObjectID -ne $NULL) -and ($_.externalDirectoryObjectID.startsWith("a"))} | sort-object -property externalDirectoryObjectID)
        $functionOffice365DataListB = [System.Collections.ArrayList]@($office365DataList | where-object {($_.externalDirectoryObjectID -ne $NULL) -and ($_.externalDirectoryObjectID.startsWith("b"))} | sort-object -property externalDirectoryObjectID)
        $functionOffice365DataListC = [System.Collections.ArrayList]@($office365DataList | where-object {($_.externalDirectoryObjectID -ne $NULL) -and ($_.externalDirectoryObjectID.startsWith("c"))} | sort-object -property externalDirectoryObjectID)
        $functionOffice365DataListD = [System.Collections.ArrayList]@($office365DataList | where-object {($_.externalDirectoryObjectID -ne $NULL) -and ($_.externalDirectoryObjectID.startsWith("d"))} | sort-object -property externalDirectoryObjectID)
        $functionOffice365DataListE = [System.Collections.ArrayList]@($office365DataList | where-object {($_.externalDirectoryObjectID -ne $NULL) -and ($_.externalDirectoryObjectID.startsWith("e"))} | sort-object -property externalDirectoryObjectID)
        $functionOffice365DataListF = [System.Collections.ArrayList]@($office365DataList | where-object {($_.externalDirectoryObjectID -ne $NULL) -and ($_.externalDirectoryObjectID.startsWith("f"))} | sort-object -property externalDirectoryObjectID)
       

        out-logfile -string "Record counts of objects for debugging."

        out-logfile -string ("Office 365 Function Data List 1: "+$functionOffice365DataList0.count)
        out-logfile -string ("Office 365 Function Data List 1: "+$functionOffice365DataList1.count)
        out-logfile -string ("Office 365 Function Data List 2: "+$functionOffice365DataList2.count)
        out-logfile -string ("Office 365 Function Data List 3: "+$functionOffice365DataList3.count)
        out-logfile -string ("Office 365 Function Data List 4: "+$functionOffice365DataList4.count)
        out-logfile -string ("Office 365 Function Data List 5: "+$functionOffice365DataList5.count)
        out-logfile -string ("Office 365 Function Data List 6: "+$functionOffice365DataList6.count)
        out-logfile -string ("Office 365 Function Data List 7: "+$functionOffice365DataList7.count)
        out-logfile -string ("Office 365 Function Data List 8: "+$functionOffice365DataList8.count)
        out-logfile -string ("Office 365 Function Data List 9: "+$functionOffice365DataList9.count)
        out-logfile -string ("Office 365 Function Data List A: "+$functionOffice365DataListA.count)
        out-logfile -string ("Office 365 Function Data List B: "+$functionOffice365DataListB.count)
        out-logfile -string ("Office 365 Function Data List C: "+$functionOffice365DataListC.count)
        out-logfile -string ("Office 365 Function Data List D: "+$functionOffice365DataListD.count)
        out-logfile -string ("Office 365 Function Data List E: "+$functionOffice365DataListE.count)
        out-logfile -string ("On Prem Function Data List SID: "+$functionOffice365DataListSID.count)
        out-logfile -string ("On Prem Function Data List SMTP: "+$functionOffice365DataListSMTP.count)
        
        $functionOffice365DataListCount = $functionOffice365DataList0.count+$functionOffice365DataList1.count+$functionOffice365DataList2.count+$functionOffice365DataList3.count+$functionOffice365DataList4.count+$functionOffice365DataList5.count+$functionOffice365DataList6.count+$functionOffice365DataList7.count+$functionOffice365DataList8.count+$functionOffice365DataList9.count+$functionOffice365DataListA.count+$functionOffice365DataListB.count+$functionOffice365DataListC.count+$functionOffice365DataListD.count+$functionOffice365DataListE.count+$functionOffice365DataListSID.count+$functionOffice365DataListSMTP.count

        out-logfile -string ("Total array data count validation: "+$functionOffice365DataListCount.tostring())
    }

    #===========================================================================================

    #===========================================================================================
    
    $createArrayLists ={
        out-logfile -string "Preparing array to array list conversion for work in this function."

        $onPremDataList = New-Object -TypeName "System.Collections.ArrayList"
        $azureDataList = New-Object -TypeName "System.Collections.ArrayList"
        $office365DataList = New-Object -TypeName "System.Collections.ArrayList"
        
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

        .$createAzureLists

        .$createOnPremLists

        .$createOffice365Lists
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

        .$createArrayLists

        out-logfile -string "Comparing data from all three directories - this has to be membership."

        out-logfile -string "Starting the comparison in the reverse order - compare Exchange Online -> Azure -> On Premises."

        foreach ($member in $office365DataList)
        {
            out-logfile -string ("Evaluating member: "+$member.externalDirectoryObjectID)

            out-logfile -string "In this case start comparison by external directory oubject id - all Office 365 objects have it unless it's a room distribution list."
            out-logfile -string "Starting Exchange Online -> Azure Evaluation"

            out-logfile -string "Determining if the object has a primary SMTP address or only an external address.  Guest users <or> mail contacts may have external addresses."

            if ($member.primarySMTPAddress.length -ne "")
            {
                out-logfile -string "Primary SMTP Address is present."

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

            out-logfile -string "Determine which subset of Azure data we should be querying against."

            $switchTest = $member.externalDirectoryObjectID[0]
            out-logfile -string ("Testing: "+$switchTest)

            switch ($switchTest)
            {
                "0" {out-logfile -string "Matched Azure Data Set 0" ; $functionAzureData = [System.Collections.ArrayList]@($functionAzureDataList0)}
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
                "f" {out-logfile -string "Matched Azure Data Set F" ; $functionAzureData = [System.Collections.ArrayList]@($functionAzureDataListF)}
            }

            #if ($functionAzureData.objectID -contains $member.externalDirectoryObjectID)
            if (($functionIndex = $functionAzureData.objectID.indexOf($member.externalDirectoryObjectID)) -ge 0)
            {
                out-logfile -string "The object was found in Azure AD. -> GOOD"
                out-logfile -string ("Azure object located at array list position: "+$functionIndex)
                out-logfile -string "Capture the azure object so that we can build the output object with it's attributes."

                #$functionAzureObject = $functionAzureData | where {$_.objectID -eq $member.externalDirectoryObjectID}

                $functionAzureObject = $functionAzureData[$functionIndex]

                out-logfile -string $functionAzureObject

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

                    out-logfile -string $functionObject.objectSID

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
                #$functionAzureData.remove($functionAzureObject)
                $functionAzureData.removeAt($functionIndex)
                out-logfile -string ("Azure Data Count Post-Remove: "+$functionAzureData.count)

                out-logfile -string "Being Office 365 -> On premises evaluation."
                out-logfile -string "The objects are matched either by external directory object id, object sid, or primary SMTP address."

                $functionExternalDirectoryObjectID = ("User_"+$member.externalDirectoryObjectID)

                out-logfile -string $functionExternalDirectoryObjectID

                switch ($switchTest)
                {
                    "0" {out-logfile -string "Matched OnPrem Data Set 0" ; $functionOnPremData = [System.Collections.ArrayList]@($functionOnPremDataList0)}
                    "1" {out-logfile -string "Matched OnPrem Data Set 1" ; $functionOnPremData = [System.Collections.ArrayList]@($functionOnPremDataList1)}
                    "2" {out-logfile -string "Matched OnPrem Data Set 2" ; $functionOnPremData = [System.Collections.ArrayList]@($functionOnPremDataList2)}
                    "3" {out-logfile -string "Matched OnPrem Data Set 3" ; $functionOnPremData = [System.Collections.ArrayList]@($functionOnPremDataList3)}
                    "4" {out-logfile -string "Matched OnPrem Data Set 4" ; $functionOnPremData = [System.Collections.ArrayList]@($functionOnPremDataList4)}
                    "5" {out-logfile -string "Matched OnPrem Data Set 5" ; $functionOnPremData = [System.Collections.ArrayList]@($functionOnPremDataList5)}
                    "6" {out-logfile -string "Matched OnPrem Data Set 6" ; $functionOnPremData = [System.Collections.ArrayList]@($functionOnPremDataList6)}
                    "7" {out-logfile -string "Matched OnPrem Data Set 7" ; $functionOnPremData = [System.Collections.ArrayList]@($functionOnPremDataList7)}
                    "8" {out-logfile -string "Matched OnPrem Data Set 8" ; $functionOnPremData = [System.Collections.ArrayList]@($functionOnPremDataList8)}
                    "9" {out-logfile -string "Matched OnPrem Data Set 9" ; $functionOnPremData = [System.Collections.ArrayList]@($functionOnPremDataList9)}
                    "a" {out-logfile -string "Matched OnPrem Data Set A" ; $functionOnPremData = [System.Collections.ArrayList]@($functionOnPremDataListA)}
                    "b" {out-logfile -string "Matched OnPrem Data Set B" ; $functionOnPremData = [System.Collections.ArrayList]@($functionOnPremDataListB)}
                    "c" {out-logfile -string "Matched OnPrem Data Set C" ; $functionOnPremData = [System.Collections.ArrayList]@($functionOnPremDataListC)}
                    "d" {out-logfile -string "Matched OnPrem Data Set D" ; $functionOnPremData = [System.Collections.ArrayList]@($functionOnPremDataListD)}
                    "e" {out-logfile -string "Matched OnPrem Data Set E" ; $functionOnPremData = [System.Collections.ArrayList]@($functionOnPremDataListE)}
                    "f" {out-logfile -string "Matched OnPrem Data Set F" ; $functionOnPremData = [System.Collections.ArrayList]@($functionOnPremDataListF)}
                }

                #Use index of so that we do not need to query the data more than once.
                #if ($functionOnPremData.externalDirectoryObjectID -contains $functionExternalDirectoryObjectID)
                if (($functionOnPremData.count -gt 0) -and ($functionIndex = $functionOnPremData.externalDirectoryObjectId.indexOf($functionExternalDirectoryObjectID)) -ge 0)
                {
                    out-logfile -string ("Found object on premises by external directory object id. "+$functionExternalDirectoryObjectID)
                    out-logfile -string ("Found object at index: "+$functionIndex.tostring())

                    $functionObject.isPresentOnPremises = "True"
                    $functionObject.isValidMember = "TRUE"

                    out-logfile -string $functionObject

                    $functionReturnArray += $functionObject

                    out-logfile -string "Object is valid in all directories - capture on premises object and add to return."

                    $functionObject = New-Object PSObject -Property @{
                        Name = $functionOnPremData[$functionIndex].name
                        PrimarySMTPAddress = $functionOnPremData[$functionIndex].primarySMTPAddress
                        UserPrincipalName = $functionOnPremData[$functionIndex].userPrincipalName
                        ExternalDirectoryObjectID = $functionOnPremData[$functionIndex].externalDirectoryObjectID
                        ObjectSID =$functionOnPremData[$functionIndex].objectSID
                        isPresentOnPremises = "Source"
                        isPresentInAzure = "True"
                        isPresentInExchangeOnline = "True"
                        IsValidMember = "TRUE"
                        ErrorMessage = "N/A"
                    }

                    out-logfile -string $functionObject

                    $functionReturnArray += $functionObject

                    out-logfile -string ("On Prem Data List Pre-Remove: "+$functionOnPremData.count)

                    #$functionIndex = $functionOnPremData.externalDirectoryObjectID.indexOf($functionExternalDirectoryObjectID)
                    #out-logfile -string $functionIndex.toString()
                    $functionOnPremData.removeAt($functionIndex)                    
                    out-logfile -string ("On Prem Data List Post-Remove: "+$functionOnPremData.count)
                }
                #elseif ($functionOnPremDataListSID.objectSid -contains $functionObject.objectSID)
                elseif (($functionOnPremDataListSID.count -gt 0) -and ($functionIndex = $functionOnPremDataListSID.objectSid.value.indexof($functionObject.objectSID)) -ge 0)
                {
                    out-logfile -string ("The object was located by object SID: "+$functionObject.objectSID)
                    out-logfile -string ("The object was located at index: "+$functionIndex.tostring())
                    $functionObject.isPresentOnPremises = "True"
                    $functionObject.isValidMember = "TRUE"

                    out-logfile -string $functionObject

                    $functionReturnArray += $functionObject

                    out-logfile -string "Object is valid in all directories - capture on premises object and add to return."

                    $functionObject = New-Object PSObject -Property @{
                        Name = $functionOnPremDataListSID[$functionIndex].name
                        PrimarySMTPAddress = $functionOnPremDataListSID[$functionIndex].primarySMTPAddress
                        UserPrincipalName = $functionOnPremDataListSID[$functionIndex].userPrincipalName
                        ExternalDirectoryObjectID = $functionOnPremDataListSID[$functionIndex].externalDirectoryObjectID
                        ObjectSID =$functionOnPremDataListSID[$functionIndex].objectSID
                        isPresentOnPremises = "Source"
                        isPresentInAzure = "True"
                        isPresentInExchangeOnline = "True"
                        IsValidMember = "TRUE"
                        ErrorMessage = "N/A"
                    }

                    out-logfile -string $functionObject

                    $functionReturnArray += $functionObject

                    #$functionIndexValue = $onPremData.objectSid.indexof($functionObject.objectSID)

                    #$onPremData[$functionIndexValue].externalDirectoryObjectID = ("User_"+$functionObject.externalDirectoryObjectID)

                    #out-logfile -string "Updating on premises external directory object ID value with matching azure values."

                    #out-logfile -string ($onPremData[$functionIndexValue].externalDirectoryObjectID)
                    
                    out-logfile -string ("On Prem Data List Pre-Remove: "+$functionOnPremDataListSID.count)
                    #$functionIndex = $functionOnPremDataListSID | where {$_.objectSid -eq $functionObject.objectSid}
                    #out-logfile -string $functionIndex.toString()
                    $functionOnPremDataListSID.remove($functionIndex)
                    out-logfile -string ("On Prem Data List Post-Remove: "+$functionOnPremDataListSID.count)
                }
                #elseif ($functionOnPremDataListSMTP.primarySMTPAddress -contains $functionPrimarySMTPAddress)
                elseif (($functionOnPremDataListSMTP.count -gt 0) -and ($functionIndex = $functionOnPremDataListSMTP.primarySMTPAddress.indexOf($functionPrimarySMTPAddress)) -ge 0)
                {
                    out-logfile -string ("The object was located by primary SMTP Address: "+$functionPrimarySMTPAddress)
                    out-logfile -string ("The object was located at array index: "+$functionIndex.tostring())

                    $functionObject.isPresentOnPremises = "True"
                    $functionObject.isValidMember = "TRUE"

                    out-logfile -string $functionObject

                    $functionReturnArray += $functionObject

                    out-logfile -string "Object is valid in all directories - capture on premises object and add to return."

                    $functionObject = New-Object PSObject -Property @{
                        Name = $functionOnPremDataListSMTP[$functionIndex].name
                        PrimarySMTPAddress = $functionOnPremDataListSMTP[$functionIndex].primarySMTPAddress
                        UserPrincipalName = $functionOnPremDataListSMTP[$functionIndex].userPrincipalName
                        ExternalDirectoryObjectID = $functionOnPremDataListSMTP[$functionIndex].externalDirectoryObjectID
                        ObjectSID =$functionOnPremDataListSMTP[$functionIndex].objectSID
                        isPresentOnPremises = "Source"
                        isPresentInAzure = "True"
                        isPresentInExchangeOnline = "True"
                        IsValidMember = "TRUE"
                        ErrorMessage = "N/A"
                    }

                    out-logfile -string $functionObject

                    $functionReturnArray += $functionObject

                    #$functionIndexvalue = $onPremData.primarySMTPAddress.indexof($functionPrimarySMTPAddress)

                    #$onPremData[$functionIndexValue].externalDirectoryObjectID = ("User_"+$functionObject.externalDirectoryObjectID)

                    #out-logfile -string "Updating on premises external directory object ID value with matching azure values."

                    #out-logfile -string ($onPremData[$functionIndexValue].externalDirectoryObjectID)

                    out-logfile -string ("On Prem Data List Pre-Remove: "+$functionOnPremDataListSMTP.count)
                    #$functionIndex = $functionOnPremDataListSMTP.primarySMTPAddress.indexOf($functionPrimarySMTPAddress)
                    #out-logfile -string $functionIndex.toString()
                    $functionOnPremDataListSMTP.removeAt($functionIndex)                   
                    out-logfile -string ("On Prem Data List Post-Remove: "+$functionOnPremDataListSMTP.count)
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

        if ($onPremDataList.count -gt 0)
        {
            foreach ($member in $onPremDataList)
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

                    out-logfile -string "Determine which subset of Azure data we should be querying against."

                    $switchTest = $functionExternalDirectoryObjectID[0]
                    out-logfile -string ("Testing: "+$switchTest)

                    switch ($switchTest)
                    {
                        "0" {out-logfile -string "Matched Azure Data Set 0" ; $functionAzureData = [System.Collections.ArrayList]@($functionAzureDataList0Orig)}
                        "1" {out-logfile -string "Matched Azure Data Set 1" ; $functionAzureData = [System.Collections.ArrayList]@($functionAzureDataList1Orig)}
                        "2" {out-logfile -string "Matched Azure Data Set 2" ; $functionAzureData = [System.Collections.ArrayList]@($functionAzureDataList2Orig)}
                        "3" {out-logfile -string "Matched Azure Data Set 3" ; $functionAzureData = [System.Collections.ArrayList]@($functionAzureDataList3Orig)}
                        "4" {out-logfile -string "Matched Azure Data Set 4" ; $functionAzureData = [System.Collections.ArrayList]@($functionAzureDataList4Orig)}
                        "5" {out-logfile -string "Matched Azure Data Set 5" ; $functionAzureData = [System.Collections.ArrayList]@($functionAzureDataList5Orig)}
                        "6" {out-logfile -string "Matched Azure Data Set 6" ; $functionAzureData = [System.Collections.ArrayList]@($functionAzureDataList6Orig)}
                        "7" {out-logfile -string "Matched Azure Data Set 7" ; $functionAzureData = [System.Collections.ArrayList]@($functionAzureDataList7Orig)}
                        "8" {out-logfile -string "Matched Azure Data Set 8" ; $functionAzureData = [System.Collections.ArrayList]@($functionAzureDataList8Orig)}
                        "9" {out-logfile -string "Matched Azure Data Set 9" ; $functionAzureData = [System.Collections.ArrayList]@($functionAzureDataList9Orig)}
                        "a" {out-logfile -string "Matched Azure Data Set A" ; $functionAzureData = [System.Collections.ArrayList]@($functionAzureDataListAOrig)}
                        "b" {out-logfile -string "Matched Azure Data Set B" ; $functionAzureData = [System.Collections.ArrayList]@($functionAzureDataListBOrig)}
                        "c" {out-logfile -string "Matched Azure Data Set C" ; $functionAzureData = [System.Collections.ArrayList]@($functionAzureDataListCOrig)}
                        "d" {out-logfile -string "Matched Azure Data Set D" ; $functionAzureData = [System.Collections.ArrayList]@($functionAzureDataListDOrig)}
                        "e" {out-logfile -string "Matched Azure Data Set E" ; $functionAzureData = [System.Collections.ArrayList]@($functionAzureDataListEOrig)}
                        "f" {out-logfile -string "Matched Azure Data Set F" ; $functionAzureData = [System.Collections.ArrayList]@($functionAzureDataListFOrig)}
                    }

                    out-logfile -string "Search Azure Member data for external directory object ID."

                    if ($functionAzureData.objectID -contains $functionExternalDirectoryObjectID)
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

                        out-logfile -string ("Azure data count pre-remove: "+$functionAzureData.count)
                        $functionIndex = $functionAzureData.objectID.indexOf($functionExternalDirectoryObjectID)
                        out-logfile -string $functionIndex.tostring()
                        $functionAzureData.removeAt($functionIndex)
                        out-logfile -string ("Azure data count post-remove: "+$functionAzureData.Count)

                        out-logfile -string "Member found in Azure evaluate Exchange Online."

                        switch ($switchTest)
                        {
                            "0" {out-logfile -string "Matched Office365 Data Set 0" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataList0)}
                            "1" {out-logfile -string "Matched Office365 Data Set 1" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataList1)}
                            "2" {out-logfile -string "Matched Office365 Data Set 2" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataList2)}
                            "3" {out-logfile -string "Matched Office365 Data Set 3" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataList3)}
                            "4" {out-logfile -string "Matched Office365 Data Set 4" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataList4)}
                            "5" {out-logfile -string "Matched Office365 Data Set 5" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataList5)}
                            "6" {out-logfile -string "Matched Office365 Data Set 6" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataList6)}
                            "7" {out-logfile -string "Matched Office365 Data Set 7" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataList7)}
                            "8" {out-logfile -string "Matched Office365 Data Set 8" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataList8)}
                            "9" {out-logfile -string "Matched Office365 Data Set 9" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataList9)}
                            "a" {out-logfile -string "Matched Office365 Data Set A" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataListA)}
                            "b" {out-logfile -string "Matched Office365 Data Set B" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataListB)}
                            "c" {out-logfile -string "Matched Office365 Data Set C" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataListC)}
                            "d" {out-logfile -string "Matched Office365 Data Set D" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataListD)}
                            "e" {out-logfile -string "Matched Office365 Data Set E" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataListE)}
                            "f" {out-logfile -string "Matched Office365 Data Set F" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataListF)}
                        }

                        if ($functionOffice365Data.externalDirectoryObjectID -contains $functionExternalDirectoryObjectID)
                        {
                            out-logfile -string "Member found in Exchange Online - GOOD"

                            $functionObject.isPresentInExchangeOnline="True"
                            $functionObject.isValidMember = "TRUE"

                            out-logfile -string $functionObject

                            $functionReturnArray += $functionObject

                            out-logfile -string ("Office 365 Data Count pre-remove: "+$functionOffice365Data.count)
                            $functionIndex = $functionOffice365Data.externalDirectoryObjectID.indexOf($functionExternalDirectoryObjectID)
                            out-logfile -string $functionIndex.tostring()
                            $functionOffice365Data.removeAt($functionIndex)
                            out-logfile -string ("Office 365 Data Count post-remove: "+$functionOffice365Data.count)
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

                    if ($functionAzureDataListOrig.OnPremisesSecurityIdentifier -contains $member.objectSID.value)
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

                        out-logfile -string ("Azure data count pre-remove: "+$functionAzureDataListOrig.count)
                        $functionIndex = $functionAzureDataListOrig.OnPremisesSecurityIdentifier.indexOf($member.objectSID.value)
                        out-logfile -string $functionIndex.tostring()
                        $functionAzureDataListOrig.removeAt($functionIndex)
                        out-logfile -string ("Azure data count post-remove: "+$functionAzureDataListOrig.count)

                        $switchTest = $functionObject.externalDirectoryObjectID[0]
                        out-logfile -string $switchTest

                        switch ($switchTest)
                        {
                            "0" {out-logfile -string "Matched Office365 Data Set 0" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataList0)}
                            "1" {out-logfile -string "Matched Office365 Data Set 1" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataList1)}
                            "2" {out-logfile -string "Matched Office365 Data Set 2" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataList2)}
                            "3" {out-logfile -string "Matched Office365 Data Set 3" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataList3)}
                            "4" {out-logfile -string "Matched Office365 Data Set 4" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataList4)}
                            "5" {out-logfile -string "Matched Office365 Data Set 5" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataList5)}
                            "6" {out-logfile -string "Matched Office365 Data Set 6" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataList6)}
                            "7" {out-logfile -string "Matched Office365 Data Set 7" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataList7)}
                            "8" {out-logfile -string "Matched Office365 Data Set 8" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataList8)}
                            "9" {out-logfile -string "Matched Office365 Data Set 9" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataList9)}
                            "a" {out-logfile -string "Matched Office365 Data Set A" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataListA)}
                            "b" {out-logfile -string "Matched Office365 Data Set B" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataListB)}
                            "c" {out-logfile -string "Matched Office365 Data Set C" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataListC)}
                            "d" {out-logfile -string "Matched Office365 Data Set D" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataListD)}
                            "e" {out-logfile -string "Matched Office365 Data Set E" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataListE)}
                            "f" {out-logfile -string "Matched Office365 Data Set F" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataListF)}
                        }


                        out-logfile -string "Search for Azure AD Object in Exchange Online."

                        if ($functionOffice365Data.externalDirectoryObjectID -contains $functionObject.externalDirectoryObjectID)
                        {
                            out-logfile -string "Azure AD object located in Exchange Online - GOOD."

                            $functionObject.isPresentInExchangeOnline = "True"
                            $functionObject.isValidMember = "TRUE"

                            out-logfile -string $functionObject

                            $functionReturnArray += $functionObject

                            out-logfile -string ("Office 365 Data Count pre-remove: "+$functionOffice365Data.count)
                            $functionIndex = $functionOffice365Data.externalDirectoryObjectID.indexOf($functionObject.externalDirectoryObjectID)
                            out-logfile -string $functionIndex.tostring()
                            $functionOffice365Data.removeAt($functionIndex)
                            out-logfile -string ("Office 365 Data Count post-remove: "+$functionOffice365Data.count)
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

                    if ($functionAzureDataListOrig.mail -contains $member.primarySMTPAddress)
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

                        $switchTest = $functionObject.externalDirectoryObjectID[0]
                        out-logfile -string $switchTest

                        switch ($switchTest)
                        {
                            "0" {out-logfile -string "Matched Office365 Data Set 0" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataList0)}
                            "1" {out-logfile -string "Matched Office365 Data Set 1" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataList1)}
                            "2" {out-logfile -string "Matched Office365 Data Set 2" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataList2)}
                            "3" {out-logfile -string "Matched Office365 Data Set 3" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataList3)}
                            "4" {out-logfile -string "Matched Office365 Data Set 4" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataList4)}
                            "5" {out-logfile -string "Matched Office365 Data Set 5" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataList5)}
                            "6" {out-logfile -string "Matched Office365 Data Set 6" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataList6)}
                            "7" {out-logfile -string "Matched Office365 Data Set 7" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataList7)}
                            "8" {out-logfile -string "Matched Office365 Data Set 8" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataList8)}
                            "9" {out-logfile -string "Matched Office365 Data Set 9" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataList9)}
                            "a" {out-logfile -string "Matched Office365 Data Set A" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataListA)}
                            "b" {out-logfile -string "Matched Office365 Data Set B" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataListB)}
                            "c" {out-logfile -string "Matched Office365 Data Set C" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataListC)}
                            "d" {out-logfile -string "Matched Office365 Data Set D" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataListD)}
                            "e" {out-logfile -string "Matched Office365 Data Set E" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataListE)}
                            "f" {out-logfile -string "Matched Office365 Data Set F" ; $functionOffice365Data = [System.Collections.ArrayList]@($functionOffice365DataListF)}
                        }


                        out-logfile -string "Member found in Azure AD now evaluate Exchange Online"

                        if ($functionOffice365Data.externalDirectoryObjectID -contains $functionObject.externalDirectoryObjectID)
                        {
                            out-logfile -string "Member found in Exchange Online - GOOD."

                            $functionObject.isPresentInExchangeOnline = "True"
                            $functionObject.isValidMember = "TRUE"

                            out-logfile -string $functionObject

                            $functionReturnArray += $functionObject

                            out-logfile -string ("Office 365 Data Count pre-remove: "+$functionOffice365Data.count)
                            $functionIndex = $functionOffice365Data.externalDirectoryObjectID.indexOf($functionObject.externalDirectoryObjectID)
                            out-logfile -string $functionIndex.tostring()
                            $functionOffice365Data.removeAt($functionIndex)
                            out-logfile -string ("Office 365 Data Count post-remove: "+$functionOffice365Data.count)
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