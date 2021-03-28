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
            [string]$attributeOperation,
            [Parameter(Mandatory = $true)]
            $canonicalObject,
            [Parameter(Mandatory = $true)]
            $adCredential,
            [Parameter(Mandatory = $true)]
            [string]$globalCatalogServer
        )

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN start-ReplaceOnPrem"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        Out-LogFile -string ("Routing Contact DN = "+$routingContactDN)
        out-logfile -string ("Attribute Operation = "+$attributeOperation)
        out-logfile -string ("Canonical Object = "+$canonicalObject)
        out-logfile -string ("AD Credential = "+$adCredential.userName)

        #Declare function variables.

        $functionGroup=$NULL
        $functionUser=$NULL

        #If the operation is of type member - a different command must be utilized.

        out-Logfile -string "Processing operation..."

        try{
            set-adobject -identity $canonicalObject.distinguishedName -add @{$attributeOperation=$routingContactDN} -server $canonicalObject.canonicalDomainName -credential $adCredential -errorAction STOP
        }
        catch{
            out-logfile -string $_ -isError:$TRUE
        }

        out-logfile -string "Operation processed successfully"      

        Out-LogFile -string "END start-replaceOnPrem"
        Out-LogFile -string "********************************************************************************"
    }