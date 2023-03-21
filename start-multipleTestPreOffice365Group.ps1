
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


Function start-multipleTestPreOffice365Group
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
        #Define Microsoft Graph Parameters
        [Parameter(Mandatory = $false)]
        [ValidateSet("China","Global","USGov","USGovDod")]
        [string]$msGraphEnvironmentName="Global",
        [Parameter(Mandatory=$false)]
        [string]$msGraphTenantID="",
        [Parameter(Mandatory=$false)]
        [string]$msGraphCertificateThumbprint="",
        [Parameter(Mandatory=$false)]
        [string]$msGraphApplicationID="",
        #Define other mandatory parameters
        [Parameter(Mandatory = $true)]
        [string]$logFolderPath,
        [Parameter(Mandatory = $false)]
        [boolean]$useCollectedSendAsOnPrem=$FALSE,
        [boolean]$allowTelemetryCollection=$TRUE,
        [Parameter(Mandatory =$FALSE)]
        [boolean]$allowDetailedTelemetryCollection=$TRUE
    )

    #Initialize telemetry collection.

    #Establish required MS Graph Scopes

    $msGraphScopesRequired = @("User.Read.All", "Group.Read.All")

    $appInsightAPIKey = "63d673af-33f4-401c-931e-f0b64a218d89"
    $traceModuleName = "DLConversion"

    $telemetryStartTime = get-universalDateTime
    $telemetryEndTime = $NULL
    [double]$telemetryElapsedSeconds = 0
    $telemetryEventName = "Start-MultipleTestPreMigrations"
    [double]$telemetryGroupCount = 0

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

    [array]$jobOutput=@()

    [int]$totalAddressCount = $groupSMTPAddresses.Count
    $telemetryGroupCount = $totalAddressCount   
    [int]$maxThreadCount = 5

    [string]$jobName="MultiplePreMigration"

    [string]$originalLogFolderPath=$logFolderPath #Store the original in case the calculated is a network drive.

    new-LogFile -groupSMTPAddress $masterFileName -logFolderPath $logFolderPath

    out-logfile -string "********************************************************************************"
    out-logfile -string "NOCTICE"
    out-logfile -string "Telemetry collection is now enabled by default."
    out-logfile -string "For information regarding telemetry collection see https://timmcmic.wordpress.com/2022/11/14/4288/"
    out-logfile -string "Administrators may opt out of telemetry collection by using -allowTelemetryCollection value FALSE"
    out-logfile -string "Telemetry collection is appreciated as it allows further development and script enhacement."
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
    out-logfile -string ("Use collected send as on premsies = "+$useCollectedSendAsOnPrem)
    Out-LogFile -string "********************************************************************************"


    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "ENTERING PARAMTER VALIDATION"
    Out-LogFile -string "********************************************************************************"


    Out-LogFile -string "Validating Exchange Online Credentials."

    start-parameterValidation -exchangeOnlineCredential $exchangeOnlineCredential -exchangeOnlineCertificateThumbprint $exchangeOnlineCertificateThumbprint -threadCount $totalThreadCount

    #Validating that all portions for exchange certificate auth are present.

    out-logfile -string "Validating parameters for Exchange Online Certificate Authentication"

    start-parametervalidation -exchangeOnlineCertificateThumbPrint $exchangeOnlineCertificateThumbprint -exchangeOnlineOrganizationName $exchangeOnlineOrganizationName -exchangeOnlineAppID $exchangeOnlineAppID

    <#

    #Validate that only one method of engaging azure was specified.

    Out-LogFile -string "Valdating azure credentials."

    start-parameterValidation -azureADCredential $azureADCredential -azureCertificateThumbPrint $azureCertificateThumbprint -threadCount 5

    #Validate that all information for the certificate connection has been provieed.

    start-parameterValidation -azureCertificateThumbPrint $azureCertificateThumbprint -azureTenantID $azureTenantID -azureApplicationID $azureApplicationID

    #>

    out-logfile -string "Validation all components available for MSGraph Cert Auth"

    start-parameterValidation -msGraphCertificateThumbPrint $msGraphCertificateThumbprint -msGraphTenantID $msGraphTenantID -msGraphApplicationID $msGraphApplicationID

    Out-LogFile -string "END PARAMETER VALIDATION"
    Out-LogFile -string "********************************************************************************"

    Out-LogFile -string "The following SMTP addresses have been requested for migration."

    #Ensure that no addresses are specified more than once.

    out-logfile -string "Unique list of SMTP addresses included in the array."

    $groupSMTPAddresses = $groupSMTPAddresses | Select-Object -Unique

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

                #Start-Job -Name $jobName -InitializationScript {import-module DLConversionV2} -ScriptBlock { Test-PreMigrationO365Group -groupSMTPAddress $args[0] -globalCatalogServer $args[1] -activeDirectoryCredential $args[2] -activeDirectoryAuthenticationMethod $args[16] -logFolderPath $args[3] -exchangeOnlineCredential $args[4] -exchangeOnlineCertificateThumbPrint $args[5] -exchangeOnlineOrganizationName $args[6] -exchangeOnlineEnvironmentName $args[7] -exchangeOnlineAppID $args[8] -useCollectedSendAsOnPrem $args[9] -threadNumberAssigned $args[10] -totalThreadCount $args[11] -msGraphEnvironmentName $args[12] -msGraphTenantID $args[13] -msGraphCertificateThumbprint $args[14] -msGraphApplicationID $args[15] -allowTelemetryCollection $args[17] -allowDetailedTelemetryCollection $args[18]} -ArgumentList $groupSMTPAddresses[$arrayLocation + $forCounter],$globalCatalogServer,$activeDirectoryCredential,$originalLogFolderPath,$exchangeOnlineCredential,$exchangeOnlineCertificateThumbPrint,$exchangeOnlineOrganizationName,$exchangeOnlineEnvironmentName,$exchangeOnlineAppID,$useCollectedSendAsOnPrem,$forThread,$loopThreadCount,$msGraphEnvironmentName,$msGraphTenantID,$msGraphCertificateThumbprint,$msGraphApplicationID,$activeDirectoryAuthenticationMethod,$allowTelemetryCollection,$allowDetailedTelemetryCollection
                Start-Job -Name $jobName -InitializationScript {import-module c:\repository\dlconversionv2\dlconversionv2.psd1 -force} -ScriptBlock { Test-PreMigrationO365Group -groupSMTPAddress $args[0] -globalCatalogServer $args[1] -activeDirectoryCredential $args[2] -activeDirectoryAuthenticationMethod $args[16] -logFolderPath $args[3] -exchangeOnlineCredential $args[4] -exchangeOnlineCertificateThumbPrint $args[5] -exchangeOnlineOrganizationName $args[6] -exchangeOnlineEnvironmentName $args[7] -exchangeOnlineAppID $args[8] -useCollectedSendAsOnPrem $args[9] -threadNumberAssigned $args[10] -totalThreadCount $args[11] -msGraphEnvironmentName $args[12] -msGraphTenantID $args[13] -msGraphCertificateThumbprint $args[14] -msGraphApplicationID $args[15] -allowTelemetryCollection $args[17] -allowDetailedTelemetryCollection $args[18]}} -ArgumentList $groupSMTPAddresses[$arrayLocation + $forCounter],$globalCatalogServer,$activeDirectoryCredential,$originalLogFolderPath,$exchangeOnlineCredential,$exchangeOnlineCertificateThumbPrint,$exchangeOnlineOrganizationName,$exchangeOnlineEnvironmentName,$exchangeOnlineAppID,$useCollectedSendAsOnPrem,$forThread,$loopThreadCount,$msGraphEnvironmentName,$msGraphTenantID,$msGraphCertificateThumbprint,$msGraphApplicationID,$activeDirectoryAuthenticationMethod,$allowTelemetryCollection,$allowDetailedTelemetryCollection


                if ($forCounter -eq 0)
                {
                    start-sleepProgress -sleepString "Sleeping after job provioning." -sleepSeconds 5

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
                
                #Start-Job -Name $jobName -InitializationScript {import-module DLConversionV2} -ScriptBlock { Test-PreMigrationO365Group -groupSMTPAddress $args[0] -globalCatalogServer $args[1] -activeDirectoryCredential $args[2] -activeDirectoryAuthenticationMethod $args[16] -logFolderPath $args[3] -exchangeOnlineCredential $args[4] -exchangeOnlineCertificateThumbPrint $args[5] -exchangeOnlineOrganizationName $args[6] -exchangeOnlineEnvironmentName $args[7] -exchangeOnlineAppID $args[8] -useCollectedSendAsOnPrem $args[9] -threadNumberAssigned $args[10] -totalThreadCount $args[11] -msGraphEnvironmentName $args[12] -msGraphTenantID $args[13] -msGraphCertificateThumbprint $args[14] -msGraphApplicationID $args[15] -allowTelemetryCollection $args[17] -allowDetailedTelemetryCollection $args[18]} -ArgumentList $groupSMTPAddresses[$arrayLocation + $forCounter],$globalCatalogServer,$activeDirectoryCredential,$originalLogFolderPath,$exchangeOnlineCredential,$exchangeOnlineCertificateThumbPrint,$exchangeOnlineOrganizationName,$exchangeOnlineEnvironmentName,$exchangeOnlineAppID,$useCollectedSendAsOnPrem,$forThread,$loopThreadCount,$msGraphEnvironmentName,$msGraphTenantID,$msGraphCertificateThumbprint,$msGraphApplicationID,$activeDirectoryAuthenticationMethod,$allowTelemetryCollection,$allowDetailedTelemetryCollection
                Start-Job -Name $jobName -InitializationScript {import-module c:\repository\dlconversionv2\dlconversionv2.psd1 -force} -ScriptBlock { Test-PreMigrationO365Group -groupSMTPAddress $args[0] -globalCatalogServer $args[1] -activeDirectoryCredential $args[2] -activeDirectoryAuthenticationMethod $args[16] -logFolderPath $args[3] -exchangeOnlineCredential $args[4] -exchangeOnlineCertificateThumbPrint $args[5] -exchangeOnlineOrganizationName $args[6] -exchangeOnlineEnvironmentName $args[7] -exchangeOnlineAppID $args[8] -useCollectedSendAsOnPrem $args[9] -threadNumberAssigned $args[10] -totalThreadCount $args[11] -msGraphEnvironmentName $args[12] -msGraphTenantID $args[13] -msGraphCertificateThumbprint $args[14] -msGraphApplicationID $args[15] -allowTelemetryCollection $args[17] -allowDetailedTelemetryCollection $args[18]}} -ArgumentList $groupSMTPAddresses[$arrayLocation + $forCounter],$globalCatalogServer,$activeDirectoryCredential,$originalLogFolderPath,$exchangeOnlineCredential,$exchangeOnlineCertificateThumbPrint,$exchangeOnlineOrganizationName,$exchangeOnlineEnvironmentName,$exchangeOnlineAppID,$useCollectedSendAsOnPrem,$forThread,$loopThreadCount,$msGraphEnvironmentName,$msGraphTenantID,$msGraphCertificateThumbprint,$msGraphApplicationID,$activeDirectoryAuthenticationMethod,$allowTelemetryCollection,$allowDetailedTelemetryCollection


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
    Out-LogFile -string "END START-MULTIPLETESTPREMIGRATIONS"
    Out-LogFile -string "================================================================================"
}
