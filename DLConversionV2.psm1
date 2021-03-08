
#############################################################################################
# DISCLAIMER:																				#
#																							#
# THE SAMPLE SCRIPTS ARE NOT SUPPORTED UNDER ANY MICROSOFT STANDARD SUPPORT					#
# PROGRAM OR SERVICE. THE SAMPLE SCRIPTS ARE PROVIDED AS IS WITHOUT WARRANTY				#
# OF ANY KIND. MICROSOFT FURTHER DISCLAIMS ALL IMPLIED WARRANTIES INCLUDING, WITHOUT		#
# LIMITATION, ANY IMPLIED WARRANTIES OF MERCHANTABILITY OR OF FITNESS FOR A PARTICULAR		#
# PURPOSE. THE ENTIRE RISK ARISING OUT OF THE USE OR PERFORMANCE OF THE SAMPLE SCRIPTS		#
# AND DOCUMENTATION REMAINS WITH YOU. IN NO EVENT SHALL MICROSOFT, ITS AUTHORS, OR			#
# ANYONE ELSE INVOLVED IN THE CREATION, PRODUCTION, OR DELIVERY OF THE SCRIPTS BE LIABLE	#
# FOR ANY DAMAGES WHATSOEVER (INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF BUSINESS	#
# PROFITS, BUSINESS INTERRUPTION, LOSS OF BUSINESS INFORMATION, OR OTHER PECUNIARY LOSS)	#
# ARISING OUT OF THE USE OF OR INABILITY TO USE THE SAMPLE SCRIPTS OR DOCUMENTATION,		#
# EVEN IF MICROSOFT HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES						#
#############################################################################################

<#
    .SYNOPSIS

    This is the trigger function that begins the process of allowing an administrator to migrate a distribution list from
    on premises to Office 365.

    .DESCRIPTION

    Trigger function.

    .PARAMETER groupSMTPAddress

    The SMTP address of the distribution list to be migrated.

    .PARAMETER userName

    At minimum this must be a domain administrator in the domain where the group resides assuming the object has no dependencies on other forests or trees within active directory.
    In a multi forest environment where the group may contain objects from multiple forests recommend an enterprise administrator be utilized.

    .PARAMETER password

    The password for the administrator account specified in userName.

    .PARAMETER globalCatalogServer

    A global catalog server in the domain where the group resides. 
    
    .PARAMETER logFolder

    The location where logging for the migration should occur including all XML outputs for backups.

	.OUTPUTS

    Logs all activities and backs up all original data to the log folder directory.

    .EXAMPLE

    Get-ExPerfwiz

    #>

Function Start-DistributionListMigration 
{
    [cmdletbinding()]

    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$groupSMTPAddress,
        [Parameter(Mandatory = $true)]
        [string]$globalCatalogServer,
        [Parameter(Mandatory = $true)]
        [pscredential]$activeDirectoryCredential,
        [Parameter(Mandatory = $true)]
        [string]$logFolderPath,
        [Parameter(Mandatory = $false)]
        [string]$aadConnectServer,
        [Parameter(Mandatory = $false)]
        [pscredential]$aadConnectCredential,
        [Parameter(Mandatory = $false)]
        [string]$exchangeServer,
        [Parameter(Mandatory = $false)]
        [pscredential]$exchangeCredential,
        [Parameter(Mandatory = $false)]
        [pscredential]$exchangeOnlineCredential,
        [Parameter(Mandatory = $false)]
        [string]$exchangeOnlineCertificateThumbPrint
    )

    #Define variables utilized in the core function that are not defined by parameters.

    [boolean]$useOnPremsiesExchange=$FALSE

    #Log file header.

    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "BEGIN DL MIGRATION"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************"

    #Output parameters to the log file for recording.

    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "PARAMETERS"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "GroupSMTPAddress"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $groupSMTPAddress
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "GlobalCatalogServer"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $globalCatalogServer
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "ActiveDirectoryUserName"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $activeDirectoryCredential.UserName
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "LogFolderPath"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $logFolderPath

    if ($aadConnectServer -ne "")
    {
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "AADConnectServer"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $aadConnectServer
    }

    if ($aadConnectCredential -ne $null)
    {
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "AADConnectUserName"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $aadConnectCredential.UserName
    }

    if ($exchangeServer -ne "")
    {
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "ExchangeServer"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $exchangeServer
    }

    if ($exchangecredential -ne $null)
    {
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "ExchangeUserName"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $exchangeCredential.UserName
    }

    if ($exchangeOnlineCredential -ne $null)
    {
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "ExchangeOnlineUserName"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $exchangeOnlineCredential.UserName
    }

    if ($exchangeOnlineCertificateThumbPrint -ne "")
    {
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "ExchangeOnlineCertificateThumbprint"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $exchangeOnlineCertificateThumbPrint
    }

    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************"

    #Perform paramter validation manually.

    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "ENTERING PARAMTER VALIDATION"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************"

    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "Validating that both AADConnectServer and AADConnectCredential are specified"
   
    if (($aadConnectServer -eq "") -and ($aadConnectCredential -ne $null))
    {
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "ERROR:  AAD Connect Server is required when specfying AAD Connect Credential" -isError:$TRUE
    }
    elseif (($aadConnectCredential -eq $NULL) -and ($aadConnectServer -ne ""))
    {
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "ERROR:  AAD Connect Credential is required when specfying AAD Connect Server" -isError:$TRUE
    }
    else
    {
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "AADConnectServer and AADConnectCredential were both specified."
    }

    #Validate that both the exchange credential and exchange server are presented together.

    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "Validating that both ExchangeServer and ExchangeCredential are specified"

    if (($exchangeServer -eq "") -and ($exchangeCredential -ne $null))
    {
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "ERROR:  Exchange Server is required when specfying Exchange Credential" -isError:$TRUE
    }
    elseif (($exchangeCredential -eq $NULL) -and ($exchangetServer -ne ""))
    {
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "ERROR:  Exchange Credential is required when specfying Exchange Server" -isError:$TRUE
    }
    else
    {
        $useOnPremsiesExchange=$TRUE
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "ExchangeServer and ExchangeCredential were both specified." 
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "The use Exchange Server attribute is set to TRUE."
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $useOnPremsiesExchange  
    }

    #Validate that only one method of engaging exchange online was specified.

    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "Validating that Exchange Credentials are not specified with Exchange Certificate Thumbprint"

    if (($exchangeOnlineCredential -ne $NULL) -and ($exchangeOnlineCertificateThumbPrint -ne ""))
    {
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "ERROR:  Only one method of cloud authentication can be specified.  Use either cloud credentials or cloud certificate thumbprint." -isError:$TRUE
    }
    else
    {
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "Only one method of Exchange Online authentication specified."
    }

    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "END PARAMETER VALIDATION"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************"

    #If exchange server information specified - create the on premises powershell session.

    if ($useOnPremsiesExchange -eq $TRUE)
    {
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "Calling New-ExchangeOnPremsiesPowershell"
        New-ExchangeOnPremisesPowershell -exchangeServer $exchangeServer -exchangeCredentials $exchangecredential
    }
    else
    {
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "No on premises Exchange specified - skipping setup of powershell session."
    }

    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "Calling Test-ExchangeOnlinePowershell to ensure modules are installed."

    #Test to determine if the exchange online powershell module is installed.
    
    Test-ExchangeOnlinePowerShell

    #Create the connection to exchange online.

    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "Calling New-ExchangeOnlinePowershellSession to create session to office 365."

    if ($exchangeOnlineCredential -ne $NULL)
    {
        New-ExchangeOnlinePowershellSession -exchangeOnlineCredentials $exchangeOnlineCredential
    }
}