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

        out-logfile "Gathering all PS Sessions"

        try{
            $functionSessions = Get-PSSession -errorAction STOP
        }
        catch
        {
            out-logfile -string "Error getting PSSessions - hard abort since this is called in exit code."
            EXIT
        }

        out-logFile -string "Disconnecting Exchange Online Session"

        foreach ($session in $functionSessions)
        {
            if ($session.computerName -eq "outlook.office365.com")
            {
                try{
                    out-logfile -string $session.id
                    out-logfile -string $session.name
                    out-logfile -string $session.computerName

                    Disconnect-ExchangeOnline -confirm:$FALSE -errorAction STOP
                }
                catch{
                    out-logfile -string "Error removing Exchange Online Session - Hard Exit since this function is called in error code."
                    EXIT
                }
            }
            else 
            {
                out-logfile -string "Removing other non-Exchange Online powershell sessions."

                out-logfile -string $session.id
                out-logfile -string $session.name
                out-logfile -string $session.computerName

                Get-PSSession | remove-pssession
            }
        }

        Out-LogFile -string "END disable-allPowerShellSessions"
        Out-LogFile -string "********************************************************************************"
    }