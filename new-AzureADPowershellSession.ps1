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
    Function New-AzureADPowershellSession
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(ParameterSetName = "UserCredentials",Mandatory = $true)]
            [pscredential]$azureADCredential,
            [Parameter(ParameterSetName = "CertificateCredentials",Mandatory = $true)]
            [string]$azureCertificateThumbPrint,
            [Parameter(ParameterSetName = "CertificateCredentials",Mandatory = $true)]
            [string]$azureTenantID,
            [Parameter(ParameterSetName = "CertificateCredentials",Mandatory = $true)]
            [string]$azureApplicationID,
            [Parameter(ParameterSetName = "UserCredentials",Mandatory = $true)]
            [Parameter(ParameterSetName = "CertificateCredentials",Mandatory = $true)]
            [string]$azureEnvironment,
            [Parameter(ParameterSetName = "UserCredentials",Mandatory = $false)]
            [Parameter(ParameterSetName = "CertificateCredentials",Mandatory = $false)]
            [boolean]$isAudit=$FALSE
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Define variables that will be utilzed in the function.

        [boolean]$isCertAuth=$false
        #$exchangeOnlineCommands=@('get-ExoRecipient','new-distributionGroup','get-recipient','set-distributionGroup','get-distributionGroupMember','get-mailbox','get-unifiedGroup','set-UnifiedGroup')
        #Initiate the session.
        
        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN NEW-AzureADPowershellSession"
        Out-LogFile -string "********************************************************************************"

        if ($azureCertificateThumbPrint -ne "")
        {
            $isCertAuth=$true
            out-logfile -string ("Is certificate auth = "+$isCertAuth)
        }

        if ($isCertAuth -eq $False)
        {
            try 
            {
                Out-LogFile -string "Creating the azure active directory powershell session."

                Connect-AzureAD -Credential $azureADCredential -azureEnvironmentName $azureEnvironmentName
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

                connect-AzureAD -certificateThumbPrint $azureCertificateThumbPrint -applicationID $azureApplicationID -tenantID $azureTenantID -azureEnvironmentName $azureEnvironmentName
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