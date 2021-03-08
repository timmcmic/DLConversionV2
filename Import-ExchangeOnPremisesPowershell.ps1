<#
    .SYNOPSIS

    This function imports the Exchange On-Premises powershell session.

    .DESCRIPTION

    This function imports the Exchange On Premises powershell session allowing exchange commands to be utilized.

    .PARAMETER exchangePowershellSession

    This is the powershell session created by new-ExchangeOnPremisesPowershell

	.OUTPUTS

    The powershell session to Exchange On-Premises.

    .EXAMPLE

    import-ExchangeOnPremisesPowershell -exchangePowershellSession session

    #>
    Function Import-ExchangeOnPremisesPowershell
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $exchangePowershellSession
        )

        #Define variables that will be utilzed in the function."

        #Begin estabilshing the powershell session.
        
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "BEGIN IMPORT-EXCHANGEONPREMISESPOWERSHELL"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "."
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "."

        try 
        {
            Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "Importing exchange on premsies powershell session."

            Import-PSSession -Session $exchangePowershellSession -ErrorAction Stop
        }
        catch 
        {
            Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $_ -iserror:$TRUE
        }

        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "The exchange on premises powershell session imported successfully."
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "END IMPORT-EXCHANGEONPREMISESPOWERSHELL"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************"
    }