
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


Function Start-MultipleMachineDistributionListMigration
{
    <#
    .SYNOPSIS

    This is the wrapper function that provisions jobs for multiple distribution list migrations.

    .DESCRIPTION

    This is the wrapper function that provisions jobs for multiple distribution list migrations.

    .PARAMETER groupSMTPAddresses

    *REQUIRED*
    This is the array of distribution lists to be migrated 

    .PARAMETER globalCatalogServer

    *REQUIRED*
    A global catalog server in the domain where the group to be migrated resides.


    .PARAMETER activeDirectoryCredential

    *REQUIRED*
    This is the credential that will be utilized to perform operations against the global catalog server.
    If the group and all it's dependencies reside in a single domain - a domain administrator is acceptable.
    If the group and it's dependencies span multiple domains in a forest - enterprise administrator is required.
      
    .PARAMETER logFolder

    *REQUIRED*
    The location where logging for the migration should occur including all XML outputs for backups.

    .PARAMETER aadConnectServer

    *OPTIONAL*
    This is the AADConnect server that automated sycn attempts will be attempted.
    If specified with an AADConnect credential - delta syncs will be triggered automatically in attempts to service the move.
    This requires WINRM be enabled on the ADConnect server and may have additional WINRM dependencies / configuration.
    Name should be specified in fully qualified domain format.

    .PARAMETER aadConnectCredential

    *OPTIONAL*
    The credential specified to perform remote powershell / winrm sessions to the AADConnect server.

    .PARAMETER exchangeServer

    *REQUIRED IF HYBRID MAIL FLOW ENALBED*
    This is the on-premises Exchange server that is required for enabling hybrid mail flow if the option is specified.
    If using a load balanced namespace - basic authentication on powershell must be enabled on all powersell virtual directories.
    If using a single server (direct connection) then kerberos authentication may be utilized.
    
    .PARAMETER exchangeCredential

    *REQUIRED IF HYBRID MAIL FLOW ENABLED*
    This is the credential utilized to establish remote powershell sessions to Exchange on-premises.
    This acccount requires Exchange Organization Management rights in order to enable hybrid mail flow.

    .PARAMETER exchangeOnlineCredential

    *REQUIRED IF NO OTHER CREDENTIALS SPECIFIED*
    This is the credential utilized for Exchange Online connections.  
    The credential must be specified if certificate based authentication is not configured.
    The account requires global administration rights / exchange organization management rights.
    An exchange online credential cannot be combined with an exchangeOnlineCertificateThumbprint.

    .PARAMETER exchangeOnlineCertificateThumbprint

    *REQUIRED IF NO OTHER CREDENTIALS SPECIFIED*
    This is the certificate thumbprint that will be utilzied for certificate authentication to Exchange Online.
    This requires all the pre-requists be established and configured prior to access.
    A certificate thumbprint cannot be specified with exchange online credentials.

    .PARAMETER exchangeAuthenticationMethod

    *OPTIONAL*
    This allows the administrator to specify either Kerberos or Basic authentication for on premises Exchange Powershell.
    Basic is the assumed default and requires basic authentication be enabled on the powershell virtual directory of the specified exchange server.

    .PARAMETER retainOffice365Settings

    *OPTIONAL*
    It is possible over the course of migrations that cloud only resources could have dependencies on objects that still remain on premises.
    The administrator can choose to scan office 365 to capture any cloud only dependencies that may exist.
    The default is true.

    .PARAMETER doNoSyncOU

    *REQUIRED IF RETAIN GROUP FALSE*
    This is the administrator specified organizational unit that is NOT configured to sync in AD Connect.
    When the administrator specifies to NOT retain the group the group is moved to this OU to allow for deletion from Office 365.
    A doNOSyncOU must be specified if the administrator specifies to NOT retain the group.

    .PARAMETER retainOriginalGroup

    *OPTIONAL*
    Allows the administrator to retain the group - for example if the group also has on premises security dependencies.
    This triggers a mail disable of the group resulting in group deletion from Office 365.
    The name of the group is randomized with a character ! to ensure no conflict with hybird mail flow - if hybrid mail flow enabled.

    .PARAMETER enableHybridMailFlow

    *OPTIONAL*
    Allows the administrator to decide that they want mail flow from on premises to cloud to work for the migrated DL.
    This involves provisioning a mail contact and a dynamic distribution group.
    The dynamic distribution group is intentionally choosen to prevent soft matching of a group and an undo of the migration.
    This option requires on premises Exchange be specified and configured.

    .PARAMETER groupTypeOverride

    *OPTIONAL*
    This allows the administrator to override the group type created in the cloud from on premises.
    For example - if the group was provisioned on premises as security but does not require security rights in Office 365 - the administrator can override to DISTRIBUTION.
    Mandatory types -> SECURITY or DISTRIBUTION

	.OUTPUTS

    Logs all activities and backs up all original data to the log folder directory.
    Moves the distribution group from on premieses source of authority to office 365 source of authority.

    .EXAMPLE

    Start-DistributionListMigration

    #>
    [cmdletbinding()]

    Param
    (
        [Parameter(Mandatory = $true)]
        [array]$groupSMTPAddresses,
        #Local Active Director Domain Controller Parameters
        [Parameter(Mandatory = $true)]
        [string]$globalCatalogServer,
        [Parameter(Mandatory = $true)]
        [array]$activeDirectoryCredential,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Basic","Negotiate")]
        $activeDirectoryAuthenticationMethod="Negotiate",
        #Azure Active Directory Connect Parameters
        [Parameter(Mandatory = $false)]
        [string]$aadConnectServer=$NULL,
        [Parameter(Mandatory = $false)]
        [array]$aadConnectCredential=$NULL,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Basic","Kerberos")]
        $aadConnectAuthenticationMethod="Kerberos",
        #Exchange On-Premises Parameters
        [Parameter(Mandatory = $false)]
        [string]$exchangeServer=$NULL,
        [Parameter(Mandatory = $false)]
        [array]$exchangeCredential=$NULL,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Basic","Kerberos")]
        [string]$exchangeAuthenticationMethod="Basic",
        #Exchange Online Parameters
        [Parameter(Mandatory = $false)]
        [array]$exchangeOnlineCredential=$NULL,
        [Parameter(Mandatory = $false)]
        [string]$exchangeOnlineCertificateThumbPrint="",
        [Parameter(Mandatory = $false)]
        [string]$exchangeOnlineOrganizationName="",
        [Parameter(Mandatory = $false)]
        [ValidateSet("O365Default","O365GermanyCloud","O365China","O365USGovGCCHigh","O365USGovDoD")]
        [string]$exchangeOnlineEnvironmentName="O365Default",
        [Parameter(Mandatory = $false)]
        [string]$exchangeOnlineAppID="",
        #Define Microsoft Graph Parameters
        [Parameter(Mandatory = $false)]
        [ValidateSet("China","Global","USGov","USGovDod")]
        [string]$msGraphEnvironmentName="Global",
        [Parameter(Mandatory=$true)]
        [string]$msGraphTenantID="",
        [Parameter(Mandatory=$true)]
        [string]$msGraphCertificateThumbprint="",
        [Parameter(Mandatory=$true)]
        [string]$msGraphApplicationID="",
        #Define other mandatory parameters
        [Parameter(Mandatory = $true)]
        [string]$logFolderPath,
        #Defining optional parameters for retention and upgrade
        [Parameter(Mandatory = $false)]
        [string]$dnNoSyncOU = "NotSet",
        [Parameter(Mandatory = $false)]
        [boolean]$retainOriginalGroup = $TRUE,
        [Parameter(Mandatory = $false)]
        [boolean]$enableHybridMailflow = $FALSE,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Security","Distribution","None")]
        [string]$groupTypeOverride="None",
        [Parameter(Mandatory = $false)]
        [boolean]$triggerUpgradeToOffice365Group=$FALSE,
        [Parameter(Mandatory=$false)]
        [boolean]$overrideCentralizedMailTransportEnabled=$FALSE,
        [Parameter(Mandatory=$false)]
        [boolean]$allowNonSyncedGroup=$FALSE,
        [Parameter(Mandatory=$false)]
        [string]$customRoutingDomain="",
        #Definte parameters for pre-collected permissions
        [Parameter(Mandatory = $false)]
        [boolean]$useCollectedFullMailboxAccessOnPrem=$FALSE,
        [Parameter(Mandatory = $false)]
        [boolean]$useCollectedFullMailboxAccessOffice365=$FALSE,
        [Parameter(Mandatory = $false)]
        [boolean]$useCollectedSendAsOnPrem=$FALSE,
        [Parameter(Mandatory = $false)]
        [boolean]$useCollectedFolderPermissionsOnPrem=$FALSE,
        [Parameter(Mandatory = $false)]
        [boolean]$useCollectedFolderPermissionsOffice365=$FALSE,
        #Define paramters for naming conventions.
        [Parameter(Mandatory = $false)]
        [string]$dlNamePrefix="",
        [Parameter(Mandatory = $false)]
        [string]$dlNameSuffix="",
        #Parameters to support multi-threading
        [Parameter(Mandatory = $TRUE)]
        [array]$serverNames = $NULL,
        [Parameter(Mandatory = $FALSE)]
        [string]$remoteDriveLetter=$NULL,
        [boolean]$allowTelemetryCollection=$TRUE,
        [Parameter(Mandatory =$FALSE)]
        [boolean]$allowDetailedTelemetryCollection=$TRUE
    )

    $global:blogURL = "https://timmcmic.wordpress.com"

    #Establish required MS Graph Scopes

    $msGraphScopesRequired = @("User.Read.All", "Group.Read.All")

    #Initialize telemetry collection.

    $appInsightAPIKey = "63d673af-33f4-401c-931e-f0b64a218d89"
    $traceModuleName = "DLConversion"

    $telemetryStartTime = get-universalDateTime
    $telemetryEndTime = $NULL
    [double]$telemetryElapsedSeconds = 0
    $telemetryEventName = "Start-MultipleMachineDistributionListMigration"
    [double]$telemetryGroupCount = $groupSMTPAddresses.Count
    [double]$telemetryMachineCount = $servernames.count
    
    if ($allowTelemetryCollection -eq $TRUE)
    {
        start-telemetryConfiguration -allowTelemetryCollection $allowTelemetryCollection -appInsightAPIKey $appInsightAPIKey -traceModuleName $traceModuleName
    }

    $windowTitle = "Start-MultipleMachineDistributionListMigration Controller"
    $host.ui.RawUI.WindowTitle = $windowTitle


    #Define global variables.

    $global:logFile=$NULL #This is the global variable for the calculated log file name
    [string]$global:staticFolderName="\Controller\"
    [string]$masterFileName="Controller"

    #Define parameters that are variables here (not available as parameters in this function.)

    [boolean]$retainSendAsOnPrem=$FALSE
    [boolean]$retainFullMailboxAccessOnPrem=$FALSE
    [boolean]$retainMailboxFolderPermsOnPrem=$FALSE
    [boolean]$retainFullMailboxAccessOffice365=$FALSE
    [boolean]$retainMailboxFolderPermsOffice365=$FALSE
    [boolean]$retainOffice365Settings=$true
    [boolean]$retainSendAsOffice365=$FALSE

    $jobOutput=$NULL

    [int]$totalAddressCount = 0
    [int]$maxThreadCount = 5

    [string]$dlConversionV2ModuleName = "DLConversionV2"

    [string]$localHostName=$NULL

    #If certificate authentication is being utilized - there is no reason to check for a server count for credential.

    [boolean]$isExchangeCertAuth = $FALSE

    new-LogFile -groupSMTPAddress $masterFileName -logFolderPath $logFolderPath

    out-logfile -string "********************************************************************************"
    out-logfile -string "NOTICE"
    out-logfile -string "Telemetry collection is now enabled by default."
    out-logfile -string "For information regarding telemetry collection see https://timmcmic.wordpress.com/2022/11/14/4288/"
    out-logfile -string "Administrators may opt out of telemetry collection by using -allowTelemetryCollection value FALSE"
    out-logfile -string "Telemetry collection is appreciated as it allows further development and script enhancement."
    out-logfile -string "********************************************************************************"

    #Output all parameters bound or unbound and their associated values.

    write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

    Out-LogFile -string "================================================================================"
    Out-LogFile -string "BEGIN START-MULTIPLEMACHINEDISTRIBUTIONLISTMIGRATION"
    Out-LogFile -string "================================================================================"

    #Add immediate check to ensure controller is running as administrator.

    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    [boolean]$adminTest = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if ($adminTest -eq $FALSE)
    {
        out-logfile -string "Please run powershell as administrator." -isError:$TRUE
    }

    #Output parameters to the log file for recording.
    #For parameters that are optional if statements determine if they are populated for recording.

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "PARAMETERS"
    Out-LogFile -string "********************************************************************************"
    out-logfile -string "SMTP Addresses:"
    foreach ($smtpAddress in $groupSMTPAddresses)
    {
        Out-LogFile -string $smtpAddress
    }
    out-logfile -string "Servers to Execute On:"
    foreach ($server in $serverNames)
    {
        Out-LogFile -string $server
    }
    Out-LogFile -string ("GlobalCatalogServer = "+$globalCatalogServer)
    Out-LogFile -string ("LogFolderPath = "+$logFolderPath)

    if ($aadConnectServer -ne "")
    {
        Out-LogFile -string ("AADConnectServer = "+$aadConnectServer)
    }

    if ($aadConnectCredential -ne $null)
    {
        Out-LogFile -string ("AADConnectUserName = "+$aadConnectCredential.UserName.tostring())
    }

    if ($exchangeServer -ne "")
    {
        Out-LogFile -string ("ExchangeServer = "+$exchangeServer)
    }

    if ($exchangecredential -ne $null)
    {
        Out-LogFile -string ("ExchangeUserName = "+$exchangeCredential.UserName.toString())
    }

    if ($exchangeOnlineCredential -ne $null)
    {
        Out-LogFile -string ("ExchangeOnlineUserName = "+ $exchangeOnlineCredential.UserName.toString())
    }

    if ($exchangeOnlineCertificateThumbPrint -ne "")
    {
        Out-LogFile -string ("ExchangeOnlineCertificateThumbprint = "+$exchangeOnlineCertificateThumbPrint)
    }

    Out-LogFile -string ("ExchangeAuthenticationMethod = "+$exchangeAuthenticationMethod)
    out-logfile -string ("Retain Office 365 Settings = "+$retainOffice365Settings)
    out-logfile -string ("OU that does not sync to Office 365 = "+$dnNoSyncOU)
    out-logfile -string ("Will the original group be retained as part of migration = "+$retainOriginalGroup)
    out-logfile -string ("Enable hybrid mail flow = "+$enableHybridMailflow)
    out-logfile -string ("Group type override = "+$groupTypeOverride)
    out-logfile -string ("Trigger upgrade to Office 365 Group = "+$triggerUpgradeToOffice365Group)
    out-logfile -string ("Retain full mailbox access on premises = "+$retainFullMailboxAccessOnPrem)
    out-logfile -string ("Retain send as rights on premise = "+$retainSendAsOnPrem)
    out-logfile -string ("Retain mailbox folder permissions on premises = "+$retainMailboxFolderPermsOnPrem)
    out-logfile -string ("Retain full mailbox access Office 365 = "+$retainFullMailboxAccessOffice365)
    out-logfile -string ("Retain send as rights Office 365 = "+$retainSendAsOffice365)
    out-logfile -string ("Retain mailbox folder permissions Office 365 = "+$retainMailboxFolderPermsOffice365)
    out-logfile -string ("Use collected full mailbox permissions on premises = "+$useCollectedFullMailboxAccessOnPrem)
    out-logfile -string ("Use collected full mailbox permissions Office 365 ="+$useCollectedFullMailboxAccessOffice365)
    out-logfile -string ("Use collected send as on premises = "+$useCollectedSendAsOnPrem)
    out-logfile -string ("Use collected mailbox folder permissions on premises = "+$useCollectedFolderPermissionsOnPrem)
    out-logfile -string ("Use collected mailbox folder permissions Office 365 = "+$useCollectedFolderPermissionsOffice365)
    Out-LogFile -string "********************************************************************************"

    #Perform paramter validation manually.

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "ENTERING PARAMETER VALIDATION"
    Out-LogFile -string "********************************************************************************"

    #Test to ensure that if any of the aadConnect parameters are passed - they are passed together.

    out-logfile -string "Validating that the remote network drive passed is a single valid drive letter"

    start-parameterValidation -remoteDriveLetter $remoteDriveLetter
    
    Out-LogFile -string "Validating that both AADConnectServer and AADConnectCredential are specified"

    start-parameterValidation -aadConnectServer $aadConnectServer -aadConnectCredential $aadConnectCredential

    #Validate that both the exchange credential and exchange server are presented together.

    Out-LogFile -string "Validating that both ExchangeServer and ExchangeCredential are specified."

    $useOnPremisesExchange = start-parameterValidation -exchangeServer $exchangeServer -exchangeCredential $exchangeCredential -serverNames $serverNames

    #Validate that only one method of engaging exchange online was specified.

    Out-LogFile -string "Validating Exchange Online Credentials."

    start-parameterValidation -exchangeOnlineCredential $exchangeOnlineCredential -exchangeOnlineCertificateThumbprint $exchangeOnlineCertificateThumbprint -serverNames $serverNames -threadCount $totalThreadCount

    #Validating that all portions for exchange certificate auth are present.

    out-logfile -string "Validating parameters for Exchange Online Certificate Authentication"

    $isExchangeCertAuth=start-parametervalidation -exchangeOnlineCertificateThumbPrint $exchangeOnlineCertificateThumbprint -exchangeOnlineOrganizationName $exchangeOnlineOrganizationName -exchangeOnlineAppID $exchangeOnlineAppID

    out-logfile -string "Validation all components available for MSGraph Cert Auth"

    start-parameterValidation -msGraphCertificateThumbPrint $msGraphCertificateThumbprint -msGraphTenantID $msGraphTenantID -msGraphApplicationID $msGraphApplicationID

    #Validate that an OU was specified <if> retain group is not set to true.

    Out-LogFile -string "Validating that if retain original group is false a non-sync OU is specified."

    start-parameterValidation -retainOriginalGroup $retainOriginalGroup -doNoSyncOU $doNoSyncOU

    out-logfile -string "Validating that on premises exchange is enabled to support hybrid mail flow enablement."

    start-parametervalidation -useOnPremisesExchange $useOnPremisesExchange -enableHybridMailFlow $enableHybridMailFlow

    out-logfile -string "Validating the active directory credential array contains all PSCredentials."

    start-parameterValidation -activeDirectoryCredential $activeDirectoryCredential -serverNames $serverNames

    out-logfile -string "Validating that server names provided is not greater than max supported."

    start-parametervalidation -serverNames $serverNames -maxThreadCount $maxThreadCount

    if ($useCollectedFullMailboxAccessOnPrem -eq $TRUE)
    {
        $retainFullMailboxAccessOnPrem=$TRUE
    }

    if ($useCollectedFullMailboxAccessOffice365 -eq $TRUE)
    {
        $retainFullMailboxAccessOffice365=$TRUE
    }

    if ($useCollectedSendAsOnPrem -eq $TRUE)
    {
        $retainSendAsOnPrem=$TRUE
    }

    if ($useCollectedFolderPermissionsOnPrem -eq $TRUE)
    {
        $retainMailboxFolderPermsOnPrem=$TRUE
    }
    
    if ($useCollectedFolderPermissionsOffice365 -eq $TRUE)
    {
        $retainMailboxFolderPermsOffice365=$TRUE
    }

    Out-LogFile -string "END PARAMETER VALIDATION"
    Out-LogFile -string "********************************************************************************"

    Out-LogFile -string "The following SMTP addresses have been requested for migration."

    #Ensure that no addresses are specified more than once.

    out-logfile -string "Unique list of SMTP addresses included in the array."

    $groupSMTPAddresses = $groupSMTPAddresses | Select-Object -Unique

    #Setting the total group count after adjusting for unique SMTP Addresses.

    $totalAddressCount = $groupSMTPAddresses.count

    foreach ($groupSMTPAddress in $groupSMTPAddresses)
    {
        out-logfile -string $GroupSMTPAddress
    }

    #At this time we need to record the FQDN of the local host.  This is used later to determine if jobs are local.

    $localHostName = ([System.Net.Dns]::GetHostByName(($env:computerName))).hostname

    out-logfile -string ("The local host name is = "+$localHostName)

    foreach ($server in $serverNames)
    {
        out-logfile -string ("Server Specified: "+$server)
    }

    #Servers must be specified in FQDN format.  Although no specific way to test - an easy method is to break the string at . and count.
    #If the count is not > 3 machine <dot> domain <dot> com then reasonably this is not an FQDN.

    foreach ($server in $servernames)
    {
        $forTest = $server.split(".")

        if ($forTest.count -lt 3)
        {
            out-logfile -string ("The servername specified does not appear in FQDN format - "+$server)
            out-logfile -string ("The servername must be in format machine.domain.com etc to proceed.") -isError:$TRUE
        }
        else 
        {
            out-logfile -string ("The servername appears in FQDN format - proceed - "+$server)    
        }
    }

    #The goal of this function is to provision remote jobs.
    #Test to ensure each machine is configured for remote management.

    foreach ($server in $serverNames)
    {
        if ($server -ne $localHostName)
        {
            try{
                out-logfile -string ("Testing server: "+$server)
                #$testResults = test-wsman -computerName $server -authentication Default -credential $activeDirectoryCredential[0] -errorAction STOP
                #Removed the credential - if the user has not logged in and has no user profile the credential fails.
                $testResults = test-wsman -computerName $server -errorAction STOP
            }
            catch{
                out-logfile -string "Unable to validate remote management enabled on host."
                out-logfile -string $server
                out-logfile -string $_ -isError:$TRUE
            }
        }
        else 
        {
            out-logfile -string ("Skipping testing of host running controller: "+$server)    
        }
    }

    #For each machine in the server name array - we need to validate that the DLConversionV2 commands are available.

    [array]$invalidServers=@()

    foreach ($server in $serverNames)
    {
        [array]$commands = @()

        out-logfile -string ("Testing server for presence of DLConversion V2 "+$server)

        if ($server -eq $localHostName)
        {
            out-logfile -string "Skipping test - this is the machine running the controller."
        }
        else 
        {
            try
            {
                $ScriptBlock = [scriptblock]::Create("Get-installedModule '$dlConversionV2ModuleName'")

                out-logfile -string $scriptBlock

                $commands = invoke-command -scriptBlock $scriptBlock -computerName $server -credential $activeDirectoryCredential[0] -errorAction Continue
                
                if ($commands.name -ne $dlConversionV2ModuleName)
                {
                    out-logfile -string ("Server "+$server+" does not have the DLConversionV2 module installed.")
                    $invalidServers+=$server
                }
                else {
                    out-logfile -string ("Server "+$server+" is ready.")
                    out-logfile -string $commands
                }
            }    
            catch{
                out-logfile -string "Unable to obtain DLConversionV2 commands." 
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }

    if ($invalidServers.count -gt 0)
    {
        foreach ($server in $invalidServers)
        {
            out-logfile -string ("Server does not have DLConversionV2 installed: "+$server)
        }
        out-logfile -string "Correct servers with missing modules." -isError:$TRUE
    }

    #At this point we have validated that each server has WinRM enabled, each server is accessible, and each server has the module installed.

    #The goal on the controller is to store all of the log files - centralized.
    #This requires a network share.
    #The share should be pre-created.

    $account = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

    if (get-SMBShare -name $dlConversionV2ModuleName -errorAction SilentlyContinue)
    {
        out-logfile -string "The DLConversionV2 share was found."

        if ((get-smbShare -name $dlConversionV2ModuleName).path -eq $logFolderPath)
        {
            out-logfile -string "The DLConversionV2 share was found and the path matches the logging path."
        }
        else 
        {
            out-logfile -string "The DLConversionV2 share was found but the path does not match the logging path."
            out-logfile -string ((get-smbShare -name $dlConversionV2ModuleName).path) -isError:$TRUE
        }
    }
    else 
    {
        try{
            out-logfile -string "Creating DLConversionV2 to share to support centralized logging."

            new-SMBShare -name $dlConversionV2ModuleName -path $logFolderPath -fullAccess $account -errorAction STOP
        }
        catch{
            out-logfile -string "Unable to create the DLConversionV2 share."
            out-logfile $_ -isError:$TRUE
        }
    }

    #Ensure the ACL is set on the folder for the active directory admin account.
    #Do not assume that just becuase the share existed the folder permissions are ok.

    try{

        foreach ($credential in $activeDirectoryCredential)
        {
            out-logfile -string "Setting the ACL on the folder for full control to the active directory credential and enabling inheritance."

            $acl = Get-Acl $logFolderPath

            out-logfile -string $acl

            $permission = $credential.userName, "FullControl", 'ContainerInherit, ObjectInherit', 'None', 'Allow' 

            out-logfile -string $permission

            $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule -argumentList $permission

            out-logfile -string $AccessRule

            $acl.SetAccessRule($AccessRule)

            out-logfile -string $acl

            $acl | Set-Acl $logFolderPath -errorAction STOP -confirm:$FALSE
        }
        foreach ($server in $servernames)
        {
            out-logfile -string "Setting the ACL on the folder for full control for machine accounts to the active directory credential and enabling inheritance."

            $forServerName = $server.split(".")
            $forSamAccountName = get-adComputer -identity $forServerName[0] -server $globalCatalogServer -Credential $activeDirectoryCredential[0]

            $acl = Get-Acl $logFolderPath

            out-logfile -string $acl

            $permission = $forSamAccountName.SAMAccountName, "FullControl", 'ContainerInherit, ObjectInherit', 'None', 'Allow' 

            out-logfile -string $permission

            $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule -argumentList $permission

            out-logfile -string $AccessRule

            $acl.SetAccessRule($AccessRule)

            out-logfile -string $acl

            $acl | Set-Acl $logFolderPath -errorAction STOP -confirm:$FALSE
        }
    }
    Catch{
        out-logfile -string "Unable to set the ACL on the folder for the active directory credential."

        out-logfile -string $_ -isError:$TRUE
    }

    #Do not assume the share was established with permissions for the active directory credentials.

    try{

        foreach ($credential in $activeDirectoryCredential)
        {
            Grant-SmbShareAccess -Name $dlConversionV2ModuleName -AccountName $credential.UserName -AccessRight Full -errorACTION STOP -force

            $shareAccess = get-SMBShareAccess -name $dlConversionV2ModuleName

            out-logfile -string $shareAccess
        }

        foreach ($server in $serverNames)
        {
            $forServerName = $server.split(".")
            $forSamAccountName = get-adComputer -identity $forServerName[0] -server $globalCatalogServer -Credential $activeDirectoryCredential[0]

            Grant-SmbShareAccess -Name $dlConversionV2ModuleName -AccountName $forSAMAccountName.SAMAccountName -AccessRight Full -errorACTION STOP -force

            $shareAccess = get-SMBShareAccess -name $dlConversionV2ModuleName

            out-logfile -string $shareAccess
        }
    }
    catch{
        out-logfile -string "Error granting active directory administrator share access."
        out-logfile -string $_ -isError:$TRUE
    }

    #The share path has been validated.  The custom logging directories need to be built.

    out-logfile -string "Build each servers network logging directory."

    [array]$networkLoggingDirectory=@()

    foreach ($server in $servernames)
    {
        $forServerName=$server.split(".")
        $forPath = "\\"+$localHostName+"\"
        out-logfile -string $forPath
        $forPath=$forPath+$dlConversionV2ModuleName+"\"
        $forPath = $forPath+$forServerName[0]
        out-logfile -string $forPath
        $networkLoggingDirectory+=$forPath
    }

    #At this time test for the paths and create them if not already there.

    foreach ($directory in $networkLoggingDirectory)
    {
        out-logFile -string "Testing to see if network path already exists."
        out-logfile -string $directory

        [boolean]$forTest = test-path -path $directory

        out-logfile -string ("Test Path Results: "+$forTest)

        if ($forTest -eq $FALSE)
        {
            out-logfile -string "Directory does not exist -> create."

            $loopCounter = 0
            $stopLoop = $FALSE

            do {
                try{
                    New-Item -ItemType Directory -Force -Path $directory -errorAction STOP
                    $stopLoop = $TRUE
                }
                catch{
                    if ($loopCounter -gt 4)
                    {
                        out-logfile -string "Unable to create the network directory."
                        out-logfile -string $_ -isError:$TRUE
                    }
                    else 
                    {
                        out-logfile -string "Initial issue creating folder - sleep -> retry."
                        start-sleepProgress -sleepString "Initial issue creating folder - sleep -> retry." -sleepSeconds 5
                        $loopCounter = $loopCounter+1
                    }
                } 
            } until ($stopLoop -eq $TRUE)

            out-logfile -string "Testing creation of path..."

            $forTest = test-path -path $directory

            out-logfile -string ("Test Path Results: "+$forTest)
        }
        else 
        {
            out-logfile -string "Network directory exists."    
        }
    }

    foreach ($directory in $networkLoggingDirectory)
    {
        out-logFile -string "Testing to see if network path already exists."
        out-logfile -string $directory

        $forDirectory = $directory+"\AuditData"

        out-logfile -string $forDirectory

        [boolean]$forTest = test-path -path $forDirectory

        out-logfile -string ("Test Path Results: "+$forTest)

        if ($forTest -eq $FALSE)
        {
            out-logfile -string "Directory does not exist -> create."

            try{
                New-Item -ItemType Directory -Force -Path $forDirectory -errorAction STOP
            }
            catch{
                out-logfile -string "Unable to create the network directory."
                out-logfile -string $_ -isError:$TRUE
            }

            out-logfile -string "Testing creation of path..."

            $forTest = test-path -path $forDirectory

            out-logfile -string ("Test Path Results: "+$forTest)
        }
        else 
        {
            out-logfile -string "Network directory exists."    
        }
    }

    #At this time we have validated the network directories exist.
    #We have also pre-staged the audit data files.
    #We will test now to see if the audit data folder exists in the directory for the controller specified.
    #If so the items will be copied to the folder in the network share.
    #This is necessary since the jobs provisioned utilze folders per machine and not the centralized folder.

    $forDirectory = $logFolderPath+"\AuditData"
    [boolean]$forTest=test-path -path $forDirectory

    out-logfile -string "Testing for local audit data directory."
    out-logfile -string ("Local Audit Data Directory: "+$forDirectory)
    out-logfile -string ("Is directory present: "+$forTest)

    if ($forTest -eq $TRUE)
    {
        out-logfile -string "Local audit data directory is present."

        foreach ($directory in $networkLoggingDirectory)
        {
            $forDirectory=$logFolderPath+"\AuditData\*"
            $forNetworkDirectory=$directory+"\AuditData\"

            out-logfile -string ("Source Directory: "+$forDirectory)
            out-logfile -string ("Target Directory: "+$forNetworkDirectory)

            copy-item $forDirectory -destination $forNetworkDirectory -force
        }
    }

    #The controller will split the addresses into groups for each machine to process.
    #To do this we simply take the total number of addresses divided by the number of controllers.
    #The we create an array of address arrays.

    out-logfile -string ("The number of addresses to process is = "+$totalAddressCount)

    [int]$maxAddressesPerMachines = ($totalAddressCount / $servernames.count)

    out-logfile -string ("The number of addresses per machine = "+$maxAddressesPerMachines)

    [array]$groupSMTPAddressArray=@()
    [array]$doArray=@()
    [int]$forCounter = 0

    #On the off chance someone tries do do a multi machine migration where the group count is less than the server count.
    #End the for loop when we've reached the count of groups.

    if ($totalAddressCount -lt $serverNames.count )
    {
        $forEnd = $totalAddressCount
    }
    else 
    {
        $forEnd = $serverNames.count 
    }

    #Ok so the below code is hokie.  Here is what we're doing.
    #It is very possible that certificate authentication is used for either exchange online or azure ad.
    #If cert auth is utilized then there are no arrays of user names.
    #In the invoke code below I go ahead and invoke the start-multiple with a full switch set.
    #If the credential array is null - then you get a null index array error.  
    #This creates a bogus username and password and stuffs the array.
    #If bogus user name is found in the other ps1 - it sets it back to null.

    if ($isExchangeCertAuth -eq $TRUE)
    {
        # Define clear text string for username and password
        [string]$bogusUserName = 'BogusUserName'
        [string]$bogusUserPassword = 'BogusPassword'

#       Convert to SecureString
        [securestring]$bogusSecStringPassword = ConvertTo-SecureString $bogusUserPassword -AsPlainText -Force

        [pscredential]$bogusCredObject = New-Object System.Management.Automation.PSCredential ($bogusUserName, $bogusSecStringPassword)

        out-logfile -string "Creating empty Exchange credentials array."

        $exchangeOnlineCredential += $bogusCredObject
        $exchangeOnlineCredential += $bogusCredObject
        $exchangeOnlineCredential += $bogusCredObject
        $exchangeOnlineCredential += $bogusCredObject
        $exchangeOnlineCredential += $bogusCredObject
    }

    for ($serverCounter = 0 ; $serverCounter -lt $forEnd ; $serverCounter++)
    {
        if ($serverCounter -eq ($forEnd - 1))
        {
            #This is the last array to be built - take all addresses that are left.

            for ($maxCounter = $forCounter ; $maxCounter -lt $totalAddressCount ; $maxCounter++)
            {
                out-logfile -string ("For Counter = "+$maxCounter)
                out-logfile -string ("SMTP Address Processed = "+$groupSMTPAddresses[$maxCounter])
                $doArray+=$groupSMTPAddresses[$maxCounter]
            }
        }
        else 
        {
            #This is not the last array - build the array up to the max per run.

            for ($maxCounter = 0 ; $maxCounter -lt $maxAddressesPerMachines ; $maxCounter++)
            {
                if ($forCounter -lt $totalAddressCount)
                {
                    out-logfile -string ("For Counter = "+$forCounter)
                    out-logfile -string ("SMTP Address Processed = "+$groupSMTPAddresses[$forCounter])
                    $doArray+=$groupSMTPAddresses[$forCounter]
    
                    $forCounter = $forCounter + 1
                }
                else 
                {
                    out-logfile -string ("For Counter = "+$forCounter)
                    $maxCounter = $maxAddressesPerMachines
                }
            }
        }
        
        out-logfile -string "Processed server and array batch."

        foreach ($address in $doArray)
        {
            out-logfile -string ("Address in Do Array = "+$address)
        }

        $groupSMTPAddressArray+=,(@($doArray))
        $doArray=@()

        foreach ($address in $groupSMTPAddressArray[$serverCounter])
        {
            out-logfile -string ("Address in group array: "+$address)
        }
    }

    out-logfile -string "Address array summary for logging..."

    foreach ($addressSet in $groupSMTPAddressArray)
    {
        out-logfile -string "Writing out address set:"

        foreach ($address in $addressSet)
        {
            out-logfile -string $address
        }
    }

    out-logfile -string ("Number of array members = "+$groupSMTPAddressArray.count)

    #At this time we have a multi-dimensional array of addresses, log file strings, and are ready to invoke jobs.
    #If the controller is specified as a machine - the job will be provisioend locally.
    #Otherwise invoke all the jobs.
    #Since the machines are capped at 5, and all of the other arrays are numer based - we'll use a numbers for loop instead of object loop.

    for ($serverCounter = 0 ; $serverCounter -lt $serverNames.count ; $serverCounter++)
    {
        if ($servernames[$serverCounter] -eq $localHostName)
        {
            out-logfile -string "THe controller is also a migration host.  Use local job."

            Start-Job -name "ControllerJob" -InitializationScript {Import-Module DLConversionV2} -ScriptBlock { start-MultipleDistributionListMigration -groupSMTPAddresses $args[0] -globalCatalogServer $args[1] -activeDirectoryCredential $args[2] -logFolderPath $args[3] -aadConnectServer $args[4] -aadConnectCredential $args[5] -exchangeServer $args[6] -exchangeCredential $args[7] -exchangeOnlineCredential $args[8] -exchangeOnlineCertificateThumbPrint $args[9] -exchangeOnlineOrganizationName $args[10] -exchangeOnlineEnvironmentName $args[11] -exchangeOnlineAppID $args[12] -exchangeAuthenticationMethod $args[13] -dnNoSyncOU $args[15] -retainOriginalGroup $args[16] -enableHybridMailflow $args[17] -groupTypeOverride $args[18] -triggerUpgradeToOffice365Group $args[19] -useCollectedFullMailboxAccessOnPrem $args[26] -useCollectedFullMailboxAccessOffice365 $args[27] -useCollectedSendAsOnPrem $args[28] -useCollectedFolderPermissionsOnPrem $args[29] -useCollectedFolderPermissionsOffice365 $args[30] -isMultiMachine $args[31] -remoteDriveLetter $args[32] -overrideCentralizedMailTransportEnabled $args[33] -msGraphEnvironmentName $args[34] -msGraphTenantID $args[35] -msGraphCertificateThumbprint $args[36] -msGraphApplicationID $args[37] -allowTelemetryCollection $args[39] -allowDetailedTelemetryCollection $args[40] -activeDirectoryAuthenticationMethod $args[41] -aadConnectAuthenticationMethod $args[42] -customRoutingDomain $args[43] -dlNamePrefix $args[44] -dlNameSuffix $args[45]} -ArgumentList $groupSMTPAddressArray[$serverCounter],$globalCatalogServer,$activeDirectoryCredential[$serverCounter],$networkLoggingDirectory[$serverCounter],$aadConnectServer,$aadConnectCredential[$serverCounter],$exchangeServer,$exchangecredential[$serverCounter],$exchangeOnlineCredential[$serverCounter],$exchangeOnlineCertificateThumbPrint,$exchangeOnlineOrganizationName,$exchangeOnlineEnvironmentName,$exchangeOnlineAppID,$exchangeAuthenticationMethod,$retainOffice365Settings,$dnNoSyncOU,$retainOriginalGroup,$enableHybridMailflow,$groupTypeOverride,$triggerUpgradeToOffice365Group,$retainFullMailboxAccessOnPrem,$retainSendAsOnPrem,$retainMailboxFolderPermsOnPrem,$retainFullMailboxAccessOffice365,$retainSendAsOffice365,$retainMailboxFolderPermsOffice365,$useCollectedFolderPermissionsOnPrem,$useCollectedFullMailboxAccessOffice365,$useCollectedSendAsOnPrem,$useCollectedFolderPermissionsOnPrem,$useCollectedFolderPermissionsOffice365,$TRUE,$remoteDriveLetter,$overrideCentralizedMailTransportEnabled,$msGraphEnvironmentName,$msGraphTenantID,$msGraphCertificateThumbprint,$msGraphApplicationID,$NULL,$allowTelemetryCollection,$allowDetailedTelemetryCollection,$activeDirectoryAuthenticationMethod,$aadConnectAuthenticationMethod,$customRoutingDomain,$dlNamePrefix,$dlNameSuffix
        }
        else 
        {
            out-logfile -string "The job is not the migration host.  Use remote job."  
            
            Invoke-Command -computerName $servernames[$serverCounter] -ScriptBlock { start-MultipleDistributionListMigration -groupSMTPAddresses $args[0] -globalCatalogServer $args[1] -activeDirectoryCredential $args[2] -logFolderPath $args[3] -aadConnectServer $args[4] -aadConnectCredential $args[5] -exchangeServer $args[6] -exchangeCredential $args[7] -exchangeOnlineCredential $args[8] -exchangeOnlineCertificateThumbPrint $args[9] -exchangeOnlineOrganizationName $args[10] -exchangeOnlineEnvironmentName $args[11] -exchangeOnlineAppID $args[12] -exchangeAuthenticationMethod $args[13] -dnNoSyncOU $args[15] -retainOriginalGroup $args[16] -enableHybridMailflow $args[17] -groupTypeOverride $args[18] -triggerUpgradeToOffice365Group $args[19] -useCollectedFullMailboxAccessOnPrem $args[26] -useCollectedFullMailboxAccessOffice365 $args[27] -useCollectedSendAsOnPrem $args[28] -useCollectedFolderPermissionsOnPrem $args[29] -useCollectedFolderPermissionsOffice365 $args[30] -isMultiMachine $args[31] -remoteDriveLetter $args[32] -overrideCentralizedMailTransportEnabled $args[33] -msGraphEnvironmentName $args[34] -msGraphTenantID $args[35] -msGraphCertificateThumbprint $args[36] -msGraphApplicationID $args[37] -allowTelemetryCollection $args[39] -allowDetailedTelemetryCollection $args[40] -activeDirectoryAuthenticationMethod $args[41] -aadConnectAuthenticationMethod $args[42] -customRoutingDomain $args[43] -dlNamePrefix $args[44] -dlNameSuffix $args[45]} -ArgumentList $groupSMTPAddressArray[$serverCounter],$globalCatalogServer,$activeDirectoryCredential[$serverCounter],$networkLoggingDirectory[$serverCounter],$aadConnectServer,$aadConnectCredential[$serverCounter],$exchangeServer,$exchangecredential[$serverCounter],$exchangeOnlineCredential[$serverCounter],$exchangeOnlineCertificateThumbPrint,$exchangeOnlineOrganizationName,$exchangeOnlineEnvironmentName,$exchangeOnlineAppID,$exchangeAuthenticationMethod,$retainOffice365Settings,$dnNoSyncOU,$retainOriginalGroup,$enableHybridMailflow,$groupTypeOverride,$triggerUpgradeToOffice365Group,$retainFullMailboxAccessOnPrem,$retainSendAsOnPrem,$retainMailboxFolderPermsOnPrem,$retainFullMailboxAccessOffice365,$retainSendAsOffice365,$retainMailboxFolderPermsOffice365,$useCollectedFolderPermissionsOnPrem,$useCollectedFullMailboxAccessOffice365,$useCollectedSendAsOnPrem,$useCollectedFolderPermissionsOnPrem,$useCollectedFolderPermissionsOffice365,$TRUE,$remoteDriveLetter,$overrideCentralizedMailTransportEnabled,$msGraphEnvironmentName,$msGraphTenantID,$msGraphCertificateThumbprint,$msGraphApplicationID,$NULL,$allowTelemetryCollection,$allowDetailedTelemetryCollection,$activeDirectoryAuthenticationMethod,$aadConnectAuthenticationMethod,$customRoutingDomain,$dlNamePrefix,$dlNameSuffix -asJob -credential $activeDirectoryCredential[$serverCounter]
        }
    }

    #At this point we can monitor for completed jobs on the machine.

    do {
        #Gather the controller job if created
        $loopJobs = get-job

        out-logfile -string ("Number of jobs that are running = "+$loopJobs.count.tostring())

        foreach ($job in $loopJobs)
        {
            out-logfile -string ("Job ID: "+$job.id+" State: "+$job.state)
        }

        start-sleepProgress -sleepString "Sleeping waiting on job completion." -sleepSeconds 30
    } until ((get-job -State Running).count -eq 0)

    $loopJobs = get-job

    foreach ($job in $loopJobs)
    {
        out-logfile -string ("Job ID: "+$job.id+" State: "+$job.state+" Job Command: "+$job.command)
    }

    out-logfile -string "Removing all completed jobs."

    get-migrationSummary -logFolderPath $logFolderPath

    write-shamelessPlug

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
        TotalGroups = $telemetryGroupCount
        TotalMachines = $telemetryMachineCount
    }

    if ($allowTelemetryCollection -eq $TRUE)
    {
        send-TelemetryEvent -traceModuleName $traceModuleName -eventName $telemetryEventName -eventMetrics $telemetryEventMetrics -eventProperties $telemetryEventProperties
    }


    Out-LogFile -string "================================================================================"
    Out-LogFile -string "END start-MultipleMachineDistributionListMigration"
    Out-LogFile -string "================================================================================"
}
