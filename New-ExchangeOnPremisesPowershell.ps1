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

        #Write function based variables to log files.

        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "ExchangeCredential"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $exchangeCredentials.userName
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "ExchangeServer"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $exchangeServer
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "ExchangeServerURL"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $exchangeServerURL
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "ExchangeServerAuthenticationType"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $exchangeServerAuthenticationType
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "ExchangeServerConfiguration"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $exchangeServerConfiguration
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "ExchangeServerAllowRedirection"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $exchangeServerAllowRedirection
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "ExchangeServerPowershellSessionName"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $exchangePowershellSessionName

        try 
        {
            Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "Creating the on premsies powershell session."

            $exchangeOnPremisesPowershellSession = New-PSSession -ConnectionUri $exchangeServerURL -Credential $exchangeCredentials -Name $exchangePowershellSessionName -ConfigurationName $exchangeServerConfiguration -AllowRedirection:$exchangeServerAllowRedirection -Authentication $exchangeServerAuthenticationType -ErrorAction:Stop
        }
        catch 
        {
            Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $_ -isError:$TRUE
        }

        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "The exchange on premsies powershell session was created successfully."

        #Import and activate the powershell session.

        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "Calling import-ExchangeOnPremisesPowershell."
        Import-ExchangeOnPremisesPowershell -exchangePowershellSession $exchangeOnPremisesPowershellSession

        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "END NEW-EXCHANGEONPREMISESPOWERSHELL"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************"
    }