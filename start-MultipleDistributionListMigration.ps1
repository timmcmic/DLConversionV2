
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


Function Start-MultipleDistributionListMigration
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
        [pscredential]$activeDirectoryCredential,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Basic","Negotiate")]
        $activeDirectoryAuthenticationMethod="Negotiate",
        #Azure Active Directory Connect Parameters
        [Parameter(Mandatory = $false)]
        [string]$aadConnectServer=$NULL,
        [Parameter(Mandatory = $false)]
        [pscredential]$aadConnectCredential=$NULL,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Basic","Kerberos")]
        $aadConnectAuthenticationMethod="Kerberos",
        #Exchange On-Premises Parameters
        [Parameter(Mandatory = $false)]
        [string]$exchangeServer=$NULL,
        [Parameter(Mandatory = $false)]
        [pscredential]$exchangeCredential=$NULL,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Basic","Kerberos")]
        [string]$exchangeAuthenticationMethod="Basic",
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
        [Parameter(Mandatory=$false)]
        [boolean]$removeGroupViaGraph = $false,
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
        [Parameter(Mandatory = $false)]
        [int]$global:threadNumber=0,
        [Parameter(Mandatory = $false)]
        [int]$totalThreadCount=0,
        [Parameter(Mandatory = $FALSE)]
        [boolean]$isMultiMachine=$FALSE,
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
    $telemetryEventName = "Start-MultipleDistributionListMigration"
    [double]$telemetryGroupCount = 0
    [boolean]$telemetryMultipleMachine = $isMultiMachine
    
    if ($allowTelemetryCollection -eq $TRUE)
    {
        start-telemetryConfiguration -allowTelemetryCollection $allowTelemetryCollection -appInsightAPIKey $appInsightAPIKey -traceModuleName $traceModuleName
    }

    $windowTitle = "Start-MultipleDistributionListMigration Controller"
    $host.ui.RawUI.WindowTitle = $windowTitle

    #Define global variables.

    $global:logFile=$NULL #This is the global variable for the calculated log file name
    [string]$global:staticFolderName="\Master\"
    [string]$masterFileName="Master"

    #Define parameters that are variables here (not available as parameters in this function.)
  
    [boolean]$retainSendAsOnPrem=$FALSE
    [boolean]$retainFullMailboxAccessOnPrem=$FALSE
    [boolean]$retainMailboxFolderPermsOnPrem=$FALSE
    [boolean]$retainFullMailboxAccessOffice365=$FALSE
    [boolean]$retainMailboxFolderPermsOffice365=$FALSE
    [boolean]$retainOffice365Settings=$true
    [boolean]$retainSendAsOffice365=$TRUE

    [boolean]$noMoreGroupsToProcess=$FALSE

    [array]$jobOutput=@()
    [array]$smtpNoSpace=@()
    [array]$smtpGTZero=@()

    [int]$totalAddressCount = 0
    $telemetryGroupCount = 0
    [int]$maxThreadCount = 5

    [string]$jobName="MultipleMigration"

    [string]$originalLogFolderPath=$logFolderPath #Store the original in case the calculated is a network drive.

    #The log folder path needs to be dynamic to support network storage.

    if ($isMultiMachine -eq $TRUE)
    {
        try{
            #In this case a multi machine migration was specified.
            #The wrapper here will go ahead and make the Z drive connection that the rest of the scripts will use.
            #Z maps directly to the server instance on the migration host.

            [string]$networkName=$remoteDriveLetter
            [string]$networkRootPath=$logFolderPath
            $logFolderPath = $networkName+":"
            #[string]$networkDescription = "This is the centralized logging folder for DLMigrations on this machine."
            #[string]$networkPSProvider = "FileSystem"

            if (get-smbMapping -LocalPath $logFolderPath)
            {
                write-host "The network drive was found present.  Remove to satisfy migration."

                try
                {
                    write-host "Removing network drive with net use."
                    
                    invoke-command -scriptBlock {net use $args /delete /yes} -ArgumentList $logFolderPath -errorAction Stop
                }
                catch
                {
                    write-error "Attempting to use net use to remove the drive."

                    try
                    {
                        write-host "Removing network drive with remove-smbMapping."

                        remove-smbMapping -LocalPath $logFolderPath -Force -errorAction STOP
                    }
                    catch
                    {
                        write-error "Unable to use remote-SMBMapping to remove the try.  Drive agian."

                        try
                        {
                            write-host "Remove network drive using remove-SMBGlobalMapping."

                            remove-smbGlobalMapping -LocalPath $logFolderPath -Force -errorAction STOP
                        }
                        catch
                        {
                            write-error "Unable to use remove-SMBGlobalMapping. Final attempt - fail."
                            EXIT
                        }
                    }  
                }
            }

            try 
            {
                New-SmbMapping -LocalPath $logFolderPath -remotePath $networkRootPath -userName $activeDirectoryCredential.userName -password $activeDirectoryCredential.GetNetworkCredential().password -errorAction Stop
            }
            catch 
            {
                write-error "Unable to create network drive for storage."
                EXIT
            }

            #new-psDrive -name $networkName -root $networkRootPath -description $networkDescription -PSProvider $networkPSProvider -errorAction STOP -credential $activeDirectoryCredential

            #$logFolderPath = $networkName+":"
        }
        catch{
            exit
        }
    }

    $xmlFiles = @{
        nestedXML = @{ "Value" =  "nestedGroupsRetried" ; "Description" = "XML file that exports the original DL configuration"}
        errorXML = @{ "Value" =  "nestedGroupErrors" ; "Description" = "XML file that exports the updated DL configuration"}
    }

    #Define the nested groups csv.

    [string]$nestedGroupCSV = "nestedGroups.csv" #Predetermined CSV file name.
    [string]$nestedCSVPath = $logFolderPath+"\"+$nestedGroupCSV #Root log folder path with CSV file name.
    [array]$nestedRetryGroups=@() #Import of the groups contained within the CSV file.
    [array]$groupsToRetry=@() #Final list of groups determined that need to be retried.
    [boolean]$nestingError = $false #True / flase determins if there was a nesting error with the object.
    [array]$crossGroupDependencyFound = @() #List of groups that have a nesting dependency and cannot be retried.
    [array]$noCrossGroupDependencyFound=@()

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
    Out-LogFile -string "BEGIN START-MULTIPLEDISTRIBUTIONLISTMIGRATION"
    Out-LogFile -string "================================================================================"

    #Call garbage collection at the beginning to help with array management.

    [system.gc]::Collect()

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
    Out-LogFile -string ("GlobalCatalogServer = "+$globalCatalogServer)
    Out-LogFile -string ("ActiveDirectoryUserName = "+$activeDirectoryCredential.UserName.tostring())
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

    if (($exchangeOnlineCredential -ne $null) -and ($isMultiMachine -eq $FALSE))
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

    if ($isMultiMachine -eq $FALSE)
    {
        #Perform paramter validation manually.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "ENTERING PARAMETER VALIDATION"
        Out-LogFile -string "********************************************************************************"

        #Test to ensure that if any of the aadConnect parameters are passed - they are passed together.

        Out-LogFile -string "Validating that both AADConnectServer and AADConnectCredential are specified"

        start-parameterValidation -aadConnectServer $aadConnectServer -aadConnectCredential $aadConnectCredential

        #Validate that both the exchange credential and exchange server are presented together.

        Out-LogFile -string "Validating that both ExchangeServer and ExchangeCredential are specified."

        $useOnPremisesExchange = start-parameterValidation -exchangeServer $exchangeServer -exchangeCredential $exchangeCredential

        #Validate that only one method of engaging exchange online was specified.

        Out-LogFile -string "Validating Exchange Online Credentials."

        start-parameterValidation -exchangeOnlineCredential $exchangeOnlineCredential -exchangeOnlineCertificateThumbprint $exchangeOnlineCertificateThumbprint -threadCount $totalThreadCount

        #Validating that all portions for exchange certificate auth are present.

        out-logfile -string "Validating parameters for Exchange Online Certificate Authentication"

        start-parametervalidation -exchangeOnlineCertificateThumbPrint $exchangeOnlineCertificateThumbprint -exchangeOnlineOrganizationName $exchangeOnlineOrganizationName -exchangeOnlineAppID $exchangeOnlineAppID

        #Validate that only one method of engaging azure was specified.

        Out-LogFile -string "Validating azure credentials."

        start-parameterValidation -azureADCredential $azureADCredential -azureCertificateThumbPrint $azureCertificateThumbprint -threadCount 5

        #Validate that all information for the certificate connection has been provieed.

        start-parameterValidation -azureCertificateThumbPrint $azureCertificateThumbprint -azureTenantID $azureTenantID -azureApplicationID $azureApplicationID

        out-logfile -string "Validation all components available for MSGraph Cert Auth"

        start-parameterValidation -msGraphCertificateThumbPrint $msGraphCertificateThumbprint -msGraphTenantID $msGraphTenantID -msGraphApplicationID $msGraphApplicationID

        #Validate that an OU was specified <if> retain group is not set to true.

        Out-LogFile -string "Validating that if retain original group is false a non-sync OU is specified."

        start-parametervalidation -retainOriginalGroup $retainOriginalGroup -doNoSyncOU $doNoSyncOU

        out-logfile -string "Validating that on premises Exchange support is enabled for enabling hybrid mail flow."
    }

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

    #Ok so this is the other half of the hokie code.
    #This checks to see if the multi machine is the caller.
    #If it is - and cert auth is used - then we know that this array contains bogus users.
    #Set the credential back to NULL before calling the migration.

    if ($exchangeOnlineCredential.userName -eq "BogusUserName")
    {
        out-logfile -string "Exchange certificate authentication in use - null out credential"
        $exchangeOnlineCredential = $NULL
    }
    
    if ($azureADCredential.userName -eq "BogusUserName")
    {
        out-logfile -string "Azure AD certificate authentication in use - null out credential."
        $azureADCredential = $NULL
    }

    Out-LogFile -string "END PARAMETER VALIDATION"
    Out-LogFile -string "********************************************************************************"

    function startMultiMigration
    {
        Out-LogFile -string "The following SMTP addresses have been requested for migration."

        #Ensure that no addresses are specified more than once.
    
        out-logfile -string "Unique list of SMTP addresses included in the array."

        if ($groupSMTPAddress.count -gt 1)
        {
            $groupSMTPAddresses = $groupSMTPAddresses | Select-Object -Unique
        }       
    
        [int]$totalAddressCount = $groupSMTPAddresses.count
        $telemetryGroupCount = $totalAddressCount
    
        foreach ($groupSMTPAddress in $groupSMTPAddresses)
        {
            out-logfile -string $GroupSMTPAddress
        }
    
        #Maximum thread count that can be supported at one time is 5 for now.
        #Performance degrades over time at greater intervals.
        #The code overall is set to take a max of 10 - but for now we're capping it at 5 concurrent / per batch.
    
        #The goal of this operation will be to batch moves in groups of 5 - and do another group after that.
    
        out-logfile -string ("The number of addresses to process is = "+$totalAddressCount)
        
        [boolean]$allDone=$FALSE
        [int]$arrayLocation=0
        [int]$maxArrayLocation = $totalAddressCount - 1
        [int]$remainingAddresses = 0
        [int]$loopThreadCount = 0
    
        #Begin processing batches of members in the SMTP array.
        #Current max jobs recommended 5 per batch.
    
        do 
        {
            out-logfile -string $arrayLocation
    
            #The remaining addrsses is the total addresses - the number of addresses alread processed by incrementing the array location.
    
            $remainingAddresses = $totalAddressCount - $arrayLocation
    
            out-logfile -string $remainingAddresses
    
            #If the remaining number of addresses to process is greater than 5 - this means that we can do another bach of 5.
            #The logic below processes groups in batches of 5.
    
            if ($remainingAddresses -ge $maxThreadCount)
            {
                Out-logfile -string ("More than "+$maxThreadCount.ToString()+" groups to process.")
    
                #Set the max threads for the job to 5 so each job knows that 5 groups are being processed.
    
                $loopThreadCount = $maxThreadCount
                out-logfile -string ("The loop thread counter = "+$loopThreadCount)
    
                #Iterate through each group with a for loop.
                #The loop counter will be the thread number (IE if forCounter=0 then thread number is 1 for the job)
                #The group to be processed is always where your at in the array + for counter.
                #If this is the first job being procsesed - sleep for 5 before provisioning any more jobs (allows priority to thread 1 to do some pre-work before others kick in.)
    
                for ($forCounter = 0 ; $forCounter -lt $maxThreadCount ; $forCounter ++)
                {
                    out-logfile -string $groupSMTPAddresses[$ArrayLocation+$forCounter]
    
                    $forThread = $forCounter+1
    
                    Start-Job -Name $jobName -InitializationScript {import-module DLConversionV2} -ScriptBlock { Start-DistributionListMigration -groupSMTPAddress $args[0] -globalCatalogServer $args[1] -activeDirectoryCredential $args[2] -logFolderPath $args[3] -aadConnectServer $args[4] -aadConnectCredential $args[5] -exchangeServer $args[6] -exchangeCredential $args[7] -exchangeOnlineCredential $args[8] -exchangeOnlineCertificateThumbPrint $args[9] -exchangeOnlineOrganizationName $args[10] -exchangeOnlineEnvironmentName $args[11] -exchangeOnlineAppID $args[12] -exchangeAuthenticationMethod $args[13] -dnNoSyncOU $args[15] -retainOriginalGroup $args[16] -enableHybridMailflow $args[17] -groupTypeOverride $args[18] -triggerUpgradeToOffice365Group $args[19] -useCollectedFullMailboxAccessOnPrem $args[26] -useCollectedFullMailboxAccessOffice365 $args[27] -useCollectedSendAsOnPrem $args[28] -useCollectedFolderPermissionsOnPrem $args[29] -useCollectedFolderPermissionsOffice365 $args[30] -threadNumberAssigned $args[31] -totalThreadCount $args[32] -isMultiMachine $args[33] -remoteDriveLetter $args[34] -overrideCentralizedMailTransportEnabled $args[35] -msGraphEnvironmentName $args[36] -msGraphTenantID $args[37] -msGraphCertificateThumbprint $args[38] -msGraphApplicationID $args[39] -allowTelemetryCollection $args[41] -allowDetailedTelemetryCollection $args[42] -activeDirectoryAuthenticationMethod $args[43] -aadConnectAuthenticationMethod $args[44] -customRoutingDomain $args[45] -dlNamePrefix $args[46] -dlNameSuffix $args[47] -removeGroupViaGraph $args[48]} -ArgumentList $groupSMTPAddresses[$arrayLocation + $forCounter],$globalCatalogServer,$activeDirectoryCredential,$originalLogFolderPath,$aadConnectServer,$aadConnectCredential,$exchangeServer,$exchangecredential,$exchangeOnlineCredential,$exchangeOnlineCertificateThumbPrint,$exchangeOnlineOrganizationName,$exchangeOnlineEnvironmentName,$exchangeOnlineAppID,$exchangeAuthenticationMethod,$retainOffice365Settings,$dnNoSyncOU,$retainOriginalGroup,$enableHybridMailflow,$groupTypeOverride,$triggerUpgradeToOffice365Group,$retainFullMailboxAccessOnPrem,$retainSendAsOnPrem,$retainMailboxFolderPermsOnPrem,$retainFullMailboxAccessOffice365,$retainSendAsOffice365,$retainMailboxFolderPermsOffice365,$useCollectedFolderPermissionsOnPrem,$useCollectedFullMailboxAccessOffice365,$useCollectedSendAsOnPrem,$useCollectedFolderPermissionsOnPrem,$useCollectedFolderPermissionsOffice365,$forThread,$loopThreadCount,$isMultiMachine,$remoteDriveLetter,$overrideCentralizedMailTransportEnabled,$msGraphEnvironmentName,$msGraphTenantID,$msGraphCertificateThumbprint,$msGraphApplicationID,$NULL,$allowTelemetryCollection,$allowDetailedTelemetryCollection,$activeDirectoryAuthenticationMethod,$aadConnectAuthenticationMethod,$customRoutingDomain,$dlNamePrefix,$dlNameSuffix,$removeGroupViaGraph
                    #Start-Job -Name $jobName -InitializationScript {import-module c:\repository\dlconversionv2\dlconversionv2.psd1 -force} -ScriptBlock { Start-DistributionListMigration -groupSMTPAddress $args[0] -globalCatalogServer $args[1] -activeDirectoryCredential $args[2] -logFolderPath $args[3] -aadConnectServer $args[4] -aadConnectCredential $args[5] -exchangeServer $args[6] -exchangeCredential $args[7] -exchangeOnlineCredential $args[8] -exchangeOnlineCertificateThumbPrint $args[9] -exchangeOnlineOrganizationName $args[10] -exchangeOnlineEnvironmentName $args[11] -exchangeOnlineAppID $args[12] -exchangeAuthenticationMethod $args[13] -dnNoSyncOU $args[15] -retainOriginalGroup $args[16] -enableHybridMailflow $args[17] -groupTypeOverride $args[18] -triggerUpgradeToOffice365Group $args[19] -useCollectedFullMailboxAccessOnPrem $args[26] -useCollectedFullMailboxAccessOffice365 $args[27] -useCollectedSendAsOnPrem $args[28] -useCollectedFolderPermissionsOnPrem $args[29] -useCollectedFolderPermissionsOffice365 $args[30] -threadNumberAssigned $args[31] -totalThreadCount $args[32] -isMultiMachine $args[33] -remoteDriveLetter $args[34] -overrideCentralizedMailTransportEnabled $args[35] -msGraphEnvironmentName $args[36] -msGraphTenantID $args[37] -msGraphCertificateThumbprint $args[38] -msGraphApplicationID $args[39] -allowTelemetryCollection $args[41] -allowDetailedTelemetryCollection $args[42] -activeDirectoryAuthenticationMethod $args[43] -aadConnectAuthenticationMethod $args[44] -customRoutingDomain $args[45] -dlNamePrefix $args[46] -dlNameSuffix $args[47] -removeGroupViaGraph $args[48]} -ArgumentList $groupSMTPAddresses[$arrayLocation + $forCounter],$globalCatalogServer,$activeDirectoryCredential,$originalLogFolderPath,$aadConnectServer,$aadConnectCredential,$exchangeServer,$exchangecredential,$exchangeOnlineCredential,$exchangeOnlineCertificateThumbPrint,$exchangeOnlineOrganizationName,$exchangeOnlineEnvironmentName,$exchangeOnlineAppID,$exchangeAuthenticationMethod,$retainOffice365Settings,$dnNoSyncOU,$retainOriginalGroup,$enableHybridMailflow,$groupTypeOverride,$triggerUpgradeToOffice365Group,$retainFullMailboxAccessOnPrem,$retainSendAsOnPrem,$retainMailboxFolderPermsOnPrem,$retainFullMailboxAccessOffice365,$retainSendAsOffice365,$retainMailboxFolderPermsOffice365,$useCollectedFolderPermissionsOnPrem,$useCollectedFullMailboxAccessOffice365,$useCollectedSendAsOnPrem,$useCollectedFolderPermissionsOnPrem,$useCollectedFolderPermissionsOffice365,$forThread,$loopThreadCount,$isMultiMachine,$remoteDriveLetter,$overrideCentralizedMailTransportEnabled,$msGraphEnvironmentName,$msGraphTenantID,$msGraphCertificateThumbprint,$msGraphApplicationID,$NULL,$allowTelemetryCollection,$allowDetailedTelemetryCollection,$activeDirectoryAuthenticationMethod,$aadConnectAuthenticationMethod,$customRoutingDomain,$dlNamePrefix,$dlNameSuffix,$removeGroupViaGraph
    
                    if ($forCounter -eq 0)
                    {
                        start-sleepProgress -sleepString "Sleeping after job provisioning." -sleepSeconds 5
                    }
                }
    
                #We cannot allow the next batch to be processed - until the current batch has no running threads.
    
                do 
                {
                    out-logfile -string "Jobs are not yet completed in this batch."
    
                    $loopJobs = get-job -state Running | where {$_.name -eq $jobName}
    
                    out-logfile -string ("Number of jobs that are running = "+$loopJobs.count.tostring())
    
                    foreach ($job in $loopJobs)
                    {
                        out-logfile -string ("Job ID: "+$job.id+" State: "+$job.state)
                    }
    
                    start-sleepProgress -sleepString "Sleeping waiting on job completion." -sleepSeconds 30
    
    
                } until ((get-job -State Running | where {$_.name -eq $jobName}).count -eq 0)
    
                #Increment the array location +5 since this loop processed 5 jobs.
    
                $arrayLocation=$arrayLocation+$maxThreadCount
    
                out-logfile -string ("The array location is = "+$arrayLocation)
    
                #Remove all completed jobs at this time.
    
                $loopJobs = get-job -name $jobName
    
                foreach ($job in $loopJobs)
                {
                    out-logfile -string ("Job ID: "+$job.id+" State: "+$job.state)
                    remove-job -id $job.id
                }  
            }
    
            #In this instance we have reached a batch of less than 5.
            #That means when we call the job we need to specify the total thread count of remaining groups .
            #In this case loop thread count would be the number of remaining groups.
            #The loop creates the jobs based on the same logic - but this time only up to the number of remaining addresses.
            #Iterate the array counter to the max number of locations when concluded.
            #This should trigger the end of the DO UNTIL for batch processing.
    
            else 
            {
                Out-logfile -string ("Less than "+$maxThreadCount.ToString()+" groups to process.")
                $loopThreadCount = $remainingAddresses
                out-logfile -string ("The loop thread counter = "+$loopThreadCount)
    
                for ($forCounter = 0 ; $forCounter -lt $remainingAddresses ; $forCounter ++)
                {
                    out-logfile -string $groupSMTPAddresses[$ArrayLocation+$forCounter]
    
                    $forThread=$forCounter+1
    
                    Start-Job -name $jobName -InitializationScript {import-module DLConversionV2} -ScriptBlock { Start-DistributionListMigration -groupSMTPAddress $args[0] -globalCatalogServer $args[1] -activeDirectoryCredential $args[2] -logFolderPath $args[3] -aadConnectServer $args[4] -aadConnectCredential $args[5] -exchangeServer $args[6] -exchangeCredential $args[7] -exchangeOnlineCredential $args[8] -exchangeOnlineCertificateThumbPrint $args[9] -exchangeOnlineOrganizationName $args[10] -exchangeOnlineEnvironmentName $args[11] -exchangeOnlineAppID $args[12] -exchangeAuthenticationMethod $args[13] -dnNoSyncOU $args[15] -retainOriginalGroup $args[16] -enableHybridMailflow $args[17] -groupTypeOverride $args[18] -triggerUpgradeToOffice365Group $args[19] -useCollectedFullMailboxAccessOnPrem $args[26] -useCollectedFullMailboxAccessOffice365 $args[27] -useCollectedSendAsOnPrem $args[28] -useCollectedFolderPermissionsOnPrem $args[29] -useCollectedFolderPermissionsOffice365 $args[30] -threadNumberAssigned $args[31] -totalThreadCount $args[32] -isMultiMachine $args[33] -remoteDriveLetter $args[34] -overrideCentralizedMailTransportEnabled $args[35] -msGraphEnvironmentName $args[36] -msGraphTenantID $args[37] -msGraphCertificateThumbprint $args[38] -msGraphApplicationID $args[39] -allowTelemetryCollection $args[41] -allowDetailedTelemetryCollection $args[42] -activeDirectoryAuthenticationMethod $args[43] -aadConnectAuthenticationMethod $args[44] -customRoutingDomain $args[45] -dlNamePrefix $args[46] -dlNameSuffix $args[47] -removeGroupViaGraph $args[48]} -ArgumentList $groupSMTPAddresses[$arrayLocation + $forCounter],$globalCatalogServer,$activeDirectoryCredential,$originalLogFolderPath,$aadConnectServer,$aadConnectCredential,$exchangeServer,$exchangecredential,$exchangeOnlineCredential,$exchangeOnlineCertificateThumbPrint,$exchangeOnlineOrganizationName,$exchangeOnlineEnvironmentName,$exchangeOnlineAppID,$exchangeAuthenticationMethod,$retainOffice365Settings,$dnNoSyncOU,$retainOriginalGroup,$enableHybridMailflow,$groupTypeOverride,$triggerUpgradeToOffice365Group,$retainFullMailboxAccessOnPrem,$retainSendAsOnPrem,$retainMailboxFolderPermsOnPrem,$retainFullMailboxAccessOffice365,$retainSendAsOffice365,$retainMailboxFolderPermsOffice365,$useCollectedFolderPermissionsOnPrem,$useCollectedFullMailboxAccessOffice365,$useCollectedSendAsOnPrem,$useCollectedFolderPermissionsOnPrem,$useCollectedFolderPermissionsOffice365,$forThread,$loopThreadCount,$isMultiMachine,$remoteDriveLetter,$overrideCentralizedMailTransportEnabled,$msGraphEnvironmentName,$msGraphTenantID,$msGraphCertificateThumbprint,$msGraphApplicationID,$NULL,$allowTelemetryCollection,$allowDetailedTelemetryCollection,$activeDirectoryAuthenticationMethod,$aadConnectAuthenticationMethod,$customRoutingDomain,$dlNamePrefix,$dlNameSuffix,$removeGroupViaGraph
                    #Start-Job -Name $jobName -InitializationScript {import-module c:\repository\dlconversionv2\dlconversionv2.psd1 -force} -ScriptBlock { Start-DistributionListMigration -groupSMTPAddress $args[0] -globalCatalogServer $args[1] -activeDirectoryCredential $args[2] -logFolderPath $args[3] -aadConnectServer $args[4] -aadConnectCredential $args[5] -exchangeServer $args[6] -exchangeCredential $args[7] -exchangeOnlineCredential $args[8] -exchangeOnlineCertificateThumbPrint $args[9] -exchangeOnlineOrganizationName $args[10] -exchangeOnlineEnvironmentName $args[11] -exchangeOnlineAppID $args[12] -exchangeAuthenticationMethod $args[13] -dnNoSyncOU $args[15] -retainOriginalGroup $args[16] -enableHybridMailflow $args[17] -groupTypeOverride $args[18] -triggerUpgradeToOffice365Group $args[19] -useCollectedFullMailboxAccessOnPrem $args[26] -useCollectedFullMailboxAccessOffice365 $args[27] -useCollectedSendAsOnPrem $args[28] -useCollectedFolderPermissionsOnPrem $args[29] -useCollectedFolderPermissionsOffice365 $args[30] -threadNumberAssigned $args[31] -totalThreadCount $args[32] -isMultiMachine $args[33] -remoteDriveLetter $args[34] -overrideCentralizedMailTransportEnabled $args[35] -msGraphEnvironmentName $args[36] -msGraphTenantID $args[37] -msGraphCertificateThumbprint $args[38] -msGraphApplicationID $args[39] -allowTelemetryCollection $args[41] -allowDetailedTelemetryCollection $args[42] -activeDirectoryAuthenticationMethod $args[43] -aadConnectAuthenticationMethod $args[44] -customRoutingDomain $args[45] -dlNamePrefix $args[46] -dlNameSuffix $args[47] -removeGroupViaGraph $args[48]} -ArgumentList $groupSMTPAddresses[$arrayLocation + $forCounter],$globalCatalogServer,$activeDirectoryCredential,$originalLogFolderPath,$aadConnectServer,$aadConnectCredential,$exchangeServer,$exchangecredential,$exchangeOnlineCredential,$exchangeOnlineCertificateThumbPrint,$exchangeOnlineOrganizationName,$exchangeOnlineEnvironmentName,$exchangeOnlineAppID,$exchangeAuthenticationMethod,$retainOffice365Settings,$dnNoSyncOU,$retainOriginalGroup,$enableHybridMailflow,$groupTypeOverride,$triggerUpgradeToOffice365Group,$retainFullMailboxAccessOnPrem,$retainSendAsOnPrem,$retainMailboxFolderPermsOnPrem,$retainFullMailboxAccessOffice365,$retainSendAsOffice365,$retainMailboxFolderPermsOffice365,$useCollectedFolderPermissionsOnPrem,$useCollectedFullMailboxAccessOffice365,$useCollectedSendAsOnPrem,$useCollectedFolderPermissionsOnPrem,$useCollectedFolderPermissionsOffice365,$forThread,$loopThreadCount,$isMultiMachine,$remoteDriveLetter,$overrideCentralizedMailTransportEnabled,$msGraphEnvironmentName,$msGraphTenantID,$msGraphCertificateThumbprint,$msGraphApplicationID,$NULL,$allowTelemetryCollection,$allowDetailedTelemetryCollection,$activeDirectoryAuthenticationMethod,$aadConnectAuthenticationMethod,$customRoutingDomain,$dlNamePrefix,$dlNameSuffix,$removeGroupViaGraph
    
                    if ($forCounter -eq 0)
                    {
                        start-sleepProgress -sleepString "Sleeping after job creation." -sleepSeconds 30
                    }
                }
    
                #We cannot allow the next batch to be processed - until the current batch has no running threads.
    
                do 
                {
                    out-logfile -string "Jobs are not yet completed in this batch."
    
                    $loopJobs = get-job -state Running | where {$_.name -eq $jobName}
    
                    out-logfile -string ("Number of jobs that are running = "+$loopJobs.count.tostring())
    
                    foreach ($job in $loopJobs)
                    {
                        out-logfile -string ("Job ID: "+$job.id+" State: "+$job.state)
                    }
    
                    start-sleepProgress -sleepString "Sleeping pending job status." -sleepSeconds 30
    
                } until ((get-job -State Running | where {$_.name -eq $jobName}).count -eq 0)
    
                out-logfile -string ("The array location is = "+$arrayLocation)
    
                #Remove all completed jobs at this time.
    
                $loopJobs = get-job -name $jobName
    
                foreach ($job in $loopJobs)
                {
                    $jobOutput+=(get-job -id $job.id).childjobs.output 
                    out-logfile -string ("Job ID: "+$job.id+" State: "+$job.state)
                    remove-job -id $job.id
                }  
    
                $arrayLocation=$arrayLocation+$remainingAddresses
            }
        } until ($arrayLocation -eq $totalAddressCount)    
    }

    #Execute the multi migration

    out-logfile -string "Starting multi-migration function."

    #Ensure no spaces in SMTP addresses.

    foreach ($group in $groupSMTPAddresses)
    {
        $smtpNoSpace+=remove-stringSpace -stringToFix $group
    }

    $groupSMTPAddresses = $smtpNoSpace

    out-logfile -string "Scanning each entry in the groups to ensure that none are a blank line."

    foreach ($group in $groupSMTPAddresses)
    {
        out-logfile -string ("Count of entry: "+$group.length)

        if ($group.length -gt 0)
        {
            out-logfile -string "Group entry length is greater than 0."

            $smtpGTZero += $group
        }
        else 
        {
            out-logfile -string "Entry is a blank line - discarding"
        }
    }

    $groupSMTPAddresses = $smtpGTZero

    if ($groupSMTPAddresses.count -gt 0)
    {
        out-logfile -string "Commencing multiple migrations after email address analysis."
        startMultiMigration
    }
    else 
    {
        out-logfile -string "After removing spaces and blank lines there are no groups to be migrated." -isError:$true
    }
    

    #Now the we've made the first pass - we can work through any of the nested group exceptions.

    out-logfile -string "Entering do / until to start nested group processing."

    do
    {
        out-logfile -string "Determining if nested groups CSV file exists."

        if (test-path $nestedCSVPath)
        {
            out-logfile -string "Nested groups CSV file exists - proceeding with nested group processing."
            #Resetting groups to retry.

            $groupsToRetry = @()
            $noCrossGroupDependencyFound = @()

            #Begin by importing the CSV file containing the nested objects.

            try{
                out-logfile -string "Importing the CSV objects for nested group retries."
    
                $nestedRetryGroups = import-csv -path $nestedCSVPath -errorAction Stop
            }
            catch {
                out-logfile -string "Unable to import the CSV file.  This is a soft error - existing the loop and nested groups will need to be manually retried"
                $noMoreGroupsToProces=$TRUE #Set to true to exit loop.
            }
    
            #Remove the CSV file that was processed.  This file will be recreated if possible.
    
            try {
                out-logfile -string "Removing the CSV file previously imported.  Will be recreated by migration threads if nesting found."
    
                Remove-Item -Path $nestedCSVPath -errorAction STOP
            }
            catch {
                out-logfile -string "Unable to remove the CSV file for nesting.  The file will continue to be appended and groups ignored."
            }
    
            #At this time the error state for each group can be reset for further process.
    
            out-logfile -string ("The number of groups to be retried for nesting: "+$nestedRetryGroups.count.tostring())
    
            out-logfile -string "Resetting error state from the imported nested groups for further processing."
    
            for ($i = 0 ; $i -lt $nestedRetryGroups.count ; $i++)
            {
                out-logfile -string ("Clearing error state for: "+$nestedRetryGroups[$i].primarySMTPAddressOrUPN)
                $nestedRetryGroups[$i].isError=$false
                $nestedRetryGroups[$i].isErrorMessage=""
            }
    
            #At this time process the groups in the nesting array.  If they match a child already migrated reproces the parent.
    
            out-logfile -string "Beginning object comparison to identity circular membership references."
    
            for  ($j = 0 ; $j -lt $nestedRetryGroups.count ; $j++)
            {
                for ($i = 0 ; $i -lt $nestedRetryGroups.Count ; $i++)
                {
                    #Compare the parent SMTP address to the SMTP address of the member found.
        
                    if (($nestedRetryGroups[$j].parentGroupSMTPAddress -eq $nestedRetryGroups[$i].primarySMTPAddressOrUPN) -and ($nestedRetryGroups[$j].primarySMTPAddressOrUPN -eq $nestedRetryGroups[$i].parentGroupSMTPAddress))
                    {
                        out-logfile -string "Circular membership reference identified - setting error state."
    
                        $nestedRetryGroups[$j].isError = $TRUE
                        $nestedRetryGroups[$j].isErrorMessage = "CIRCULAR_REFERENCE_EXCEPTION: This group has a child distribution list that also has this group as a member.  This creates a circular dependency which cannot be handeled automatically."
                    }
                    else 
                    {
                        out-logfile -string "No circular reference state detected."
                    }
                }
            }

            out-logfile -string "Creating arrays for groups to reprocess and groups in permanent failure."
    
            foreach ($group in $nestedRetryGroups)
            {
                if ($group.isError -eq $TRUE)
                {
                    $crossGroupDependencyFound +=$group
                }
                else
                {
                    $noCrossGroupDependencyFound+= $group
                }
            }

            out-logfile -string "Writing out all groups that will be reprocessed."
    
            if ($noCrossGroupDependencyFound.count -gt 0)
            {
                out-logfile -string "+++++++++++++++++++++++++++++++++++++++++++"
                out-logfile -string "The following groups do not have a circular dependency and will be evaluated for automatic retry migration."
                out-logfile -string "+++++++++++++++++++++++++++++++++++++++++++"
    
                foreach ($group in $noCrossGroupDependencyFound)
                {
                    #Using write error since I wrote a function to output errors but really it's just way to ensure consistent object loging.
    
                    write-ErrorEntry -errorEntry $group
                }
    
                out-xmlFile -itemToExport $noCrossGroupDependencyFound -itemNameToExport $xmlFiles.nestedXML.value
            }

            out-logfile -string "Determining if groups are eligible for reprocessing..."
    
            if ($noCrossGroupDependencyFound.count -gt 0)
            {
                foreach ($group in $noCrossGroupDependencyFound)
                {
                    out-logfile -string ("Processing nested DL: "+$group.primarySMTPAddressOrUPN)
                    out-logfile -string ("Processing nested parent DL:"+$group.parentGroupSMTPAddress)
    
                    if ($groupSMTPAddresses -contains $group.primarySMTPAddressOrUPN)
                    {
                        out-logfile -string ("Nested DL parent eligable for retry: "+$group.ParentGroupSMTPAddress)
                        $groupsToRetry+=$group.ParentGroupSMTPAddress
                    }
                    else 
                    {
                        $group.isError = $TRUE
                        $group.isErrorMessage = "CHILD_GROUP_MIGRATION_EXCEPTION:  The groupt to be migrated has a child group not included in the migration set."
                        $crossGroupDependencyFound +=$group #Overloading this since it contains errors before and this is an error that I want outputted.
                        out-logfile -string "Parent group not eligible for retry - child not included in migration set."
                    }
                } 
            }
    
            out-logfile -string ("Number of groups to retry: "+$groupsToRetry.Count.tostring())
    
            out-logfile -string "Resetting groupSMTPAddresses to the retry group set and selecting only unique values."
    
            $groupSMTPAddresses = $groupsToRetry | Select-Object -Unique
    
            out-logfile -string ("New group SMTP address count: "+$groupSMTPAddresses.Count.tostring())
    
            if ($groupSMTPAddresses.count -gt 0)
            {
                out-logfile -string "Restarting function to reprocess groups."
                startMultiMigration
            }
            else
            {
                out-logfile -string "No additional groups to process - not calling."
                out-logfile -string "Setting no more groups to process to TRUE."
                $noMoreGroupsToProcess = $TRUE
            }

            out-logfile -string "Setting noMoreGroupsToProcess = FALSE to have it loop through again."
            $noMoreGroupsToProcess = $FALSE
        }
        else
        {
            $noMoreGroupsToProcess = $TRUE
        }
    }
    until($noMoreGroupsToProcess -eq $TRUE)

    if ($crossGroupDependencyFound.count -gt 0)
    {
        out-logfile -string "+++++++++++++++++++++++++++++++++++++++++++"
        out-logfile -string "ERROR:  The following nested groups have errors."
        out-logfile -string "CircularReferenceException = A group to be migrated has a child group where the child group has the migrated group as a member."
        out-logfile -string "Group -> GroupB || GroupB -> GroupA"
        out-logfile -string "The dependencies must be removed and each group migrated.  Post migration the dependencies may be restored."
        out-logfile -string "ChildGroupMigrationException = A group contains a child group not included in the migration set."
        out-logfile -string "Automatic migration of nested groups cannot proceed.  Remove the child group or add the child group to the migration set."
        out-logfile -string "+++++++++++++++++++++++++++++++++++++++++++"

        foreach ($group in $crossGroupDependencyFound)
        {
            write-errorEntry -errorEntry $group
        }

        out-xmlFile -itemToExport $crossGroupDependencyFound -itemNameToExport $xmlFiles.errorXML.value
    }

    get-migrationSummary -logFolderPath $logFolderPath

    #Call .net garbage collection due to bulk arrays.

    [system.gc]::Collect()

    write-shamelessPlug

    $telemetryEndTime = get-universalDateTime
    $telemetryElapsedSeconds = get-elapsedTime -startTime $telemetryStartTime -endTime $telemetryEndTime

    # build the properties and metrics #
    $telemetryEventProperties = @{
        DLConversionV2Command = $telemetryEventName
        MigrationStartTimeUTC = $telemetryStartTime
        MigrationEndTimeUTC = $telemetryEndTime
        MultipleMachineMigration = $telemetryMultipleMachine
    }

    $telemetryEventMetrics = @{
        MigrationElapsedSeconds = $telemetryElapsedSeconds
        TotalGroups = $telemetryGroupCount
    }

    if ($allowTelemetryCollection -eq $TRUE)
    {
        send-TelemetryEvent -traceModuleName $traceModuleName -eventName $telemetryEventName -eventMetrics $telemetryEventMetrics -eventProperties $telemetryEventProperties
    }

    Out-LogFile -string "================================================================================"
    Out-LogFile -string "END START-DISTRIBUTIONLISTMIGRATION"
    Out-LogFile -string "================================================================================"

    if ($isMultiMachine -eq $TRUE)
    {
        try{            
            #remove-PSDrive $networkName -Force
            remove-smbMapping $logFolderPath -Force
        }
        catch{
            exit
        }
    }
}
