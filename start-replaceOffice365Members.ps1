<#
    .SYNOPSIS

    This function updates the membership of any cloud only distribution lists for the migrated distribution group.

    .DESCRIPTION

    This function updates the membership of any cloud only distribution lists for the migrated distribution group.

    .PARAMETER office365Group

    The member that is being added.

    .PARAMETER groupSMTPAddress

    The member that is being added.

    .OUTPUTS

    None

    .EXAMPLE

    sstart-replaceOffice365 -office365Attribute Attribute -office365Member groupMember -groupSMTPAddress smtpAddess

    #>
    Function start-replaceOffice365Members
    {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $office365Group,
            [Parameter(Mandatory = $true)]
            [string]$groupSMTPAddress
        )

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN start-ReplaceOffice365Members"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        $functionCommand=$NULL

        Out-LogFile -string ("Office 365 Attribute = "+$office365Group)
        out-logfile -string ("Office 365 Member = "+$groupSMTPAddress)

        #Declare function variables.

        out-Logfile -string "Processing operation..."

        add-o365DistributionGroupMember -identity $office365Group -member $groupSMTPAddress -errorAction STOP

        Out-LogFile -string "END start-replaceOffice365Members"
        Out-LogFile -string "********************************************************************************"
    }