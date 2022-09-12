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
            [string]$groupSMTPAddress
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Declare function variables.

        [boolean]$firstLoopProcessing=$TRUE

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN TEST-CLOUDDLPRESENT"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        out-Logfile -string ("Group SMTP Address = "+$groupSMTPAddress)

        do 
        {
            if ($firstLoopProcessing -eq $TRUE)
            {
                Out-LogFile -string "First time checking for group - do not sleep."
                $firstLoopProcessing = $FALSE
            }
            else 
            {
                start-sleepProgress -sleepString "Group found in Office 365 - sleep for 30 seconds - try again." -sleepSeconds 30
            }

        } while (get-exoRecipient -identity $groupSMTPAddress)

        Out-LogFile -string "END TEST-CLOUDDLPRESENT"
        Out-LogFile -string "********************************************************************************"
    }