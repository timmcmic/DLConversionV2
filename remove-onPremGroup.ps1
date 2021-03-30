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

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN remove-onPremGroup"
        Out-LogFile -string "********************************************************************************"

        out-logFile -string "Remove on premises distribution group."

        try
        {
            remove-adobject -identity $originalDLConfiguration.distinguishedName -server $globalCatalogServer -credential $adCredential -confirm:$FALSE
        }
        catch
        {
            out-logfile -string $_ -isError:$TRUE
        }

        Out-LogFile -string "END remove-onPremGroup"
        Out-LogFile -string "********************************************************************************"
    }