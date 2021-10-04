<#
    .SYNOPSIS

    This function begins the process of replacing the Office 365 settings for dynamic groups that have been migrated that had cloud only dependencies.

    .DESCRIPTION

    This function begins the process of replacing the Office 365 settings for dynamic groups that have been migrated that had cloud only dependencies.

    .PARAMETER office365Attribute

    The office 365 attribute.

    .PARAMETER office365Member

    The member that is being added.

    .PARAMETER groupSMTPAddress

    The member that is being added.

    .OUTPUTS

    None

    .EXAMPLE

    sstart-ReplaceOffice365Dynamic -office365Attribute Attribute -office365Member groupMember -groupSMTPAddress smtpAddess

    #>
    Function start-ReplaceOffice365Dynamic
    {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $office365Attribute,
            [Parameter(Mandatory = $true)]
            [string]$office365Member,
            [Parameter(Mandatory = $true)]
            [string]$groupSMTPAddress
        )

        [string]$isTestError="No"

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN start-ReplaceOffice365Dynamic"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        $functionCommand=$NULL

        Out-LogFile -string ("Office 365 Attribute = "+$office365Attribute)
        out-logfile -string ("Office 365 Member = "+$office365Member.primarySMTPAddress)

        #Declare function variables.

        out-Logfile -string "Processing operation..."

        if ($office365Attribute -eq "ManagedBy")
        {
            $error.clear() #Using invoke expression need to clear the error first.

            out-logfile -string "Attribute is managedBy - this is single value on Dynamic DLs"

            $functionCommand="set-o365DynamicDistributionGroup -identity $office365Member -$office365Attribute '$groupSMTPAddress'"

            out-logfile -string ("The command to execute:  "+$functionCommand)

            invoke-expression -Command $functionCommand

            #Test to see if there is an error on the stack.

            if ($error.count -gt 0)
            {
                out-logfile -string $error[0]
                $isTestError=$TRUE
            }
        }
        else 
        {
            $error.clear() #Clear error array to test for invoke expression.

            $functionCommand="set-o365DynamicDistributionGroup -identity $office365Member -$office365Attribute @{add='$groupSMTPAddress'}"
            out-logfile -string ("The command to execute:  "+$functionCommand)

            invoke-expression -Command $functionCommand -errorAction Stop 

            if ($error.count -gt 0)
            {
                out-logfile -string $error[0]
                $isTestError=$TRUE
            }

        }
        
        Out-LogFile -string "END start-ReplaceOffice365Dynamic"
        Out-LogFile -string "********************************************************************************"

        return $isTestError
    }