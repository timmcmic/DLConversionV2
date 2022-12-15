<#
    .SYNOPSIS

    This function loops until we detect that the cloud DL is no longer present.
    
    .DESCRIPTION

    This function loops until we detect that the cloud DL is no longer present.

    .PARAMETER groupSMTPAddress

    The SMTP Address of the group.

    .OUTPUTS

    None

    .EXAMPLE

    test-CloudDLPresent -groupSMTPAddress SMTPAddress

    #>
    Function test-CloudDLPresent
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$groupSMTPAddress,
            [Parameter(Mandatory = $FALSE)]
            $aadConnectPowershellSessionName=$NULL
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Declare function variables.

        [boolean]$firstLoopProcessing=$TRUE
        [int]$waitTime=0
        [int]$maxWaitTIme = 11

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN TEST-CLOUDDLPRESENT"
        Out-LogFile -string "********************************************************************************"

        do 
        {
            if ($firstLoopProcessing -eq $TRUE)
            {
                Out-LogFile -string "First time checking for group - do not sleep."
                $firstLoopProcessing = $FALSE
            }
            else 
            {
                out-logfile -string "Determine if AD Connect should be proactivly triggered (suspect thread 1 failure)."

                if (($waitTime -eq $maxWaitTime) -and ($aadConnectPowershellSessionName -ne $NULL))
                {
                    out-logfile -string "Time elapsed 5 minutes - proactively invoking AD Connect - assuming thread 1 failure in multi-migration."
                    invoke-adconnect -PowershellSessionName $aadConnectPowershellSessionName
                }
                else 
                {
                    out-logfile -string "No need to invoke ADConnect at this time."
                    $waitTime++
                }

                start-sleepProgress -sleepString "Group found in Office 365 - sleep for 30 seconds - try again." -sleepSeconds 30
            }

        } while (get-o365Recipient -identity $groupSMTPAddress)

        Out-LogFile -string "END TEST-CLOUDDLPRESENT"
        Out-LogFile -string "********************************************************************************"
    }