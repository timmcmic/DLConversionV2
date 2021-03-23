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
                Out-LogFile -string "Group found in Office 365  Sleep for 30 seconds and check again."
                start-sleep -seconds 30
            }

        } while (get-exoRecipient -identity $groupSMTPAddress)

        Out-LogFile -string "END TEST-CLOUDDLPRESENT"
        Out-LogFile -string "********************************************************************************"
    }