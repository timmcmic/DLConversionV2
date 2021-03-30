<#
    .SYNOPSIS

    This function triggers the upgrade of the group to an Office 365 Modern / Unified Group
    
    .DESCRIPTION

    This function triggers the upgrade of the group to an Office 365 Modern / Unified Group

    .PARAMETER groupSMTPAddress

    .OUTPUTS

    None

    .EXAMPLE

    start-upgradeToOffice365Group -groupSMTPAddress address

    #>
    Function start-upgradeToOffice365Group
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$groupSMTPAddress
        )

        #Declare function variables.

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN start-upgradeToOffice365Group"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        out-logfile -string ("Group SMTP Address = "+$groupSMTPAddress)

        #Call the command to begin the upgrade process.

        out-logFile -string "Calling command to being the upgrade process."
        out-logfile -string "NOTE:  This command runs in the background and no status is provided."
        out-logfile -string "Administrators MUST validate the upgrade as successful manually."

        try{
            $attempt=upgrade-o365DistributionGroup -DlIdentities $groupSMTPAddress
        }
        catch{
            out-logFile -string $_ -isError:$TRUE
        }

        out-logfile -string $attempt

        Out-LogFile -string "END start-upgradeToOffice365Group"
        Out-LogFile -string "********************************************************************************"
    }