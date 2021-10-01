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
        [bool]$isTestError=0

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN TEST-O365RECIPIENT"
        Out-LogFile -string "********************************************************************************"

        out-logfile -string $isTestError

        if (($member.externalDirectoryObjectID -ne $NULL) -and ($member.recipientOrUser -eq "Recipient"))
        {
            out-LogFile -string "Testing based on External Directory Object ID"
            out-logfile -string $member.ExternalDirectoryObjectID
            out-logfile -string $member.recipientOrUser

            #Modify the external directory object id.

            $functionDirectoryObjectID=$member.externalDirectoryObjectID.Split("_")

            out-logfile -string $functionDirectoryObjectID[1]

            try {
                get-exoRecipient -identity $functionDirectoryObjectID[1] -errorAction STOP
                $isTestError=0
            }
            catch {
                out-logfile -string ("The recipient was not found in Office 365.  ERROR --"+$functionDirectoryObjectID[1] )
                out-logFile -string $_
                $isTestError=1
            }
        }
        elseif (($member.PrimarySMTPAddressOrUPN -ne $NULL) -and ($member.recipientoruser -eq "Recipient"))
        {
            out-LogFile -string "Testing based on Primary SMTP Address"
            out-logfile -string $member.PrimarySMTPAddressOrUPN
            out-logfile -string $member.recipientOrUser

            try {
                get-exoRecipient -identity $member.PrimarySMTPAddressOrUPN -errorAction Stop
                $isTestError=0
            }
            catch {
                out-logfile -string ("The recipient was not found in Office 365.  ERROR -- "+$member.primarySMTPAddressOrUPN)
                out-logfile -string $_
                $isTestError = 1
            }
        }
        elseif (($member.ExternalDirectoryObjectID -ne $NULL) -and ($member.recipientoruser -eq "User"))
        {
            out-LogFile -string "Testing based on external directory object ID."
            out-logfile -string $member.externalDirectoryObjectID
            out-logfile -string $member.recipientOrUser

            #Modify the external directory object id.

            $functionDirectoryObjectID=$member.externalDirectoryObjectID.Split("_")

            out-logfile -string $functionDirectoryObjectID[1]

            try {
                get-o365User -identity $functionDirectoryObjectID[1] -errorAction STOP
                $isTestError=0
            }
            catch {
                out-logfile -string ("The recipient was not found in Office 365.  ERROR --"+$functionDirectoryObjectID[1] )
                out-logFile -string $_
                $isTestError=1
            }
        }
        elseif (($member.PrimarySMTPAddressOrUPN -ne $NULL) -and ($member.recipientoruser -eq "User"))
        {
            out-LogFile -string "Testing based on user principal name."
            out-logfile -string $member.PrimarySMTPAddressOrUPN
            out-logfile -string $member.recipientOrUser

            try {
                get-o365User -identity $member.primarySMTPAddressOrUPN -errorAction STOP
                $isTestError=0
            }
            catch {
                out-logfile -string ("The recipient was not found in Office 365.  ERROR -- "+$member.primarySMTPAddressOrUPN)
                out-logfile -string $_
                $isTestError=1
            }
        }
        else 
        {
            out-logfile -string "An invalid object was passed to test-o365recipient - failing." -isError:$TRUE

        }

        out-logfile -string $isTestError

        Out-LogFile -string "END TEST-O365RECIPIENT"
        Out-LogFile -string "********************************************************************************"    

        return $isTestError
    }