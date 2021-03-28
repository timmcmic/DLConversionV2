<#
    .SYNOPSIS

    This function resets the on premises dependencies of the group that was mirgated.

    .DESCRIPTION

    This function resets the on premises dependencies of the group that was mirgated.

    .PARAMETER routingContactDN

    The original configuration of the DL on premises.

    .PARAMETER attributeOperation

    The attibute that we will be operating against.

    .PARAMETER canonicalObject

    The canonical object that will be reset.

    .PARAMETER adCredential

    The active directory credential

    .OUTPUTS

    None

    .EXAMPLE

    sstart-replaceONPrem -canonicalObject $object -attributeOperation $attribute -routingContactConfiguration $routingContactDN -adCredential $cred

    #>
    Function start-ReplaceOnPrem
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $routingContactDN,
            [Parameter(Mandatory = $true)]
            $attributeOperation,
            [Parameter(Mandatory = $true)]
            $canonicalObject,
            [Parameter(Mandatory = $true)]
            $adCredential
        )

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN start-ReplaceOnPrem"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        Out-LogFile -string ("OriginalDLConfiguration = "+$routingContactDN)
        out-logfile -string ("Attribute Operation = "+$attributeOperation)
        out-logfile -string ("Canonical Object = "+$canonicalObject)
        out-logfile -string ("AD Credential = "+$adCredential.userName)

        #Declare function variables.

        $functionGroup=$NULL
        $functionUser=$NULL

        #If the operation is of type member - a different command must be utilized.

        if ($attributeOperation -eq "MemberOf")
        {
            $functionGroup=get-adobject -identity $canonicalObject.distinguishedName -server $cononicalObject.canonicalDomainName -credentials $adCredential
            $functionUser=get-adObject -identity $routingContactDN

            add-adgroupMember -identity $functionGroup -members $functionUser -server $cononicalObject.canonicalDomainName -credential $adCredn
        }


        

        Out-LogFile -string "END start-replaceOnPrem"
        Out-LogFile -string "********************************************************************************"
    }