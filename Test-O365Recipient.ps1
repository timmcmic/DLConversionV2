<#
    .SYNOPSIS

    This function tests if the recipient is found in Office 365.

    .DESCRIPTION

    This function tests to ensure a recipient is found in Office 365.

    .PARAMETER recipientSMTPAddress

    The address of the recipient to look for.

    .PARAMETER externalDirectoryObjectID

    The external directory objectID of the object.

    .OUTPUTS

    None

    .EXAMPLE

    test-O365Recipient -recipientSMTPAddress address
    test-O365Recipient -externalDirectoryObjectID

    #>
    Function Test-O365Recipient
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$recipientSMTPAddress,
            [Parameter(Mandatory = $true)]
            [string]$externalDirectoryObjectID,
            [Parameter(Mandatory = $true)]
            [string]$userPrincipalName
        )

        #Declare local variables.

        [array]$functionDirectoryObjectID = $NULL
        $functionTest=$NULL
        [string]$errorID=$NULL

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN TEST-O365RECIPIENT"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        if ($externalDirectoryObjectID -ne "None")
        {
            out-logfile -string ("External directory object id to test = "+$externalDirectoryObjectID)

            #Modify the external directory object id.

            $functionDirectoryObjectID=$externalDirectoryObjectID.Split("_")

            out-logfile -string ("Modified external directory object id to test ="+$functionDirectoryObjectID[1])
        }
        elseif($recipientSMTPAddress -ne "None")
        {
            out-logfile -string ("Recipient SMTP Address to test - "+$recipientSMTPAddress)
        }
        elseif($userPrincipalName -ne "None")
        {
            out-logfile -string ("User principal name to test - "+$UserprincipalName)
        }
        else 
        {
            out-logfile -string "Function called without parameter - failure." -isError:$TRUE    
        }
        
        #Get the recipient using the exchange online powershell session.
        
        try 
        {
            if ($recipientSMTPAddress -ne "None")
            {
                Out-LogFile -string "Testing for recipient by SMTP Address"

                $errorID = $recipientSMTPAddress

                $functionTest=get-exorecipient -identity $recipientSMTPAddress -errorAction STOP

                out-logfile -string $functionTest.externalDirectoryObjectID
                out-logfile -string $functionTest.primarySMTPAddress
            }
            elseif ($externalDirectoryObjectID -ne "None")
            {
                Out-LogFile -string "Function received external directory object ID to test."

                $errorID = $externalDirectoryObjectID

                $functionTest=get-exorecipient -identity $functionDirectoryObjectID[1] -errorAction STOP

                out-logfile -string $functionTest.externalDirectoryObjectID
                out-logfile -string $functionTest.primarySMTPAddress
            }
            elseif ($userPrincipalName -ne "None")
            {
                Out-LogFile -string "Testing for user by user principal name."

                $errorid = $userPrincipalName

                $functionTest=get-o365User -identity $userPrincipalName -errorAction STOP

                out-logfile -string $functionTest.externalDirectoryObjectID
                out-logfile -string $functionTest.userPrincipalName
            }
        }
        catch 
        {
            out-logfile -string "The recipient was not found in Office 365.  The migrateion cannot proceed."
            out-logfile -string $errorID
            Out-LogFile -string $_ -isError:$TRUE
        }

        Out-LogFile -string "END TEST-O365RECIPIENT"
        Out-LogFile -string "********************************************************************************"    
    }