<#
    .SYNOPSIS

    This function creates the powershell session to Azure AD.

    .DESCRIPTION

    This function creates the powershell session to Azure AD.

    .PARAMETER azureADCredential

    The credential utilized to connect to azure ad.

    .PARAMETER azureCertificateThumbprint

    The certificate thumbprint for the associated azure application.

    .PARAMETER azureTenantID

    The tenant ID associated with the azure application.

    .PARAMETER azureApplicationID

    The application ID for azure management.

    .PARAMETER azureEnvironmentName

    The azure environment for the connection to azure ad.

	.OUTPUTS

    Powershell session to use for exchange online commands.

    .EXAMPLE

    new-AzureADPowershellSession -AzureADCredential $CRED -azureEnvironmentName NAME

    #>
    Function New-AzureADPowershellSession
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(ParameterSetName = "UserCredentials",Mandatory = $true)]
            [pscredential]$azureADCredential=$NULL,,
            [Parameter(ParameterSetName = "CertificateCredentials",Mandatory = $true)]
            [string]$azureCertificateThumbPrint,
            [Parameter(ParameterSetName = "CertificateCredentials",Mandatory = $true)]
            [string]$azureTenantID,
            [Parameter(ParameterSetName = "CertificateCredentials",Mandatory = $true)]
            [string]$azureApplicationID,
            [Parameter(ParameterSetName = "UserCredentials",Mandatory = $true)]
            [Parameter(ParameterSetName = "CertificateCredentials",Mandatory = $true)]
            [string]$azureEnvironmentName,
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
            if ($azureADCredential -ne $NULL)
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
            else
            {
                try 
                {
                    Out-LogFile -string "Creating the azure active directory powershell session."

                    Connect-AzureAD -azureEnvironmentName $azureEnvironmentName
                }
                catch 
                {
                    Out-LogFile -string $_ -isError:$TRUE -isAudit $isAudit
                }
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

        Out-LogFile -string "END NEW-AZUREADPOWERSHELL SESSION"
        Out-LogFile -string "********************************************************************************"
    }