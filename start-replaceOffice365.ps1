<#
    .SYNOPSIS

    This function begins the process of replacing the Office 365 settings for groups that have been migrated that had cloud only dependencies.

    .DESCRIPTION

    This function begins the process of replacing the Office 365 settings for groups that have been migrated that had cloud only dependencies.

    .PARAMETER office365Attribute

    The office 365 attribute.

    .PARAMETER office365Member

    The member that is being added.

    .PARAMETER groupSMTPAddress

    The member that is being added.

    .OUTPUTS

    None

    .EXAMPLE

    sstart-replaceOffice365 -office365Attribute Attribute -office365Member groupMember -groupSMTPAddress smtpAddess

    #>
    Function start-ReplaceOffice365
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
        Out-LogFile -string "BEGIN start-ReplaceOffice365"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        $functionCommand=$NULL

        Out-LogFile -string ("Office 365 Attribute = "+$office365Attribute)
        out-logfile -string ("Office 365 Member = "+$office365Member.primarySMTPAddress)

        #Declare function variables.

        out-Logfile -string "Processing operation..."

        $functionCommand="set-o365DistributionGroup -identity $office365Member -$office365Attribute @{add='$groupSMTPAddress'} -errorAction STOP -bypassSecurityGroupManagerCheck"
        out-logfile -string ("The command to execute:  "+$functionCommand)

        $scriptBlock = [scriptBlock]::create($functionCommand)

        out-logfile -string ("The script block to execute: "+$scriptBlock)

        try {
            & $scriptBlock
        }
        catch {
            out-logfile -string $_
            $isTestError="Yes"
        }

        Out-LogFile -string "END start-replaceOffice365"
        Out-LogFile -string "********************************************************************************"

        return $isTestError
    }