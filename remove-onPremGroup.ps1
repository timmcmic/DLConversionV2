<#
    .SYNOPSIS

    This function disables all open powershell sessions.

    .DESCRIPTION

    This function disables all open powershell sessions.

    .OUTPUTS

    No return.

    .EXAMPLE

    disable-allPowerShellSessions

    #>
    Function remove-onPremGroup
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$globalCatalogServer,
            [Parameter(Mandatory = $true)]
            $originalDLConfiguration,
            [Parameter(Mandatory = $true)]
            $adCredential
        )

        [string]$isTestError="No"

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN remove-onPremGroup"
        Out-LogFile -string "********************************************************************************"

        out-logFile -string "Remove on premises distribution group."

        try
        {
            remove-adobject -identity $originalDLConfiguration.distinguishedName -server $globalCatalogServer -credential $adCredential -confirm:$FALSE -errorAction STOP
        }
        catch
        {
            out-logfile -string $_
            $isTestError="Yes"
        }

        Out-LogFile -string "END remove-onPremGroup"
        Out-LogFile -string "********************************************************************************"

        return $isTestError
    }