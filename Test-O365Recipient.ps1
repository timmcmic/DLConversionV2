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
            $member
        )

        #Declare local variables.

        [array]$functionDirectoryObjectID=@()

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN TEST-O365RECIPIENT"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        out-logfile -string $member

        if (($member.externalDirectoryObjectID -ne $NULL) -and ($member.recipientOrUser -eq "Recipient"))
        {
            out-LogFile -string "Testing based on External Directory Object ID"
            out-logfile -string $member.ExternalDirectoryObjectID
            out-logfile -string $member.recipientOrUser

            #Modify the external directory object id.

            $functionDirectoryObjectID=$externalDirectoryObjectID.Split("_")

            out-logfile -string ("Modified external directory object id to test ="+$functionDirectoryObjectID[1])

            try {
                get-exoRecipient -identity $functionDirectoryObjectID -errorAction STOP
            }
            catch {
                out-logFile -string $_ -isError:$TRUE
            }
        }
        elseif (($member.PrimarySMTPAddressOrUPN -ne $NULL) -and ($member.recipientoruser -eq "Recipient"))
        {
            out-LogFile -string "Testing based on Primary SMTP Address"
            out-logfile -string $member.PrimarySMTPAddressOrUPN
            out-logfile -string $member.recipientOrUser

            try {
                get-exoRecipient -identity $member.PrimarySMTPAddressOrUPN -errorAction Stop
            }
            catch {
                out-logfile -string $_ -isError:$TRUE
            }
        }
        elseif (($member.PrimarySMTPAddressOrUPN -ne $NULL) -and ($member.recipientoruser -eq "User"))
        {
            out-LogFile -string "Testing based on user principal name."
            out-logfile -string $member.PrimarySMTPAddressOrUPN
            out-logfile -string $member.recipientOrUser

            try {
                get-o365User -identity $member.primarySMTPAddressOrUPN -errorAction STOP
            }
            catch {
                out-logfile -string $_ -isError:$TRUE
            }
        }
        else 
        {
            out-logfile -string "An invalid object was passed to test-o365recipient - failing." -isError:$TRUE

        }
    }

<#
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

                #$functionTest=get-o365recipient -identity $recipientSMTPAddress -errorAction STOP

                out-logfile -string $functionTest.externalDirectoryObjectID
                out-logfile -string $functionTest.primarySMTPAddress
            }
            elseif ($externalDirectoryObjectID -ne "None")
            {
                Out-LogFile -string "Function received external directory object ID to test."

                $errorID = $externalDirectoryObjectID

                $functionTest=get-exorecipient -identity $functionDirectoryObjectID[1] -errorAction STOP
                #$functionTest=get-o365recipient -identity $functionDirectoryObjectID[1] -errorAction STOP

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
    #>