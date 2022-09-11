<#
    .SYNOPSIS

    This function ensures that view entire forest is set to TRUE for exchange on premsies connections.
    
    .DESCRIPTION

    This function ensures that view entire forest is set to TRUE for exchange on premsies connections.

    .OUTPUTS

    None

    .EXAMPLE

    enable-ExchangeOnPremEntireForest

    #>
    Function enable-ExchangeOnPremEntireForest
     {
        Param
        (
            [Parameter(Mandatory = $false)]
            [boolean]$isAudit=$FALSE
        )

        out-logfile -string "Output bound parameters..."

        $parameteroutput = @()

        foreach ($paramName in $MyInvocation.MyCommand.Parameters.Keys)
        {
            $bound = $PSBoundParameters.ContainsKey($paramName)

            $parameterObject = New-Object PSObject -Property @{
                ParameterName = $paramName
                ParameterValue = if ($bound) { $PSBoundParameters[$paramName] }
                                    else { Get-Variable -Scope Local -ErrorAction Ignore -ValueOnly $paramName }
                Bound = $bound
                }

            $parameterOutput+=$parameterObject
        }

        out-logfile -string $parameterOutput
        
        #Declare function variables.

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN enable-ExchangeOnPremEntireForest"
        Out-LogFile -string "********************************************************************************"

        try {
            out-logfile -string "Attempting to set view entire forest = TRUE."

            Set-ADServerSettings -ViewEntireForest:$TRUE -ErrorAction STOP
        }
        catch {
            out-logfile -string "Unable to set the entire forest settings to true."
            out-logfile -string $_ -isError:$TRUE -isAudit $isAudit
        }

        Out-LogFile -string "END enable-ExchangeOnPremEntireForest"
        Out-LogFile -string "********************************************************************************"
    }