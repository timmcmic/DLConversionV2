Function update-hybridMailAddress
{
    <#
    .SYNOPSIS

    This function allows administrators to change the primary SMTP address of migrated lists that were migrated utilizing -enableHybridMailFlow 

    .DESCRIPTION

    This function allows administrators to change the primary SMTP address of migrated lists that were migrated utilizing -enableHybridMailFlow 

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

    .PARAMETER NEWGROUPSMTPADDRESS

    This is the new group SMTP address.

	.OUTPUTS

    Performs all of the health checking assoicated with a distribution list migration.

    .NOTES

    #>
    
    [cmdletbinding()]

    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$groupSMTPAddress,
        [Parameter(Mandatory = $true)]
        [string]$newGroupSMTPAddress,
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
        #Define other mandatory parameters
        [Parameter(Mandatory = $true)]
        [string]$logFolderPath,
        [Parameter(Mandatory =$FALSE)]
        [boolean]$allowTelemetryCollection=$TRUE,
        [Parameter(Mandatory =$FALSE)]
        [boolean]$allowDetailedTelemetryCollection=$TRUE
    )

    #Initialize telemetry collection.

    $appInsightAPIKey = "63d673af-33f4-401c-931e-f0b64a218d89"
    $traceModuleName = "DLConversion"

    if ($allowTelemetryCollection -eq $TRUE)
    {
        start-telemetryConfiguration -allowTelemetryCollection $allowTelemetryCollection -appInsightAPIKey $appInsightAPIKey -traceModuleName $traceModuleName
    }

    #Create telemetry values.

    $telemetryDLConversionV2Version = $NULL
    $telemetryExchangeOnlineVersion = $NULL
    $telemetryAzureADVersion = $NULL
    $telemetryMSGraphAuthentication = $NULL
    $telemetryMSGraphUsers = $NULL
    $telemetryMSGraphGroups = $NULL
    $telemetryActiveDirectoryVersion = $NULL
    $telemetryOSVersion = (Get-CimInstance Win32_OperatingSystem).version
    $telemetryStartTime = get-universalDateTime
    $telemetryEndTime = $NULL
    [double]$telemetryElapsedSeconds = 0
    $telemetryEventName = "Start-DistributionListMigration"
    $telemetryFunctionStartTime=$NULL
    $telemetryFunctionEndTime=$NULL
    [double]$telemetryNormalizeDN=0
    [double]$telemetryValidateCloudRecipients=0
    [double]$telemetryDependencyOnPrem=0
    [double]$telemetryCollectOffice365Dependency=0
    [double]$telemetryTimeToRemoveDL=0
    [double]$telemetryCreateOffice365DL=0
    [double]$telemetryCreateOffice365DLFirstPass=0
    [double]$telemetryReplaceOnPremDependency=0
    [double]$telemetryReplaceOffice365Dependency=0
    [boolean]$telemetryError=$FALSE


    $windowTitle = ("Start-DistributionListMigration "+$groupSMTPAddress)
    $host.ui.RawUI.WindowTitle = $windowTitle

    #Define XML files to contain backups.

    $xmlFiles = @{
        originalDLConfigurationADXML = @{ "Value" =  "originalDLConfigurationADXML" ; "Description" = "XML file that exports the original DL configuration"}
        originalDLConfigurationUpdatedXML = @{ "Value" =  "originalDLConfigurationUpdatedXML" ; "Description" = "XML file that exports the updated DL configuration"}
        office365DLConfigurationXML = @{ "Value" =  "office365DLConfigurationXML" ; "Description" = "XML file that exports the Office 365 DL configuration"}
        office365DLConfigurationUpdatedXML = @{ "Value" =  "office365DLConfigurationUpdatedXML" ; "Description" = "XML file that exports the Office 365 DL configuration post migration"}
        office365GroupConfigurationXML = @{ "Value" =  "office365GroupConfigurationXML" ; "Description" = "XML file that exports the Office 365 Group configuration post migration"}
    }

    $coreVariables = @{ 
        ADGlobalCatalogPowershellSessionName = @{ "Value" = "ADGlobalCatalog" ; "Description" = "Static AD Domain controller powershell session name" }
        exchangeOnlinePowershellModuleName = @{ "Value" = "ExchangeOnlineManagement" ; "Description" = "Static Exchange Online powershell module name" }
        activeDirectoryPowershellModuleName = @{ "Value" = "ActiveDirectory" ; "Description" = "Static active directory powershell module name" }
        msGraphAuthenticationPowershellModuleName = @{ "Value" = "Microsoft.Graph.Authentication" ; "Description" = "Static ms graph powershell name authentication" }
        msGraphUsersPowershellModuleName = @{ "Value" = "Microsoft.Graph.Users" ; "Description" = "Static ms graph powershell name users" }
        msGraphGroupsPowershellModuleName = @{ "Value" = "Microsoft.Graph.Groups" ; "Description" = "Static ms graph powershell name groups" }
        dlConversionPowershellModule = @{ "Value" = "DLConversionV2" ; "Description" = "Static dlConversionv2 powershell module name" }
        globalCatalogPort = @{ "Value" = ":3268" ; "Description" = "Global catalog port definition" }
        globalCatalogWithPort = @{ "Value" = ($globalCatalogServer+($corevariables.globalCatalogPort.value)) ; "Description" = "Global catalog server with port" }
    }

    #Create local variables for group configuration storage.

    $originalDLConfiguration=$NULL #This holds the on premises DL configuration for the group to be migrated.
    $originalDLConfigurationUpdated=$NULL #This holds the on premises DL configuration post the rename operations.
    $office365DLConfiguration = $NULL #This holds the office 365 DL configuration for the group to be migrated.
    $office365DLConfigurationUpdated = $NULL
    $office365GroupConfiguration = $NULL

    [array]$dlPropertySet = '*' #Clear all properties of a given object

    #Start the log file.

    new-LogFile -groupSMTPAddress $groupSMTPAddress.trim() -logFolderPath $logFolderPath

    out-logfile -string "********************************************************************************"
    out-logfile -string "NOCTICE"
    out-logfile -string "Telemetry collection is now enabled by default."
    out-logfile -string "For information regarding telemetry collection see https://timmcmic.wordpress.com/2022/11/14/4288/"
    out-logfile -string "Administrators may opt out of telemetry collection by using -allowTelemetryCollection value FALSE"
    out-logfile -string "Telemetry collection is appreciated as it allows further development and script enhacement."
    out-logfile -string "********************************************************************************"

    #Output all parameters bound or unbound and their associated values.

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "PARAMETERS"
    Out-LogFile -string "********************************************************************************"

    write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

    Out-LogFile -string "================================================================================"
    Out-LogFile -string "BEGIN START-DISTRIBUTIONLISTMIGRATION"
    Out-LogFile -string "================================================================================"

    out-logfile -string "Set error action preference to continue to allow write-error in out-logfile to service exception retrys"

    out-logfile -string ("Runtime start UTC: " + $telemetryStartTime.ToString())

    if ($errorActionPreference -ne "Continue")
    {
        out-logfile -string ("Current Error Action Preference: "+$errorActionPreference)
        $errorActionPreference = "Continue"
        out-logfile -string ("New Error Action Preference: "+$errorActionPreference)
    }
    else
    {
        out-logfile -string ("Current Error Action Preference is CONTINUE: "+$errorActionPreference)
    }

    out-logfile -string "Ensure that all strings specified have no leading or trailing spaces."

    #Perform cleanup of any strings so that no spaces existin trailing or leading.

    $groupSMTPAddress = remove-stringSpace -stringToFix $groupSMTPAddress
    $newGroupSMTPAddress = remove-stringSpace -stringToFix $newGroupSMTPAddress
    $globalCatalogServer = remove-stringSpace -stringToFix $globalCatalogServer
    $logFolderPath = remove-stringSpace -stringToFix $logFolderPath 

    if ($exchangeOnlineCertificateThumbPrint -ne "")
    {
        $exchangeOnlineCertificateThumbPrint=remove-stringSpace -stringToFix $exchangeOnlineCertificateThumbPrint
    }

    $exchangeOnlineEnvironmentName=remove-stringSpace -stringToFix $exchangeOnlineEnvironmentName

    if ($exchangeOnlineOrganizationName -ne "")
    {
        $exchangeOnlineOrganizationName=remove-stringSpace -stringToFix $exchangeOnlineOrganizationName
    }

    if ($exchangeOnlineAppID -ne "")
    {
        $exchangeOnlineAppID=remove-stringSpace -stringToFix $exchangeOnlineAppID
    }

    if ($exchangeOnlineCredential -ne $null)
    {
        Out-LogFile -string ("ExchangeOnlineUserName = "+ $exchangeOnlineCredential.UserName.toString())
    }

    #Validate that only one method of engaging exchange online was specified.

    Out-LogFile -string "Validating Exchange Online Credentials."

    start-parameterValidation -exchangeOnlineCredential $exchangeOnlineCredential -exchangeOnlineCertificateThumbprint $exchangeOnlineCertificateThumbprint -threadCount $totalThreadCount

    #Validating that all portions for exchange certificate auth are present.

    out-logfile -string "Validating parameters for Exchange Online Certificate Authentication"

    start-parametervalidation -exchangeOnlineCertificateThumbPrint $exchangeOnlineCertificateThumbprint -exchangeOnlineOrganizationName $exchangeOnlineOrganizationName -exchangeOnlineAppID $exchangeOnlineAppID

    Out-LogFile -string "Calling Test-PowerShellModule to validate the Exchange Module is installed."

    $telemetryExchangeOnlineVersion = Test-PowershellModule -powershellModuleName $corevariables.exchangeOnlinePowershellModuleName.value -powershellVersionTest:$TRUE

    Out-LogFile -string "Calling Test-PowerShellModule to validate the Active Directory is installed."

    $telemetryActiveDirectoryVersion = Test-PowershellModule -powershellModuleName $corevariables.activeDirectoryPowershellModuleName.value

    out-logfile -string "Calling Test-PowershellModule to validate the DL Conversion Module version installed."

    $telemetryDLConversionV2Version = Test-PowershellModule -powershellModuleName $corevariables.dlConversionPowershellModule.value -powershellVersionTest:$TRUE

    out-logfile -string "Calling Test-PowershellModule to validate the Microsoft Graph Authentication versions installed."

    $telemetryMSGraphAuthentication = test-powershellModule -powershellmodulename $corevariables.msgraphauthenticationpowershellmodulename.value -powershellVersionTest:$TRUE

    out-logfile -string "Calling Test-PowershellModule to validate the Microsoft Graph Users versions installed."

    $telemetryMSGraphUsers = test-powershellModule -powershellmodulename $corevariables.msgraphuserspowershellmodulename.value -powershellVersionTest:$TRUE

    out-logfile -string "Calling Test-PowershellModule to validate the Microsoft Graph Users versions installed."

    $telemetryMSGraphGroups = test-powershellModule -powershellmodulename $corevariables.msgraphgroupspowershellmodulename.value -powershellVersionTest:$TRUE

    Out-LogFile -string "Calling New-ExchangeOnlinePowershellSession to create session to office 365."

    if ($exchangeOnlineCertificateThumbPrint -eq "")
    {
        #User specified non-certifate authentication credentials.

            try {
                New-ExchangeOnlinePowershellSession -exchangeOnlineCredentials $exchangeOnlineCredential -exchangeOnlineEnvironmentName $exchangeOnlineEnvironmentName -debugLogPath $logFolderPath
            }
            catch {
                out-logfile -string "Unable to create the exchange online connection using credentials."
                out-logfile -string $_ -isError:$TRUE
            }
    }
    elseif ($exchangeOnlineCertificateThumbPrint -ne "")
    {
        #User specified thumbprint authentication.

            try {
                new-ExchangeOnlinePowershellSession -exchangeOnlineCertificateThumbPrint $exchangeOnlineCertificateThumbPrint -exchangeOnlineAppId $exchangeOnlineAppID -exchangeOnlineOrganizationName $exchangeOnlineOrganizationName -exchangeOnlineEnvironmentName $exchangeOnlineEnvironmentName -debugLogPath $logFolderPath
            }
            catch {
                out-logfile -string "Unable to create the exchange online connection using certificate."
                out-logfile -string $_ -isError:$TRUE
            }
    }

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "BEGIN GET ORIGINAL DL CONFIGURATION LOCAL AND CLOUD"
    Out-LogFile -string "********************************************************************************"

    #At this point we are ready to capture the original DL configuration.  We'll use the ad provider to gather this information.

    Out-LogFile -string "Getting the original DL Configuration"

    try
    {
        $originalDLConfiguration = Get-ADObjectConfiguration -groupSMTPAddress $groupSMTPAddress -globalCatalogServer $corevariables.globalCatalogWithPort.value -parameterSet $dlPropertySet -errorAction STOP -adCredential $activeDirectoryCredential
    }
    catch
    {
        out-logfile -string $_ -isError:$TRUE
    }

    Out-LogFile -string "Log original DL configuration."
    out-logFile -string $originalDLConfiguration

    Out-LogFile -string "Create an XML file backup of the on premises DL Configuration"

    Out-XMLFile -itemToExport $originalDLConfiguration -itemNameToExport $xmlFiles.originalDLConfigurationADXML.value

    Out-LogFile -string "Capture the original office 365 distribution list information."

    try 
    {
        $office365DLConfiguration=Get-O365DLConfiguration -groupSMTPAddress $groupSMTPAddress -isFirstPass:$TRUE -errorAction STOP
    }
    catch 
    {
        out-logFile -string $_ -isError:$TRUE
    }
    try 
    {
        $office365GroupConfiguration = get-o365GroupConfiguration -groupSMTPAddress $groupSMTPAddress -errorAction STOP
    }
    catch {
        out-logfile -string $_ -isError:$TRUE
    }

    Out-LogFile -string $office365DLConfiguration

    Out-LogFile -string "Create an XML file backup of the office 365 DL configuration."

    Out-XMLFile -itemToExport $office365DLConfiguration -itemNameToExport $xmlFiles.office365DLConfigurationXML.value

    out-logfile -string $office365GroupConfiguration

    out-logfile -string "Create an XML file backup of the office 365 group cofniguration."

    out-xmlfile -itemToExport $office365GroupConfiguration -itemNameToExport $xmlFiles.office365GroupConfigurationXML.value

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END GET ORIGINAL DL CONFIGURATION LOCAL AND CLOUD"
    Out-LogFile -string "********************************************************************************"
}