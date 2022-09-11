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
            [string]$exchangeOnlineCertificateThumbPrint,
            [Parameter(ParameterSetName = "CertificateCredentials",Mandatory = $true)]
            [string]$exchangeOnlineAppID,
            [Parameter(ParameterSetName = "CertificateCredentials",Mandatory = $true)]
            [string]$exchangeOnlineOrganizationName,
            [Parameter(ParameterSetName = "UserCredentials",Mandatory = $true)]
            [Parameter(ParameterSetName = "CertificateCredentials",Mandatory = $true)]
            [string]$exchangeOnlineEnvironmentName,
            [Parameter(ParameterSetName = "UserCredentials",Mandatory = $true)]
            [Parameter(ParameterSetName = "CertificateCredentials",Mandatory = $true)]
            [string]$debugLogPath,
            [Parameter(ParameterSetName = "UserCredentials",Mandatory = $false)]
            [Parameter(ParameterSetName = "CertificateCredentials",Mandatory = $false)]
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

        #Define variables that will be utilzed in the function.

        [string]$exchangeOnlineCommandPrefix="O365"
        [boolean]$isCertAuth=$false
        #$exchangeOnlineCommands=@('get-ExoRecipient','new-distributionGroup','get-recipient','set-distributionGroup','get-distributionGroupMember','get-mailbox','get-unifiedGroup','set-UnifiedGroup')
        #Initiate the session.
        
        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN NEW-EXCHANGEONLINEPOWERSHELLSESSION"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        if ($exchangeOnlineCredentials -ne $NULL)
        {
            Out-LogFile -string ("ExchangeOnlineCredentialsUserName = "+$exchangeOnlineCredentials.userName.tostring())
            out-logfile -string ("Is certificate auth = "+$isCertAuth)
        }
        elseif ($exchangeOnlineCertificate -ne "")
        {
            Out-LogFile -string ("ExchangeOnlineCertificate = "+$exchangeOnlineCertificateThumbPrint)
            out-logfile -string ("ExchangeAppID = "+$exchangeOnlineAppID)
            out-logfile -string ("ExchangeOrgName = "+$exchangeOnlineOrganizationName)
            $isCertAuth=$true
            out-logfile -string ("Is certificate auth = "+$isCertAuth)
        }

        Out-LogFile -string ("ExchangeOnlineCommandPrefix = "+$exchangeOnlineCommandPrefix)

        if ($isCertAuth -eq $False)
        {
            try 
            {
                Out-LogFile -string "Creating the exchange online powershell session."

                Connect-ExchangeOnline -Credential $exchangeOnlineCredentials -prefix $exchangeOnlineCommandPrefix -exchangeEnvironmentName $exchangeOnlineEnvironmentName -LogDirectoryPath $debugLogPath -LogLevel All
            }
            catch 
            {
                Out-LogFile -string $_ -isError:$TRUE -isAudit $isAudit
            }
        }
        elseif ($isCertAuth -eq $TRUE) 
        {
            try 
            {
                out-logfile -string "Creating the connection to exchange online powershell using certificate authentication."

                connect-exchangeOnline -certificateThumbPrint $exchangeOnlineCertificateThumbPrint -appID $exchangeOnlineAppID -Organization $exchangeOnlineOrganizationName -exchangeEnvironmentName $exchangeOnlineEnvironmentName -prefix $exchangeOnlineCommandPrefix -LogDirectoryPath $debugLogPath -LogLevel All 
            } 
            catch 
            {
                out-logfile -string $_ -isError:$TRUE -isAudit $isAudit
            }
        }
               
        Out-LogFile -string "The exchange online powershell session was created successfully."

        Out-LogFile -string "END NEW-EXCHANGEONLINEPOWERSHELLSESSION"
        Out-LogFile -string "********************************************************************************"
    }