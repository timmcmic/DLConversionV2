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
            $PowershellSession,
            [Parameter(Mandatory = $false)]
            [boolean]$isAudit=$false
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Define variables that will be utilzed in the function."

        #Begin estabilshing the powershell session.
        
        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN IMPORT-POWERSHELLSESSION"
        Out-LogFile -string "********************************************************************************"

        try 
        {
            Out-LogFile -string "Importing powershell session."

            Import-PSSession -Session $PowershellSession -ErrorAction Stop
        }
        catch 
        {
            Out-LogFile -string $_ -iserror:$TRUE -isAudit $isAudit
        }

        Out-LogFile -string "The powershell session imported successfully."
        Out-LogFile -string "END IMPORT-POWERSHELLSESSION"
        Out-LogFile -string "********************************************************************************"
    }