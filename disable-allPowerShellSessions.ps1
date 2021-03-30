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
    Function disable-allPowerShellSessions
     {

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN disable-allPowerShellSessions"
        Out-LogFile -string "********************************************************************************"

        out-logFile -string "Disconnecting Exchange Online Session"

        try{
            Disconnect-ExchangeOnline -confirm:$FALSE
        }
        catch{
            out-logFile -string $_ -isError:$TRUE
        }

        out-logfile -string "Remove all other PSSessions"

        try{
            Get-PSSession | remove-pssession
        }
        catch{
            out-logfile -string $_ -isError:$TRUE
        }

        Out-LogFile -string "END disable-allPowerShellSessions"
        Out-LogFile -string "********************************************************************************"
    }