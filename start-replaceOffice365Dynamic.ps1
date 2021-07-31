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

        $functionCommand="set-o365DynamicDistributionGroup -identity $office365Member -$office365Attribute @{add='$groupSMTPAddress'}"
        out-logfile -string ("The command to execute:  "+$functionCommand)

        try{
            invoke-expression -Command $functionCommand -errorAction Stop
        }
        catch{
            out-logfile -string $_ -isError:$TRUE
        }



        Out-LogFile -string "END start-ReplaceOffice365Dynamic"
        Out-LogFile -string "********************************************************************************"
    }