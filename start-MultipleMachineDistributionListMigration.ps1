
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
        [Parameter(Mandatory = $true)]
        [string]$globalCatalogServer,
        [Parameter(Mandatory = $true)]
        [pscredential]$activeDirectoryCredential,
        [Parameter(Mandatory = $true)]
        [string]$logFolderPath,
        [Parameter(Mandatory = $false)]
        [string]$aadConnectServer=$NULL,
        [Parameter(Mandatory = $false)]
        [pscredential]$aadConnectCredential=$NULL,
        [Parameter(Mandatory = $false)]
        [string]$exchangeServer=$NULL,
        [Parameter(Mandatory = $false)]
        [pscredential]$exchangeCredential=$NULL,
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
        [Parameter(Mandatory = $false)]
        [ValidateSet("Basic","Kerberos")]
        [string]$exchangeAuthenticationMethod="Basic",
        [Parameter(Mandatory = $false)]
        [boolean]$retainOffice365Settings=$true,
        [Parameter(Mandatory = $true)]
        [string]$dnNoSyncOU = "NotSet",
        [Parameter(Mandatory = $false)]
        [boolean]$retainOriginalGroup = $TRUE,
        [Parameter(Mandatory = $false)]
        [boolean]$enableHybridMailflow = $FALSE,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Security","Distribution")]
        [string]$groupTypeOverride="None",
        [Parameter(Mandatory = $false)]
        [boolean]$triggerUpgradeToOffice365Group=$FALSE,
        [Parameter(Mandatory = $false)]
        [boolean]$retainSendAsOffice365=$FALSE,
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
        [Parameter(Mandatory = $TRUE)]
        [array]$serverNames = $NULL
    )

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

    $jobOutput=$NULL

    [int]$totalAddressCount = $groupSMTPAddresses.Count
    [int]$maxThreadCount = 5

    [string]$localHostName=$NULL

    new-LogFile -groupSMTPAddress $masterFileName -logFolderPath $logFolderPath

    Out-LogFile -string "================================================================================"
    Out-LogFile -string "BEGIN START-MULTIPLEMACHINEDISTRIBUTIONLISTMIGRATION"
    Out-LogFile -string "================================================================================"

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
    out-logfile -string "Servers to Excute On:"
    foreach ($server in $serverNames)
    {
        Out-LogFile -string $server
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
    out-logfile -string ("Use collected send as on premsies = "+$useCollectedSendAsOnPrem)
    out-logfile -string ("Use colleced mailbox folder permissions on premises = "+$useCollectedFolderPermissionsOnPrem)
    out-logfile -string ("Use collected mailbox folder permissions Office 365 = "+$useCollectedFolderPermissionsOffice365)
    Out-LogFile -string "********************************************************************************"

    #Perform paramter validation manually.

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "ENTERING PARAMTER VALIDATION"
    Out-LogFile -string "********************************************************************************"

    #Test to ensure that if any of the aadConnect parameters are passed - they are passed together.

    Out-LogFile -string "Validating that both AADConnectServer and AADConnectCredential are specified"
   
    if (($aadConnectServer -eq "") -and ($aadConnectCredential -ne $null))
    {
        #The credential was specified but the server name was not.

        Out-LogFile -string "ERROR:  AAD Connect Server is required when specfying AAD Connect Credential" -isError:$TRUE
    }
    elseif (($aadConnectCredential -eq $NULL) -and ($aadConnectServer -ne ""))
    {
        #The server name was specified but the credential was not.

        Out-LogFile -string "ERROR:  AAD Connect Credential is required when specfying AAD Connect Server" -isError:$TRUE
    }
    elseif (($aadConnectCredential -ne $NULL) -and ($aadConnectServer -ne ""))
    {
        #The server name and credential were specified for AADConnect.

        Out-LogFile -string "AADConnectServer and AADConnectCredential were both specified." 
    }

    #Validate that both the exchange credential and exchange server are presented together.

    Out-LogFile -string "Validating that both ExchangeServer and ExchangeCredential are specified."

    if (($exchangeServer -eq "") -and ($exchangeCredential -ne $null))
    {
        #The exchange credential was specified but the exchange server was not specified.

        Out-LogFile -string "ERROR:  Exchange Server is required when specfying Exchange Credential." -isError:$TRUE
    }
    elseif (($exchangeCredential -eq $NULL) -and ($exchangeServer -ne ""))
    {
        #The exchange server was specified but the exchange credential was not.

        Out-LogFile -string "ERROR:  Exchange Credential is required when specfying Exchange Server." -isError:$TRUE
    }
    elseif (($exchangeCredential -ne $NULL) -and ($exchangetServer -ne ""))
    {
        #The server name and credential were specified for Exchange.

        Out-LogFile -string "The server name and credential were specified for Exchange."
    }
    else
    {
        Out-LogFile -string ("Neither Exchange Server or Exchange Credentials specified - retain useOnPremisesExchange FALSE - "+$useOnPremisesExchange)
    }

    #Validate that only one method of engaging exchange online was specified.

    Out-LogFile -string "Validating Exchange Online Credentials."

    if (($exchangeOnlineCredential -ne $NULL) -and ($exchangeOnlineCertificateThumbPrint -ne ""))
    {
        Out-LogFile -string "ERROR:  Only one method of cloud authentication can be specified.  Use either cloud credentials or cloud certificate thumbprint." -isError:$TRUE
    }
    elseif (($exchangeOnlineCredential -eq $NULL) -and ($exchangeOnlineCertificateThumbPrint -eq ""))
    {
        out-logfile -string "ERROR:  One permissions method to connect to Exchange Online must be specified." -isError:$TRUE
    }
    else
    {
        Out-LogFile -string "Only one method of Exchange Online authentication specified."
    }

    #Validate that all information for the certificate connection has been provieed.

    if (($exchangeOnlineCertificateThumbPrint -ne "") -and ($exchangeOnlineOrganizationName -eq "") -and ($exchangeOnlineAppID -eq ""))
    {
        out-logfile -string "The exchange organiztion name and application ID are required when using certificate thumbprint authentication to Exchange Online." -isError:$TRUE
    }
    elseif (($exchangeOnlineCertificateThumbPrint -ne "") -and ($exchangeOnlineOrganizationName -ne "") -and ($exchangeOnlineAppID -eq ""))
    {
        out-logfile -string "The exchange application ID is required when using certificate thumbprint authentication." -isError:$TRUE
    }
    elseif (($exchangeOnlineCertificateThumbPrint -ne "") -and ($exchangeOnlineOrganizationName -eq "") -and ($exchangeOnlineAppID -ne ""))
    {
        out-logfile -string "The exchange organization name is required when using certificate thumbprint authentication." -isError:$TRUE
    }
    else 
    {
        out-logfile -string "All components necessary for Exchange certificate thumbprint authentication were specified."    
    }

    #Validate that an OU was specified <if> retain group is not set to true.

    Out-LogFile -string "Validating that if retain original group is false a non-sync OU is specified."

    if (($retainOriginalGroup -eq $FALSE) -and ($dnNoSyncOU -eq "NotSet"))
    {
        out-LogFile -string "A no SYNC OU is required if retain original group is false." -isError:$TRUE
    }

    if (($useOnPremisesExchange -eq $False) -and ($enableHybridMailflow -eq $true))
    {
        out-logfile -string "Exchange on premsies information must be provided in order to enable hybrid mail flow." -isError:$TRUE
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

    if (($retainMailboxFolderPermsOffice365 -eq $TRUE) -and ($useCollectedFolderPermissionsOffice365 -eq $FALSE))
    {
        out-logfile -string "In order to retain folder permissions of migrated distribution lists the collection functions / files must first exist and be utilized." -isError:$TRUE
    }

    if (($retainOnPremMailboxFolderPermissions -eq $TRUE) -and ($useCollectedFolderPermissionsOnPrem -eq $FALSE))
    {
        out-logfile -string "In order to retain folder permissions of migrated distribution lists the collection functions / files must first exist and be utilized." -isError:$TRUE
    }

    out-logfile "Check to ensure that no more than 5 servers were specified."

    if ($serverNames.count -gt 5)
    {
        out-logfile -string "More than 5 servers were specified.  Use 5 or less servers." -isError:$TRUE
    }

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
                $testResults = test-wsman -computerName $server -authentication Default -credential $activeDirectoryCredential -errorAction STOP
            }
            catch{
                out-logfile -string "Unable to validate remote management enabled on host."
                out-logfile -string $server
                out-logfile -string $_ -isError:$TRUE
            }
        }
        else 
        {
            out-logfile -string ("Skipping testing of host running controoler: "+$server)    
        }
    }

    #For each machine in the server name array - we need to validate that the DLConversionV2 commands are available.

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
                $commands = invoke-command -scriptBlock {get-command -module DLConversionV2 -errorAction STOP} -computerName $server -credential $activeDirectoryCredential -errorAction STOP
                
                if ($commands.count -eq 0)
                {
                    out-logfile -string "Server "+$server+" does not have the DLConversionV2 module installed." -isError:$TRUE
                }
                else {
                    out-logfile -string "Server "+$server+" is ready."
                }
            }    
            catch{
                out-logfile -string "Unable to obtain DLConversionV2 commands." 
                out-logfile -string $_ -isError:$TRUE
            }
        }
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
    $jobOutput=$NULL

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

                Start-Job -InitializationScript {Import-Module DLConversionV2} -ScriptBlock { Start-DistributionListMigration -groupSMTPAddress $args[0] -globalCatalogServer $args[1] -activeDirectoryCredential $args[2] -logFolderPath $args[3] -aadConnectServer $args[4] -aadConnectCredential $args[5] -exchangeServer $args[6] -exchangeCredential $args[7] -exchangeOnlineCredential $args[8] -exchangeOnlineCertificateThumbPrint $args[9] -exchangeOnlineOrganizationName $args[10] -exchangeOnlineEnvironmentName $args[11] -exchangeOnlineAppID $args[12] -exchangeAuthenticationMethod $args[13] -retainOffice365Settings $args[14] -dnNoSyncOU $args[15] -retainOriginalGroup $args[16] -enableHybridMailflow $args[17] -groupTypeOverride $args[18] -triggerUpgradeToOffice365Group $args[19] -retainFullMailboxAccessOnPrem $args[20] -retainSendAsOnPrem $args[21] -retainMailboxFolderPermsOnPrem $args[22] -retainFullMailboxAccessOffice365 $args[23] -retainSendAsOffice365 $args[24] -retainMailboxFolderPermsOffice365 $args[25] -useCollectedFullMailboxAccessOnPrem $args[26] -useCollectedFullMailboxAccessOffice365 $args[27] -useCollectedSendAsOnPrem $args[28] -useCollectedFolderPermissionsOnPrem $args[29] -useCollectedFolderPermissionsOffice365 $args[30] -threadNumberAssigned $args[31] -totalThreadCount $args[32]} -ArgumentList $groupSMTPAddresses[$arrayLocation + $forCounter],$globalCatalogServer,$activeDirectoryCredential,$logFolderPath,$aadConnectServer,$aadConnectCredential,$exchangeServer,$exchangecredential,$exchangeOnlineCredential,$exchangeOnlineCertificateThumbPrint,$exchangeOnlineOrganizationName,$exchangeOnlineEnvironmentName,$exchangeOnlineAppID,$exchangeAuthenticationMethod,$retainOffice365Settings,$dnNoSyncOU,$retainOriginalGroup,$enableHybridMailflow,$groupTypeOverride,$triggerUpgradeToOffice365Group,$retainFullMailboxAccessOnPrem,$retainSendAsOnPrem,$retainMailboxFolderPermsOnPrem,$retainFullMailboxAccessOffice365,$retainSendAsOffice365,$retainMailboxFolderPermsOffice365,$useCollectedFolderPermissionsOnPrem,$useCollectedFullMailboxAccessOffice365,$useCollectedSendAsOnPrem,$useCollectedFolderPermissionsOnPrem,$useCollectedFolderPermissionsOffice365,$forThread,$loopThreadCount

                if ($forCounter -eq 0)
                {
                    start-sleepProgress -sleepString "Sleeping after job provioning." -sleepSeconds 5

                }
            }

            #We cannot allow the next batch to be processed - until the current batch has no running threads.

            do 
            {
                out-logfile -string "Jobs are not yet completed in this batch."

                $loopJobs = get-job -state Running

                out-logfile -string ("Number of jobs that are running = "+$loopJobs.count.tostring())

                foreach ($job in $loopJobs)
                {
                    out-logfile -string ("Job ID: "+$job.id+" State: "+$job.state+" Job Command: "+$job.command)
                }

                start-sleepProgress -sleepString "Sleeping waiting on job completion." -sleepSeconds 30


            } until ((get-job -State Running).count -eq 0)

            #Increment the array location +5 since this loop processed 5 jobs.

            $arrayLocation=$arrayLocation+$maxThreadCount

            out-logfile -string ("The array location is = "+$arrayLocation)

            #Remove all completed jobs at this time.

            $loopJobs = get-job

            foreach ($job in $loopJobs)
            {
                out-logfile -string ("Job ID: "+$job.id+" State: "+$job.state+" Job Command: "+$job.command)
            }

            out-logfile -string "Removing all completed jobs."

            get-job | remove-job    
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

                Start-Job -InitializationScript {DLConversionV2} -ScriptBlock { Start-DistributionListMigration -groupSMTPAddress $args[0] -globalCatalogServer $args[1] -activeDirectoryCredential $args[2] -logFolderPath $args[3] -aadConnectServer $args[4] -aadConnectCredential $args[5] -exchangeServer $args[6] -exchangeCredential $args[7] -exchangeOnlineCredential $args[8] -exchangeOnlineCertificateThumbPrint $args[9] -exchangeOnlineOrganizationName $args[10] -exchangeOnlineEnvironmentName $args[11] -exchangeOnlineAppID $args[12] -exchangeAuthenticationMethod $args[13] -retainOffice365Settings $args[14] -dnNoSyncOU $args[15] -retainOriginalGroup $args[16] -enableHybridMailflow $args[17] -groupTypeOverride $args[18] -triggerUpgradeToOffice365Group $args[19] -retainFullMailboxAccessOnPrem $args[20] -retainSendAsOnPrem $args[21] -retainMailboxFolderPermsOnPrem $args[22] -retainFullMailboxAccessOffice365 $args[23] -retainSendAsOffice365 $args[24] -retainMailboxFolderPermsOffice365 $args[25] -useCollectedFullMailboxAccessOnPrem $args[26] -useCollectedFullMailboxAccessOffice365 $args[27] -useCollectedSendAsOnPrem $args[28] -useCollectedFolderPermissionsOnPrem $args[29] -useCollectedFolderPermissionsOffice365 $args[30] -threadNumberAssigned $args[31] -totalThreadCount $args[32]} -ArgumentList $groupSMTPAddresses[$arrayLocation + $forCounter],$globalCatalogServer,$activeDirectoryCredential,$logFolderPath,$aadConnectServer,$aadConnectCredential,$exchangeServer,$exchangecredential,$exchangeOnlineCredential,$exchangeOnlineCertificateThumbPrint,$exchangeOnlineOrganizationName,$exchangeOnlineEnvironmentName,$exchangeOnlineAppID,$exchangeAuthenticationMethod,$retainOffice365Settings,$dnNoSyncOU,$retainOriginalGroup,$enableHybridMailflow,$groupTypeOverride,$triggerUpgradeToOffice365Group,$retainFullMailboxAccessOnPrem,$retainSendAsOnPrem,$retainMailboxFolderPermsOnPrem,$retainFullMailboxAccessOffice365,$retainSendAsOffice365,$retainMailboxFolderPermsOffice365,$useCollectedFolderPermissionsOnPrem,$useCollectedFullMailboxAccessOffice365,$useCollectedSendAsOnPrem,$useCollectedFolderPermissionsOnPrem,$useCollectedFolderPermissionsOffice365,$forThread,$loopThreadCount

                if ($forCounter -eq 0)
                {
                    start-sleepProgress -sleepString "Sleeping after job creation." -sleepSeconds 30

                }
            }

            #We cannot allow the next batch to be processed - until the current batch has no running threads.

            do 
            {
                out-logfile -string "Jobs are not yet completed in this batch."

                $loopJobs = get-job -state Running

                out-logfile -string ("Number of jobs that are running = "+$loopJobs.count.tostring())

                foreach ($job in $loopJobs)
                {
                    out-logfile -string ("Job ID: "+$job.id+" State: "+$job.state+" Job Command: "+$job.command)
                }

                start-sleepProgress -sleepString "Sleeping pending job status." -sleepSeconds 5

            } until ((get-job -State Running).count -eq 0)

            out-logfile -string ("The array location is = "+$arrayLocation)

            #Remove all completed jobs at this time.

            $loopJobs = get-job -state Completed

            foreach ($job in $loopJobs)
            {
                $jobOutput+=(get-job -id $job.id).childjobs.output
                out-logfile -string ("Job ID: "+$job.id+" State: "+$job.state+" Job Command: "+$job.command)
            }

            out-logfile -string "Removing all completed jobs."

            get-job | remove-job    

            $arrayLocation=$arrayLocation+$remainingAddresses
        }
    } until ($arrayLocation -eq $totalAddressCount)

    Out-LogFile -string "================================================================================"
    Out-LogFile -string "END START-DISTRIBUTIONLISTMIGRATION"
    Out-LogFile -string "================================================================================"
}
