<#
    .SYNOPSIS

    This function creates the powershell session to Exchange Online.

    .DESCRIPTION

    This function uses the exchange management shell v2 to utilize modern authentication to connect to exchange online.

    .PARAMETER exchangeOnlineThumbprint

    The user specified thumbprint if using certificate authentication for exchange online.

    .PARAMETER exchangeOnlineCredential

    The user specified credential for exchange online.

	.OUTPUTS

    Powershell session to use for exchange online commands.

    .EXAMPLE

    New-ExchangeOnlinePowershellSession -exchangeOnlineCredentials $cred
    New-ExchangeOnlinePowershellSession -exchangeOnlineCertificate $thumbprint

    #>
    Function New-ExchangeOnlinePowershellSession
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(ParameterSetName = "UserCredentials",Mandatory = $true)]
            [pscredential]$exchangeOnlineCredentials,
            [Parameter(ParameterSetName = "CertificateCredentials",Mandatory = $true)]
            [string]$exchangeOnlineCertificate
        )

        #Define variables that will be utilzed in the function.

        [string]$exchangeOnlineCommandPrefix="O365"

        #Initiate the session.
        
        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN NEW-EXCHANGEONLINEPOWERSHELLSESSION"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        if ($exchangeOnlineCredentials -ne $NULL)
        {
            Out-LogFile -string ("ExchangeOnlineCredentialsUserName = "+$exchangeOnlineCredentials.userName.tostring())
        }
        elseif ($exchangeOnlineCertificate -ne "")
        {
            Out-LogFile -string ("ExchangeOnlineCertificate = "+$exchangeOnlineCertificate)
        }

        Out-LogFile -string ("ExchangeOnlineCommandPrefix = "+$exchangeOnlineCommandPrefix)
               
        try 
        {
            Out-LogFile -string "Creating the exchange online powershell session."

            Connect-ExchangeOnline -Credential $exchangeOnlineCredentials -prefix $exchangeOnlineCommandPrefix
        }
        catch 
        {
            Out-LogFile -string $_ -isError:$TRUE
        }

        Out-LogFile -string "The exchange online powershell session was created successfully."

        Out-LogFile -string "END NEW-EXCHANGEONLINEPOWERSHELLSESSION"
        Out-LogFile -string "********************************************************************************"
    }