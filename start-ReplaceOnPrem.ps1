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
            $routingContact,
            [Parameter(Mandatory = $true)]
            [string]$attributeOperation,
            [Parameter(Mandatory = $true)]
            $canonicalObject,
            [Parameter(Mandatory = $true)]
            $adCredential,
            [Parameter(Mandatory = $true)]
            [string]$globalCatalogServer
        )

        [string]$isTestError="No"

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN start-ReplaceOnPrem"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        Out-LogFile -string ("Routing Contact DN = "+$routingContact)
        out-logfile -string ("Attribute Operation = "+$attributeOperation)
        out-logfile -string ("Canonical Object = "+$canonicalObject)
        out-logfile -string ("AD Credential = "+$adCredential.userName)

        #Declare function variables.


        $functionContactObject = get-canonicalName -globalCatalogServer $globalCatalogServer -dn $routingContact.distinguishedName -adCredential $adCredential
        $loopCounter=0
        $functionSleepTest=$FALSE
        $loopError=$FALSE


        out-Logfile -string "Processing operation..."

        #If the contact and the object to operate on are in the same domain - the utilize the same GC that we have for other operations.
        #If not - we'll need to utilize the domain name as the server - and allow the AD commandlts to make a best attempt against a DC in that domain based on "best selection."

        if ($functionContactObject.canonicalDomainName -eq $canonicalObject.canonicalDomainName)
        {
            out-logfile -string "Source and Target objects are in the same domain - utilize GC."

            try{
                set-adobject -identity $canonicalObject.distinguishedName -add @{$attributeOperation=$routingContact.distinguishedName} -server $globalCatalogServer -credential $adCredential -errorAction STOP
            }
            catch{
                out-logfile -string $_
                $isTestError="Yes"
            }
        }
        else 
        {
           out-logfile -string "Source and target are in different domains - adding additional sleep and trying operation." 

            do {
                $loopError = $FALSE

                if ($functionSleepTest -ne $FALSE)
                {
                    start-sleepProgress -sleepString "Failed adding member to the group - sleeping before rety." -sleepSeconds 30

                }

                try
                {
                    set-adobject -identity $canonicalObject.distinguishedName -add @{$attributeOperation=$routingContact.distinguishedName} -server $canonicalObject.canonicalDomainName -credential $adCredential -errorAction STOP

                    $functionSleepTest=$TRUE

                    $loopCounter++
                }
                catch
                {
                    out-logfile -string "Error adding member to group."

                    $loopError = $TRUE
                }   
            } while (($loopError -eq $TRUE) -and ($loopCounter -eq 10))
        }

        if ($loopCounter -eq 10)
        {
            out-logfile -string "ERROR adding member to group."
            out-logfile -string $canonicalObject.canonicalName
            $isTestError="Yes"
        }
        else 
        {
            out-logfile -string "Operation processed successfully"      
        }


        Out-LogFile -string "END start-replaceOnPrem"
        Out-LogFile -string "********************************************************************************"

        return $isTestError
    }