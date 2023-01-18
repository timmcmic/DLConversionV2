
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


Function Convert-Office365DLtoUnifiedGroup
{
    <#
    .SYNOPSIS

    This is the trigger function that begins the process of allowing an administrator to migrate a distribution list from
    on premises to Office 365.

    .DESCRIPTION

    Trigger function.

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

    .PARAMETER AADCONNECTSERVER

    *OPTIONAL*
    This parameter specifies the FQDN of the Azure Active Directory Connect Server.
    When specified the server is utilized to trigger delta syncs to provide timely migrations.
    If not specified the script will wait for standard sync cycles to run.

    .PARAMETER AADCONNECTCREDENTIAL

    *OPTIONAL*
    *MANDATORY with AADConnectServer specified*
    This parameter specifies the credentials used to connect to the AADConnect server.
    The account specified must be a member of the local administrators sync group of the AADConnect Server

    .PARAMETER EXCHANGESERVER

    *OPTIONAL*
    *REQUIRED with enableHybridMailFlow:TRUE*
    This parameter specifies that local Exchange on premises installation utilized for hybrid mail flow enablement.
    Exchange server is no required for migrations unlss enable hyrbid mail flow is required.

    .PARAMETER EXCHANGECREDENTIAL

    *OPTIONAL*
    *REQUIRED with ExchangeServer specified*
    This is the credential utilized to connect to the Exchange server remote powershell instance.
    Exchange Organization Adminitrator rights are recommended.

    .PARAMETER EXCHANGEAUTHENTICATIONMETHOD

    *OPTIONAL*
    *DEFAULT:  BASIC*
    This specifies the authentication method for the Exchage on-premsies remote powershell session.

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

    .PARAMETER doNoSyncOU

    *REQUIRED*
    This is the organizational unit configured in Azure AD Connect to not sync.
    This is utilize for temporary group storage to process the deletion of the group from Office 365.

    .PARAMETER RETAINORIGINALGROUP

    *OPTIONAL*
    By default the original group is retained, mail disabled, and renamed with an !.
    If the group should be deleted post migration set this value to TRUE.

    .PARAMETER ENBABLEHYBRIDMAILFLOW

    *OPTIONAL*
    *REQUIRES use of ExchangeServer and ExchangeCredential*
    This option enables mail flow objects in the on-premises Active Directory post migration.
    This supports relay scenarios through the onpremises Exchange organization.

    .PARAMETER OVERRIDECENTRALIZEDMAILTRANSPORTENABLED

    *OPTIONAL*
    If centralied transport enabled is detected during migration this switch is required.
    This is an administrator acknowledgement that emails may flow externally in certain mail flow scenarios for migrated groups.

    .PARAMETER ALLOWNONSYNCEDGROUP

    *OPTIONAL*
    Allows for on-premises group creation in Office 365 from forests that are not directory syncrhonized for some reason.

    .PARAMETER USECOLLECTEDFULLMAILBOXACCESSONPREM

    *OPTIONAL*
    *Requires us of start-collectOnPremFullMailboxAccess*
    This switch will import pre-collected full mailbox access data for the on premises organization and detect permissions for migrated DLs.

    .PARAMETER USECOLLECTEDFULLMAILBOXACCESSOFFICE365

    *OPTIONAL*
    *Requires use of start-collectOffice365FullMailboxAccess
    THis switch will import pre-collected full mailbox access data from the Office 365 organiation and detect permissions for migrated DLs.

    .PARAMETER USERCOLLECTEDSENDASONPREM

    *OPTIONAL*
    *Requires use of start-collectOnPremSendAs*
    This switch will import pre-collected send as data from the on premsies Exchange organization and detect dependencies on the migrated DLs.

    .PARAMETER USECOLLECTEDFOLDERPERMISSIONSONPREM

    *OPTIONAL*
    *Requires use of start-collectOnPremMailboxFolderPermissions*
    This switch will import pre-collected mailbox folder permissions for any default or user created folders within mailboxes.
    The data is searched to discover any dependencies on the migrated DL.

    .PARAMETER USECOLLECTEDFOLDERPERMISSIONSOFFICE365

    *OPTIONAL*
    *Requires use of start-collectOffice365MailboxFolderPermissions*
    This switch will import pre-collected mailbox folder permissions for any default or user created folders within mailboxes.
    The data is searched to discover any dependencies on the migrated DL.

    .PARAMETER THREADNUMBERASSIGNED

    *RESERVED*

    .PARAMETER TOTALTHREADCOUNT

    *RESERVED*

    .PARAMETER ISMULTIMACHINE

    *RESERVED*

    .PARAMETER REMOTEDRIVELETTER

    *RESERVED*

	.OUTPUTS

    Logs all activities and backs up all original data to the log folder directory.
    Moves the distribution group from on premieses source of authority to office 365 source of authority.

    .NOTES

    The following blog posts maintain documentation regarding this module.

    https://timmcmic.wordpress.com/2023/01/08/office-365-distribution-list-migration-version-2-0/

    .EXAMPLE

    Start-Office365GroupMigration -groupSMTPAddress $groupSMTPAddress -globalCatalogServer server.domain.com -activeDirectoryCredential $cred -logfolderpath c:\temp -dnNoSyncOU "OU" -exchangeOnlineCredential $cred -azureADCredential $cred

    .EXAMPLE

    Start-Office365GroupMigration -groupSMTPAddress $groupSMTPAddress -globalCatalogServer server.domain.com -activeDirectoryCredential $cred -logfolderpath c:\temp -dnNoSyncOU "OU" -exchangeOnlineCredential $cred -azureADCredential $cred -enableHybridMailFlow:$TRUE -triggerUpgradeToOffice365Group:$TRUE

    .EXAMPLE

    Start-Office365GroupMigration -groupSMTPAddress $groupSMTPAddress -globalCatalogServer server.domain.com -activeDirectoryCredential $cred -logfolderpath c:\temp -dnNoSyncOU "OU" -exchangeOnlineCredential $cred -azureADCredential $cred -enableHybridMailFlow:$TRUE -triggerUpgradeToOffice365Group:$TRUE -useCollectedOnPremMailboxFolderPermissions:$TRUE -useCollectedOffice365MailboxFolderPermissions:$TRUE -useCollectedOnPremSendAs:$TRUE -useCollectedOnPremFullMailboxAccess:$TRUE -useCollectedOffice365FullMailboxAccess:$TRUE

    #>

    [cmdletbinding()]

    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$groupSMTPAddress,
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
        #Defining optional parameters for retention and upgrade
        #Definte parameters for pre-collected permissions
        [Parameter(Mandatory = $false)]
        [boolean]$useCollectedFullMailboxAccessOffice365=$FALSE,
        [Parameter(Mandatory = $false)]
        [boolean]$useCollectedFolderPermissionsOnPrem=$FALSE,
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
        [boolean]$allowDetailedTelemetryCollection=$TRUE,
        [Parameter(Mandatory =$FALSE)]
        [boolean]$isHealthCheck=$FALSE
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
    $telemetryActiveDirectoryVersion = $NULL
    $telemetryOSVersion = (Get-CimInstance Win32_OperatingSystem).version
    $telemetryStartTime = get-universalDateTime
    $telemetryEndTime = $NULL
    [double]$telemetryElapsedSeconds = 0
    $telemetryEventName = "Start-Office365GroupMigration"
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


    $windowTitle = ("Start-Office365GroupMigration "+$groupSMTPAddress)
    $host.ui.RawUI.WindowTitle = $windowTitle

     #Define the status directory.

     [string]$global:statusPath="\Status\"
     [string]$global:fullStatusPath=$NULL
     [int]$statusFileCount=0

    #Define global variables.

    $global:threadNumber=$threadNumberAssigned

    if ($isHealthCheck -eq $FALSE)
    {
        $global:logFile=$NULL #This is the global variable for the calculated log file name
        [string]$global:staticFolderName="\DLMigration\"
        [string]$global:staticAuditFolderName="\AuditData\"
        [string]$global:importFile=$logFolderPath+$global:staticAuditFolderName
    }

    #Define variables for import data - used for importing data into pre-collect.

    [array]$importData=@() #Empty array for the import data.
    [string]$importFilePath=$NULL #Import file path where the XML data is located to import (calculated later)

    if ($isMultiMachine -eq $TRUE)
    {
        try{
            #At this point we know that multiple machines was in use.
            #For multiple machines - the local controller instance mapped the drive Z for us in windows.
            #Therefore we override the original log folder path passed in and just use Z.

            [string]$networkName=$remoteDriveLetter
            $logFolderPath = $networkName+":"
        }
        catch{
            exit
        }
    }

    #Define the nested groups csv.

    [string]$nestedGroupCSV = "nestedGroups.csv"
    [string]$nestedGroupException = "*NestedGroupException*"
    [string]$nestedCSVPath = $logFolderPath+"\"+$nestedGroupCSV

    if ($isHealthCheck -eq $FALSE)
    {
        #Define the sub folders for multi-threading.

        [array]$threadFolder="\Thread0","\Thread1","\Thread2","\Thread3","\Thread4","\Thread5","\Thread6","\Thread7","\Thread8","\Thread9","\Thread10"

        #If multi threaded - the log directory needs to be created for each thread.
        #Create the log folder path for status before changing the log folder path.

        if ($totalThreadCount -gt 0)
        {
            new-statusFile -logFolderPath $logFolderPath

            $logFolderPath=$logFolderPath+$threadFolder[$global:threadNumber]
        }
    }
    

    #For mailbox folder permissions set these to false.
    #Supported methods for gathering folder permissions require use of the pre-collection.
    #Precolletion automatically sets these to true.  These were origianlly added to support doing it at runtime - but its too slow.
    
    [boolean]$retainMailboxFolderPermsOffice365=$FALSE
    [boolean]$retainOffice365Settings=$true
    [boolean]$retainFullMailboxAccessOffice365=$FALSE
    [boolean]$retainSendAsOffice365=$TRUE

    #Define variables utilized in the core function that are not defined by parameters.

    $coreVariables = @{ 
        exchangeOnlinePowershellModuleName = @{ "Value" = "ExchangeOnlineManagement" ; "Description" = "Static Exchange Online powershell module name" }
        azureActiveDirectoryPowershellModuleName = @{ "Value" = "AzureAD" ; "Description" = "Static azure active directory powershell module name" }
        dlConversionPowershellModule = @{ "Value" = "DLConversionV2" ; "Description" = "Static dlConversionv2 powershell module name" }
    }

    #The variables below are utilized to define working parameter sets.
    #Some variables are assigned to single values - since these will be utilized with functions that query or set information.

    #Define the Office 365 attributes that will be used for filters.

    $office365Attributes  = @{ 
        office365AcceptMessagesFrom = @{ "Value" = "AcceptMessagesOnlyFromDLMembers" ; "Description" = "All Office 365 objects that have accept messages from senders or members for the migrated group"}
        office365BypassModerationFrom = @{ "Value" = "BypassModerationFromDLMembers" ; "Description" = "All Office 365 objects that have bypass moderation from senders or members for the migrated group"}
        office365CoManagers = @{ "Value" = "CoManagedBy" ; "Description" = "ALl office 365 objects that have managed by set for the migrated group"}
        office365GrantSendOnBehalfTo = @{ "Value" = "GrantSendOnBehalfTo" ; "Description" = "All Office 365 objects that have grant sent on behalf to for the migrated group"}
        office365ManagedBy = @{ "Value" = "ManagedBy" ; "Description" = "All Office 365 objects that have managed by set on the group"}
        office365Members = @{ "Value" = "Members" ; "Description" = "All Office 365 groups that the migrated group is a member of"}
        office365RejectMessagesFrom = @{ "Value" = "RejectMessagesFromDLMembers" ; "Description" = "All Office 365 groups that have the reject messages from senders or members right assignged to the migrated group"}
        office365ForwardingAddress = @{ "Value" = "ForwardingAddress" ; "Description" = "All Office 365 objects that have the migrated group set for forwarding"}
        office365BypassModerationusers = @{ "Value" = "BypassModerationFromSendersOrMembers" ; "Description" = "All Office 365 objects that have bypass moderation for the migrated group"}
        office365UnifiedAccept = @{ "Value" = "AcceptMessagesOnlyFromSendersOrMembers" ; "Description" = "All Office 365 Unified Groups that the migrated group has accept messages from senders or members rights assigned"}
        office365UnifiedReject = @{ "Value" = "RejectMessagesFromSendersOrMembers" ; "Description" = "All Office 365 Unified Groups that the migrated group has reject messages from senders or members rights assigned"}
    }

    #Define XML files to contain backups.

    $xmlFiles = @{
        originalDLConfigurationADXML = @{ "Value" =  "originalDLConfigurationADXML" ; "Description" = "XML file that exports the original DL configuration"}
        originalDLConfigurationUpdatedXML = @{ "Value" =  "originalDLConfigurationUpdatedXML" ; "Description" = "XML file that exports the updated DL configuration"}
        office365DLConfigurationXML = @{ "Value" =  "office365DLConfigurationXML" ; "Description" = "XML file that exports the Office 365 DL configuration"}
        office365DLConfigurationPostMigrationXML = @{ "Value" =  "office365DLConfigurationPostMigrationXML" ; "Description" = "XML file that exports the Office 365 DL configuration post migration"}
        office365DLMembershipPostMigrationXML = @{ "Value" =  "office365DLMembershipPostMigrationXML" ; "Description" = "XML file that exports the Office 365 DL membership post migration"}
        office365DLOwnersPostMigrationXML = @{ "Value" =  "office365DLOwnersPostMigrationXML" ; "Description" = "XML file that exports the Office 365 DL owners post migration"}
        office365DLSubscribersPostMigrationXML = @{ "Value" =  "office365DLSubscribersPostMigrationXML" ; "Description" = "XML file that exports the Office 365 DL owners post migration"}
        exchangeDLMembershipSMTPXML = @{ "Value" =  "exchangeDLMemberShipSMTPXML" ; "Description" = "XML file that holds the SMTP addresses of the on premises DL membership"}
        exchangeRejectMessagesSMTPXML = @{ "Value" =  "exchangeRejectMessagesSMTPXML" ; "Description" = "XML file that holds the Reject Messages From Senders or Members property of the on premises DL"}
        exchangeAcceptMessagesSMTPXML = @{ "Value" =  "exchangeAcceptMessagesSMTPXML" ; "Description" = "XML file that holds the Accept Messages from Senders or Members property of the on premises DL"}
        exchangeManagedBySMTPXML = @{ "Value" =  "exchangeManagedBySMTPXML" ; "Description" = "XML file that holds the ManagedBy proprty of the on premises DL"}
        exchangeModeratedBySMTPXML = @{ "Value" =  "exchangeModeratedBYSMTPXML" ; "Description" = "XML file that holds the Moderated By property of the on premises DL"}
        exchangeBypassModerationSMTPXML = @{ "Value" =  "exchangeBypassModerationSMTPXML" ; "Description" = "XML file that holds the Bypass Moderation From Senders or Members property of the on premises DL"}
        exchangeGrantSendOnBehalfToSMTPXML = @{ "Value" =  "exchangeGrantSendOnBehalfToXML" ; "Description" = "XML file that holds the Grant Send On Behalf To property of the on premises DL"}
        exchangeSendAsSMTPXML = @{ "Value" =  "exchangeSendASSMTPXML" ; "Description" = "XML file that holds the Send As rights of the on premises DL"}
        allOffice365MemberOfXML= @{ "Value" = "allOffice365MemberOfXML" ; "Description" = "XML file that holds All cloud only groups that have the migrated group as a member"}
        allOffice365AcceptXML= @{ "Value" = "allOffice365AcceptXML" ; "Description" = "XML file that holds All cloud only groups that have the migrated group assigned accept messages from senders or members rights"}
        allOffice365RejectXML= @{ "Value" = "allOffice365RejectXML" ; "Description" = "XML file that holds All cloud only groups that have the migrated group assigned reject messages from senders or members rights"}
        allOffice365BypassModerationXML= @{ "Value" = "allOffice365BypassModerationXML" ; "Description" = "XML file that holds All cloud only groups that have the migrated group assigned bypass moderation from senders or members"}
        allOffice365GrantSendOnBehalfToXML= @{ "Value" = "allOffice365GrantSentOnBehalfToXML" ; "Description" = "XML file that holds All cloud only groups that have the migrated group assigned grant send on behalf to rights"}
        allOffice365ManagedByXML= @{ "Value" = "allOffice365ManagedByXML" ; "Description" = "XML file that holds All cloud only groups that have the migrated group assigned managed by rights"}
        allOffice365ForwardingAddressXML= @{ "Value" = "allOffice365ForwardingAddressXML" ; "Description" = " XML file that holds all cloud only recipients where forwarding is set to the migrated grouop"}
        allOffic365SendAsAccessXML = @{ "Value" =  "allOffice365SendAsAccessXML" ; "Description" = "XML file that holds all cloud groups where send as rights are assigned to the migrated group"}
        allOffice365FullMailboxAccessXML = @{ "Value" =  "allOffice365FullMailboxAccessXML" ; "Description" = "XML file that holds all cloud only objects where full mailbox access is assigned to the migrated group"}
        allOffice365MailboxesFolderPermissionsXML = @{ "Value" =  'allOffice365MailboxesFolderPermissionsXML' ; "Description" = "XML file that holds all cloud only recipients where a mailbox folder permission is assigned to the migrated group"}
        allOffice365SendAsAccessOnGroupXML = @{ "Value" =  'allOffice365SendAsAccessOnGroupXML' ; "Description" = "XML file that holds all cloud only send as rights assigned to the migrated group"}
        retainOffice365RecipientFullMailboxAccessXML= @{ "Value" = "office365RecipientFullMailboxAccess.xml" ; "Description" = "Import XML file for pre-gathered full mailbox access rights in Office 365"}
        retainMailboxFolderPermsOffice365XML= @{ "Value" = "office365MailboxFolderPermissions.xml" ; "Description" = "Import XML file for pre-gathered mailbox folder permissions in Office 365"}
        azureDLConfigurationXML = @{"Value" = "azureADDL" ; "Description" = "Export XML file holding the configuration from azure active directory"}
        preCreateErrorsXML = @{"value" = "preCreateErrors" ; "Description" = "Export XML of all precreate errors for group to be migrated."}
        testOffice365ErrorsXML = @{"value" = "testOffice365Errors" ; "Description" = "Export XML of all tested recipient errors in Offic3 365."}
    }

    #On premises variables for the distribution list to be migrated.

    $originalDLConfiguration=$NULL #This holds the on premises DL configuration for the group to be migrated.
    $originalAzureADConfiguration=$NULL #This holds the azure ad DL configuration
    [array]$exchangeDLMembershipSMTP=@() #Array of DL membership from AD.
    [array]$exchangeRejectMessagesSMTP=@() #Array of members with reject permissions from AD.
    [array]$exchangeAcceptMessagesSMTP=@() #Array of members with accept permissions from AD.
    [array]$exchangeManagedBySMTP=@() #Array of members with manage by rights from AD.
    [array]$exchangeModeratedBySMTP=@() #Array of members  with moderation rights.
    [array]$exchangeBypassModerationSMTP=@() #Array of objects with bypass moderation rights from AD.
    [array]$exchangeGrantSendOnBehalfToSMTP=@() #Array of objects with grant send on behalf to normalized SMTP
    [array]$exchangeSendAsSMTP=@() #Array of objects wtih send as rights normalized SMTP
    [array]$exchangeDLSubscribersSMTP=@() #Array of objects that are subscribers to the DL.


    #The following variables hold information regarding Office 365 objects that have dependencies on the migrated DL.

    [array]$allOffice365MemberOf=$NULL #All cloud only groups the migrated group is a member of.
    [array]$allOffice365Accept=$NULL #All cloud only groups the migrated group has accept messages from senders or members.
    [array]$allOffice365Reject=$NULL #All cloud only groups the migrated group has reject messages from senders or members.
    [array]$allOffice365BypassModeration=$NULL #All cloud only groups the migrated group has bypass moderation from senders or members.
    [array]$allOffice365ManagedBy=$NULL #All cloud only groups the migrated group has managed by rights on.
    [array]$allOffice365GrantSendOnBehalfTo=$NULL #All cloud only groups the migrated group has grant send on behalf to on.
    [array]$allOffice365ForwardingAddress=$NULL #All cloud only recipients the migrated group has forwarding address 
    [array]$allOffice365FullMailboxAccess=$NULL #All cloud only recipients the migrated group has full ,amilbox access on.
    [array]$allOffice365SendAsAccess=$NULL #All cloud only groups the migrated group has send as access on.
    [array]$allOffice365SendAsAccessOnGroup = $NULL #All send as permissions set on the on premises group that are set in the cloud.
    [array]$allOffice365MailboxFolderPermissions=$NULL #All cloud only groups the migrated group has mailbox folder permissions on.
    [array]$allObjectsSendAsAccessNormalized=@() #This array will be empty.  Reused code requires it be present / set with no values.
    
    #Cloud variables for the distribution list to be migrated.

    $office365DLConfiguration = $NULL #This holds the office 365 DL configuration for the group to be migrated.
    $azureADDlConfiguration = $NULL #This holds the Azure AD DL configuration
    $office365DLConfigurationPostMigration = $NULL #This hold the Office 365 DL configuration post migration.
    $office365DLMembership = @()
    $office365DLMembershipPostMigration=$NULL #This holds the Office 365 DL membership information post migration
    $office365DLOwnersPostMigration=$NULL #This holds the Office 365 DL owners information post migration.
    $office365DLSubscribersPostMigration=$NULL #This holds the Office 365 DL subscribers information post migration

    #For loop counter.

    [int]$forLoopCounter=0

    #Define new arrays to check for errors instead of failing.

    [array]$global:preCreateErrors=@()
    [array]$global:testOffice365Errors=@()
    [array]$global:postCreateErrors=@()
    [array]$onPremReplaceErrors=@()
    [array]$office365ReplaceErrors=@()
    [array]$global:office365ReplacePermissionsErrors=@()
    [array]$global:onPremReplacePermissionsErrors=@()
    [array]$generalErrors=@()
    [string]$isTestError="No"


    [int]$forLoopTrigger=1000
    [int]$createMailContactDelay=5

    [boolean]$allowNonSyncedGroup = $FALSE

    #Ensure that no status files exist at the start of the run.

    if ($isHealthCheck -eq $FALSE)
    {
        if ($totalThreadCount -gt 0)
        {
            if ($global:threadNumber -eq 1)
            {
                remove-statusFiles -fullCleanup:$TRUE
            }
        }
    }

    #Log start of DL migration to the log file.

    if ($isHealthCheck -eq $FALSE)
    {
        new-LogFile -groupSMTPAddress $groupSMTPAddress.trim() -logFolderPath $logFolderPath
    }

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
    Out-LogFile -string "BEGIN Start-Office365GroupMigration"
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
    
    if ($azureTenantID -ne $NULL)
    {
        $azureTenantID = remove-StringSpace -stringToFix $azureTenantID
    }

    if ($azureCertificateThumbprint -ne $NULL)
    {
        $azureCertificateThumbprint = remove-StringSpace -stringToFix $azureCertificateThumbPrint
    }

    if ($azureEnvironmentName -ne $NULL)
    {
        $azureEnvironmentName = remove-StringSpace -stringToFix $azureEnvironmentName
    }

    if ($azureApplicationID -ne $NULL)
    {
        $azureApplicationID = remove-stringSpace -stringToFix $azureApplicationID
    }

    if ($exchangeOnlineCredential -ne $null)
    {
        Out-LogFile -string ("ExchangeOnlineUserName = "+ $exchangeOnlineCredential.UserName.toString())
    }

    if ($azureADCredential -ne $NULL)
    {
        out-logfile -string ("AzureADUserName = "+$azureADCredential.userName.toString())
    }

    Out-LogFile -string "********************************************************************************"

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string " RECORD VARIABLES"
    Out-LogFile -string "********************************************************************************"

    out-logfile -string ("Predefined thread folders = ")

    foreach ($property in $threadFolder)
    {
        out-logfile -string $property
    }

    out-logfile -string ("Global import file: "+$global:importFile)
    out-logfile -string ("Global staticFolderName: "+$global:staticFolderName)
    out-logfile -string ("Global threadNumber: "+$global:threadNumber)

    write-hashTable -hashTable $xmlFiles
    write-hashTable -hashTable $office365Attributes
    write-hashTable -hashTable $coreVariables
    
    Out-LogFile -string "********************************************************************************"

    #Perform paramter validation manually.

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "ENTERING PARAMTER VALIDATION"
    Out-LogFile -string "********************************************************************************"

    #Validate that only one method of engaging exchange online was specified.

    Out-LogFile -string "Validating Exchange Online Credentials."

    start-parameterValidation -exchangeOnlineCredential $exchangeOnlineCredential -exchangeOnlineCertificateThumbprint $exchangeOnlineCertificateThumbprint

    #Validating that all portions for exchange certificate auth are present.

    out-logfile -string "Validating parameters for Exchange Online Certificate Authentication"

    start-parametervalidation -exchangeOnlineCertificateThumbPrint $exchangeOnlineCertificateThumbprint -exchangeOnlineOrganizationName $exchangeOnlineOrganizationName -exchangeOnlineAppID $exchangeOnlineAppID

    #Validate that only one method of engaging exchange online was specified.

    Out-LogFile -string "Validating Azure AD Credentials."

    start-parameterValidation -azureADCredential $azureADCredential -azureCertificateThumbPrint $azureCertificateThumbprint

    #Validate that all information for the certificate connection has been provieed.

    out-logfile -string "Validation all components available for AzureAD Cert Authentication"

    start-parameterValidation -azureCertificateThumbPrint $azureCertificateThumbprint -azureTenantID $azureTenantID -azureApplicationID $azureApplicationID

    #exit #Debug exit.

    #Evaluate if administrators have selected to retain Office 365 permissions from files.

    if ($useCollectedFullMailboxAccessOffice365 -eq $TRUE)
    {
        $retainFullMailboxAccessOffice365=$TRUE
    }

    if ($useCollectedFolderPermissionsOffice365 -eq $TRUE)
    {
        $retainMailboxFolderPermsOffice365=$TRUE
    }

    Out-LogFile -string "END PARAMETER VALIDATION"
    Out-LogFile -string "********************************************************************************"

    # EXIT #Debug Exit

    #If exchange server information specified - create the on premises powershell session.

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "ESTABLISH POWERSHELL SESSIONS"
    Out-LogFile -string "********************************************************************************"

   #Test to determine if the exchange online powershell module is installed.
   #The exchange online session has to be established first or the commandlet set from on premises fails.

   Out-LogFile -string "Calling Test-PowerShellModule to validate the Exchange Module is installed."

   $telemetryExchangeOnlineVersion = Test-PowershellModule -powershellModuleName $corevariables.exchangeOnlinePowershellModuleName.value -powershellVersionTest:$TRUE

   out-logfile -string "Calling Test-PowershellModule to validate the DL Conversion Module version installed."

   $telemetryDLConversionV2Version = Test-PowershellModule -powershellModuleName $corevariables.dlConversionPowershellModule.value -powershellVersionTest:$TRUE

   out-logfile -string "Calling Test-PowershellModule to validate the AzureAD Powershell Module version installed."

   $telemetryAzureADVersion = Test-PowershellModule -powershellModuleName $corevariables.azureActiveDirectoryPowershellModuleName.value -powershellVersionTest:$TRUE

   #Create the azure ad connection

   Out-LogFile -string "Calling nea-AzureADPowershellSession to create new connection to azure active directory."

   if ($azureADCredential -ne $NULL)
   {
      #User specified non-certifate authentication credentials.

        try {
            New-AzureADPowershellSession -azureADCredential $azureADCredential -azureEnvironmentName $azureEnvironmentName
        }
        catch {
            out-logfile -string "Unable to create the Azure AD powershell session using credentials."
            out-logfile -string $_ -isError:$TRUE
        }
   }
   elseif ($azureCertificateThumbprint -ne "")
   {
      #User specified thumbprint authentication.

        try {
            new-AzureADPowershellSession -azureCertificateThumbprint $azureCertificateThumbprint -azureApplicationID $azureApplicationID -azureTenantID $azureTenantID -azureEnvironmentName $azureEnvironmentName
        }
        catch {
            out-logfile -string "Unable to create the exchange online connection using certificate."
            out-logfile -string $_ -isError:$TRUE
        }
   }

   #exit #Debug Exit

   #Create the connection to exchange online.

   Out-LogFile -string "Calling New-ExchangeOnlinePowershellSession to create session to office 365."

   if ($exchangeOnlineCredential -ne $NULL)
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

   #exit #debug exit    

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END ESTABLISH POWERSHELL SESSIONS"
    Out-LogFile -string "********************************************************************************"

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "BEGIN GET ORIGINAL DL CONFIGURATION LOCAL AND CLOUD"
    Out-LogFile -string "********************************************************************************"

    #exit #Debug Exit

    Out-LogFile -string "Capture the original office 365 distribution list information."

    try 
    {
        $office365DLConfiguration=Get-O365DLConfiguration -groupSMTPAddress $groupSMTPAddress -errorAction STOP
    }
    catch 
    {
        out-logFile -string $_ -isError:$TRUE
    }
            
    Out-LogFile -string $office365DLConfiguration

    Out-LogFile -string "Create an XML file backup of the office 365 DL configuration."

    Out-XMLFile -itemToExport $office365DLConfiguration -itemNameToExport $xmlFiles.office365DLConfigurationXML.value

    out-logfile -string "Capture the original Azure AD distribution list information"

    try{
        $azureADDLConfiguration = get-AzureADDLConfiguration -office365DLConfiguration $office365DLConfiguration
    }
    catch{
        out-logfile -string $_
        out-logfile -string "Unable to obtain Azure Active Directory DL Configuration"
    }

    if ($azureAADLConfiguration -ne $NULL)
    {
        out-logfile -string $azureADDLConfiguration

        out-logfile -string "Create an XML file backup of the Azure AD DL Configuration"

        out-xmlFile -itemToExport $azureADDLConfiguration -itemNameToExport $xmlFiles.azureDLConfigurationXML.value
    }

    Invoke-Office365SafetyCheck -o365dlconfiguration $office365DLConfiguration -azureADDLConfiguration $azureADDLConfiguration -isCloudOnly $TRUE -errorAction STOP

    out-logfile -string "Convert Office 365 DL configuration to orignal DL configuration for function reuse."

    try
    {
        $originalDLConfiguration = convert-O365DLSettingsToOnPremSettings -office365DLConfiguration $office365DLConfiguration -errorAction STOP
    }
    catch
    {
        out-lofile -string "Unable to convert the cloud DL settings to on premises settings for code reuse."
        out-logfile -string $_ -isError:$TRUE
    }

    Out-LogFile -string "Log original DL configuration."
    out-logFile -string $originalDLConfiguration

    Out-LogFile -string "Create an XML file backup of the on premises DL Configuration coverted from Office 365 values."

    Out-XMLFile -itemToExport $originalDLConfiguration -itemNameToExport $xmlFiles.originalDLConfigurationADXML.value

    #exit 

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END GET ORIGINAL DL CONFIGURATION LOCAL AND CLOUD"
    Out-LogFile -string "********************************************************************************"

    #At this time we have the DL configuration on both sides and have checked to ensure it is dir synced.
    #Membership of attributes is via DN - these need to be normalized to SMTP addresses in order to find users in Office 365.

    #Start with DL membership and normallize.

    $telemetryFunctionStartTime = get-universalDateTime

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "BEGIN NORMALIZE DNS FOR ALL ATTRIBUTES"
    Out-LogFile -string "********************************************************************************"

    Out-LogFile -string "Invoke get-NormalizedO365 to normalize the reject members."

    Out-LogFile -string "REJECT USERS"

    try {
        $exchangeRejectMessagesSMTP = get-normalizedO365 -attributeToNormalize $office365DLConfiguration.RejectMessagesFromSendersOrMembers -errorAction STOP
    }
    catch {
        out-logfile -string $_
        out-logfile -string "Unable to normalize Office 365 reject messages from senders or members." -isError:$TRUE
    }

    if ($exchangeRejectMessagesSMTP.count -gt 0)
    {
        out-logfile -string "The group has reject messages members."
        Out-logFile -string $exchangeRejectMessagesSMTP
    }
    else 
    {
        $exchangeRejectMessagesSMTP = @()
        out-logfile "The group to be migrated has no reject messages from members."    
    }
    
    Out-LogFile -string "Invoke get-Normalizedo365 to normalize the accept members."

    Out-LogFile -string "ACCEPT USERS"

    try {
        $exchangeAcceptMessagesSMTP = get-normalizedO365 -attributeToNormalize $office365DLConfiguration.AcceptMessagesOnlyFromSendersOrMembers -errorAction STOP
    }
    catch {
        out-logfile -string $_
        out-logfile -string "Unable to normalize Office 365 accept messages from senders or members." -isError:$TRUE
    }

    if ($exchangeAcceptMessagesSMTP.count -gt 0)
    {
        Out-LogFile -string "The following objects are members of the accept messages from senders:"
        
        out-logfile -string $exchangeAcceptMessagesSMTP
    }
    else
    {
        $exchangeAcceptMessagesSMTP = @()
        out-logFile -string "This group has no accept message from restrictions."    
    }
    
    Out-LogFile -string "Invoke get-NormalizedDN to normalize the managedBy members."

    Out-LogFile -string "Process MANAGEDBY"

    try {
        $exchangeManagedBySMTP = get-normalizedO365 -attributeToNormalize $office365DLConfiguration.ManagedBy -errorAction STOP
    }
    catch {
        out-logfile -string $_
        out-logfile -string "Unable to normalize Office 365 managedBy." -isError:$TRUE
    }

    if ($exchangeManagedBySMTP.count -gt 0)
    {
        Out-LogFile -string "The following objects are members of the managedBY:"
        
        out-logfile -string $exchangeManagedBySMTP
    }
    else 
    {
        $exchangeManagedBySMTP =@()
        out-logfile -string "The group has no managers."    
    }

    Out-LogFile -string "Invoke get-NormalizedDN to normalize the moderatedBy members."

    Out-LogFile -string "Process MODERATEDBY"

    try {
        $exchangeModeratedBySMTP = get-normalizedO365 -attributeToNormalize $office365DLConfiguration.ModeratedBy -errorAction STOP
    }
    catch {
        out-logfile -string $_
        out-logfile -string "Unable to normalize Office 365 ModeratedBy." -isError:$TRUE
    }

    if ($exchangeModeratedBySMTP.Count -gt 0)
    {
        Out-LogFile -string "The following objects are members of the moderatedBY:"
        
        out-logfile -string $exchangeModeratedBySMTP    
    }
    else 
    {
        $exchangeModeratedBySMTP = @()
        out-logfile "The group has no moderators."    
    }

    Out-LogFile -string "Invoke get-NormalizedO365 to normalize the bypass moderation users members."

    Out-LogFile -string "Process BYPASS USERS"

    try {
        $exchangeBypassModerationSMTP = get-normalizedO365 -attributeToNormalize $office365DLConfiguration.BypassModerationFromSendersOrMembers -errorAction STOP
    }
    catch {
        out-logfile -string $_
        out-logfile -string "Unable to normalize Office 365 BypassModerationFromSendersOrMembers." -isError:$TRUE
    }

    if ($exchangeBypassModerationSMTP.Count -gt 0)
    {
        Out-LogFile -string "The following objects are members of the bypass moderation:"
        
        out-logfile -string $exchangeBypassModerationSMTP 
    }
    else 
    {
        $exchangeBypassModerationSMTP = @()
        out-logfile "The group has no bypass moderation."    
    }

    out-logfile -string "Invoke get-normalizedO365 to normalize grant send on behalf to."

    try {
        $exchangeGrantSendOnBehalfToSMTP = get-normalizedO365 -attributeToNormalize $office365DLConfiguration.GrantSendOnBehalfTo -errorAction STOP
    }
    catch {
        out-logfile -string $_
        out-logfile -string "Unable to normalize Office 365 GrantSendOnBehalfTo." -isError:$TRUE
    }

    if ($exchangeGrantSendOnBehalfToSMTP.Count -gt 0)
    {
        Out-LogFile -string "The following objects are members of the grant send on behalf to:"
        
        out-logfile -string $exchangeGrantSendOnBehalfToSMTP
    }
    else 
    {
        $exchangeGrantSendOnBehalfToSMTP = @()
        out-logfile "The group has no grant send on behalf to."    
    }

    #At this time we have discovered all permissions based off the LDAP properties of the users.  The one remaining is what objects have SENDAS rights on this DL.

    out-logfile -string "Obtaining send as permissions - setting to empty as not relevant for this code."

    $exchangeSendAsSMTP=@()

    Out-LogFile -string "Invoke get-NormalizedDN to normalize the members."

    try {
        out-logfile -string "Obtianing the original Office 365 Group membership."

        $office365DLMembership = get-o365DlMembership -groupSMTPAddres $groupSMTPAddress -errorAction STOP
    }
    catch {
        out-logfile -string $_
        out-logfile -string "Unable to obtain the Office 365 DL membership." -isError:$TRUE
    }

    if ($office365DLMembership.count -gt 0)
    {
        out-logfile -string "Office 365 DL has membership - begin normalizing..."
        try {
            $exchangeDLMembershipSMTP = get-normalizedO365 -attributeToNormalize $office365DLMembership -errorAction STOP
        }
        catch {
            out-logfile -string $_
            out-logfile -string "Unable to normalize Office 365 Members." -isError:$TRUE
        }
    }
    else 
    {
        out-logfile -string "No office 365 DL members to normalize."
        $exchangeDLMembershipSMTP = @()
    }

    out-logfile -string "Normalize the membership now."

    if ($exchangeDLMembershipSMTP.Count -gt 0)
    {
        Out-LogFile -string "The following objects are members of the group:"
        
        out-logfile -string $exchangeDLMembershipSMTP
    }
    else 
    {
        out-logFile -string "The distribution group has no members."    
    }

    #exit #Debug Exit

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END NORMALIZE DNS FOR ALL ATTRIBUTES"
    Out-LogFile -string "********************************************************************************"

    $telemetryFunctionEndTime = get-universalDateTime

    $telemetryNormalizeDN = get-elapsedTime -startTime $telemetryFunctionStartTime -endTime $telemetryFunctionEndTime

    out-logfile -string ("Time to Normalize DNs: "+$telemetryNormalizeDN.toString())

    out-logfile -string "/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
    out-logFile -string "Summary of group information:"
    out-logfile -string ("The number of objects included in the member migration: "+$exchangeDLMembershipSMTP.count)
    out-logfile -string ("The number of objects included in the reject memebers: "+$exchangeRejectMessagesSMTP.count)
    out-logfile -string ("The number of objects included in the accept memebers: "+$exchangeAcceptMessagesSMTP.count)
    out-logfile -string ("The number of objects included in the managedBY memebers: "+$exchangeManagedBySMTP.count)
    out-logfile -string ("The number of objects included in the moderatedBY memebers: "+$exchangeModeratedBySMTP.count)
    out-logfile -string ("The number of objects included in the bypassModeration memebers: "+$exchangeBypassModerationSMTP.count)
    out-logfile -string ("The number of objects included in the grantSendOnBehalfTo memebers: "+$exchangeGrantSendOnBehalfToSMTP.count)
    out-logfile -string ("The number of objects included in the send as rights: "+$exchangeSendAsSMTP.count)
    out-logfile -string "/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"

    #Exit #Debug Exit.

    #At this point we have obtained all the information relevant to the individual group.
    #Validate that the discovered dependencies are valid in Office 365.

    $forLoopCounter=0 #Resetting counter at next set of queries.

    $telemetryFunctionStartTime = get-universalDateTime

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "BEGIN VALIDATE UNIFIED GROUP PRE-REQS"
    Out-LogFile -string "********************************************************************************"

    try {
        start-testo365UnifiedGroupDependency -exchangeDLMembershipSMTP $exchangeDLMembershipSMTP -exchangeBypassModerationSMTP $exchangeBypassModerationSMTP -exchangeManagedBySMTP $exchangeManagedBySMTP -allObjectsSendAsAccessNormalized @() -addManagersAsMembers $addManagersAsMembers -originalDLConfiguration $originalDLConfiguration -errorAction STOP
    }
    catch {
        out-logfile -string "Unable to test for Office 365 Unified group dependencies."
        out-logfile -string $_ -isError:$TRUE
    }

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END VALIDATE UNIFIED GROUP PRE-REQS"
    Out-LogFile -string "********************************************************************************"

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "BEGIN VALIDATE RECIPIENTS IN CLOUD"
    Out-LogFile -string "********************************************************************************"

    try {
        $mailOnMicrosoftComDomain = Get-MailOnMicrosoftComDomain -errorAction STOP
    }
    catch {
        out-logfile -string $_
        out-logfile -string "Unable to obtain the onmicrosoft.com domain." -errorAction STOP    
    }

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END VALIDATE RECIPIENTS IN CLOUD"
    Out-LogFile -string "********************************************************************************"

    $telemetryFunctionEndTime = get-universalDateTime

    $telemetryValidateCloudRecipients = get-elapsedTime -startTime $telemetryFunctionStartTime -endTime $telemetryFunctionEndTime

    out-logfile -string ("Time to validate recipients in cloud: "+ $telemetryValidateCloudRecipients.toString())

    #Exit #Debug Exit

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "BEGIN RECORD DEPENDENCIES ON MIGRATED GROUP"
    Out-LogFile -string "********************************************************************************"

    $telemetryFunctionStartTime = get-universalDateTime

    $telemetryFunctionEndTime = get-universalDateTime

    $telemetryDependencyOnPrem = get-elapsedTime -startTime $telemetryFunctionStartTime -endTime $telemetryFunctionEndTime

    out-logfile -string ("Time to calculate on premsies dependencies: "+ $telemetryDependencyOnPrem.toString())

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END RECORD DEPENDENCIES ON MIGRATED GROUP"
    Out-LogFile -string "********************************************************************************"

    Out-LogFile -string "Recording all gathered information to XML to preserve original values."
    
    if ($exchangeDLMembershipSMTP.count -gt 0)
    {
        Out-XMLFile -itemtoexport $exchangeDLMembershipSMTP -itemNameToExport $xmlFiles.exchangeDLMembershipSMTPXML.value
    }
    else 
    {
        $exchangeDLMembershipSMTP=@()
    }

    if ($exchangeRejectMessagesSMTP.count -gt 0)
    {
        out-xmlfile -itemtoexport $exchangeRejectMessagesSMTP -itemNameToExport $xmlFiles.exchangeRejectMessagesSMTPXML.value
    }
    else 
    {
        $exchangeRejectMessagesSMTP=@()
    }

    if ($exchangeAcceptMessagesSMTP.count -gt 0)
    {
        out-xmlfile -itemtoexport $exchangeAcceptMessagesSMTP -itemNameToExport $xmlFiles.exchangeAcceptMessagesSMTPXML.value
    }
    else 
    {
        $exchangeAcceptMessagesSMTP=@()
    }

    if ($exchangeManagedBySMTP.count -gt 0)
    {
        out-xmlfile -itemtoexport $exchangeManagedBySMTP -itemNameToExport $xmlFiles.exchangeManagedBySMTPXML.value
    }
    else 
    {
        $exchangeManagedBySMTP=@()
    }

    if ($exchangeModeratedBySMTP.count -gt 0)
    {
        out-xmlfile -itemtoexport $exchangeModeratedBySMTP -itemNameToExport $xmlFiles.exchangeModeratedBySMTPXML.value
    }
    else 
    {
        $exchangeModeratedBySMTP=@()
    }

    if ($exchangeBypassModerationSMTP.count -gt 0)
    {
        out-xmlfile -itemtoexport $exchangeBypassModerationSMTP -itemNameToExport $xmlFiles.exchangeBypassModerationSMTPXML.value
    }
    else 
    {
        $exchangeBypassModerationSMTP=@()
    }

    if ($exchangeGrantSendOnBehalfToSMTP.count -gt 0)
    {
        out-xmlfile -itemToExport $exchangeGrantSendOnBehalfToSMTP -itemNameToExport $xmlFiles.exchangeGrantSendOnBehalfToSMTPXML.value
    }
    else 
    {
        $exchangeGrantSendOnBehalfToSMTP=@()
    }

    if ($exchangeSendAsSMTP.count -gt 0)
    {
        out-xmlfile -itemToExport $exchangeSendAsSMTP -itemNameToExport $xmlFiles.exchangeSendAsSMTPXML.value
    }
    else 
    {
        $exchangeSendAsSMTP=@()
    }

    #EXIT #Debug Exit

    #Ok so at this point we have preserved all of the information regarding the on premises DL.
    #It is possible that there could be cloud only objects that this group was made dependent on.
    #For example - the dirSync group could have been added as a member of a cloud only group - or another group that was migrated.
    #The issue here is that this gets VERY expensive to track - since some of the word to do do is not filterable.
    #With the LDAP improvements we no longer offert the option to track on premises - but the administrator can choose to track the cloud

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "START RETAIN OFFICE 365 GROUP DEPENDENCIES"
    Out-LogFile -string "********************************************************************************"

    $telemetryFunctionStartTime = get-universalDateTime

    #Process normal mail enabled groups.

    if (($retainOffice365Settings -eq $TRUE) -and ($allowNonSyncedGroup -eq $FALSE))
    {
        out-logFile -string "Office 365 settings are to be retained."

        try {
            $allOffice365MemberOf = Get-O365GroupDependency -dn $office365DLConfiguration.distinguishedName -attributeType $office365Attributes.office365Members.value -errorAction STOP
        }
        catch {
            out-logFile -string $_ -isError:$TRUE
        }

        out-logfile -string ("The number of groups in Office 365 cloud only that the DL is a member of = "+$allOffice365MemberOf.count)

        try {
            $allOffice365Accept = Get-O365GroupDependency -dn $office365DLConfiguration.distinguishedName -attributeType $office365Attributes.office365AcceptMessagesFrom.value -errorAction STOP
        }
        catch {
            out-logFile -string $_ -isError:$TRUE
        }

        out-logfile -string ("The number of groups in Office 365 cloud only that the DL has accept rights = "+$allOffice365Accept.count)

        try {
            $allOffice365Reject = Get-O365GroupDependency -dn $office365DLConfiguration.distinguishedName -attributeType $office365Attributes.office365RejectMessagesFrom.value -errorAction STOP
        }
        catch {
            out-logFile -string $_ -isError:$TRUE
        }

        out-logfile -string ("The number of groups in Office 365 cloud only that the DL has reject rights = "+$allOffice365Reject.count)

        try {
            $allOffice365BypassModeration = Get-O365GroupDependency -dn $office365DLConfiguration.distinguishedName -attributeType $office365Attributes.office365BypassModerationFrom.value -errorAction STOP
        }
        catch {
            out-logFile -string $_ -isError:$TRUE
        }

        out-logfile -string ("The number of groups in Office 365 cloud only that the DL has grant send on behalf to righbypassModeration rights = "+$allOffice365BypassModeration.count)

        try {
            $allOffice365GrantSendOnBehalfTo = Get-O365GroupDependency -dn $office365DLConfiguration.distinguishedName -attributeType $office365Attributes.office365GrantSendOnBehalfTo.value -errorAction STOP
        }
        catch {
            out-logFile -string $_ -isError:$TRUE
        }

        out-logfile -string ("The number of groups in Office 365 cloud only that the DL has grantSendOnBehalFto = "+$allOffice365GrantSendOnBehalfTo.count)

        try {
            $allOffice365ManagedBy = Get-O365GroupDependency -dn $office365DLConfiguration.distinguishedName -attributeType $office365Attributes.office365ManagedBy.value -errorAction STOP
        }
        catch {
            out-logFile -string $_ -isError:$TRUE
        }

        out-logfile -string ("The number of groups in Office 365 cloud only that the DL has managedBY = "+$allOffice365ManagedBy.count)

        try {
            $allOffice365ForwardingAddress = Get-O365GroupDependency -dn $office365DLConfiguration.distinguishedName -attributeType $office365Attributes.office365ForwardingAddress.value -errorAction STOP
        }
        catch {
            out-logFile -string $_ -isError:$TRUE
        }

        out-logfile -string ("The number of groups in Office 365 cloud only that the DL has forwarding on mailboxes = "+$allOffice365ForwardingAddress.count)

        if ($retainSendAsOffice365 -eq $TRUE)
        {
            if ($office365DLConfiguration.recipientType -eq "MailUniversalSecurityGroup")
            {
                out-logfile -string "Group is a security group - attempt to locate send as permissions."

                try{
                    $allOffice365SendAsAccess = Get-O365DLSendAs -groupSMTPAddress $groupSMTPAddress -isTrustee:$TRUE -errorAction STOP
                }
                catch{
                    out-logfile -string $_ -isError:$TRUE
                }
            }
        }
        else 
        {
            out-logfile -string "Group is not a security group - do not search permissions."
        }

        out-logfile -string ("The number of groups in Office 365 cloud only that the DL has send as rights on = "+$allOffice365SendAsAccess.count)

        try {
            $allOffice365SendAsAccessOnGroup = get-o365DLSendAs -groupSMTPAddress $groupSMTPAddress -errorAction STOP
        }
        catch {
            out-logFile -string $_ -isError:$TRUE
        }

        if ($retainFullMailboxAccessOffice365 -eq $TRUE)
        {
            if ($useCollectedFullMailboxAccessOffice365 -eq $FALSE)
            {
                try {
                    $allOffice365FullMailboxAccess = Get-O365DLFullMaiboxAccess -groupSMTPAddress $groupSMTPAddress
                }
                catch {
                    out-logfile -string $_ -isError:$TRUE
                }
            }
            elseif ($useCollectedFullMailboxAccessOffice365 -eq $TRUE)
            {
                $importFilePath=Join-path $importFile $xmlFiles.retainOffice365RecipientFullMailboxAccessXML.value

                try {
                    $importData = import-CLIXML -path $importFilePath
                }
                catch {
                    out-logfile -string "Error importing the send as permissions from collect function."
                    out-logfile -string $_ -isError:$TRUE
                }

                try {
                    $allOffice365FullMailboxAccess = Get-O365DLFullMaiboxAccess -groupSMTPAddress $groupSMTPAddress -collectedData $importData
                }
                catch {
                    out-logfile -string $_ -isError:$TRUE
                }
            }
 
        }  

        out-logfile -string ("The number of Office 365 mailboxes that have full mailbox access rights for the migrated group ="+$allOffice365FullMailboxAccess.count)

        if ($useCollectedFolderPermissionsOffice365 -eq $TRUE)
        {
            out-logfile -string "Administrator has opted to retain folder permissions in Office 365."

            $importFilePath=Join-path $importFile $xmlFiles.retainMailboxFolderPermsOffice365XML.value

            try {
                $importData = import-CLIXML -path $importFilePath
            }
            catch {
                out-logfile -string "Error importing the send as permissions from collect function."
                out-logfile -string $_ -isError:$TRUE
            }

            try {
                $allOffice365MailboxFolderPermissions = Get-O365DLMailboxFolderPermissions -groupSMTPAddress $groupSMTPAddress -collectedData $importData
            }
            catch {
                out-logfile -string $_ -isError:$TRUE
            }
        }

        out-logfile -string ("The number of Office 365 mailboxes folders that have folder permissions for the migrated group ="+$allOffice365MailboxFolderPermissions.count)

        if ($allOffice365MemberOf -ne $NULL)
        {
            out-logfile -string $allOffice365MemberOf
            out-xmlfile -itemtoexport $allOffice365MemberOf -itemNameToExport $xmlFiles.allOffice365MemberOfXML.value
        }
        else 
        {
            $allOffice365MemberOf=@()
        }

        if ($allOffice365Accept -ne $NULL)
        {
            out-logfile -string $allOffice365Accept
            out-xmlFile -itemToExport $allOffice365Accept -itemNameToExport $xmlFiles.allOffice365AcceptXML.value
        }
        else 
        {
            $allOffice365Accept=@()    
        }

        if ($allOffice365Reject -ne $NULL)
        {
            out-logfile -string $allOffice365Reject
            out-xmlFile -itemToExport $allOffice365Reject -itemNameToExport $xmlFiles.allOffice365RejectXML.value
        }
        else 
        {
            $allOffice365Reject=@()    
        }
        
        if ($allOffice365BypassModeration -ne $NULL)
        {
            out-logfile -string $allOffice365BypassModeration
            out-xmlFile -itemToExport $allOffice365BypassModeration -itemNameToExport $xmlFiles.allOffice365BypassModerationXML.value
        }
        else 
        {
            $allOffice365BypassModeration=@()    
        }

        if ($allOffice365GrantSendOnBehalfTo -ne $NULL)
        {
            out-logfile -string $allOffice365GrantSendOnBehalfTo
            out-xmlfile -itemToExport $allOffice365GrantSendOnBehalfTo -itemNameToExport $xmlFiles.allOffice365GrantSendOnBehalfToXML.value
        }
        else 
        {
            $allOffice365GrantSendOnBehalfTo=@()    
        }

        if ($allOffice365ManagedBy -ne $NULL)
        {
            out-logfile -string $allOffice365ManagedBy
            out-xmlFile -itemToExport $allOffice365ManagedBy -itemNameToExport $xmlFiles.allOffice365ManagedByXML.value
        }
        else 
        {
            $allOffice365ManagedBy=@()    
        }

        if ($allOffice365ForwardingAddress -ne $NULL)
        {
            out-logfile -string $allOffice365ForwardingAddress
            out-xmlfile -itemToExport $allOffice365ForwardingAddress -itemNameToExport $xmlFiles.allOffice365ForwardingAddressXML.value
        }
        else 
        {
            $allOffice365ForwardingAddress=@()    
        }

        if ($allOffice365SendAsAccess -ne $NULL)
        {
            out-logfile -string $allOffice365SendAsAccess
            out-xmlfile -itemToExport $allOffice365SendAsAccess -itemNameToExport $xmlFiles.allOffic365SendAsAccessXML.value
        }
        else 
        {
            $allOffice365SendAsAccess=@()    
        }

        if ($allOffice365SendAsAccessOnGroup -ne $NULL)
        {
            out-logfile -string $allOffice365SendAsAccessOnGroup
            out-xmlfile -itemToExport $allOffice365SendAsAccessOnGroup -itemNameToExport $xmlFiles.allOffice365SendAsAccessOnGroupXML.value
        }
        else
        {
            $allOffice365SendAsAccessOnGroup=@()
        }
        

        if ($allOffice365FullMailboxAccess -ne $NULL)
        {
            out-logfile -string $allOffice365FullMailboxAccess
            out-xmlFile -itemToExport $allOffice365FullMailboxAccess -itemNameToExport $xmlFiles.allOffice365FullMailboxAccessXML.value
        }
        else 
        {
            $allOffice365FullMailboxAccess=@()    
        }

        if ($allOffice365MailboxFolderPermissions -ne $NULL)
        {
            out-logfile -string $allOffice365MailboxFolderPermissions
            out-xmlfile -itemToExport $allOffice365MailboxFolderPermissions -itemNameToExport $xmlFiles.allOffice365MailboxesFolderPermissionsXML.value
        }
        else 
        {
            $allOffice365MailboxFolderPermissions=@()    
        }
    }
    else 
    {
        out-logfile -string "Administrator opted out of recording Office 365 dependencies."
        $allOffice365MailboxFolderPermissions=@() 
        $allOffice365FullMailboxAccess=@()  
        $allOffice365SendAsAccessOnGroup=@()
        $allOffice365SendAsAccess=@()  
        $allOffice365ForwardingAddress=@() 
        $allOffice365ManagedBy=@() 
        $allOffice365GrantSendOnBehalfTo=@()  
        $allOffice365BypassModeration=@()
        $allOffice365Reject=@() 
        $allOffice365Accept=@()  
        $allOffice365MemberOf=@()
    }

    $telemetryFunctionEndTime = get-universalDateTime

    $telemetryCollectOffice365Dependency = ($telemetryFunctionEndTime - $telemetryFunctionStartTime).seconds

    out-logfile -string ("Time to gather Office 365 dependencies: "+$telemetryCollectOffice365Dependency.tostring())

    out-logfile -string "/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
    out-logfile -string ("Summary of dependencies found:")
    out-logfile -string ("The number of office 365 objects that the migrated DL is a member of = "+$allOffice365MemberOf.count)
    out-logfile -string ("The number of office 365 objects that this group is a manager of: = "+$allOffice365ManagedBy.count)
    out-logfile -string ("The number of office 365 objects that this group has grant send on behalf to = "+$allOffice365GrantSendOnBehalfTo.count)
    out-logfile -string ("The number of office 365 objects that have this group as bypass moderation = "+$allOffice365BypassModeration.count)
    out-logfile -string ("The number of office 365 objects with accept permissions = "+$allOffice365Accept.count)
    out-logfile -string ("The number of office 365 objects with reject permissions = "+$allOffice365Reject.count)
    out-logfile -string ("The number of office 365 mailboxes forwarding to this group is = "+$allOffice365ForwardingAddress.count)
    out-logfile -string ("The number of recipients that have send as rights on the group to be migrated = "+$allOffice365SendAsAccessOnGroup.count)
    out-logfile -string ("The number of office 365 recipients where the group has send as rights = "+$allOffice365SendAsAccess.count)
    out-logfile -string ("The number of office 365 recipients with full mailbox access = "+$allOffice365FullMailboxAccess.count)
    out-logfile -string ("The number of office 365 mailbox folders with migrated group rights = "+$allOffice365MailboxFolderPermissions.count)
    out-logfile -string "/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"

    
    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END RETAIN OFFICE 365 GROUP DEPENDENCIES"
    Out-LogFile -string "********************************************************************************"

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "BEGIN VALIDATE UNIFIED GROUP PRE-REQS"
    Out-LogFile -string "********************************************************************************"

    try {
        start-testo365UnifiedGroupDependency -allOffice365ManagedBy $allOffice365ManagedBy -allOffice365SendAsAccess $allOffice365SendAsAccess -allOffice365FullMailboxAccess $allOffice365FullMailboxAccess -allOffice365MailboxFolderPermissions $allOffice365MailboxFolderPermissions -errorAction STOP
    }
    catch {
        out-logfile -string "Unable to test for Office 365 Unified group dependencies."
        out-logfile -string $_ -isError:$TRUE
    }

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END VALIDATE UNIFIED GROUP PRE-REQS"
    Out-LogFile -string "********************************************************************************"

    #At this time we have validated the on premises pre-requisits for group migration.
    #If anything is not in order - this code will provide the summary list to the customer and then trigger end.

    if (($global:preCreateErrors.count -gt 0) -or ($global:testOffice365Errors.count -gt 0))
    {
        #Write the XML files first so that the error table is complete without separation.

        if ($global:preCreateErrors.count -gt 0)
        {
            out-xmlFile -itemToExport $global:preCreateErrors -itemNameToExport $xmlFiles.preCreateErrorsXML.value
        }

        if ($global:testOffice365Errors.Count -gt 0)
        {
            out-xmlFile -itemToExport $global:testOffice365Errors -itemNametoExport $xmlfiles.testOffice365ErrorsXML.value
        }

        out-logfile -string "+++++"
        out-logfile -string "Pre-requist checks failed.  Please refer to the following list of items that require addressing for migration to proceed."
        out-logfile -string "+++++"
        out-logfile -string ""

        if ($global:preCreateErrors.count -gt 0)
        {
            foreach ($preReq in $global:preCreateErrors)
            {
                write-errorEntry -errorEntry $preReq

                #Test to see if the error is a NestedGroupException - if so write it to the nested group csv.

                if ($preReq.isErrorMessage -like $nestedGroupException)
                {
                    out-logfile -string "Nested group exception written to CSV."
                    export-csv -Path $nestedCSVPath -inputObject $preReq -append
                }
            }
        }

        if ($global:testOffice365Errors.count -gt 0)
        {
            foreach ($preReq in $global:testOffice365Errors)
            {
                write-errorEntry -errorEntry $prereq
            }
        }

        if ($isHealthCheck -eq $FALSE)
        {
            out-logfile -string "Pre-requist checks failed.  Please refer to the previous list of items that require addressing for migration to proceed." -isError:$TRUE
        }
        else
        {
            out-logfile -string "Pre-requist checks failed.  Please refer to the previous list of items that require addressing for migration to proceed."
        }  
    }

    #If we're only doing health checking return to the health checking function.

    if ($isHealthCheck -eq $TRUE)
    {
        return
    }

    out-logfile "All Unified Group pre-reqs passed - determine if managers are added to owners."

    if ($addManagersAsMembers -eq $TRUE)
    {
        out-logfile -string "Attempting to add managers to the members array if they are not already there."

        $exchangeDLMembershipSMTP += $exchangeManagedBySMTP

        out-logfile -string $exchangeDLMembershipSMTP

        out-logfile -string "Ensuring that the membership array is unique as it may contain overlap with managers."

        $exchangeDLMembershipSMTP = $exchangeDLMembershipSMTP | sort-object -unique -property PrimarySMTPAddressOrUPN

        out-logfile -string $exchangeDLMembershipSMTP
    }
    else
    {
        out-logfile -string "Managers not automatically added as members."
    }

    #EXIT #Debug Exit

    #We can begin the process of recreating the distribution group in Exchange Online.
    #This will make a first pass at creating a stub distribution list and perfomring long running transations like updating membership.
    #By creating the DL first and updating these items - the original DL remains fully available until the new DL is populated and ready to turn over.

    out-logfile -string "Create the new distribution list in Office 365.  This list uses the tempoary name for creation."

    $telemetryFunctionStartTime = get-universalDateTime

    out-logfile "Attempting to create the DL in Office 365."

    $stopLoop = $FALSE
    [int]$loopCounter = 0

    do {
        try {
            $office365DLConfigurationPostMigration=new-office365Group -originalDLConfiguration $originalDLConfiguration -office365DLConfiguration $office365DLConfiguration -errorAction STOP

            #If we made it this far then the group was created.

            $stopLoop=$TRUE
        }
        catch {
            if ($loopCounter -gt 10)
            {
                out-logFile -string $_ -isError:$TRUE 
            }
            else 
            {
                out-logfile -string "Unable to create the distribution list on attempt.  Retry"

                if ($loopCounter -gt 0)
                {
                    start-sleepProgress -sleepSeconds ($loopCounter * 5) -sleepstring "Invoke sleep - error creating distribution group."
                }
                $loopCounter=$loopCounter+1
            }
        }
    } while ($stopLoop -eq $FALSE)

    #Sometimes the configuration is not immediately available due to ad sync time in Office 365.
    #Implement a loop that protects us here - trying 10 times and sleeping the bare minimum in between to eliminate longer static sleeps.

    $stopLoop = $FALSE
    [int]$loopCounter = 0

    do 
    {
        try {
                        
            #If we hit here we did not get a terminating error.  Write the configuration.

            out-LogFile -string "Write new DL configuration to XML."

            out-Logfile -string $office365DLConfigurationPostMigration
            out-xmlFile -itemToExport $office365DLConfigurationPostMigration -itemNameToExport (($xmlFiles.office365DLConfigurationPostMigrationXML.value)+"-NewO365DL")
            
            #If we made it this far we can end the loop - we were succssful.

            $stopLoop=$TRUE
        }
        catch {
            if ($loopCounter -gt 10)
            {
                out-logfile -string "Unable to get Office 365 distribution list configuration after 10 tries."
                $stopLoop = $TRUE
            }
            else 
            {
                start-sleepProgress -sleepString "Unable to capture the Office 365 DL configuration.  Sleeping 15 seconds." -sleepSeconds 15

                $loopCounter = $loopCounter+1 
            }
        }   
    } while ($stopLoop -eq $false)

    #Now it is time to set the multi valued attributes on the DL in Office 365.
    #Setting these first must occur since moderators have to be established before moderation can be enabled.

    out-logFile -string "Setting the multivalued attributes of the migrated group for the first pass."

    out-logfile -string $office365DLConfigurationPostMigration.primarySMTPAddress

    [int]$loopCounter=0
    [boolean]$stopLoop = $FALSE
    
    do {
        try {
            set-Office365GroupMV -originalDLConfiguration $originalDLConfiguration -office365DLConfiguration $office365DLConfiguration -office365DLConfigurationPostMigration $office365DLConfigurationPostMigration -exchangeDLMembership $exchangeDLMembershipSMTP -exchangeRejectMessage $exchangeRejectMessagesSMTP -exchangeAcceptMessage $exchangeAcceptMessagesSMTP -exchangeModeratedBy $exchangeModeratedBySMTP -exchangeManagedBy $exchangeManagedBySMTP -exchangeBypassMOderation $exchangeBypassModerationSMTP -exchangeGrantSendOnBehalfTo $exchangeGrantSendOnBehalfToSMTP -exchangeSendAsSMTP $exchangeSendAsSMTP -mailOnMicrosoftComDomain $mailOnMicrosoftComDomain -allowNonSyncedGroup $allowNonSyncedGroup -allOffice365SendAsAccessOnGroup $allOffice365SendAsAccessOnGroup -isFirstAttempt:$TRUE -exchangeOnlineCredential $exchangeOnlineCredential -errorAction STOP

            $stopLoop = $TRUE
        }
        catch {
            if ($loopCounter -gt 4)
            {
                out-logFile -string $_ -isError:$TRUE
            }
            else {
                start-sleepProgress -sleepString "Uanble to set Office 365 DL Multi Value attributes - try again." -sleepSeconds 5

                $loopCounter = $loopCounter +1
            } 
        }
    } while ($stopLoop -eq $FALSE)

    out-logfile -string ("The number of post create errors is: "+$global:postCreateErrors.count)

    #Sometimes the configuration is not immediately available due to ad sync time in Office 365.
    #Implement a loop that protects us here - trying 10 times and sleeping the bare minimum in between to eliminate longer static sleeps.

    $stopLoop = $FALSE
    [int]$loopCounter = 0

    do {
        try {
            $office365DLConfigurationPostMigration = Get-O365DLConfiguration -groupSMTPAddress $office365DLConfigurationPostMigration.GUID -isUnifiedGroup:$TRUE -errorAction STOP

            #If we made it this far we were successful - output the information to XML.

            out-LogFile -string "Write new DL configuration to XML."

            out-Logfile -string $office365DLConfigurationPostMigration
            out-xmlFile -itemToExport $office365DLConfigurationPostMigration -itemNameToExport (($xmlFiles.office365DLConfigurationPostMigrationXML.value)+"-SetMVAttsFirstAttempt")

            #Now that we are this far - we can exit the loop.

            $stopLoop=$TRUE
        }
        catch {
            if ($loopCounter -gt 10)
            {
                out-logfile -string "Unable to get Office 365 distribution list configuration after 10 tries."
                $stopLoop = $TRUE
            }
            else 
            {
                start-sleepProgress -sleepString "Unable to capture the Office 365 DL configuration.  Sleeping 15 seconds." -sleepSeconds 15

                $loopCounter = $loopCounter+1 
            }
        }
        
    } while ($stopLoop -eq $FALSE)

    #The distribution list has now been created.  There are single value attributes that we're now ready to update.

    $stopLoop = $FALSE
    [int]$loopCounter = 0

    do {
        try {
            set-Office365Group -originalDLConfiguration $originalDLConfiguration -office365DLConfiguration $office365DLConfiguration -office365DLConfigurationPostMigration $office365DLConfigurationPostMigration -isFirstAttempt:$TRUE
            $stopLoop=$TRUE
        }
        catch {
            if ($loopCounter -gt 4)
            {
                out-logfile -string $_ -isError:$TRUE
            }
            else 
            {
                start-sleepProgress -sleepString "Transient error updating distribution group - retrying." -sleepSeconds 5

                $loopCounter=$loopCounter+1
            }
        }
    } while ($stopLoop -eq $FALSE)

    out-logfile -string ("The number of post create errors is: "+$global:postCreateErrors.count)

    out-logFile -string ("Capture the DL status post migration.")

    $stopLoop = $FALSE
    [int]$loopCounter = 0

    do {
        try {
            $office365DLConfigurationPostMigration = Get-O365DLConfiguration -groupSMTPAddress $office365DLConfigurationPostMigration.GUID -isUnifiedGroup $TRUE -errorAction STOP

            #If we made it this far we successfully got the DL.  Write it.

            out-LogFile -string "Write new DL configuration to XML."

            out-Logfile -string $office365DLConfigurationPostMigration
            out-xmlFile -itemToExport $office365DLConfigurationPostMigration -itemNameToExport (($xmlFiles.office365DLConfigurationPostMigrationXML.value)+"-SetSingleValAttsFirstAttempt")

            #Now that we wrote it - stop the loop.

            $stopLoop=$TRUE
        }
        catch {
            if ($loopCounter -gt 10)
            {
                out-logfile -string "Unable to get Office 365 distribution list configuration after 10 tries."
                $stopLoop = $TRUE
            }
            else 
            {
                start-sleepProgress -sleepString "Unable to capture the Office 365 DL configuration.  Sleeping 15 seconds." -sleepSeconds 15

                $loopCounter = $loopCounter+1 
            }
        }   
    } while ($stopLoop -eq $false)

    $telemetryFunctionEndTime = get-universalDateTime

    $telemetryCreateOffice365DLFirstPass = get-elapsedTime -startTime $telemetryFunctionStartTime -endTime $telemetryFunctionEndTime

    out-logfile -string ("The time it took to create the Office 365 distribution group and run first pass attributes: "+$telemetryCreateOffice365DLFirstPass.toString())

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "START Remove on premises distribution group from office 365.."
    Out-LogFile -string "********************************************************************************"

    #At this stage we will move the group to the non-Sync OU and then re-record the attributes.
    #The move here will allow us to preserve the original groups with attributes until we know that the migration was successful.
    #We will use the move to the non-SYNC OU to trigger deletion.

    #EXIT #Debug exit

    try{
        remove-o365CloudOnlyGroup -office365DLConfiguration $office365DLConfiguration -errorAction STOP
    }
    catch {
        out-logfile -string "Unable to remove the Office 365 Distribution List."
        out-logfile -string $_
    }

    #At this time we have processed the deletion to azure.
    #We need to wait for that deletion to occur in Exchange Online.

    $telemetryFunctionStartTime = get-universalDateTime

    start-sleepProgress -sleepSeconds 60 -sleepString "Sleeping after removal of group from Office 365."

    $telemetryFunctionEndTime = get-universalDateTime

    $telemetryTimeToRemoveDL = get-elapsedTime -startTime $telemetryFunctionStartTime -endTime $telemetryFunctionEndTime

    out-logfile -string ("Elapsed time to remove the Office 365 Distribution List: "+$telemetryTimeToRemoveDL.tostring())

    #At this point we have validated that the group is gone from office 365.
    
    #EXIT #Debug Exit.

    $telemetryFunctionStartTime = get-universalDateTime

    #Now it is time to set the multi valued attributes on the DL in Office 365.
    #Setting these first must occur since moderators have to be established before moderation can be enabled.

    out-logFile -string "Setting the multivalued attributes of the migrated group for the first pass."

    out-logfile -string $office365DLConfigurationPostMigration.primarySMTPAddress

    [int]$loopCounter=0
    [boolean]$stopLoop = $FALSE
    
    do {
        try {
            set-Office365GroupMV -originalDLConfiguration $originalDLConfiguration -office365DLConfiguration $office365DLConfiguration -office365DLConfigurationPostMigration $office365DLConfigurationPostMigration -exchangeDLMembership $exchangeDLMembershipSMTP -exchangeRejectMessage $exchangeRejectMessagesSMTP -exchangeAcceptMessage $exchangeAcceptMessagesSMTP -exchangeModeratedBy $exchangeModeratedBySMTP -exchangeManagedBy $exchangeManagedBySMTP -exchangeBypassMOderation $exchangeBypassModerationSMTP -exchangeGrantSendOnBehalfTo $exchangeGrantSendOnBehalfToSMTP -exchangeSendAsSMTP $exchangeSendAsSMTP -mailOnMicrosoftComDomain $mailOnMicrosoftComDomain -allowNonSyncedGroup $allowNonSyncedGroup -allOffice365SendAsAccessOnGroup $allOffice365SendAsAccessOnGroup -exchangeOnlineCredential $exchangeOnlineCredential -errorAction STOP

            $stopLoop = $TRUE
        }
        catch {
            if ($loopCounter -gt 4)
            {
                out-logFile -string $_ -isError:$TRUE
            }
            else {
                start-sleepProgress -sleepString "Uanble to set Office 365 DL Multi Value attributes - try again." -sleepSeconds 5

                $loopCounter = $loopCounter +1
            } 
        }
    } while ($stopLoop -eq $FALSE)

    out-logfile -string ("The number of post create errors is: "+$global:postCreateErrors.count)

    #Sometimes the configuration is not immediately available due to ad sync time in Office 365.
    #Implement a loop that protects us here - trying 10 times and sleeping the bare minimum in between to eliminate longer static sleeps.

    $stopLoop = $FALSE
    [int]$loopCounter = 0

    do {
        try {
            $office365DLConfigurationPostMigration = Get-O365DLConfiguration -groupSMTPAddress $office365DLConfigurationPostMigration.GUID -isUnifiedGroup $TRUE -errorAction STOP

            #If we made it this far we were successful - output the information to XML.

            out-LogFile -string "Write new DL configuration to XML."

            out-Logfile -string $office365DLConfigurationPostMigration
            out-xmlFile -itemToExport $office365DLConfigurationPostMigration -itemNameToExport (($xmlFiles.office365DLConfigurationPostMigrationXML.value)+"-SetMVAtts")

            #Now that we are this far - we can exit the loop.

            $stopLoop=$TRUE
        }
        catch {
            if ($loopCounter -gt 10)
            {
                out-logfile -string "Unable to get Office 365 distribution list configuration after 10 tries."
                $stopLoop = $TRUE
            }
            else 
            {
                start-sleepProgress -sleepString "Unable to capture the Office 365 DL configuration.  Sleeping 15 seconds." -sleepSeconds 15

                $loopCounter = $loopCounter+1 
            }
        }
        
    } while ($stopLoop -eq $FALSE)

    #The distribution list has now been created.  There are single value attributes that we're now ready to update.

    $stopLoop = $FALSE
    [int]$loopCounter = 0

    do {
        try {
            set-Office365Group -originalDLConfiguration $originalDLConfiguration -office365DLConfiguration $office365DLConfiguration -office365DLConfigurationPostMigration $office365DLConfigurationPostMigration
            $stopLoop=$TRUE
        }
        catch {
            if ($loopCounter -gt 4)
            {
                out-logfile -string $_ -isError:$TRUE
            }
            else 
            {
                start-sleepProgress -sleepString "Transient error updating distribution group - retrying." -sleepSeconds 5

                $loopCounter=$loopCounter+1
            }
        }
    } while ($stopLoop -eq $FALSE)

    
    out-logfile -string ("The number of post create errors is: "+$global:postCreateErrors.count)
    
    out-logFile -string ("Capture the DL status post migration.")

    $stopLoop = $FALSE
    [int]$loopCounter = 0

    do {
        try {
            $office365DLConfigurationPostMigration = Get-O365DLConfiguration -groupSMTPAddress $office365DLConfigurationPostMigration.GUID -isUnifiedGroup $TRUE -errorAction STOP

            #If we made it this far we successfully got the DL.  Write it.

            out-LogFile -string "Write new DL configuration to XML."

            out-Logfile -string $office365DLConfigurationPostMigration
            out-xmlFile -itemToExport $office365DLConfigurationPostMigration -itemNameToExport (($xmlFiles.office365DLConfigurationPostMigrationXML.value)+"-SetSingleValAtts")

            #Now that we wrote it - stop the loop.

            $stopLoop=$TRUE
        }
        catch {
            if ($loopCounter -gt 10)
            {
                out-logfile -string "Unable to get Office 365 distribution list configuration after 10 tries."
                $stopLoop = $TRUE
            }
            else 
            {
                start-sleepProgress -sleepString "Unable to capture the Office 365 DL configuration.  Sleeping 15 seconds." -sleepSeconds 15

                $loopCounter = $loopCounter+1 
            }
        }   
    } while ($stopLoop -eq $false)

    out-logfile -string "Obtain the migrated DL membership and record it for validation."

    $stopLoop = $FALSE
    [int]$loopCounter = 0

    do {
        try{
            $office365DLMembershipPostMigration = get-O365DLMembership -groupSMTPAddress $office365DLConfigurationPostMigration.guid -isUnifiedGroup $TRUE -getUnifiedMembers $TRUE -errorAction STOP

            #Membership obtained - export.

            if ($office365DlMembershipPostMigration.count -gt 0)
            {
                out-logFile -string "Write the new DL membership to XML."
                out-logfile -string $office365DLMembershipPostMigration
    
                out-xmlFile -itemToExport $office365DLMembershipPostMigration -itemNametoExport $xmlFiles.office365DLMembershipPostMigrationXML.value
            }
            else {
                out-logfile -string "No members to export."
            }

           

            #Exports complete - stop loop

            $stopLoop=$TRUE
        }
        catch{
            if ($loopCounter -gt 10)
            {
                out-logfile -string "Unable to get Office 365 distribution list configuration after 10 tries."
                out-logfile -string $_
                $stopLoop = $TRUE
            }
            else 
            {
                start-sleepProgress -sleepString "Unable to capture the Office 365 DL configuration.  Sleeping 15 seconds." -sleepSeconds 15
                
                out-logfile -string $_

                $loopCounter = $loopCounter+1 
            }
        }
    } while ($stopLoop -eq $FALSE)

    $stopLoop = $FALSE
    [int]$loopCounter = 0

    do {
        try{
            $office365DLOwnersPostMigration = get-O365DLMembership -groupSMTPAddress $office365DLConfigurationPostMigration.guid -isUnifiedGroup $TRUE -getUnifiedOwners $TRUE -errorAction STOP

            #Membership obtained - export.

            if ($office365DLOwnersPostMigration.count -gt 0)
            {
                out-logFile -string "Write the new DL membership to XML."
                out-logfile -string $office365DLOwnersPostMigration

                out-xmlFile -itemToExport $office365DLOwnersPostMigration -itemNametoExport $xmlFiles.office365DLOwnersPostMigrationXML.value
            }
            else {
                out-logfile -string "No owners to export."
            }

            #Exports complete - stop loop

            $stopLoop=$TRUE
        }
        catch{
            if ($loopCounter -gt 10)
            {
                out-logfile -string "Unable to get Office 365 distribution list configuration after 10 tries."
                out-logfile -string $_
                $stopLoop = $TRUE
            }
            else 
            {
                start-sleepProgress -sleepString "Unable to capture the Office 365 DL configuration.  Sleeping 15 seconds." -sleepSeconds 15

                out-logfile -string $_
 
                $loopCounter = $loopCounter+1 
            }
        }
    } while ($stopLoop -eq $FALSE)

    $stopLoop = $FALSE
    [int]$loopCounter = 0

    do {
        try{
            $office365DLSubscribersPostMigration = get-O365DLMembership -groupSMTPAddress $office365DLConfigurationPostMigration.guid -isUnifiedGroup $TRUE -getUnifiedSubscribers $TRUE -errorAction STOP

            #Membership obtained - export.

            if ($office365DlSubscribersPostMigration.count -gt 0)
            {
                out-logFile -string "Write the new DL membership to XML."
                out-logfile -string $office365DLSubscribersPostMigration

                out-xmlFile -itemToExport $office365DLSubscribersPostMigration -itemNametoExport $xmlFiles.office365DLSubscribersPostMigrationXML.value
            }
            else {
                out-logfile -string "No subscribers to export."
            }
            
            #Exports complete - stop loop

            $stopLoop=$TRUE
        }
        catch{
            if ($loopCounter -gt 10)
            {
                out-logfile -string "Unable to get Office 365 distribution list configuration after 10 tries."
                out-logfile -string $_
                $stopLoop = $TRUE
            }
            else 
            {
                start-sleepProgress -sleepString "Unable to capture the Office 365 DL configuration.  Sleeping 15 seconds." -sleepSeconds 15

                out-logfile -string $_
 
                $loopCounter = $loopCounter+1 
            }
        }
    } while ($stopLoop -eq $FALSE)

    $telemetryFunctionEndTime = get-universalDateTime

    $telemetryCreateOffice365DL = get-elapsedTime -startTime $telemetryFunctionStartTime -endTime $telemetryFunctionEndTime

    out-logfile -string ("Time elapsed to fully create Office 365 DL: "+$telemetryCreateOffice365DL.toString())

    #At this time we are ready to begin resetting the on premises dependencies.

    $telemetryFunctionStartTime = get-universalDateTime

    $telemetryFunctionEndTime = get-universalDateTime

    $telemetryReplaceOnPremDependency = get-elapsedTime -startTime $telemetryFunctionStartTime -endTime $telemetryFunctionEndTime

    out-logfile -string ("Time elapsed resetting on premises dependencies: "+$telemetryReplaceOnPremDependency.toString())

    $forLoopCounter=0 #Resetting loop counter now that we're switching to cloud operations.

    $telemetryFunctionStartTime = get-universalDateTime

    out-logfile -string "Processing Office 365 Accept Messages From"

    if ($allOffice365Accept.count -gt 0)
    {
        foreach ($member in $allOffice365Accept)
        {
            $isTestError="No" #Reset error tracking.

            if ($forLoopCounter -eq $forLoopTrigger)
            {
                start-sleepProgress -sleepString "Throttling for 5 seconds...." -sleepSeconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try{
                $isTestError=start-ReplaceOffice365 -office365Attribute $office365Attributes.office365UnifiedAccept.value -office365Member $member -groupSMTPAddress $groupSMTPAddress -errorAction STOP
            }
            catch{
                out-logfile -string $_
                $isTestErrorDetail = $_
                $isTestError="Yes"
            }

            if ($isTestError -eq "Yes")
            {
                out-logfile -string "Error adding migrated distribution list to Office 365 Resource."

                $isErrorObject = new-Object psObject -property @{
                    distinguishedName = $member.distinguishedName
                    primarySMTPAddress = $member.primarySMTPAddress
                    alias = $member.Alias
                    displayName = $member.displayName
                    attribute = "Distribution List AcceptMessagesOnlyFromSendersOrMembers"
                    errorMessage = "Unable to add the migrated distribution list to Office 365 distribution group.  Manual add required."
                    erroMessageDetail = $isTestErrorDetail
                }

                out-logfile -string $isErrorObject

                $office365ReplaceErrors+=$isErrorObject
            }
        }
    }
    else 
    {
        out-LogFile -string "There were no Office 365 groups with accept permissions."    
    }

    out-logfile -string "Processing Office 365 Reject Messages From"

    if ($allOffice365Reject.count -gt 0)
    {
        foreach ($member in $allOffice365Reject)
        {
            $isTestError="No" #Reset error tracking.

            if ($forLoopCounter -eq $forLoopTrigger)
            {
                start-sleepProgress -sleepString "Throttling for 5 seconds...." -sleepSeconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try{
                $isTestError=start-ReplaceOffice365 -office365Attribute $office365Attributes.office365UnifiedReject.value -office365Member $member -groupSMTPAddress $groupSMTPAddress -errorAction STOP
            }
            catch{
                out-logfile -string $_
                $isTestErrorDetail = $_
                $isTestError="Yes"
            }

            if ($isTestError -eq "Yes")
            {
                out-logfile -string "Error adding migrated distribution list to Office 365 Resource."

                $isErrorObject = new-Object psObject -property @{
                    distinguishedName = $member.distinguishedName
                    primarySMTPAddress = $member.primarySMTPAddress
                    alias = $member.Alias
                    displayName = $member.displayName
                    attribute = "Distribution List RejectMessagesFromSendersOrMembers"
                    errorMessage = "Unable to add the migrated distribution list to Office 365 distribution group.  Manual add required."
                    erroMessageDetail = $isTestErrorDetail
                }

                out-logfile -string $isErrorObject

                $office365ReplaceErrors+=$isErrorObject
            }
        }
    }
    else 
    {
        out-LogFile -string "There were no Office 365 groups with reject permissions."    
    }

    out-logfile -string "Processing Office 365 Bypass Moderation From Users"

    if ($allOffice365BypassModeration.count -gt 0)
    {
        foreach ($member in $allOffice365BypassModeration)
        {
            $isTestError="No" #Reset error tracking.

            if ($forLoopCounter -eq $forLoopTrigger)
            {
                start-sleepProgress -sleepString "Throttling for 5 seconds...." -sleepSeconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try{
                $isTestError=start-ReplaceOffice365 -office365Attribute $office365Attributes.office365BypassModerationusers.value -office365Member $member -groupSMTPAddress $groupSMTPAddress -errorAction STOP
            }
            catch{
                out-logfile -string $_
                $isTestErrorDetail = $_
                $isTestError="Yes"
            }

            if ($isTestError -eq "Yes")
            {
                out-logfile -string "Error adding migrated distribution list to Office 365 Resource."

                $isErrorObject = new-Object psObject -property @{
                    distinguishedName = $member.distinguishedName
                    primarySMTPAddress = $member.primarySMTPAddress
                    alias = $member.Alias
                    displayName = $member.displayName
                    attribute = "Distribution List BypassModerationFromSendersOrMembers"
                    errorMessage = "Unable to add the migrated distribution list to Office 365 distribution group.  Manual add required."
                    erroMessageDetail = $isTestErrorDetail
                }

                out-logfile -string $isErrorObject

                $office365ReplaceErrors+=$isErrorObject
            }
        }
    }
    else 
    {
        out-LogFile -string "There were no Office 365 groups with bypass moderation permissions."    
    }

    out-logfile -string "Processing Office 365 Grant Send On Behalf To Users"

    if ($allOffice365GrantSendOnBehalfTo.count -gt 0)
    {
        foreach ($member in $allOffice365GrantSendOnBehalfTo)
        {
            $isTestError="No" #Reset error tracking.

            if ($forLoopCounter -eq $forLoopTrigger)
            {
                start-sleepProgress -sleepString "Throttling for 5 seconds...." -sleepSeconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try{
                $isTestError=start-ReplaceOffice365 -office365Attribute $office365Attributes.office365GrantSendOnBehalfTo.value -office365Member $member -groupSMTPAddress $groupSMTPAddress -errorAction STOP
            }
            catch{
                out-logfile -string $_
                $isTestErrorDetail = $_
                $isTestError="Yes"
            }

            if ($isTestError -eq "Yes")
            {
                out-logfile -string "Error adding migrated distribution list to Office 365 Resource."

                $isErrorObject = new-Object psObject -property @{
                    distinguishedName = $member.distinguishedName
                    primarySMTPAddress = $member.primarySMTPAddress
                    alias = $member.Alias
                    displayName = $member.displayName
                    attribute = "Distribution List GrantSendOnBehalfTo"
                    errorMessage = "Unable to add the migrated distribution list to Office 365 distribution group.  Manual add required."
                    erroMessageDetail = $isTestErrorDetail
                }

                out-logfile -string $isErrorObject

                $office365ReplaceErrors+=$isErrorObject
            }
        }
    }
    else 
    {
        out-LogFile -string "There were no Office 365 groups with grant send on behalf to permissions."    
    }

    out-logfile -string "Processing Office 365 Managed By"

    if ($allOffice365ManagedBy.count -gt 0)
    {
        foreach ($member in $allOffice365ManagedBy)
        {
            $isTestError="No" #Reset error tracking.

            if ($forLoopCounter -eq $forLoopTrigger)
            {
                start-sleepProgress -sleepString "Throttling for 5 seconds...." -sleepSeconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try{
                $isTestError=start-ReplaceOffice365 -office365Attribute $office365Attributes.office365ManagedBy.value -office365Member $member -groupSMTPAddress $groupSMTPAddress -errorAction STOP
            }
            catch{
                out-logfile -string $_
                $isTestErrorDetail = $_
                $isTestError="Yes"
            }

            if ($isTestError -eq "Yes")
            {
                out-logfile -string "Error adding migrated distribution list to Office 365 Resource."

                $isErrorObject = new-Object psObject -property @{
                    distinguishedName = $member.distinguishedName
                    primarySMTPAddress = $member.primarySMTPAddress
                    alias = $member.Alias
                    displayName = $member.displayName
                    attribute = "Distribution List ManagedBy"
                    errorMessage = "Unable to add the migrated distribution list to Office 365 distribution group.  Manual add required."
                    erroMessageDetail = $isTestErrorDetail
                }

                out-logfile -string $isErrorObject

                $office365ReplaceErrors+=$isErrorObject
            }
        }
    }
    else 
    {
        out-LogFile -string "There were no Office 365 managed by permissions."    
    }

    #Process any group memberships to the service.

    out-logfile -string ("Adding migrated group to any cloud only groups.")

    if ($allOffice365MemberOf.count -gt 0)
    {
        out-logfile -string "Adding cloud only group member."

        foreach ($member in $allOffice365MemberOf )
        {
            $isTestError="No" #Reset error tracking.
            if ($forLoopCounter -eq $forLoopTrigger)
            {
                start-sleepProgress -sleepString "Throttling for 5 seconds...." -sleepSeconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            out-logfile -string ("Processing group = "+$member.primarySMTPAddress)
            try {
                $isTestError=start-replaceOffice365Members -office365Group $member -groupSMTPAddress $groupSMTPAddress -errorAction STOP
            }
            catch {
                out-logfile -string $_
                $isTestErrorDetail = $_
                $isTestError="Yes"
            }

            if ($isTestError -eq "Yes")
            {
                out-logfile -string "Error adding migrated distribution list to Office 365 Distribution List."

                $isErrorObject = new-Object psObject -property @{
                    distinguishedName = $member.distinguishedName
                    primarySMTPAddress = $member.primarySMTPAddress
                    alias = $member.Alias
                    displayName = $member.displayName
                    attribute = "Distribution List Membership"
                    errorMessage = "Unable to add the migrated distribution list to Office 365 distribution group.  Manual add required."
                    erroMessageDetail = $isTestErrorDetail
                }

                out-logfile -string $isErrorObject

                $office365ReplaceErrors+=$isErrorObject
            }
        }
    }
    else 
    {
        out-logfile -string "No cloud only groups had the migrated group as a member."
    }   

    out-logfile -string "Processing Office 365 Managed By"

    if ($allOffice365ForwardingAddress.count -gt 0)
    {
        foreach ($member in $allOffice365ForwardingAddress)
        {
            $isTestError="No" #Reset error tracking.

            if ($forLoopCounter -eq $forLoopTrigger)
            {
                start-sleepProgress -sleepString "Throttling for 5 seconds...." -sleepSeconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try{
                $isTestError=start-ReplaceOffice365 -office365Attribute $office365Attributes.office365ForwardingAddress.value -office365Member $member -groupSMTPAddress $groupSMTPAddress -errorAction STOP
            }
            catch{
                out-logfile -string $_
                $isTestErrorDetail = $_
                $isTestError="Yes"
            }

            if ($isTestError -eq "Yes")
            {
                out-logfile -string "Error adding forwarding address to a mailbox."

                $isErrorObject = new-Object psObject -property @{
                    distinguishedName = $member.distinguishedName
                    primarySMTPAddress = $member.primarySMTPAddress
                    alias = $member.Alias
                    displayName = $member.displayName
                    attribute = "Distribution List Forwarding Address"
                    errorMessage = "Unable to add the distribution list as a forwarding address to a mailbox recipient."
                    erroMessageDetail = $isTestErrorDetail
                }

                out-logfile -string $isErrorObject

                $office365ReplaceErrors+=$isErrorObject
            }
        }
    }
    else 
    {
        out-LogFile -string "There were no mailboxes in Office 365 with the distribution list as forwarding address."    
    }

    if ($allowNonSyncedGroup -eq $FALSE)
    {
        out-logFile -string "Start replacing Office 365 permissions."

        try 
        {
            set-Office365DLPermissions -allSendAs $allOffice365SendAsAccess -allFullMailboxAccess $allOffice365FullMailboxAccess -allFolderPermissions $allOffice365MailboxFolderPermissions -allOnPremSendAs $allObjectsSendAsAccessNormalized -originalGroupPrimarySMTPAddress $office365DLConfigurationPostMigration.externalDirectoryObjectID -errorAction STOP
        }
        catch 
        {
            out-logfile -string "Unable to set office 365 send as or full mailbox access permissions."
            out-logfile -string $_
            $isTestErrorDetail=$_

            $isErrorObject = new-Object psObject -property @{
                permissionIdentity = "ALL"
                attribute = "Send As / Full Mailbox Access / Mailbox Folder Permissions"
                errorMessage = "Unable to call function to reset send as, full mailbox access, and mailbox folder permissions in Office 365."
                erroMessageDetail = $isTestErrorDetail
            }

            out-logfile -string $isErrorObject

            $global:office365ReplacePermissionsErrors+=$isErrorObject
        }
    }
    
    $telemetryFunctionEndTime = get-universalDateTime

    $telemetryReplaceOffice365Dependency = get-elapsedTime -startTime $telemetryFunctionStartTime -endTime $telemetryFunctionEndTime

    out-logfile -string "Calling function to disconnect all powershell sessions."

    disable-allPowerShellSessions

    Out-LogFile -string "================================================================================"
    Out-LogFile -string "END Start-Office365GroupMigration"
    Out-LogFile -string "================================================================================"

    if (($global:office365ReplacePermissionsErrors.count -gt 0) -or ($global:postCreateErrors.count -gt 0) -or ($onPremReplaceErrors.count -gt 0) -or ($office365ReplaceErrors.count -gt 0) -or ($global:office365ReplacePermissionsErrors.count -gt 0) -or ($generalErrors.count -gt 0))
    {
        out-logfile -string ""
        out-logfile -string "+++++"
        out-logfile -string "++++++++++"
        out-logfile -string "MIGRATION ERRORS OCCURED - REFER TO LIST BELOW FOR ERRORS"
        out-logfile -string ("Post Create Errors: "+$global:postCreateErrors.count)
        out-logfile -string ("On-Premises Replace Errors :"+$onPremReplaceErrors.count)
        out-logfile -string ("Office 365 Replace Errors: "+$office365ReplaceErrors.count)
        out-logfile -string ("Office 365 Replace Permissions Errors: "+$global:office365ReplacePermissionsErrors.count)
        out-logfile -string ("On Prem Replace Permissions Errors: "+$global:onPremReplacePermissionsErrors.count)
        out-logfile -string ("General Errors: "+$generalErrors.count)
        out-logfile -string "++++++++++"
        out-logfile -string "+++++"
        out-logfile -string ""

        if ($global:postCreateErrors.count -gt 0)
        {
            foreach ($createError in $global:postCreateErrors)
            {
                out-logfile -string "====="
                out-logfile -string "Post Create Errors:"
                out-logfile -string ("Primary Email Address or UPN: " +$CreateError.primarySMTPAddressOrUPN)
                out-logfile -string ("External Directory Object ID: " +$CreateError.externalDirectoryObjectID)
                out-logfile -string ("Name: "+$CreateError.name)
                out-logfile -string ("Alias: "+$CreateError.Alias)
                out-logfile -string ("Attribute in Error: "+$CreateError.attribute)
                out-logfile -string ("Error Message: "+$CreateError.errorMessage)
                out-logfile -string ("Error Message Details: "+$CreateError.errorMessageDetail)
                out-logfile -string "====="
            }
        }

        if ($onPremReplaceErrors.count -gt 0)
        {
            foreach ($onPremReplaceError in $onPremReplaceErrors)
            {
                out-logfile -string "====="
                out-logfile -string "Replace On Premises Errors:"
                out-logfile -string ("Distinguished Name: "+$onPremReplaceError.distinguishedName)
                out-logfile -string ("Canonical Domain Name: "+$onPremReplaceError.canonicalDomainName)
                out-logfile -string ("Canonical Name: "+$onPremReplaceError.canonicalName)
                out-logfile -string ("Attribute in Error: "+$onPremReplaceError.attribute)
                out-logfile -string ("Error Message: "+$onPremReplaceError.errorMessage)
                out-logfile -string ("Error Message Details: "+$onPremReplaceError.errorMessageDetail)
                out-logfile -string "====="
            }
        }

       
        if ($office365ReplaceErrors.count -gt 0)
        {
            foreach ($office365ReplaceError in $office365ReplaceErrors)
            {
                out-logfile -string "====="
                out-logfile -string "Replace Office 365 Errors:"
                out-logfile -string ("Distinguished Name: "+$office365ReplaceError.distinguishedName)
                out-logfile -string ("Primary SMTP Address: "+$office365ReplaceError.primarySMTPAddress)
                out-logfile -string ("Alias: "+$office365ReplaceError.alias)
                out-logfile -string ("Display Name: "+$office365ReplaceError.displayName)
                out-logfile -string ("Attribute in Error: "+$office365ReplaceError.attribute)
                out-logfile -string ("Error Message: "+$office365ReplaceError.errorMessage)
                out-logfile -string ("Error Message Details: "+$office365Replace.errorMessageDetail)
                out-logfile -string "====="
            }
        }
        
        if ($global:office365ReplacePermissionsErrors.count -gt 0)
        {
            foreach ($office365ReplacePermissionsError in $global:office365ReplacePermissionsErrors)
            {
                out-logfile -string "====="
                out-logfile -string "Office 365 Permissions Error: "
                out-logfile -string ("Permission in Error: "+$office365ReplacePermissionsError.permissionidentity)
                out-logfile -string ("Attribute in Error: "+$office365ReplacePermissionsError.attribute)
                out-logfile -string ("Error Message: "+$office365ReplacePermissionsError.errorMessage)
                out-logfile -string ("Error Message Detail: "+$office365ReplacePermissionsError.errorMessageDetail)
                out-logfile -string "====="
            }
        }

        if ($global:onPremReplacePermissionsErrors.count -gt 0)
        {
            foreach ($onPremReplacePermissionsError in $global:office365ReplacePermissionsErrors)
            {
                out-logfile -string "====="
                out-logfile -string "On Prem Permissions Error: "
                out-logfile -string ("Permission in Error: "+$office365ReplacePermissionsError.permissionidentity)
                out-logfile -string ("Attribute in Error: "+$office365ReplacePermissionsError.attribute)
                out-logfile -string ("Error Message: "+$office365ReplacePermissionsError.errorMessage)
                out-logfile -string ("Error Message Detail: "+$office365ReplacePermissionsError.errorMessageDetail)
                out-logfile -string "====="
            }
        }
        
        if ($generalErrors.count -gt 0)
        {
            foreach ($generalError in $generalErrors)
            {
                out-logfile -string "====="
                out-logfile -string "General Errors:"
                out-logfile -string ("Error Message: "+$generalError.errorMessage)
                out-logfile -string ("Error Message Detail: "+$generalError.errorMessageDetail)
                out-logfile -string "====="
            }
        }

        out-logfile -string ""
        out-logfile -string "+++++"
        out-logfile -string "++++++++++"
        out-logfile -string "Errors were encountered in the distribution list creation process requireing administrator review."
        out-logfile -string "Although the migration may have been successful - manual actions may need to be taken to full complete the migration."
        out-logfile -string "++++++++++"
        out-logfile -string "+++++"

        $telemetryError = $TRUE
    }

    #Archive the files into a date time success folder.

    $telemetryEndTime = get-universalDateTime
    $telemetryElapsedSeconds = get-elapsedTime -startTime $telemetryStartTime -endTime $telemetryEndTime

    # build the properties and metrics #
    $telemetryEventProperties = @{
        DLConversionV2Command = $telemetryEventName
        DLConversionV2Version = $telemetryDLConversionV2Version
        ExchangeOnlineVersion = $telemetryExchangeOnlineVersion
        AzureADVersion = $telemetryAzureADVersion
        OSVersion = $telemetryOSVersion
        MigrationStartTimeUTC = $telemetryStartTime
        MigrationEndTimeUTC = $telemetryEndTime
        MigrationErrors = $telemetryError
    }

    if (($allowTelemetryCollection -eq $TRUE) -and ($allowDetailedTelemetryCollection -eq $FALSE))
    {
        $telemetryEventMetrics = @{
            MigrationElapsedSeconds = $telemetryElapsedSeconds
            TimeToNormalizeDNs = $telemetryNormalizeDN
            TimeToValidateCloudRecipients = $telemetryValidateCloudRecipients
            TimeToCollectOnPremDependency = $telemetryDependencyOnPrem
            TimeToCollectOffice365Dependency = $telemetryCollectOffice365Dependency
            TimePendingRemoveDLOffice365 = $telemetryTimeToRemoveDL
            TimeToCreateOffice365DLComplete = $telemetryCreateOffice365DL
            TimeToCreateOffice365DLFirstPass = $telemetryCreateOffice365DLFirstPass
            TimeToReplaceOnPremDependency = $telemetryReplaceOnPremDependency
            TimeToReplaceOffice365Dependency = $telemetryReplaceOffice365Dependency
        }
    }
    elseif (($allowTelemetryCollection -eq $TRUE) -and ($allowDetailedTelemetryCollection -eq $TRUE))
    {
        $telemetryEventMetrics = @{
            MigrationElapsedSeconds = $telemetryElapsedSeconds
            TimeToNormalizeDNs = $telemetryNormalizeDN
            TimeToValidateCloudRecipients = $telemetryValidateCloudRecipients
            TimeToCollectOnPremDependency = $telemetryDependencyOnPrem
            TimeToCollectOffice365Dependency = $telemetryCollectOffice365Dependency
            TimePendingRemoveDLOffice365 = $telemetryTimeToRemoveDL
            TimeToCreateOffice365DLComplete = $telemetryCreateOffice365DL
            TimeToReplaceOnPremDependency = $telemetryReplaceOnPremDependency
            TimeToReplaceOffice365Dependency = $telemetryReplaceOffice365Dependency
            NumberOfGroupMembers = $exchangeDLMembershipSMTP.count
            NumberofGroupRejectSenders = $exchangeRejectMessagesSMTP.count
            NumberofGroupAcceptSenders = $exchangeAcceptMessagesSMTP.count
            NumberofGroupManagedBy = $exchangeManagedBySMTP.count
            NumberofGroupModeratedBy = $exchangeModeratedBySMTP.count
            NumberofGroupBypassModerators = $exchangeBypassModerationSMTP.count
            NumberofGroupGrantSendOnBehalfTo = $exchangeGrantSendOnBehalfToSMTP.count
            NumberofGroupSendAsOnGroup = $exchangeSendAsSMTP.Count
            NumberofOnPremsiesMemberOf = $allGroupsMemberOf.Count
            NumberofOnPremisesRejectSenders = $allGroupsReject.Count
            NumberofOnPremisesAcceptSenders = $allGroupsAccept.Count
            NumberofOnPremisesBypassModeration = $allGroupsBypassModeration.Count
            NumberofOnPremisesMailboxForwarding = $allUsersForwardingAddress.Count
            NumberofOnPrmiesesGrantSendBehalfTo = $allGroupsGrantSendOnBehalfTo.Count
            NumberofOnPremisesManagedBy = $allGroupsManagedBy.Count
            NumberofOnPremisesFullMailboxAccess = $allObjectsFullMailboxAccess.Count
            NumberofOnPremsiesSendAs = $allObjectSendAsAccess.Count
            NumberofOnPremisesFolderPermissions = $allMailboxesFolderPermissions.Count
            NumberofOnPremisesCoManagers = $allGroupsCoManagedByBL.Count
            NumberofOffice365Members = $allOffice365MemberOf.Count
            NumberofOffice365AcceptSenders = $allOffice365Accept.Count
            NumberofOffice365RejectSenders = $allOffice365Reject.Count
            NumberofOffice365BypassModeration = $allOffice365BypassModeration.Count
            NumberofOffice365ManagedBy = $allOffice365ManagedBy.Count
            NumberofOffice365GrantSendOnBehalf = $allOffice365GrantSendOnBehalfTo.Count
            NumberofOffice365ForwardingMailboxes= $allOffice365ForwardingAddress.Count
            NumberofOffice365FullMailboxAccess = $allOffice365FullMailboxAccess.Count
            NumberofOffice365SendAs = $allOffice365SendAsAccess.Count
            NumberofOffice365SendAsAccessOnGroup = $allOffice365SendAsAccessOnGroup.Count
            NumberofOffice365MailboxFolderPermissions = $allOffice365MailboxFolderPermissions.Count
        }
    }

    if ($allowTelemetryCollection -eq $TRUE)
    {
        send-TelemetryEvent -traceModuleName $traceModuleName -eventName $telemetryEventName -eventMetrics $telemetryEventMetrics -eventProperties $telemetryEventProperties
    }

    if ($telemetryError -eq $TRUE)
    {
        out-logfile -string "" -isError:$TRUE
    }

    Start-ArchiveFiles -isSuccess:$TRUE -logFolderPath $logFolderPath
}