<#
    .SYNOPSIS

    This function tests if the recipient is found in Office 365.

    .DESCRIPTION

    This function tests to ensure a recipient is found in Office 365.

    .PARAMETER member

    The member to test for.

    .OUTPUTS

    None

    .EXAMPLE

    test-o365Recipient -member $member

    #>
    Function Test-O365Recipient
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $member
        )

        out-logfile -string "Output bound parameters..."

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Declare local variables.

        [array]$functionDirectoryObjectID=@()
        [string]$isTestError="No"

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN TEST-O365RECIPIENT"
        Out-LogFile -string "********************************************************************************"

        if (($member.externalDirectoryObjectID -ne $NULL) -and ($member.recipientOrUser -eq "Recipient"))
        {
            out-LogFile -string "Testing based on External Directory Object ID"
            out-logfile -string $member.ExternalDirectoryObjectID
            out-logfile -string $member.recipientOrUser

            #Modify the external directory object id.

            $functionDirectoryObjectID=$member.externalDirectoryObjectID.Split("_")

            out-logfile -string $functionDirectoryObjectID[1]

            try {
                #get-exoRecipient -identity $functionDirectoryObjectID[1] -errorAction STOP
                get-o365Recipient -identity $functionDirectoryObjectID[1] -errorAction STOP
                $isTestError="No"
            }
            catch {
                out-logfile -string ("The recipient was not found in Office 365.  ERROR --"+$functionDirectoryObjectID[1] )
                out-logFile -string $_
                $isTestError="Yes"
            }
        }
        elseif (($member.PrimarySMTPAddressOrUPN -ne $NULL) -and ($member.recipientoruser -eq "Recipient"))
        {
            out-LogFile -string "Testing based on Primary SMTP Address"
            out-logfile -string $member.PrimarySMTPAddressOrUPN
            out-logfile -string $member.recipientOrUser

            try {
                #get-exoRecipient -identity $member.PrimarySMTPAddressOrUPN -errorAction Stop
                get-o365Recipient -identity $member.PrimarySMTPAddressOrUPN -errorAction Stop
                $isTestError="No"
            }
            catch {
                out-logfile -string ("The recipient was not found in Office 365.  ERROR -- "+$member.primarySMTPAddressOrUPN)
                out-logfile -string $_
                $isTestError="Yes"
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
                $isTestError="No"
            }
            catch {
                out-logfile -string ("The recipient was not found in Office 365.  ERROR --"+$functionDirectoryObjectID[1] )
                out-logFile -string $_
                $isTestError="Yes"
            }
        }
        elseif (($member.PrimarySMTPAddressOrUPN -ne $NULL) -and ($member.recipientoruser -eq "User"))
        {
            out-LogFile -string "Testing based on user principal name."
            out-logfile -string $member.PrimarySMTPAddressOrUPN
            out-logfile -string $member.recipientOrUser

            try {
                get-o365User -identity $member.primarySMTPAddressOrUPN -errorAction STOP
                $isTestError="No"
            }
            catch {
                out-logfile -string ("The recipient was not found in Office 365.  ERROR -- "+$member.primarySMTPAddressOrUPN)
                out-logfile -string $_
                $isTestError="Yes"
            }
        }
        elseif ($member.recipientOrUser -eq "SecurityGroup")
        {
            out-logfile -string "Found a security group as a member."
            out-logfile -string "Testing based on GUID which was overloaded with the groups SID."
            out-logfile -string ("Testing SID: "+$member.GUID)

            try
            {
                $functionFilter = "`""
                $functionFilter += "onPremisesSecurityIdentifier eq "
                $functionFilter += "`'"
                $functionFilter += $member.GUID
                $functionFilter += "`'"
                $functionFilter += "`""
                out-logfile -string $functionFilter

                $functionCommand = "get-mgGroup -filter $functionFilter"

                out-logfile -string $functionCommand

                $scriptBlock=[scriptBlock]::create($functionCommand)

                $functionTest = invoke-command -ScriptBlock $scriptBlock

                out-logfile -string $functionTest.id
                out-logfile -string $functionTest.mailNickName

                $member.externalDirectoryObjectID = ("User_"+$functionTest.Id)
                $member.alias = $functionTest.mailNickName
            }
            catch
            {
                out-logfile -string ("The recipient was not found in Office 365.  ERROR -- "+$member.GUID)
                out-logfile -string $_
                $isTestError="Yes"
            }
        }
        else 
        {
            out-logfile -string "An invalid object was passed to test-o365recipient - failing."
            $isTestError="Yes"
        }

        Out-LogFile -string "END TEST-O365RECIPIENT"
        Out-LogFile -string "********************************************************************************"    

        return $isTestError
    }