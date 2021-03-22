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
    Function Import-PowershellSession
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $PowershellSession
        )

        #Define variables that will be utilzed in the function."

        [string]$exchangeOnPremCommandPrefix="OnPrem"

        #Begin estabilshing the powershell session.
        
        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN IMPORT-POWERSHELLSESSION"
        Out-LogFile -string "********************************************************************************"

        try 
        {
            Out-LogFile -string "Importing powershell session."

            Import-PSSession -Session $PowershellSession -ErrorAction Stop -prefix $exchangeOnPremCommandPrefix
        }
        catch 
        {
            Out-LogFile -string $_ -iserror:$TRUE
        }

        Out-LogFile -string "The powershell session imported successfully."
        Out-LogFile -string "END IMPORT-POWERSHELLSESSION"
        Out-LogFile -string "********************************************************************************"
    }