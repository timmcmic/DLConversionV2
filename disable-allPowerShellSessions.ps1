<#
    .SYNOPSIS

    This function disables all open powershell sessions.

    .DESCRIPTION

    This function disables all open powershell sessions.

    .OUTPUTS

    No return.

    #>
    Function disable-allPowerShellSessions
     {

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN disable-allPowerShellSessions"
        Out-LogFile -string "********************************************************************************"

        out-logfile -string "Determining if the temporary DL should be cleaned up."

        if ($global:DLCleanupInfo -ne $NULL)
        {
            out-logfile -string "Failure occured prior to full DL creation in Office 365.  Remove temporary DL."

            remove-o365CloudOnlyGroup -office365DLConfiguration $global:DLCleanupInfo -dlCleanupRequired:$TRUE
        }
        else {
            out-logfile -string "Skip temporary DL removal."
        }

        out-logfile -string "Determining if the original DL should be moved back to the original OU due to failure."

        if ($global:DLMoveCleanup.originalDLConfiguration -ne $NULL)
        {
            out-logfile -string "The original DL should be moved back to the original group."

            $tempOUSubstring = Get-OULocation -originalDLConfiguration $global:DLMoveCleanup.originalDLConfiguration -errorAction STOP

            move-toNonSyncOU -OU $tempOUSubstring -dn $global:DLMoveCleanup.originalDLConfiguration.GUID -adCredential $global:DLMoveCleanup.adCredential -globalCatalogServer $global:DLMoveCleanup.globalCatalogServer -dlMoveCleanup:$TRUE -errorAction SilentlyContinue
        }
        else 
        {
            out-logfile -string "Skip moving original DL to original OU."
        }

        out-logfile "Gathering all PS Sessions"

        try{
            $functionSessions = Get-PSSession -errorAction STOP
        }
        catch
        {
            out-logfile -string "Error getting PSSessions - hard abort since this is called in exit code."
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
                    #EXIT
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

        try {
            Disconnect-ExchangeOnline -ErrorAction Stop -confirm:$false
        }
        catch {
            out-logfile -string "Error getting PSSessions - hard abort since this is called in exit code."
        }

        try {
            Disconnect-MgGraph -errorAction STOP 
        }
        catch {
            out-logfile -string "Error disconnecting powershell graph - hard abort since this is called in exit code."
        }

        out-logfile -string "***IT MAY BE NECESSARY TO EXIT THIS POWERSHELL WINDOW AND REOPEN TO RESTART FROM A FAILED MIGRATION***"

        Out-LogFile -string "END disable-allPowerShellSessions"
        Out-LogFile -string "********************************************************************************"
    }