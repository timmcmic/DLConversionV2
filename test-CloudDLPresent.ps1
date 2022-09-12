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

        out-logfile -string "Output bound parameters..."

        $parameteroutput = @()

        foreach ($paramName in $MyInvocation.MyCommand.Parameters.Keys)
        {
            $bound = $PSBoundParameters.ContainsKey($paramName)

            $parameterObject = New-Object PSObject -Property @{
                ParameterName = $paramName
                ParameterValue = if ($bound) { $PSBoundParameters[$paramName] }
                                    else { Get-Variable -Scope Local -ErrorAction Ignore -ValueOnly $paramName }
                Bound = $bound
                }

            $parameterOutput+=$parameterObject
        }

        out-logfile -string $parameterOutput

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