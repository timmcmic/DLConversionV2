
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


Function Test-PreMigrationO365Group 
{
    <#
    .SYNOPSIS

    This function performs the tests for health checking and pre-migration.  

    .DESCRIPTION

    This function performs the tests for health checking and pre-migration. 

    .PARAMETER GROUPSMTPADDRESS

    *REQUIRED*
    This attribute specifies the windows mail address of the group to be migrated.

    .PARAMETER GLOBALCATALOGSERVER

    *REQUIRED*
    This attribute specifies the global catalog server that will be utilized to process Active Directory commands.

    .PARAMETER ACIVEDIRECTORYCREDENTIAL

    *REQUIRED*
    This attribute specifies the credentials for Active Directory connections.
    Domain admin credentials are required if the group does not have resorces outside of the domain where the group resides.
    Enterprise admin credentials are required if the group has resources across multiple domains in the forest.

    .PARAMETER EXCHANGEONLINECREDENTIAL

    *REQUIRED if ExchangeOnlineCertificateThumbprint not specified*
    *NOT ALLOWED if ExchangeCertificateThubprint is specified*
    The credential utilized to connect to Exchange Online.
    This account cannot have interactive logon requirements such as multi-factored authentication.
    Exchange Organization Administrator rights recommened.

    .PARAMETER EXCHANGEONLINECERTIFICATETHUMBPRINT

    *REQUIRED if ExchangeOnlineCredential is not specified*
    *NOT ALLOWED if ExchangeCredential is specified*
    This is the thumbprint of the certificate utilized to authenticate to the Azure application created for Exchange Certificate Authentication

    .PARAMETER EXCHANGEONLINEORGANIZATIONNAME

    *REQUIRED only with ExchangeCertificateThumbpint*
    This specifies the Exchange Online oragnization name in domain.onmicroosft.com format.

    .PARAMETER EXCHANGEONLINEENVIRONMENTNAME

    *OPTIONAL*
    *DEFAULT:  O365DEFAULT
    This specifies the Exchange Online environment to connect to if a non-commercial forest is utilized.

    .PARAMETER EXCHANGEONLINEAPPID

    *REQUIRED with ExchangeCertificateThumbprint*
    This specifies the application ID of the Azure application for Exchange certificate authentication.

    .PARAMETER AZUREADCREDENTIAL

    *REQUIRED if AzureCertificateThumbprint is not specified*
    This is the credential utilized to connect to Azure Active Directory.
    Global administrator is the tested permissions set / minimum permissions to execute get-azureADGroup

    .PARAMETER AZUREENVRONMENTNAME

    *OPTIONAL*
    *DEFAULT:  AzureCloud*
    This is the Azure tenant type to connect to if a non-commercial tenant is used.

    .PARAMETER AZURETENANTID

    *REQUIRED if AzureCertificateThumbprint is specified*
    This is the Azure tenant ID / GUID utilized for Azure certificate authentication.

    .PARAMETER AZURECERTIFICATETHUMBPRINT

    *REQUIRED if AzureADCredential is not specified*
    This is the certificate thumbprint associated with the Azure app id for Azure certificate authentication

    .PARAMETER AZUREAPPLICATIONID

    *REQUIRED if AzureCertificateThumbprint is specified*
    This is the application ID assocaited with the Azure application created for certificate authentication.

    .PARAMETER LOGFOLDERPATH

    *REQUIRED*
    This is the logging directory for storing the migration log and all backup XML files.
    If running multiple SINGLE instance migrations use different logging directories.

    .PARAMETER USERCOLLECTEDSENDASONPREM

    *OPTIONAL*
    *Requires use of start-collectOnPremSendAs*
    This switch will import pre-collected send as data from the on premsies Exchange organization and detect dependencies on the migrated DLs.

	.OUTPUTS

    Performs all of the health checking assoicated with a distribution list migration.

    .NOTES

    
    .EXAMPLE

    test-PreMigration -groupSMTPAddress address -globalCatalogServer server -activeDirectoryCredential $cred -activeDirectoryAuthenticationMethod Kerberos -exchangeOnlineCredential $cred -azureADCredential $cred -logFolderPath c:\temp

    #>

    [cmdletbinding()]

    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$groupSMTPAddress,
        #Local Active Director Domain Controller Parameters
        [Parameter(Mandatory = $true)]
        [string]$globalCatalogServer,
        [Parameter(Mandatory = $true)]
        [pscredential]$activeDirectoryCredential,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Basic","Kerberos")]
        $activeDirectoryAuthenticationMethod="Kerberos",
        #Exchange Online Parameters
        [Parameter(Mandatory = $false)]
        [pscredential]$exchangeOnlineCredential=$NULL,
        [Parameter(Mandatory = $false)]
        [string]$exchangeOnlineCertificateThumbPrint="",
        [Parameter(Mandatory = $false)]
        [string]$exchangeOnlineOrganizationName="",
        [Parameter(Mandatory = $false)]
        [ValidateSet("O365Default","O365GermanyCloud","O365China","O365USGovGCCHigh","O365USGovDoD")]
        [string]$exchangeOnlineEnvironmentName="O365Default",
        [Parameter(Mandatory = $false)]
        [string]$exchangeOnlineAppID="",
        #Azure Active Directory Parameters
        [Parameter(Mandatory=$false)]
        [pscredential]$azureADCredential,
        [Parameter(Mandatory = $false)]
        [ValidateSet("AzureCloud","AzureChinaCloud","AzureGermanyCloud","AzureUSGovernment")]
        [string]$azureEnvironmentName="AzureCloud",
        [Parameter(Mandatory=$false)]
        [string]$azureTenantID="",
        [Parameter(Mandatory=$false)]
        [string]$azureCertificateThumbprint="",
        [Parameter(Mandatory=$false)]
        [string]$azureApplicationID="",
        #Define other mandatory parameters
        [Parameter(Mandatory = $true)]
        [string]$logFolderPath,
        #Definte parameters for pre-collected permissions
        [Parameter(Mandatory = $false)]
        [boolean]$useCollectedFullMailboxAccessOffice365=$FALSE,
        [Parameter(Mandatory = $false)]
        [boolean]$useCollectedSendAsOnPrem=$FALSE,
        [Parameter(Mandatory = $false)]
        [boolean]$useCollectedFolderPermissionsOffice365=$FALSE,
        [Parameter(Mandatory = $false)]
        [boolean]$addManagersAsMembers = $false,
        #Define parameters for multi-threaded operations
        [Parameter(Mandatory = $false)]
        [int]$threadNumberAssigned=0,
        [Parameter(Mandatory = $false)]
        [int]$totalThreadCount=0,
        [Parameter(Mandatory = $FALSE)]
        [boolean]$isMultiMachine=$FALSE,
        [Parameter(Mandatory = $FALSE)]
        [string]$remoteDriveLetter=$NULL,
        [Parameter(Mandatory =$FALSE)]
        [boolean]$allowTelemetryCollection=$TRUE,
        [Parameter(Mandatory =$FALSE)]
        [boolean]$allowDetailedTelemetryCollection=$TRUE
    )

    #Initialize telemetry collection.

    $appInsightAPIKey = "63d673af-33f4-401c-931e-f0b64a218d89"
    $traceModuleName = "DLConversion"

    [string]$dnNoSyncOU = "NotSet"

    if ($allowTelemetryCollection -eq $TRUE)
    {
        start-telemetryConfiguration -allowTelemetryCollection $allowTelemetryCollection -appInsightAPIKey $appInsightAPIKey -traceModuleName $traceModuleName
    }

    #Initialize telemetry collection.

    $appInsightAPIKey = "63d673af-33f4-401c-931e-f0b64a218d89"
    $traceModuleName = "DLConversion"

    $telemetryStartTime = get-universalDateTime
    $telemetryEndTime = $NULL
    [double]$telemetryElapsedSeconds = 0
    $telemetryEventName = "test-PreMigration"
    
    if ($allowTelemetryCollection -eq $TRUE)
    {
        start-telemetryConfiguration -allowTelemetryCollection $allowTelemetryCollection -appInsightAPIKey $appInsightAPIKey -traceModuleName $traceModuleName
    }

    $windowTitle = ("Test-PreMigration "+$groupSMTPAddress)
    $host.ui.RawUI.WindowTitle = $windowTitle

    $global:logFile=$NULL #This is the global variable for the calculated log file name
    [string]$global:staticFolderName="\PreReqCheck\"
    [string]$global:staticAuditFolderName="\AuditData\"
    [string]$global:importFile=$logFolderPath+$global:staticAuditFolderName

    #Define variables for import data - used for importing data into pre-collect.

    [array]$importData=@() #Empty array for the import data.
    [string]$importFilePath=$NULL #Import file path where the XML data is located to import (calculated later)

    #Define XML files to contain backups.

    $xmlFiles = @{
        preCreateErrorsXML = @{"value" = "preCreateErrors" ; "Description" = "Export XML of all precreate errors for group to be migrated."}
    }

    #Log start of DL migration to the log file.

    #Define the sub folders for multi-threading.

    $global:threadNumber=$threadNumberAssigned

    [array]$threadFolder="\Thread0","\Thread1","\Thread2","\Thread3","\Thread4","\Thread5","\Thread6","\Thread7","\Thread8","\Thread9","\Thread10"

    #If multi threaded - the log directory needs to be created for each thread.
    #Create the log folder path for status before changing the log folder path.

    if ($totalThreadCount -gt 0)
    {
        $logFolderPath=$logFolderPath+$threadFolder[$global:threadNumber]
    }

    new-LogFile -groupSMTPAddress $groupSMTPAddress.trim() -logFolderPath $logFolderPath

    #Output all parameters bound or unbound and their associated values.

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "PARAMETERS"
    Out-LogFile -string "********************************************************************************"

    write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

    start-office365GroupMigration -groupSMTPAddress $groupSMTPAddress -globalCatalogServer $globalCatalogServer -activeDirectoryCredential $activeDirectoryCredential -activeDirectoryAuthenticationMethod $activeDirectoryAuthenticationMethod -exchangeOnlineCredential $exchangeOnlineCredential -exchangeOnlineCertificateThumbPrint $exchangeOnlineCertificateThumbPrint -exchangeOnlineOrganizationName $exchangeOnlineOrganizationName -exchangeOnlineEnvironmentName $exchangeOnlineEnvironmentName -exchangeOnlineAppID $exchangeOnlineAppID -azureADCredential $azureADCredential -azureEnvironmentName $azureEnvironmentName -azureCertificateThumbprint $azureCertificateThumbprint -azureTenantID $azureTenantID -azureApplicationID $azureApplicationID -logFolderPath $logFolderPath -allowTelemetryCollection:$FALSE -isHealthCheck $TRUE -threadNumberAssigned $threadNumberAssigned -totalThreadCount $totalThreadCount -useCollectedFullMailboxAccessOffice365 $useCollectedFullMailboxAccessOffice365 -useCollectedSendAsOnPrem $useCollectedSendAsOnPrem -useCollectedFolderPermissionsOffice365 $useCollectedFolderPermissionsOffice365 -addManagersAsMembers $addManagersAsMembers

    Out-LogFile -string "================================================================================"
    Out-LogFile -string "BEGIN test-PreMigrationO365Group"
    Out-LogFile -string "================================================================================"

    $telemetryEndTime = get-universalDateTime
    $telemetryElapsedSeconds = get-elapsedTime -startTime $telemetryStartTime -endTime $telemetryEndTime

    # build the properties and metrics #
    $telemetryEventProperties = @{
        DLConversionV2Command = $telemetryEventName
        MigrationStartTimeUTC = $telemetryStartTime
        MigrationEndTimeUTC = $telemetryEndTime
    }

    $telemetryEventMetrics = @{
        MigrationElapsedSeconds = $telemetryElapsedSeconds
    }

    if ($allowTelemetryCollection -eq $TRUE)
    {
        send-TelemetryEvent -traceModuleName $traceModuleName -eventName $telemetryEventName -eventMetrics $telemetryEventMetrics -eventProperties $telemetryEventProperties
    }

    if (($global:preCreateErrors.count -gt 0) -or ($global:testOffice365Errors.count -gt 0))
    {
        Start-ArchiveFiles -isSuccess:$FALSE -logFolderPath $logFolderPath -isHealthCheck:$TRUE
    }
    else 
    {
        Start-ArchiveFiles -isSuccess:$TRUE -logFolderPath $logFolderPath -isHealthCheck:$TRUE
    }
}