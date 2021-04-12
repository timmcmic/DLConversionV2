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
        #Declare function variables.

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN enable-ExchangeOnPremEntireForest"
        Out-LogFile -string "********************************************************************************"

        try {
            out-logfile -string "Attempting to set view entire forest = TRUE."

            Set-ADServerSettings -ViewEntireForest:$TRUE
        }
        catch {
            out-logfile -string "Unable to set the entire forest settings to true."
            out-logfile -string $_ -isError:$TRUE
        }

        Out-LogFile -string "END enable-ExchangeOnPremEntireForest"
        Out-LogFile -string "********************************************************************************"
    }