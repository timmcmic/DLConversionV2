<#
    .SYNOPSIS

    This function creates a powershell session to Exchange On Premsies.

    .DESCRIPTION

    Creates the remote powershell session to the specified on premises Exchange Server.

    .PARAMETER exchangeCredential

    The credentials that will be utilized to establish the Exchange Session.

    .PARAMETER exchangeServer

    The full qualified domain name of the exchange server utilized for the connection.

	.OUTPUTS

    Powershell session to use for exchange on premises commands.

    .EXAMPLE

    New-ExchangeOnPremisesPowershell -exchangeServer NAME -exchangeCredentials credential.

    #>
    Function New-ExchangeOnPremisesPowershell
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [pscredential]$exchangeCredentials,
            [Parameter(Mandatory = $true)]
            [string]$exchangeServer
        )

        #Define variables that will be utilzed in the function.

        [string]$exchangeServerURL = $NULL
        $exchangeOnPremisesPowershellSession = $NULL
        [string]$exchangeServerAuthenticationType = "Basic"
        [string]$exchangeServerConfiguration = "Microsoft.Exchange"
        [boolean]$exchangeServerAllowRedirection = $TRUE
        [string]$exchangePowershellSessionName = "ExchangeOnPremises"

        #Create the exchange server powershell URL.

        $exchangeServerURL = "https://"+$exchangeServer+"/powershell"

        #Begin estabilshing the powershell session.
        
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "BEGIN NEW-EXCHANGEONPREMISESPOWERSHELL"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "."
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "."

        #Clear the error array before trying since this would be a non-terminating error.

        try 
        {
            Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "Creating the on premsies powershell session."

            $exchangeOnPremisesPowershellSession = New-PSSession -ConnectionUri $exchangeServerURL -Credential $exchangeCredentials -Name $exchangePowershellSessionName -ConfigurationName $exchangeServerConfiguration -AllowRedirection:$exchangeServerAllowRedirection -Authentication $exchangeServerAuthenticationType -ErrorAction:Stop
        }
        catch 
        {
            Write-Host "Made the catch"
            Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $_ -isError:$TRUE
        }

        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "The exchange online powershell session was created successfully."

        #Import and activate the powershell session.

        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "Calling import-ExchangeOnPremisesPowershell."
        Import-ExchangeOnPremisesPowershell -exchangePowershellSession $exchangeOnPremisesPowershellSession

        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "END NEW-EXCHANGEONPREMISESPOWERSHELL"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "."
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "."
    }