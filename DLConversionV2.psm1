
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
    [cmdletbinding(DefaultParameterSetName = 'DEFAULT')]

    Param
    (
        [Parameter(ParameterSetName='DEFAULT',Mandatory = $true)]
        [string]$groupSMTPAddress,
        [Parameter(ParameterSetName='DEFAULT',Mandatory = $true)]
        [string]$globalCatalogServer,
        [Parameter(ParameterSetName='DEFAULT',Mandatory = $true)]
        [string]$activeDirectoryUserName,
        [Parameter(ParameterSetName='DEFAULT',Mandatory = $true)]
        [securestring]$activeDirectoryPassword,
        [Parameter(ParameterSetName='DEFAULT',Mandatory = $true)]
        [string]$logFolderPath,
        [Parameter(ParameterSetName='EnableAADConnect',Mandatory = $false)]
        [string]$aadConnectServer,
        [Parameter(ParameterSetName='EnableAADConnect',Mandatory = $true)]
        [string]$aadConnectUserName,
        [Parameter(ParameterSetName='EnableAADConnect',Mandatory = $true)]
        [securestring]$aadConnectPassword,
        [Parameter(ParameterSetName='EnableExchange',Mandatory = $false)]
        [string]$exchangeServer,
        [Parameter(ParameterSetName='EnableExchange',Mandatory = $true)]
        [string]$exchangeUserName,
        [Parameter(ParameterSetName='EnableExchange',Mandatory = $true)]
        [securestring]$exchangePassword
    )

    #Define variables utilized in the core function that are not defined by parameters.

    

    #Log file header.

    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "BEGIN DL MIGRATION"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "."
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "."

    #Output parameters to the log file for recording.

    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "PARAMETERS"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "GroupSMTPAddress"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $groupSMTPAddress
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "GlobalCatalogServer"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $globalCatalogServer
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "ActiveDirectoryUserName"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $activeDirectoryUserName
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "LogFolderPath"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $logFolderPath

    if ($aadConnectServer -ne "")
    {
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "AADConnectServer"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $aadConnectServer
    }

    if ($aadConnectUserName -ne "")
    {
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "AADConnectUserName"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $aadConnectUserName
    }

    if ($exchangeServer -ne "")
    {
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "ExchangeServer"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $exchangeServer
    }

    if ($exchangeUserName -ne "")
    {
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "ExchangeUserName"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $exchangeUserName
    }


    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "."
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "."


}