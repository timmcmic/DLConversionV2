
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


Function get-DLHealthReport
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

    .PARAMETER ACTIVEDIRECTORYAUTHENTICATIONMETHOD

    Allows the administrator to specify kerberos or basic authentication for connections to Active Directory.

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

    .PARAMETER AADCONNECTAUTHENTICATIONMETHOD

    Allows the administrator to specify kerberos or basic authentication for connections to the AADConnect server.

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

    .PARAMETER GROUPTYPEOVERRIDE

    *OPTIONAL*
    This allows the administrator to override the group creation type in Office 365.
    For example, an on premises security group may be migrated to Office 365 as a distribution only list.
    If any security dependencies are discovered during the migration this option is always overridden to preserve security and the settings.

    .PARAMETER TRIGGERUPGRADETOOFFICE365GROUP

    *OPTIONAL*
    *Parameter retained for backwards compatibility but now disabled.*

    .PARAMETER OVERRIDECENTRALIZEDMAILTRANSPORTENABLED

    *OPTIONAL*
    If centralized transport enabled is detected during migration this switch is required.
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

    .PARAMETER ALLOWTELEMETRYCOLLECTION

    Allows administrators to opt out of telemetry collection for DL migrations.  No identifiable information is collected in telemetry.

    .PARAMETER ALLOWDETAILEDTELEMETRYCOLLECTIOn

    Allows administrators to opt out of detailed telemetry collection.  Detailed telemetry collection includes information such as attribute member counts and time to process stages of the migration.

    .PARAMETER ISHEALTHCHECK

    Specifies if the function call is performing a distribution list health check.

    .OUTPUTS

    Logs all activities and backs up all original data to the log folder directory.
    Moves the distribution group from on premieses source of authority to office 365 source of authority.

    .NOTES

    The following blog posts maintain documentation regarding this module.

    https://timmcmic.wordpress.com.  

    Refer to the first pinned blog post that is the table of contents.

    
    .EXAMPLE

    Start-DistributionListMigration -groupSMTPAddress $groupSMTPAddress -globalCatalogServer server.domain.com -activeDirectoryCredential $cred -logfolderpath c:\temp -dnNoSyncOU "OU" -exchangeOnlineCredential $cred -azureADCredential $cred

    .EXAMPLE

    Start-DistributionListMigration -groupSMTPAddress $groupSMTPAddress -globalCatalogServer server.domain.com -activeDirectoryCredential $cred -logfolderpath c:\temp -dnNoSyncOU "OU" -exchangeOnlineCredential $cred -azureADCredential $cred -enableHybridMailFlow:$TRUE -triggerUpgradeToOffice365Group:$TRUE

    .EXAMPLE

    Start-DistributionListMigration -groupSMTPAddress $groupSMTPAddress -globalCatalogServer server.domain.com -activeDirectoryCredential $cred -logfolderpath c:\temp -dnNoSyncOU "OU" -exchangeOnlineCredential $cred -azureADCredential $cred -enableHybridMailFlow:$TRUE -triggerUpgradeToOffice365Group:$TRUE -useCollectedOnPremMailboxFolderPermissions:$TRUE -useCollectedOffice365MailboxFolderPermissions:$TRUE -useCollectedOnPremSendAs:$TRUE -useCollectedOnPremFullMailboxAccess:$TRUE -useCollectedOffice365FullMailboxAccess:$TRUE

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
        [boolean]$useCollectedFullMailboxAccessOnPrem=$FALSE,
        [Parameter(Mandatory = $false)]
        [boolean]$useCollectedFullMailboxAccessOffice365=$FALSE,
        [Parameter(Mandatory = $false)]
        [boolean]$useCollectedSendAsOnPrem=$FALSE,
        [Parameter(Mandatory = $false)]
        [boolean]$useCollectedFolderPermissionsOnPrem=$FALSE,
        [Parameter(Mandatory = $false)]
        [boolean]$useCollectedFolderPermissionsOffice365=$FALSE,
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
    [boolean]$telemetryError=$FALSE


    $windowTitle = ("get-DLHealthReport "+$groupSMTPAddress)
    $host.ui.RawUI.WindowTitle = $windowTitle


    $global:logFile=$NULL #This is the global variable for the calculated log file name
    [string]$global:staticFolderName="\DLHealthCheck\"
    [string]$global:staticAuditFolderName="\AuditData\"
    [string]$global:importFile=$logFolderPath+$global:staticAuditFolderName


    [array]$global:testOffice365Errors=@()

    [array]$htmlSections = @()


    #Define variables for import data - used for importing data into pre-collect.

    [array]$importData=@() #Empty array for the import data.
    [string]$importFilePath=$NULL #Import file path where the XML data is located to import (calculated later)    

    #For mailbox folder permissions set these to false.
    #Supported methods for gathering folder permissions require use of the pre-collection.
    #Precolletion automatically sets these to true.  These were origianlly added to support doing it at runtime - but its too slow.
    
    [boolean]$retainMailboxFolderPermsOnPrem=$FALSE
    [boolean]$retainMailboxFolderPermsOffice365=$FALSE
    [boolean]$retainOffice365Settings=$true
    [boolean]$retainFullMailboxAccessOnPrem=$FALSE
    [boolean]$retainSendAsOnPrem=$FALSE
    [boolean]$retainFullMailboxAccessOffice365=$FALSE
    [boolean]$retainSendAsOffice365=$TRUE

    #Define variables utilized in the core function that are not defined by parameters.

    $coreVariables = @{ 
        useOnPremisesExchange = @{ "Value" = $FALSE ; "Description" = "Boolean determines if Exchange on premises should be utilized" }
        useAADConnect = @{ "Value" = $FALSE ; "Description" = "Boolean determines if an AADConnect isntance will be utilzied" }
        exchangeOnPremisesPowershellSessionName = @{ "Value" = "ExchangeOnPremises" ; "Description" = "Static exchange on premises powershell session name" }
        aadConnectPowershellSessionName = @{ "Value" = "AADConnect" ; "Description" = "Static AADConnect powershell session name" }
        ADGlobalCatalogPowershellSessionName = @{ "Value" = "ADGlobalCatalog" ; "Description" = "Static AD Domain controller powershell session name" }
        exchangeOnlinePowershellModuleName = @{ "Value" = "ExchangeOnlineManagement" ; "Description" = "Static Exchange Online powershell module name" }
        activeDirectoryPowershellModuleName = @{ "Value" = "ActiveDirectory" ; "Description" = "Static active directory powershell module name" }
        azureActiveDirectoryPowershellModuleName = @{ "Value" = "AzureAD" ; "Description" = "Static azure active directory powershell module name" }
        dlConversionPowershellModule = @{ "Value" = "DLConversionV2" ; "Description" = "Static dlConversionv2 powershell module name" }
        globalCatalogPort = @{ "Value" = ":3268" ; "Description" = "Global catalog port definition" }
        globalCatalogWithPort = @{ "Value" = ($globalCatalogServer+($corevariables.globalCatalogPort.value)) ; "Description" = "Global catalog server with port" }
    }

    #The variables below are utilized to define working parameter sets.
    #Some variables are assigned to single values - since these will be utilized with functions that query or set information.

    $onPremADAttributes = @{
        onPremAcceptMessagesFromDLMembers = @{"Value" = "dlMemSubmitPerms" ; "Description" = "LDAP Attribute for Accept Messages from DL Members"}
        onPremAcceptMessagesFromDLMembersCommon = @{"Value" = "AcceptMessagesFromMembers" ; "Description" = "LDAP Attribute for Accept Messages from DL Members"}
        onPremRejectMessagesFromDLMembers = @{"Value" = "dlMemRejectPerms" ; "Description" = "LDAP Attribute for Reject Messages from DL Members"}
        onPremRejectMessagesFromDLMembersCommon = @{"Value" = "RejectMessagesFromMembers" ; "Description" = "LDAP Attribute for Reject Messages from DL Members"}
        onPremBypassModerationFromDL = @{"Value" = "msExchBypassModerationFromDLMembersLink" ; "Description" = "LDAP Attribute for Bypass Moderation from DL Members"}
        onPremBypassModerationFromDLCommon = @{"Value" = "BypassModerationFromSendersOrMembers" ; "Description" = "LDAP Attribute for Bypass Moderation from DL Members"}
        onPremForwardingAddress = @{"Value" = "altRecipient" ; "Description" = "LDAP Attribute for ForwardingAddress"}
        onPremForwardingAddressCommon = @{"Value" = "ForwardingAddress" ; "Description" = "LDAP Attribute for ForwardingAddress"}
        onPremGrantSendOnBehalfTo = @{"Value" = "publicDelegates" ; "Description" = "LDAP Attribute for Grant Send on Behalf To"}
        onPremGrantSendOnBehalfToCommon = @{"Value" = "GrantSendOnBehalfTo" ; "Description" = "LDAP Attribute for Grant Send on Behalf To"}
        onPremRejectMessagesFromSenders = @{"Value" = "unauthorig" ; "Description" = "LDAP Attribute for Reject Messages from Sender"}
        onPremRejectMessagesFromSendersCommon = @{"Value" = "RejectMessagesFromSenders" ; "Description" = "LDAP Attribute for Reject Messages from Sender"}
        onPremAcceptMessagesFromSenders = @{"Value" = "authOrig" ; "Description" = "LDAp Attribute for Accept Messages From Sender"} 
        onPremAcceptMessagesFromSendersCommon = @{"Value" = "AcceptMessagesFromSenders" ; "Description" = "LDAp Attribute for Accept Messages From Sender"} 
        onPremManagedBy = @{"Value" = "managedBy" ; "Description" = "LDAP Attribute for Managed By"}
        onPremManagedByCommon = @{"Value" = "ManagedBy" ; "Description" = "LDAP Attribute for Managed By"}
        onPremCoManagedBy = @{"Value" = "msExchCoManagedByLink" ; "Description" = "LDAP Attributes for Co Managers (Muiltivalued ManagedBy)"}
        onPremCoManagedByCommon = @{"Value" = "ManagedBy" ; "Description" = "LDAP Attributes for Co Managers (Muiltivalued ManagedBy)"}
        onPremModeratedBy = @{"Value" = "msExchModeratedByLink" ; "Description" = "LDAP Attrbitute for Moderated By"}
        onPremModeratedByCommon = @{"Value" = "ModeratedBy" ; "Description" = "LDAP Attrbitute for Moderated By"}
        onPremBypassModerationFromSenders = @{"Value" = "msExchBypassModerationLink" ; "Description" = "LDAP Attribute for Bypass Moderation from Senders"}
        onPremBypassModerationFromSendersCommon = @{"Value" = "BypassModerationFromSendersorMembers" ; "Description" = "LDAP Attribute for Bypass Moderation from Senders"}
        onPremMembers = @{"Value" = "member" ; "Description" = "LDAP Attribute for Distribution Group Members" }
        onPremMembersCommon = @{"Value" = "Member" ; "Description" = "LDAP Attribute for Distribution Group Members" }
        onPremForwardingAddressBL = @{"Value" = "altRecipientBL" ; "Description" = "LDAP Backlink Attribute for Forwarding Address"}
        onPremRejectMessagesFromDLMembersBL = @{"Value" = "dlMemRejectPermsBL" ; "Description" = "LDAP Backlink Attribute for Reject Messages from DL Members"}
        onPremAcceptMessagesFromDLMembersBL = @{"Value" = "dlMemSubmitPermsBL" ; "Description" = "LDAP Backlink Attribute for Accept Messages from DL Members"}
        onPremManagedObjects = @{"Value" = "managedObjects" ; "Description" = "LDAP Backlink Attribute for Managed By"}
        onPremMemberOf = @{"Value" = "memberOf" ; "Description" = "LDAP Backlink Attribute for Members"}
        onPremBypassModerationFromDLMembersBL = @{"Value" = "msExchBypassModerationFromDLMembersBL" ; "Description" = "LDAP Backlink Attribute for Bypass Moderation from DL Members"}
        onPremCoManagedByBL = @{"Value" = "msExchCoManagedObjectsBL" ; "Description" = "LDAP Backlink Attribute for Co Managers (Multivalued ManagedBY)"}
        onPremGrantSendOnBehalfToBL = @{"Value" = "publicDelegatesBL" ; "Description" = "LDAP Backlink Attribute for Grant Send On Behalf To"}
        onPremGroupType = @{"Value" = "groupType" ; "Description" = "Value representing universal / global / local / security / distribution"}
    }

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
        office365DLMembershipXML = @{ "Value" =  "office365DLMembershipXML" ; "Description" = "XML file that exports the Office 365 DL membership post migration"}
        exchangeDLMembershipSMTPXML = @{ "Value" =  "exchangeDLMemberShipSMTPXML" ; "Description" = "XML file that holds the SMTP addresses of the on premises DL membership"}
        exchangeRejectMessagesSMTPXML = @{ "Value" =  "exchangeRejectMessagesSMTPXML" ; "Description" = "XML file that holds the Reject Messages From Senders or Members property of the on premises DL"}
        exchangeAcceptMessagesSMTPXML = @{ "Value" =  "exchangeAcceptMessagesSMTPXML" ; "Description" = "XML file that holds the Accept Messages from Senders or Members property of the on premises DL"}
        exchangeManagedBySMTPXML = @{ "Value" =  "exchangeManagedBySMTPXML" ; "Description" = "XML file that holds the ManagedBy proprty of the on premises DL"}
        exchangeModeratedBySMTPXML = @{ "Value" =  "exchangeModeratedBYSMTPXML" ; "Description" = "XML file that holds the Moderated By property of the on premises DL"}
        exchangeBypassModerationSMTPXML = @{ "Value" =  "exchangeBypassModerationSMTPXML" ; "Description" = "XML file that holds the Bypass Moderation From Senders or Members property of the on premises DL"}
        exchangeGrantSendOnBehalfToSMTPXML = @{ "Value" =  "exchangeGrantSendOnBehalfToXML" ; "Description" = "XML file that holds the Grant Send On Behalf To property of the on premises DL"}
        exchangeSendAsSMTPXML = @{ "Value" =  "exchangeSendASSMTPXML" ; "Description" = "XML file that holds the Send As rights of the on premises DL"}
        allGroupsMemberOfXML = @{ "Value" =  "allGroupsMemberOfXML" ; "Description" = "XML file that holds all of on premises groups the migrated group is a member of"}
        allGroupsRejectXML = @{ "Value" =  "allGroupsRejectXML" ; "Description" = "XML file that holds all of the on premises groups the migrated group has reject rights assigned"}
        allGroupsAcceptXML = @{ "Value" =  "allGroupsAcceptXML" ; "Description" = "XML file that holds all of the on premises groups the migrated group has accept rights assigned"}
        allGroupsBypassModerationXML = @{ "Value" =  "allGroupsBypassModerationXML" ; "Description" = "XML file that holds all of the on premises groups that the migrated group has bypass moderation rights assigned"}
        allUsersForwardingAddressXML = @{ "Value" =  "allUsersForwardingAddressXML" ; "Description" = "XML file that holds all recipients the migrated group hsa forwarding address set on"}
        allGroupsGrantSendOnBehalfToXML = @{ "Value" =  "allGroupsGrantSendOnBehalfToXML" ; "Description" = "XML file that holds all of the on premises objects that the migrated group hsa grant send on behalf to on"}
        allGroupsManagedByXML = @{ "Value" =  "allGroupsManagedByXML" ; "Description" = "XML file that holds all of the on premises objects the migrated group has managed by rights assigned"}
        allGroupsSendAsXML = @{ "Value" =  "allGroupSendAsXML" ; "Description" = "XML file that holds all of the on premises objects that have the migrated group with send as rights assigned"}
        allGroupsSendAsNormalizedXML= @{ "Value" = "allGroupsSendAsNormalizedXML" ; "Description" = "XML file that holds all normalized send as right"}
        allGroupsFullMailboxAccessXML = @{ "Value" =  "allGroupsFullMailboxAccessXML" ; "Description" = "XML file that holds all full mailbox access rights assigned to the migrated group"}
        allMailboxesFolderPermissionsXML = @{ "Value" =  "allMailboxesFolderPermissionsXML" ; "Description" = "XML file that holds all mailbox folder permissions assigned to the migrated group"}
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
        routingContactXML= @{ "Value" = "routingContactXML" ; "Description" = "XML file holds the routing contact configuration when intially created"}
        routingDynamicGroupXML= @{ "Value" = "routingDynamicGroupXML" ; "Description" = "XML file holds the routing contact configuration when mail enabled"}
        allGroupsCoManagedByXML= @{ "Value" = "allGroupsCoManagedByXML" ; "Description" = "XML file holds all on premises objects that the migrated group has managed by rights assigned"}
        retainOffice365RecipientFullMailboxAccessXML= @{ "Value" = "office365RecipientFullMailboxAccess.xml" ; "Description" = "Import XML file for pre-gathered full mailbox access rights in Office 365"}
        retainMailboxFolderPermsOffice365XML= @{ "Value" = "office365MailboxFolderPermissions.xml" ; "Description" = "Import XML file for pre-gathered mailbox folder permissions in Office 365"}
        retainOnPremRecipientFullMailboxAccessXML= @{ "Value" = "onPremRecipientFullMailboxAccess.xml" ; "Description" = "Import XML for pre-gathered full mailbox access rights "}
        retainOnPremMailboxFolderPermissionsXML= @{ "Value" = "onPremailboxFolderPermissions.xml" ; "Description" = "Import XML file for mailbox folder permissions"}
        retainOnPremRecipientSendAsXML= @{ "Value" = "onPremRecipientSendAs.xml" ; "Description" = "Import XML file for send as permissions"}
        azureDLConfigurationXML = @{"Value" = "azureADDL" ; "Description" = "Export XML file holding the configuration from azure active directory"}
        azureDLMembershipXML = @{"Value" = "azureADDLMembership" ; "Description" = "Export XML file holding the membership of the Azure AD group"}
        preCreateErrorsXML = @{"value" = "preCreateErrors" ; "Description" = "Export XML of all precreate errors for group to be migrated."}
        testOffice365ErrorsXML = @{"value" = "testOffice365Errors" ; "Description" = "Export XML of all tested recipient errors in Offic3 365."}
        office365AcceptMessagesFromSendersOrMembersXML= @{"value" = "office365AcceptMessagesFromSendersOrMembers" ; "Description" = "Export XML of all Office 365 accept messages from senders or member normalized."}
        office365RejectMessagesFromSendersOrMembersXML= @{"value" = "office365RejectMessagesFromSendersOrMembers" ; "Description" = "Export XML of all Office 365 reject messages from senders or member normalized."}
        office365ModeratedByXML= @{"value" = "office365ModeratedByXML" ; "Description" = "Export XML of all Office 365 moderatedBy normalized."}
        office365BypassModerationFromSendersOrMembersXML= @{"value" = "office365BypassModerationFromSendersOrMembers" ; "Description" = "Export XML of all Office 365 bypass moderatios from senders or member normalized."}
        office365ManagedByXML= @{"value" = "office365ManagedBy" ; "Description" = "Export XML of all Office 365 managedby normalized."}
        office365GrantSendOnBehalfToXML= @{"value" = "office365GrantSendOnBehalfToXML" ; "Description" = "Export XML of all Office 365 grant send on behalf to normalized."}
        onPremMemberEvalXML= @{"value" = "onPremMemberEvalXML" ; "Description" = "Export XML of all Office 365 grant send on behalf to normalized."}
        office365MemberEvalXML = @{"value" = "office365MemberEvalXML" ; "Description" = "Export XML of all Office 365 grant send on behalf to normalized."}
        office365AcceptMessagesFromSendersOrMembersEvalXML = @{"value" = "office365AcceptMessagesFromSendersOrMembersEvalXML" ; "Description" = "Export XML of all Office 365 grant send on behalf to normalized."}
        office365RejectMessagesFromSendersOrMembersEvalXML = @{"value" = "office365RejectMessagesFromSendersOrMembersEvalXML" ; "Description" = "Export XML of all Office 365 grant send on behalf to normalized."}
        office365ModeratedByEvalXML = @{"value" = "office365ModeratedByEvalXML" ; "Description" = "Export XML of all Office 365 grant send on behalf to normalized."}
        office365BypassMOderationFromSendersOrMembersEvalXML = @{"value" = "office365BypassModerationFromSendersOrMembersEvalXML" ; "Description" = "Export XML of all Office 365 grant send on behalf to normalized."}
        office365ManagedByEvalXML = @{"value" = "office365ManagedByEvalXML" ; "Description" = "Export XML of all Office 365 grant send on behalf to normalized."}
        office365GrantSendOnBehalfToEvalXML = @{"value" = "office365GrantSendOnBehalfToEvalXML" ; "Description" = "Export XML of all Office 365 grant send on behalf to normalized."}
        office365ProxyAddressesEvalXML = @{"value" = "office365ProxyAddressesEvalXML" ; "Description" = "Export XML of all Office 365 grant send on behalf to normalized."}
        office365AttributeEvalXML = @{"value" = "office365AttributeEvalXML" ; "Description" = "Export XML of all Office 365 grant send on behalf to normalized."}
        summaryCountsXML = @{"value" = "summaryCountsXML" ; "Description" = "Export XML of all Office 365 grant send on behalf to normalized."}
    }


    [array]$dlPropertySet = '*' #Clear all properties of a given object

    #On premises variables for the distribution list to be migrated.

    $originalDLConfiguration=$NULL #This holds the on premises DL configuration for the group to be migrated.
    [array]$exchangeDLMembershipSMTP=@() #Array of DL membership from AD.
    [array]$exchangeRejectMessagesSMTP=@() #Array of members with reject permissions from AD.
    [array]$exchangeAcceptMessagesSMTP=@() #Array of members with accept permissions from AD.
    [array]$exchangeManagedBySMTP=@() #Array of members with manage by rights from AD.
    [array]$exchangeModeratedBySMTP=@() #Array of members  with moderation rights.
    [array]$exchangeBypassModerationSMTP=@() #Array of objects with bypass moderation rights from AD.
    [array]$exchangeGrantSendOnBehalfToSMTP=@() #Array of objects with grant send on behalf to normalized SMTP
    [array]$exchangeSendAsSMTP=@() #Array of objects wtih send as rights normalized SMTP

    #The following variables hold information regarding other groups in the environment that have dependnecies on the group to be migrated.

    [array]$allGroupsMemberOf=$NULL #Complete AD information for all groups the migrated group is a member of.
    [array]$allGroupsReject=$NULL #Complete AD inforomation for all groups that the migrated group has reject mesages from.
    [array]$allGroupsAccept=$NULL #Complete AD information for all groups that the migrated group has accept messages from.
    [array]$allGroupsBypassModeration=$NULL #Complete AD information for all groups that the migrated group has bypass moderations.
    [array]$allUsersForwardingAddress=$NULL #All users on premsies that have this group as a forwarding DN.
    [array]$allGroupsGrantSendOnBehalfTo=$NULL #All dependencies on premsies that have grant send on behalf to.
    [array]$allGroupsManagedBy=$NULL #All dependencies on premises that have managed by rights
    [array]$allObjectsFullMailboxAccess=$NULL #All dependencies on premises that have full mailbox access rights
    [array]$allObjectSendAsAccess=$NULL #All dependencies on premises that have the migrated group with send as rights.
    [array]$allObjectsSendAsAccessNormalized=@() #All dependencies send as rights normalized
    [array]$allMailboxesFolderPermissions=@() #All dependencies on premises with mailbox folder permissions defined
    [array]$allGroupsCoManagedByBL=$NULL #All groups on premises where the migrated group is a manager

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

    #Define normlaized variables for the Office 365 group.

    [array]$office365AcceptMessagesFromSendersOrMembers=$NULL
    [array]$office365RejectMessagesFromSendersOrMembers=$NULL
    [array]$office365ModeratedBy=$NULL
    [array]$office365BypassModerationFromSendersOrMembers=$NULL
    [array]$office365ManagedBy = $NULL
    [array]$office365GrantSendOnBehalfTo = $NULL
    [array]$office365DLMembership = $NULL
    
    
    #Cloud variables for the distribution list to be migrated.

    $office365DLConfiguration = $NULL #This holds the office 365 DL configuration for the group to be migrated.
    $azureADDlConfiguration = $NULL #This holds the Azure AD DL configuration
    $azureADDlMembership = $NULL

    #Create arrays to track the health objects that will be converted in the reprot.

    [array]$onPremMemberEval = @()
    [array]$office365MemberEval = @()
    [array]$office365AcceptMessagesFromSendersOrMembersEval=@()
    [array]$office365RejectMessagesFromSendrsOfMembersEval=@()
    [array]$office365ModeratedByEval=@()
    [array]$office365BypassModerationFromSendersOrMembersEval=@()
    [array]$office365ManagedByEval=@()
    [array]$office365GrantSendOnBehalfToEval=@()
    [array]$office365ProxyAddressesEval = @()
    [array]$office365AttributeEval = @()

    #For loop counter.

    [int]$forLoopCounter=0

    [int]$forLoopTrigger=1000

    #Define variables for kerberos enablement.

    $commandStartTime = get-date
    $commandEndTime = $NULL
    [int]$kerberosRunTime = 4


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

    if ($azureADCreential -ne $NULL)
    {
        out-logfile -string ("AzureADUserName = "+$azureADCredential.userName.toString())
    }

    Out-LogFile -string "********************************************************************************"

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string " RECORD VARIABLES"
    Out-LogFile -string "********************************************************************************"

    out-logfile -string ("Global import file: "+$global:importFile)
    out-logfile -string ("Global staticFolderName: "+$global:staticFolderName)
    out-logfile -string ("Global threadNumber: "+$global:threadNumber)

    write-hashTable -hashTable $xmlFiles
    write-hashTable -hashTable $office365Attributes
    write-hashTable -hashTable $onPremADAttributes
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

    #Validate that an OU was specified <if> retain group is not set to true.

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

    # EXIT #Debug Exit

    #If exchange server information specified - create the on premises powershell session.

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "ESTABLISH POWERSHELL SESSIONS"
    Out-LogFile -string "********************************************************************************"

   #Test to determine if the exchange online powershell module is installed.
   #The exchange online session has to be established first or the commandlet set from on premises fails.

   Out-LogFile -string "Calling Test-PowerShellModule to validate the Exchange Module is installed."

   $telemetryExchangeOnlineVersion = Test-PowershellModule -powershellModuleName $corevariables.exchangeOnlinePowershellModuleName.value -powershellVersionTest:$TRUE

   Out-LogFile -string "Calling Test-PowerShellModule to validate the Active Directory is installed."

   $telemetryActiveDirectoryVersion = Test-PowershellModule -powershellModuleName $corevariables.activeDirectoryPowershellModuleName.value

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

    #Establish powershell session to the global catalog server.

    try 
    {
        Out-LogFile -string "Establish powershell session to the global catalog server specified."

        new-powershellsession -server $globalCatalogServer -credentials $activeDirectoryCredential -powershellsessionname $coreVariables.ADGlobalCatalogPowershellSessionName.value -authenticationType $activeDirectoryAuthenticationMethod
    }
    catch 
    {
        out-logfile -string "Unable to create remote powershell session to the AD Global Catalog server."
        out-logfile -string $_ -isError:$TRUE
    }
    

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END ESTABLISH POWERSHELL SESSIONS"
    Out-LogFile -string "********************************************************************************"

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

    out-logfile -string "Creating the HTML representation of this data for reporting."

    if ($originalDLConfiguration -ne $NULL)
    {
        $params = @{'As'='List';
                    'MakeHiddenSection'=$true;
                    'PreContent'='<h2>&diams;Active Directory Distribution List Configuration</h2>'}

        $html_originalDLConfig = ConvertTo-EnhancedHTMLFragment -inputObject $originalDLConfiguration @params

        $htmlSections += $html_originalDLConfig
    }

    
    Out-LogFile -string "Log original DL configuration."
    out-logFile -string $originalDLConfiguration

    Out-LogFile -string "Create an XML file backup of the on premises DL Configuration"

    Out-XMLFile -itemToExport $originalDLConfiguration -itemNameToExport $xmlFiles.originalDLConfigurationADXML.value

    Out-LogFile -string "Determine if administrator desires to audit send as."

    if ($retainSendAsOnPrem -eq $TRUE)
    {
        out-logfile -string "Administrator has choosen to audit on premsies send as."
        out-logfile -string "NOTE:  THIS IS A LONG RUNNING OPERATION."

        if ($useCollectedSendAsOnPrem -eq $TRUE)
        {
            out-logfile -string "Administrator has selected to import previously gathered permissions."
            
            $importFilePath=Join-path $importFile $xmlFiles.retainOnPremRecipientSendAsXML.value

            try {
                $importData = import-CLIXML -path $importFilePath
            }
            catch {
                out-logfile -string "Error importing the send as permissions from collect function."
                out-logfile -string $_ -isError:$TRUE
            }

            try {
                $allObjectSendAsAccess = get-onPremSendAs -originalDLConfiguration $originalDLConfiguration -collectedData $importData
            }
            catch {
                out-logfile -string "Unable to process send as rights on premises."
                out-logfile -string $_ -isError:$TRUE
            }  
        }
        else 
        {
            try {
                $allObjectSendAsAccess = Get-onPremSendAs -originalDLConfiguration $originalDLConfiguration
            }
            catch {
                out-logfile -string "Unable to process send as rights on premsies."
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }
    else
    {
        out-logfile -string "Administrator has choosen to not audit on premises send as."
    }

    #Record what was returned.

    if ($allObjectSendAsAccess.count -ne 0)
    {
        out-logfile -string $allObjectSendAsAccess

        out-xmlFile -itemToExport $allObjectSendAsAccess -itemNameToExport $xmlFiles.allGroupsSendAsXML.value
    }

    Out-LogFile -string "Determine if administrator desires to audit full mailbox access."

    if ($retainFullMailboxAccessOnPrem -eq $TRUE)
    {
        out-logfile -string "Administrator has choosen to audit on premsies full mailbox access."
        out-logfile -string "NOTE:  THIS IS A LONG RUNNING OPERATION."

        if ($useCollectedFullMailboxAccessOnPrem -eq $TRUE)
        {
            out-logfile -string "Administrator has selected to import previously gathered permissions."

            $importFilePath=Join-path $importFile $xmlFiles.retainOnPremRecipientFullMailboxAccessXML.value

            try {
                $importData = import-CLIXML -path $importFilePath
            }
            catch {
                out-logfile -string "Error importing the send as permissions from collect function."
                out-logfile -string $_ -isError:$TRUE
            }

            $allObjectsFullMailboxAccess = Get-onPremFullMailboxAccess -originalDLConfiguration $originalDLConfiguration -collectedData $importData
        }
        else 
        {
            $allObjectsFullMailboxAccess = Get-onPremFullMailboxAccess -originalDLConfiguration $originalDLConfiguration
        }
    }
    else
    {
        out-logfile -string "Administrator has choosen to not audit on premises full mailbox access."
    }

    #Record what was returned.

    if ($allObjectsFullMailboxAccess.count -ne 0)
    {
        out-logfile -string $allObjectsFullMailboxAccess

        out-xmlFile -itemToExport $allObjectsFullMailboxAccess -itemNameToExport $xmlFiles.allGroupsFullMailboxAccessXML.value
    }

    out-logfile -string "Determine if the administrator has choosen to audit folder permissions on premsies."

    if ($retainMailboxFolderPermsOnPrem -eq $TRUE)
    {
        out-logfile -string "Administrator has choosen to retain mailbox folder permissions.."
        out-logfile -string "NOTE:  THIS IS A LONG RUNNING OPERATION."

        if ($useCollectedFolderPermissionsOnPrem -eq $TRUE)
        {
            out-logfile -string "Administrator has selected to import previously gathered permissions."

            $importFilePath=Join-path $importFile $xmlFiles.retainOnPremMailboxFolderPermissionsXML.value

            try {
                $importData = import-CLIXML -path $importFilePath
            }
            catch {
                out-logfile -string "Error importing the send as permissions from collect function."
                out-logfile -string $_ -isError:$TRUE
            }

            try {
                $allMailboxesFolderPermissions = get-onPremFolderPermissions -originalDLConfiguration $originalDLConfiguration -collectedData $importData
            }
            catch {
                out-logfile -string "Unable to process on prem folder permissions."
                out-logfile -string $_ -isError:$TRUE
            }  
        }
    }
    else
    {
        out-logfile -string "Administrator has choosen to not audit on premises send as."
    }

    #Record what was returned.

    if ($allMailboxesFolderPermissions.count -ne 0)
    {
        out-logfile -string $allMailboxesFolderPermissions

        out-xmlFile -itemToExport $allMailboxesFolderPermissions -itemNameToExport $xmlFiles.allMailboxesFolderPermissionsXML.value
    }

    #exit #Debug Exit

    Out-LogFile -string "Capture the original office 365 distribution list information."

    try 
    {
        $office365DLConfiguration=Get-O365DLConfiguration -groupSMTPAddress $groupSMTPAddress -isFirstPass:$TRUE -errorAction STOP
    }
    catch 
    {
        out-logFile -string $_ -isError:$TRUE
    }    

    out-logfile -string "Creating the HTML representation of this object for reporting."

    if ($office365DlConfiguration -ne $NULL)
    {
        $params = @{'As'='List';
                    'MakeHiddenSection'=$true;
                    'PreContent'='<h2>&diams;Exchange Online Distribution List Configuration</h2>'}

        $html_office365DLConfig = ConvertTo-EnhancedHTMLFragment -inputObject $office365DLConfiguration @params

        $htmlSections += $html_office365DLConfig
    }
    
    Out-LogFile -string $office365DLConfiguration

    Out-LogFile -string "Create an XML file backup of the office 365 DL configuration."

    Out-XMLFile -itemToExport $office365DLConfiguration -itemNameToExport $xmlFiles.office365DLConfigurationXML.value

    out-logfile -string "Capture the Office 365 DL membership."

    try {
        $office365DLMembership = get-o365DLMembership -groupSMTPAddress $office365DLConfiguration.externalDirectoryObjectID -errorAction STOP
    }
    catch {
        out-logfile $_ -isError:$TRUE
    }

    if ($office365DLMembership -ne $NULL)
    {
        out-logfile -string $office365DLMembership

        out-xmlfile -itemToExport $office365DLMembership -itemNameToExport $xmlFiles.office365DLMembershipXML.value
    }
    else
    {
        out-logfile -string "No members to process."

        $office365DLMembership=@()
    }

    
    out-logfile -string "Capture the original Azure AD distribution list informaiton"

    try{
        $azureADDLConfiguration = get-AzureADDLConfiguration -office365DLConfiguration $office365DLConfiguration
    }
    catch{
        out-logfile -string $_
        out-logfile -string "Unable to obtain Azure Active Directory DL Configuration"
    }

    out-logfile -string "Creating the Azure AD HTML representation"

    if ($azureADDLConfiguration -ne $NULL)
    {
        $params = @{'As'='List';
                    'MakeHiddenSection'=$true;
                    'PreContent'='<h2>&diams;Azure Active Directory Distribution List Configuration</h2>'}

        $html_AzureADDLConfig = ConvertTo-EnhancedHTMLFragment -inputObject $azureADDLConfiguration @params

        $htmlSections += $html_AzureADDLConfig
    }

    if ($azureADDLConfiguration -ne $NULL)
    {
        out-logfile -string $azureADDLConfiguration

        out-logfile -string "Create an XML file backup of the Azure AD DL Configuration"

        out-xmlFile -itemToExport $azureADDLConfiguration -itemNameToExport $xmlFiles.azureDLConfigurationXML.value
    }

    out-logfile -string "Recording Azure AD DL membership."

    try {
        $azureADDLMembership = get-AzureADMembership -groupobjectID $azureADDLConfiguration.objectID -errorAction STOP
    }
    catch {
        out-logfile -string "Unable to obtain Azure AD DL Membership."
        out-logfile -string $_
    }

    if ($azureADDLMembership -ne $NULL)
    {
        out-logfile -string $azureADDLMembership

        out-logfile -string "Creating an XML file backup of the Azure AD DL Membership."

        out-xmlFile -itemToExport $azureADDLMembership -itemNameToExport $xmlFiles.azureDLMembershipXML.Value
    }
    else 
    {
        $azureADDLMembership = @()
    }

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

    Out-LogFile -string "Invoke get-normalizedDNAD to normalize the members DN to Office 365 identifier."

    if ($originalDLConfiguration.($onPremADAttributes.onPremMembers.Value) -ne $NULL)
    {
        foreach ($DN in $originalDLConfiguration.($onPremADAttributes.onPremMembers.Value))
        {
            #Resetting error variable.

            $isTestError="No"

            if ($forLoopCounter -eq $forLoopTrigger)
            {
                start-sleepProgress -sleepString "Throttling for 5 seconds..." -sleepSeconds 5

                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try 
            {
                $normalizedTest = get-normalizedDNAD -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -isMember:$TRUE -activeDirectoryAttribute $onPremADAttributes.onPremMembers.Value -activeDirectoryAttributeCommon $onPremADAttributes.onPremMembersCommon.Value -groupSMTPAddress $groupSMTPAddress -errorAction STOP -cn "None"

                out-logfile -string $normalizedTest

                $exchangeDLMembershipSMTP+=$normalizedTest                
            }
            catch 
            {
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }

    if ($exchangeDLMembershipSMTP -ne $NULL)
    {
        Out-LogFile -string "The following objects are members of the group:"
        
        out-logfile -string $exchangeDLMembershipSMTP
    }
    else 
    {
        out-logFile -string "The distribution group has no members."    
    }

    Out-LogFile -string "Invoke get-normalizedDNAD to normalize the reject members DN to Office 365 identifier."

    Out-LogFile -string "REJECT USERS"

    if ($originalDLConfiguration.($onPremADAttributes.onPremRejectMessagesFromSenders.value) -ne $NULL)
    {
        foreach ($DN in $originalDLConfiguration.($onPremADAttributes.onPremRejectMessagesFromSenders.value))
        {
            if ($forLoopCounter -eq $forLoopTrigger)
            {
                start-sleepProgress -sleepString "Throttling for 5 seconds..." -sleepSeconds 5

                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try 
            {
                $normalizedTest = get-normalizedDNAD -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -activeDirectoryAttribute $onPremADAttributes.onPremRejectMessagesFromSenders.value -activeDirectoryAttributeCommon $onPremADAttributes.onPremRejectMessagesFromSendersCommon.value -groupSMTPAddress $groupSMTPAddress -errorAction STOP -cn "None"

                out-logfile -string $normalizedTest

                $exchangeRejectMessagesSMTP+=$normalizedTest
            }
            catch 
            {
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }

    Out-LogFile -string "REJECT GROUPS"

    if ($originalDLConfiguration.($onPremADAttributes.onPremRejectMessagesFromDLMembers.value) -ne $NULL)
    {
        foreach ($DN in $originalDLConfiguration.($onPremADAttributes.onPremRejectMessagesFromDLMembers.value))
        {
            if ($forLoopCounter -eq $forLoopTrigger)
            {
                start-sleepProgress -sleepString "Throttling for 5 seconds..." -sleepSeconds 5

                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try 
            {
                $normalizedTest=get-normalizedDNAD -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -activeDirectoryAttribute $onPremADAttributes.onPremRejectMessagesFromDLMembers.value -activeDirectoryAttributeCommon $onPremADAttributes.onPremRejectMessagesFromDLMembersCommon.value -groupSMTPAddress $groupSMTPAddress -errorAction STOP -cn "None"

                out-logfile -string $normalizedTest

                $exchangeRejectMessagesSMTP+=$normalizedTest
            }
            catch 
            {
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }

    if ($exchangeRejectMessagesSMTP -ne $NULL)
    {
        out-logfile -string "The group has reject messages members."
        Out-logFile -string $exchangeRejectMessagesSMTP
    }
    else 
    {
        out-logfile "The group to be migrated has no reject messages from members."    
    }
    
    Out-LogFile -string "Invoke get-normalizedDNAD to normalize the accept members DN to Office 365 identifier."

    Out-LogFile -string "ACCEPT USERS"

    if ($originalDLConfiguration.($onPremADAttributes.onPremRejectMessagesFromDLMembers.value) -ne $NULL)
    {
        foreach ($DN in $originalDLConfiguration.($onPremADAttributes.onPremAcceptMessagesFromSenders.value))
        {
            if ($forLoopCounter -eq $forLoopTrigger)
            {
                start-sleepProgress -sleepString "Throttling for 5 seconds..." -sleepSeconds 5

                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try 
            {
                $normalizedTest=get-normalizedDNAD -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -activeDirectoryAttribute $onPremADAttributes.onPremRejectMessagesFromDLMembers.value -activeDirectoryAttributeCommon $onPremADAttributes.onPremRejectMessagesFromDLMembersCommon.value -groupSMTPAddress $groupSMTPAddress -errorAction STOP -cn "None"

                out-logfile -string $normalizedTest

                $exchangeAcceptMessagesSMTP+=$normalizedTest
            }
            catch 
            {
                out-logFile -string $_ -isError:$TRUE
            }
        }
    }

    Out-LogFile -string "ACCEPT GROUPS"

    if ($originalDLConfiguration.($onPremADAttributes.onPremAcceptMessagesFromDLMembers.value) -ne $NULL)
    {
        foreach ($DN in $originalDLConfiguration.($onPremADAttributes.onPremAcceptMessagesFromDLMembers.value))
        {
            if ($forLoopCounter -eq $forLoopTrigger)
            {
                start-sleepProgress -sleepString "Throttling for 5 seconds..." -sleepSeconds 5

                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try 
            {
                $normalizedTest=get-normalizedDNAD -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -activeDirectoryAttribute $onPremADAttributes.onPremAcceptMessagesFromDLMembers.value -activeDirectoryAttributeCommon $onPremADAttributes.onPremAcceptMessagesFromDLMembersCommon.value -groupSMTPAddress $groupSMTPAddress -errorAction STOP -cn "None"

                out-logfile -string $normalizedTest

                $exchangeAcceptMessagesSMTP+=$normalizedTest
            }
            catch 
            {
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }

    if ($exchangeAcceptMessagesSMTP -ne $NULL)
    {
        Out-LogFile -string "The following objects are members of the accept messages from senders:"
        
        out-logfile -string $exchangeAcceptMessagesSMTP
    }
    else
    {
        out-logFile -string "This group has no accept message from restrictions."    
    }
    
    Out-LogFile -string "Invoke get-normalizedDNAD to normalize the managedBy members DN to Office 365 identifier."

    Out-LogFile -string "Process MANAGEDBY"

    if ($originalDLConfiguration.($onPremADAttributes.onPremManagedBy.Value) -ne $NULL)
    {
        foreach ($DN in $originalDLConfiguration.($onPremADAttributes.onPremManagedBy.Value))
        {
            if ($forLoopCounter -eq $forLoopTrigger)
            {
                start-sleepProgress -sleepString "Throttling for 5 seconds..." -sleepSeconds 5

                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try 
            {
                $normalizedTest=get-normalizedDNAD -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -activeDirectoryAttribute $onPremADAttributes.onPremManagedBy.Value -activeDirectoryAttributeCommon $onPremADAttributes.onPremManagedByCommon.Value -groupSMTPAddress $groupSMTPAddress -errorAction STOP -cn "None"

                out-logfile -string $normalizedTest

                $exchangeManagedBySMTP+=$normalizedTest
            }
            catch 
            {
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }

    Out-LogFile -string "Process CoMANAGERS"

    if ($originalDLConfiguration.($onPremADAttributes.onPremCoManagedBy.Value) -ne $NULL)
    {
        foreach ($DN in $originalDLConfiguration.($onPremADAttributes.onPremCoManagedBy.Value))
        {
            if ($forLoopCounter -eq $forLoopTrigger)
            {
                start-sleepProgress -sleepString "Throttling for 5 seconds..." -sleepSeconds 5

                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try 
            {
                $normalizedTest = get-normalizedDNAD -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -activeDirectoryAttribute $onPremADAttributes.onPremCoManagedBy.Value -activeDirectoryAttributeCommon $onPremADAttributes.onPremCoManagedByCommon.Value -groupSMTPAddress $groupSMTPAddress -errorAction STOP -cn "None"

                out-logfile -string $normalizedTest

                $exchangeManagedBySMTP+=$normalizedTest                
            }
            catch 
            {
                out-logFile -string $_ -isError:$TRUE
            }
        }
    }

    if ($exchangeManagedBySMTP -ne $NULL)
    {
        Out-LogFile -string "The following objects are members of the managedBY:"
        
        out-logfile -string $exchangeManagedBySMTP
    }
    else 
    {
        out-logfile -string "The group has no managers."    
    }

    Out-LogFile -string "Invoke get-normalizedDNAD to normalize the moderatedBy members DN to Office 365 identifier."

    Out-LogFile -string "Process MODERATEDBY"

    if ($originalDLConfiguration.($onPremADAttributes.onPremModeratedBy.Value) -ne $NULL)
    {
        foreach ($DN in $originalDLConfiguration.($onPremADAttributes.onPremModeratedBy.Value))
        {
            if ($forLoopCounter -eq $forLoopTrigger)
            {
                start-sleepProgress -sleepString "Throttling for 5 seconds..." -sleepSeconds 5

                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try 
            {
                $normalizedTest = get-normalizedDNAD -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -activeDirectoryAttribute $onPremADAttributes.onPremModeratedBy.Value -activeDirectoryAttributeCommon $onPremADAttributes.onPremModeratedByCommon.Value -groupSMTPAddress $groupSMTPAddress -errorAction STOP -cn "None"

                out-logfile -string $normalizedTest

                $exchangeModeratedBySMTP+=$normalizedTest
            }
            catch 
            {
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }

    if ($exchangeModeratedBySMTP -ne $NULL)
    {
        Out-LogFile -string "The following objects are members of the moderatedBY:"
        
        out-logfile -string $exchangeModeratedBySMTP    
    }
    else 
    {
        out-logfile "The group has no moderators."    
    }

    Out-LogFile -string "Invoke get-normalizedDNAD to normalize the bypass moderation users members DN to Office 365 identifier."

    Out-LogFile -string "Process BYPASS USERS"

    if ($originalDLConfiguration.($onPremADAttributes.onPremBypassModerationFromSenders.Value) -ne $NULL)
    {
        foreach ($DN in $originalDLConfiguration.($onPremADAttributes.onPremBypassModerationFromSenders.Value))
        {
            if ($forLoopCounter -eq $forLoopTrigger)
            {
                start-sleepProgress -sleepString "Throttling for 5 seconds..." -sleepSeconds 5

                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try 
            {
                $normalizedTest = get-normalizedDNAD -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -activeDirectoryAttribute $onPremADAttributes.onPremBypassModerationFromSenders.Value -activeDirectoryAttributeCommon $onPremADAttributes.onPremBypassModerationFromSendersCommon.Value -groupSMTPAddress $groupSMTPAddress -errorAction STOP -cn "None"

                out-logfile -string $normalizedTest

                $exchangeBypassModerationSMTP+=$normalizedTest
            }
            catch 
            {
                out-logFile -string $_ -isError:$TRUE
            }
        }
    }

    Out-LogFile -string "Invoke get-normalizedDNAD to normalize the bypass moderation groups members DN to Office 365 identifier."

    Out-LogFile -string "Process BYPASS GROUPS"

    if ($originalDLConfiguration.($onPremADAttributes.onPremBypassModerationFromDL.Value) -ne $NULL)
    {
        foreach ($DN in $originalDLConfiguration.($onPremADAttributes.onPremBypassModerationFromDL.Value))
        {
            if ($forLoopCounter -eq $forLoopTrigger)
            {
                start-sleepProgress -sleepString "Throttling for 5 seconds..." -sleepSeconds 5

                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try 
            {
                $normalizedTest = get-normalizedDNAD -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -activeDirectoryAttribute $onPremADAttributes.onPremBypassModerationFromDL.Value -activeDirectoryAttributeCommon $onPremADAttributes.onPremBypassModerationFromDLCommon.Value -groupSMTPAddress $groupSMTPAddress -errorAction STOP -cn "None"

                out-logfile -string $normalizedTest

                $exchangeBypassModerationSMTP+=$normalizedTest
            }
            catch 
            {
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }

    if ($exchangeBypassModerationSMTP -ne $NULL)
    {
        Out-LogFile -string "The following objects are members of the bypass moderation:"
        
        out-logfile -string $exchangeBypassModerationSMTP 
    }
    else 
    {
        out-logfile "The group has no bypass moderation."    
    }

    if ($originalDLConfiguration.($onPremADAttributes.onPremGrantSendOnBehalfTo.Value)-ne $NULL)
    {
        foreach ($DN in $originalDLConfiguration.($onPremADAttributes.onPremGrantSendOnBehalfTo.Value))
        {
            if ($forLoopCounter -eq $forLoopTrigger)
            {
                start-sleepProgress -sleepString "Throttling for 5 seconds..." -sleepSeconds 5

                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try 
            {
                $normalizedTest=get-normalizedDNAD -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -activeDirectoryAttribute $onPremADAttributes.onPremGrantSendOnBehalfTo.Value -activeDirectoryAttributeCommon $onPremADAttributes.onPremGrantSendOnBehalfToCommon.Value -groupSMTPAddress $groupSMTPAddress -errorAction STOP -cn "None"

                out-logfile -string $normalizedTest

                $exchangeGrantSendOnBehalfToSMTP+=$normalizedTest                
            }
            catch 
            {
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }

    if ($exchangeGrantSendOnBehalfToSMTP -ne $NULL)
    {
        Out-LogFile -string "The following objects are members of the grant send on behalf to:"
        
        out-logfile -string $exchangeGrantSendOnBehalfToSMTP
    }
    else 
    {
        out-logfile "The group has no grant send on behalf to."    
    }

    Out-LogFile -string "Invoke get-normalizedDNAD for any on premises object that the migrated group has send as permissions."

    Out-LogFile -string "GROUPS WITH SEND AS PERMISSIONS"

    if ($allObjectSendAsAccess -ne $NULL)
    {
        foreach ($permission in $allObjectSendAsAccess)
        {
            if ($forLoopCounter -eq $forLoopTrigger)
            {
                start-sleepProgress -sleepString "Throttling for 5 seconds..." -sleepSeconds 5

                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try 
            {
                $normalizedTest=get-normalizedDNAD -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN "None" -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -activeDirectoryAttribute "SendAsDependency" -activeDirectoryAttributeCommon "SendAsDependency" -groupSMTPAddress $groupSMTPAddress -errorAction STOP -CN:$permission.Identity

                out-logfile -string $normalizedTest

                $allObjectsSendAsAccessNormalized+=$normalizedTest
            }
            catch 
            {
                out-logFile -string $_ -isError:$TRUE
            }
        }
    }

   #At this time we have discovered all permissions based off the LDAP properties of the users.  The one remaining is what objects have SENDAS rights on this DL.

    out-logfile -string "Obtaining send as permissions."

    try 
    {
        $exchangeSendAsSMTP=get-GroupSendAsPermissions -globalCatalog $corevariables.globalCatalogWithPort.value -dn $originalDLConfiguration.distinguishedName -adCredential $activeDirectoryCredential -adGlobalCatalogPowershellSessionName $coreVariables.ADGlobalCatalogPowershellSessionName.value -groupSMTPAddress $groupSMTPAddress
    }
    catch 
    {
        out-logfile -string "Unable to normalize the send as DNs."
        out-logfile -string $_ -isError:$TRUE
    }

    if ($exchangeSendAsSMTP -ne $NULL)
    {
        Out-LogFile -string "The following objects have send as rights on the DL."
        
        out-logfile -string $exchangeSendAsSMTP
    }

    #exit #Debug Exit

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END NORMALIZE DNS FOR ALL ATTRIBUTES"
    Out-LogFile -string "********************************************************************************"

    $telemetryFunctionEndTime = get-universalDateTime

    $telemetryNormalizeDN = get-elapsedTime -startTime $telemetryFunctionStartTime -endTime $telemetryFunctionEndTime

    out-logfile -string ("Time to Normalize DNs: "+$telemetryNormalizeDN.toString())

    #Exit #Debug Exit.

    #At this point we have obtained all the information relevant to the individual group.
    #Validate that the discovered dependencies are valid in Office 365.

    $forLoopCounter=0 #Resetting counter at next set of queries.

    $telemetryFunctionStartTime = get-universalDateTime

    $telemetryFunctionEndTime = get-universalDateTime

    $telemetryValidateCloudRecipients = get-elapsedTime -startTime $telemetryFunctionStartTime -endTime $telemetryFunctionEndTime

    out-logfile -string ("Time to validate recipients in cloud: "+ $telemetryValidateCloudRecipients.toString())

    #Exit #Debug Exit

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "BEGIN RECORD DEPENDENCIES ON MIGRATED GROUP"
    Out-LogFile -string "********************************************************************************"

    $telemetryFunctionStartTime = get-universalDateTime

    out-logfile -string "Get all the groups that this user is a member of - normalize to canonicalname."

    #Start with groups this DL is a member of remaining on premises.

    if ($originalDLConfiguration.($onPremADAttributes.onPremMemberOf.value) -ne $NULL)
    {
        out-logfile -string "Calling get-CanonicalName."

        foreach ($DN in $originalDLConfiguration.($onPremADAttributes.onPremMemberOf.value))
        {
            try 
            {
                $allGroupsMemberOf += get-canonicalname -globalCatalog $corevariables.globalCatalogWithPort.value -dn $DN -adCredential $activeDirectoryCredential -errorAction STOP
            }
            catch 
            {
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }

    if ($allGroupsMemberOf -ne $NULL)
    {
        out-logFile -string "The group to be migrated is a member of the following groups."
        out-logfile -string $allGroupsMemberOf
    }
    else 
    {
        out-logfile -string "The group is not a member of any other groups on premises."
    }

    #Handle all recipients that have forwarding to this group based on forwarding address.

    if ($originalDLConfiguration.($onPremADAttributes.onPremForwardingAddressBL.value) -ne $NULL)
    {
        out-logfile -string "Calling get-CanonicalName."

        foreach ($DN in $originalDLConfiguration.($onPremADAttributes.onPremForwardingAddressBL.value))
        {
            try 
            {
                $allUsersForwardingAddress += get-canonicalname -globalCatalog $corevariables.globalCatalogWithPort.value -dn $DN -adCredential $activeDirectoryCredential -errorAction STOP
            }
            catch 
            {
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }

    if ($allUsersForwardingAddress -ne $NULL)
    {
        out-logFile -string "The group has forwarding address set on the following users.."
        out-logfile -string $allUsersForwardingAddress
    }
    else 
    {
        out-logfile -string "The group does not have forwarding set on any other users."
    }

    #Handle all groups this object has reject permissions on.

    if ($originalDLConfiguration.($onPremADAttributes.onPremRejectMessagesFromDLMembersBL.value) -ne $NULL)
    {
        out-logfile -string "Calling get-CanonicalName."

        foreach ($DN in $originalDLConfiguration.($onPremADAttributes.onPremRejectMessagesFromDLMembersBL.value))
        {
            try 
            {
                $allGroupsReject += get-canonicalname -globalCatalog $corevariables.globalCatalogWithPort.value -dn $DN -adCredential $activeDirectoryCredential -errorAction STOP
            }
            catch 
            {
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }

    if ($allGroupsReject -ne $NULL)
    {
        out-logFile -string "The group has reject permissions on the following groups:"
        out-logfile -string $allGroupsReject
    }
    else 
    {
        out-logfile -string "The group does not have any reject permissions on other groups."
    }

    #Handle all groups this object has accept permissions on.

    if ($originalDLConfiguration.($onPremADAttributes.onPremAcceptMessagesFromDLMembersBL.value) -ne $NULL)
    {
        out-logfile -string "Calling get-CanonicalName."

        foreach ($DN in $originalDLConfiguration.($onPremADAttributes.onPremAcceptMessagesFromDLMembersBL.value))
        {
            try 
            {
                $allGroupsAccept += get-canonicalname -globalCatalog $corevariables.globalCatalogWithPort.value -dn $DN -adCredential $activeDirectoryCredential -errorAction STOP
            }
            catch 
            {
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }

    if ($allGroupsAccept -ne $NULL)
    {
        out-logFile -string "The group has accept messages from on the following groups:"
        out-logfile -string $allGroupsAccept
    }
    else 
    {
        out-logfile -string "The group does not have accept permissions on any groups."
    }

    if ($originalDlConfiguration.($onPremADAttributes.onPremCoManagedByBL.value) -ne $NULL)
    {
        out-logfile -string "Calling ge canonical name."

        foreach ($dn in $originalDLConfiguration.($onPremADAttributes.onPremCoManagedByBL.value))
        {
            try 
            {
                $allGroupsCoManagedByBL += get-canonicalName -globalCatalog $corevariables.globalCatalogWithPort.value -dn $DN -adCredential $activeDirectoryCredential -errorAction STOP

            }
            catch {
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }
    else 
    {
        out-logfile -string "The group is not a co manager on any other groups."    
    }

    if ($allGroupsCoManagedByBL -ne $NULL)
    {
        out-logFile -string "The group is a co-manager on the following objects:"
        out-logfile -string $allGroupsCoManagedByBL
    }
    else 
    {
        out-logfile -string "The group is not a co manager on any other objects."
    }

    #Handle all groups this object has bypass moderation permissions on.

    if ($originalDLConfiguration.($onPremADAttributes.onPremBypassModerationFromDLMembersBL.value) -ne $NULL)
    {
        out-logfile -string "Calling get-CanonicalName."

        foreach ($DN in $originalDLConfiguration.($onPremADAttributes.onPremBypassModerationFromDLMembersBL.value))
        {
            try 
            {
                $allGroupsBypassModeration += get-canonicalname -globalCatalog $corevariables.globalCatalogWithPort.value -dn $DN -adCredential $activeDirectoryCredential -errorAction STOP
            }
            catch 
            {
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }

    if ($allGroupsBypassModeration -ne $NULL)
    {
        out-logFile -string "This group has bypass moderation on the following groups:"
        out-logfile -string $allGroupsBypassModeration
    }
    else 
    {
        out-logfile -string "This group does not have any bypass moderation on any groups."
    }

    #Handle all groups this object has accept permissions on.

    if ($originalDLConfiguration.($onPremADAttributes.onPremGrantSendOnBehalfToBL.value) -ne $NULL)
    {
        out-logfile -string "Calling get-CanonicalName."

        foreach ($DN in $originalDLConfiguration.($onPremADAttributes.onPremGrantSendOnBehalfToBL.value))
        {
            try 
            {
                $allGroupsGrantSendOnBehalfTo += get-canonicalname -globalCatalog $corevariables.globalCatalogWithPort.value -dn $DN -adCredential $activeDirectoryCredential -errorAction STOP
            }
            catch 
            {
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }

    if ($allGroupsGrantSendOnBehalfTo -ne $NULL)
    {
        out-logFile -string "This group has grant send on behalf to to the following groups:"
        out-logfile -string $allGroupsGrantSendOnBehalfTo
    }
    else 
    {
        out-logfile -string "The group does ont have any send on behalf of rights to other groups."
    }

    #Handle all groups this object has manager permissions on.

    if ($originalDLConfiguration.($onPremADAttributes.onPremCoManagedByBL.value) -ne $NULL)
    {
        out-logfile -string "Calling get-CanonicalName."

        foreach ($DN in $originalDLConfiguration.($onPremADAttributes.onPremCoManagedByBL.value))
        {
            try 
            {
                $allGroupsManagedBy += get-canonicalname -globalCatalog $corevariables.globalCatalogWithPort.value -dn $DN -adCredential $activeDirectoryCredential -errorAction STOP
            }
            catch 
            {
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }

    if ($allGroupsManagedBy -ne $NULL)
    {
        out-logFile -string "This group has managedBY rights on the following groups."
        out-logfile -string $allGroupsManagedBy
    }
    else 
    {
        out-logfile -string "The group is not a manager on any other groups."
    }

    $telemetryFunctionEndTime = get-universalDateTime

    $telemetryDependencyOnPrem = get-elapsedTime -startTime $telemetryFunctionStartTime -endTime $telemetryFunctionEndTime

    out-logfile -string ("Time to calculate on premsies dependencies: "+ $telemetryDependencyOnPrem.toString())

    
    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END RECORD DEPENDENCIES ON MIGRATED GROUP"
    Out-LogFile -string "********************************************************************************"

    Out-LogFile -string "Recording all gathered information to XML to preserve original values."

    if ($allObjectsSendAsAccessNormalized.count -ne 0)
    {
        out-logfile -string $allObjectsSendAsAccessNormalized

        out-xmlFile -itemToExport $allObjectsSendAsAccessNormalized -itemNameToExport $xmlFiles.allGroupsSendAsNormalizedXML.value
    }
    
    if ($exchangeDLMembershipSMTP -ne $NULL)
    {
        Out-XMLFile -itemtoexport $exchangeDLMembershipSMTP -itemNameToExport $xmlFiles.exchangeDLMembershipSMTPXML.value
    }
    else 
    {
        $exchangeDLMembershipSMTP=@()
    }

    if ($exchangeRejectMessagesSMTP -ne $NULL)
    {
        out-xmlfile -itemtoexport $exchangeRejectMessagesSMTP -itemNameToExport $xmlFiles.exchangeRejectMessagesSMTPXML.value
    }
    else 
    {
        $exchangeRejectMessagesSMTP=@()
    }

    if ($exchangeAcceptMessagesSMTP -ne $NULL)
    {
        out-xmlfile -itemtoexport $exchangeAcceptMessagesSMTP -itemNameToExport $xmlFiles.exchangeAcceptMessagesSMTPXML.value
    }
    else 
    {
        $exchangeAcceptMessagesSMTP=@()
    }

    if ($exchangeManagedBySMTP -ne $NULL)
    {
        out-xmlfile -itemtoexport $exchangeManagedBySMTP -itemNameToExport $xmlFiles.exchangeManagedBySMTPXML.value
    }
    else 
    {
        $exchangeManagedBySMTP=@()
    }

    if ($exchangeModeratedBySMTP -ne $NULL)
    {
        out-xmlfile -itemtoexport $exchangeModeratedBySMTP -itemNameToExport $xmlFiles.exchangeModeratedBySMTPXML.value
    }
    else 
    {
        $exchangeModeratedBySMTP=@()
    }

    if ($exchangeBypassModerationSMTP -ne $NULL)
    {
        out-xmlfile -itemtoexport $exchangeBypassModerationSMTP -itemNameToExport $xmlFiles.exchangeBypassModerationSMTPXML.value
    }
    else 
    {
        $exchangeBypassModerationSMTP=@()
    }

    if ($exchangeGrantSendOnBehalfToSMTP -ne $NULL)
    {
        out-xmlfile -itemToExport $exchangeGrantSendOnBehalfToSMTP -itemNameToExport $xmlFiles.exchangeGrantSendOnBehalfToSMTPXML.value
    }
    else 
    {
        $exchangeGrantSendOnBehalfToSMTP=@()
    }

    if ($exchangeSendAsSMTP -ne $NULL)
    {
        out-xmlfile -itemToExport $exchangeSendAsSMTP -itemNameToExport $xmlFiles.exchangeSendAsSMTPXML.value
    }
    else 
    {
        $exchangeSendAsSMTP=@()
    }

    if ($allGroupsMemberOf -ne $NULL)
    {
        out-xmlfile -itemtoexport $allGroupsMemberOf -itemNameToExport $xmlFiles.allGroupsMemberOfXML.value
    }
    else 
    {
        $allGroupsMemberOf=@()
    }
    
    if ($allGroupsReject -ne $NULL)
    {
        out-xmlfile -itemtoexport $allGroupsReject -itemNameToExport $xmlFiles.allGroupsRejectXML.value
    }
    else 
    {
        $allGroupsReject=@()
    }
    
    if ($allGroupsAccept -ne $NULL)
    {
        out-xmlfile -itemtoexport $allGroupsAccept -itemNameToExport $xmlFiles.allGroupsAcceptXML.value
    }
    else 
    {
        $allGroupsAccept=@()
    }

    if ($allGroupsCoManagedByBL -ne $NULL)
    {
        out-xmlfile -itemToExport $allGroupsCoManagedByBL -itemNameToExport $xmlFiles.allGroupsCoManagedByXML.value
    }
    else 
    {
        $allGroupsCoManagedByBL=@()    
    }

    if ($allGroupsBypassModeration -ne $NULL)
    {
        out-xmlfile -itemtoexport $allGroupsBypassModeration -itemNameToExport $xmlFiles.allGroupsBypassModerationXML.value
    }
    else 
    {
        $allGroupsBypassModeration=@()
    }

    if ($allUsersForwardingAddress -ne $NULL)
    {
        out-xmlFile -itemToExport $allUsersForwardingAddress -itemNameToExport $xmlFiles.allUsersForwardingAddressXML.value
    }
    else 
    {
        $allUsersForwardingAddress=@()
    }

    if ($allGroupsManagedBy -ne $NULL)
    {
        out-xmlFile -itemToExport $allGroupsManagedBy -itemNameToExport $xmlFiles.allGroupsManagedByXML.value
    }
    else 
    {
        $allGroupsManagedBy=@()
    }

    if ($allGroupsGrantSendOnBehalfTo -ne $NULL)
    {
        out-xmlFile -itemToExport $allGroupsGrantSendOnBehalfTo -itemNameToExport $xmlFiles.allGroupsGrantSendOnBehalfToXML.value
    }
    else 
    {
        $allGroupsGrantSendOnBehalfTo =@()
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

    if ($retainOffice365Settings -eq $TRUE)
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
            out-logfile -string "Retain Office 365 send as set to try - invoke only if group is type security on premsies."

            if (($originalDLConfiguration.groupType -eq "-2147483640") -or ($originalDLConfiguration.groupType -eq "-2147483646") -or ($originalDLConfiguration.groupType -eq "-2147483644"))
            {
                out-logfile -string "Group is type security on premises - therefore it may have send as rights."

                try{
                    $allOffice365SendAsAccess = Get-O365DLSendAs -groupSMTPAddress $groupSMTPAddress -isTrustee:$TRUE -errorAction STOP
                }
                catch{
                    out-logfile -string $_ -isError:$TRUE
                }
            }
            else 
            {
                out-logfile -string "Group is not security on premsies therefore has no send as rights in Office 365."
            }
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

            out-logfile -string "Setting group type override to security - the group type may have changed on premises after the permission was added."

            $groupTypeOverride="Security"
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
    
    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END RETAIN OFFICE 365 GROUP DEPENDENCIES"
    Out-LogFile -string "********************************************************************************"

    out-logfile -string "Normalzing all Office 365 attributes so that they can be easily searched."

    out-logfile -string "Processing accept messages from senders or members."

    try {
        $office365AcceptMessagesFromSendersOrMembers = get-NormalizedO365 -attributeToNormalize $office365DLConfiguration.AcceptMessagesOnlyFromSendersOrMembers -errorAction STOP
    }
    catch {
        out-logfile -string "Unable to normalize Office 365 DL accept messages from senders or members."
        out-logfile -string $_ -isError:$TRUE
    }

    out-logfile -string "Processing reject messages from senders or members."

    try {
        $office365RejectMessagesFromSendersOrMembers = get-normalizedO365 -attributeToNormalize $office365DLConfiguration.RejectMessagesFromSendersOrMembers -errorAction STOP
    }
    catch {
        out-logfile -string "Unable to normalize Office 365 DL reject messages from senders or members."
        out-logfile -string $_ -isError:$TRUE
    }

    out-logfile -string "Processing moderatedBy members"

    try {
        $office365ModeratedBy = get-normalizedO365 -attributeToNormalize $office365DLConfiguration.ModeratedBy -errorAction STOP
    }
    catch {
        out-logfile -string "Unable to normalize Office 365 DL moderatedBy members."
        out-logfile -string $_ -isError:$TRUE
    }

    out-logfile -string "Processing bypass moderation from senders or members."

    try {
        $office365BypassModerationFromSendersOrMembers = get-normalizedO365 -attributeToNormalize $office365DLConfiguration.BypassModerationFromSendersOrMembers -errorAction STOP
    }
    catch {
        out-logfile -string "Unable to normalize Office 365 DL bypass moderation from senders members."
        out-logfile -string $_ -isError:$TRUE
    }

    out-logfile -string "Processing managed by members."

    try {
        $office365ManagedBy = get-normalizedO365 -attributeToNormalize $office365DLConfiguration.managedBy -errorAction STOP
    }
    catch {
        out-logfile -string "Unable to normalize Office 365 DL managedBY members."
        out-logfile -string $_ -isError:$TRUE
    }

    out-logfile -string "Processing grant send on behalf to."

    try {
        $office365GrantSendOnBehalfTo = get-normalizedO365 -attributeToNormalize $office365DLConfiguration.GrantSendOnBehalfTo -errorAction STOP
    }
    catch {
        out-logfile -string "Unable to normalize Office 365 DL grantSendOnBehalfTo members."
        out-logfile -string $_ -isError:$TRUE
    }
    
    if ($office365AcceptMessagesFromSendersOrMembers -ne $NULL)
    {
        out-xmlfile -itemToExport $office365AcceptMessagesFromSendersOrMembers -itemNameTOExport $xmlFiles.office365AcceptMessagesFromSendersOrMembersXML.value
    }
    else {
        $office365AcceptMessagesFromSendersOrMembers=@()
    }

    if ($office365RejectMessagesFromSendersOrMembers -ne $NULL)
    {
        out-xmlfile -itemToExport $office365RejectMessagesFromSendersOrMembers -itemNameTOExport $xmlFiles.office365RejectMessagesFromSendersOrMembersXML.value
    }
    else {
        $office365RejectMessagesFromSendersOrMembers=@()
    }

    if ($office365ModeratedBy -ne $NULL)
    {

        out-xmlfile -itemToExport $office365ModeratedBy -itemNameTOExport $xmlFiles.office365ModeratedByXML.value
    }
    else {
        $office365ModeratedBy=@()
    }

    if ($office365BypassModerationFromSendersOrMembers -ne $NULL)
    {
        out-xmlfile -itemToExport $office365BypassModerationFromSendersOrMembers -itemNameTOExport $xmlFiles.office365BypassModerationFromSendersOrMembersXML.value
    }
    else 
    {
        $office365BypassModerationFromSendersOrMembers=@()
    }

    if ($office365ManagedBy -ne $NULL)
    {
        out-xmlfile -itemToExport $office365ManagedBy -itemNameTOExport $xmlFiles.office365ManagedByXML.value
    }
    else {
        $office365ManagedBy=@()
    }

    if ($office365GrantSendOnBehalfTo -ne $NULL)
    {
        out-xmlfile -itemToExport $office365GrantSendOnBehalfTo -itemNameTOExport $xmlFiles.office365GrantSendOnBehalfToXML.value
    }
    else {
        $office365GrantSendOnBehalfTo=@()
    }

    #EXIT #Debug Exit

    #We can begin the process of recreating the distribution group in Exchange Online.
    #This will make a first pass at creating a stub distribution list and perfomring long running transations like updating membership.
    #By creating the DL first and updating these items - the original DL remains fully available until the new DL is populated and ready to turn over.

    #Archive the files into a date time success folder.

    $telemetryEndTime = get-universalDateTime
    $telemetryElapsedSeconds = get-elapsedTime -startTime $telemetryStartTime -endTime $telemetryEndTime

    #At this time we need to start building the comparison arrays.

    <#

    out-logfile -string "Comparing on premises membership to azure ad membership."

    try {
        $onPremMemberEval = @(compare-recipientArrays -onPremData $exchangeDLMembershipSMTP -azureData $azureADDlMembership -errorAction STOP)
    }
    catch {
        out-logfile -string $_ -isError:$TRUE
    }

    out-logfile -string "Comparing azure ad membership to Office 365 membership."

    try {
        $office365MemberEval = @(compare-recipientArrays -office365Data $office365DLMembership -azureData $azureADDlMembership -errorAction STOP)
    }
    catch {
        out-logfile -string $_ -isError:$TRUE
    }

    #>

    out-logfile -string "Beginning list membership comparison."

    try {
        $office365MemberEval = @(compare-recipientArrays -office365Data $office365DLMembership -azureData $azureADDlMembership -onPremData $exchangeDLMembershipSMTP -isAllTest:$TRUE -errorAction STOP)
    }
    catch {
        out-logfile -string $_ -isError:$TRUE
    }

    out-logfile -string "Comparing proxy addresses between all directories."

    try
    {
        $office365ProxyAddressesEval = @(compare-recipientArrays -onPremData $originalDLConfiguration.proxyAddresses -azureData $azureADDlConfiguration.proxyAddresses -Office365Data $office365DLConfiguration.emailAddresses -isProxyTest:$TRUE -errorAction STOP)
    }
    catch {
        out-logfile -string $_ -isError:$TRUE
    }

    out-logfile -string "Comparing accept messages from senders or members on premsies to Office 365."

    try {
        $office365AcceptMessagesFromSendersOrMembersEval = @(compare-recipientArrays -office365Data $office365AcceptMessagesFromSendersOrMembers -onPremData $exchangeAcceptMessagesSMTP -isAttributeTest:$TRUE -errorAction STOP)
    }
    catch {
        out-logfile -string $_ -isError:$TRUE
    }

    out-logfile -string "Comparing reject messages from senders or members on premsies to Office 365."

    try {
        $office365RejectMessagesFromSendrsOfMembersEval = @(compare-recipientArrays -office365Data $office365RejectMessagesFromSendersOrMembers -onPremData $exchangeRejectMessagesSMTP -isAttributeTest:$TRUE -errorAction STOP)
    }
    catch {
        out-logfile -string $_ -isError:$TRUE
    }

    out-logfile -string "Comparing on premises moderated by to Office 365 moderated by."

    try{
        $office365ModeratedByEval = @(compare-recipientArrays -office365Data $office365ModeratedBy -onPremData $exchangeModeratedBySMTP -isAttributeTest:$TRUE -errorAction STOP)
    }
    catch{
        out-logfile -string $_ -isError:$TRUE
    }

    out-logfile -string "Comparing on premises bypass moderation from senders or members to Office 365."

    try{
        $office365BypassModerationFromSendersOrMembersEval = @(compare-recipientArrays -office365Data $office365BypassModerationFromSendersOrMembers -onPremData $exchangeBypassModerationSMTP -isAttributeTest:$TRUE -errorAction STOP)
    }
    catch {
        out-logfile -string $_ -isError:$TRUE
    }

    out-logfile -string "Comapring on premsies managed by to Office 365."

    try{
        $office365ManagedByEval = @(compare-recipientArrays -office365Data $office365ManagedBy -onPremData $exchangeManagedBySMTP -isAttributeTest:$TRUE -errorAction STOP)
    }
    catch {
        out-logfile -string $_ -isError:$TRUE
    }

    out-logfile -string "Comparing grant send on behalf to on premsies to Office 365."

    try{
        $office365GrantSendOnBehalfToEval = @(compare-recipientArrays -office365Data $office365GrantSendOnBehalfTo -onPremData $exchangeGrantSendOnBehalfToSMTP -isAttributeTest:$TRUE -errorAction STOP)
    }
    catch {
        out-logfile -string $_ -isError:$TRUE
    }

    try {
        $office365AttributeEval = @(compare-recipientProperties -office365Data $office365DLConfiguration -onPremData $originalDLConfiguration -azureData $azureADDlConfiguration -errorAction STOP)
    }
    catch {
        out-logfile -string $_ -isError:$TRUE
    }

    if ($office365AttributeEval -ne $NULL)
    {
        out-logfile -string "Exporting the office 365 attribute eval."

        out-xmlFile -itemToExport $office365AttributeEval -itemNameToExport $xmlFiles.office365AttributeEvalXML.value
    }

    if ($onPremMemberEval -ne $NULL)
    {
        out-logfile -string "Exporting on premises member evaluation."

        $onPremMembersEval = $onPremMembersEval | sort-object -property "isvalidMember"
        out-xmlFile -itemToExport $onPremMemberEval -itemNameToExport $xmlFiles.onPremMemberEvalXML.value
    }
    else
    {
        out-logfile -string "No on premises member evaluation to export."
    }

    if ($office365MemberEval -ne $NULL)
    {
        out-logfile -string "Exporting Office 365 member evaluation."

        $office365MemberEval = $office365MemberEval | sort-object -property "isValidMember"
        out-xmlFile -itemToExport $office365MemberEval -itemNameToExport $xmlFiles.office365MemberEvalXML.value
    }
    else {
        out-logfile -string "No Office 365 member evaluation to export."
    }

    if ($office365ProxyAddressesEval -ne $NULL)
    {
        out-logfile -string "Exporting Office 365 Proxy Address evaluation."
        $office365ProxyAddressesEval = $office365ProxyAddressesEval | sort-object -property "isValidMember"

        out-xmlFile -itemToExport $office365ProxyAddressesEval -itemNameToExport $xmlFiles.office365ProxyAddressesEvalXML.value
    }
    else
    {
        out-logfile -string "No office 365 proxy addresses evaluation to report."
    }

    if ($office365AcceptMessagesFromSendersOrMembersEval -ne $NULL)
    {
        out-logfile -string "Exporting accept messages from senders or members evaluation."

        $office365AcceptMessagesFromSendersOrMembersEval = $office365AcceptMessagesFromSendersOrMembersEval | sort-object -property "isValidMember"
        out-xmlFile -itemToExport $office365AcceptMessagesFromSendersOrMembersEval -itemNameToExport $xmlFiles.office365AcceptMessagesFromSendersOrMembersEvalXML.value
    }
    else {
        out-logfile -string "No accept messages from senders or members evaluation to export."
    }

    if ($office365RejectMessagesFromSendrsOfMembersEval -ne $NULL)
    {
        out-logfile -string "Exporting reject messages from senders or members evaluation."

        $office365RejectMessagesFromSendrsOfMembersEval = $office365RejectMessagesFromSendrsOfMembersEval | sort-object -property "isValidMember"
        out-xmlFile -itemToExport $office365RejectMessagesFromSendrsOfMembersEval -itemNameToExport $xmlFiles.office365RejectMessagesFromSendersOrMembersEvalXML.value
    }
    else
    {
        out-logfile -string "No reject messages from senders or members evaluation to export."
    }

    if ($office365ModeratedByEval -ne $NULL)
    {
        out-logfile -string "Exporting moderated by evaluation."

        $office365ModeratedByEval = $office365ModeratedByEval | Sort-Object -property "isValidMember"
        out-xmlFile -itemToExport $office365ModeratedByEval -itemNameToExport $xmlFiles.office365ModeratedByEvalXML.value
    }
    else {
        out-logfile -string "No moderated by evaluation to export."
    }

    if ($office365BypassModerationFromSendersOrMembersEval -ne $NULL)
    {
        out-logfile -string "Exporting bypass moderation from senders or members evaluation."

        $office365BypassModerationFromSendersOrMembersEval = $office365BypassModerationFromSendersOrMembersEval | sort-object -property "isValidMember"
        out-xmlFile -itemToExport $office365BypassModerationFromSendersOrMembersEval -itemNameToExport $xmlFiles.office365BypassModerationFromSendersOrMembersEvalXML.value
    }
    else {
        out-logfile -string "No bypass moderation from senders or members evaluation to export."
    }

    if ($office365ManagedByEval -ne $NULL)
    {
        out-logfile -string "Exporting managed by evaluation."

        $office365ManagedByEval = $office365ManagedByEval | sort-object -property "isValidMember"
        out-xmlFile -itemToExport $office365ManagedByEval -itemNameToExport $xmlFiles.office365ManagedByEvalXML.value
    }
    else
    {
        out-logfile -string "No managed by evaluation to export."
    }

    if ($office365GrantSendOnBehalfTo -ne $NULL)
    {
        out-logfile -string "Exporting grant send on behalf to evaluation."

        $office365GrantSendOnBehalfTo = $office365GrantSendOnBehalfTo | sort-object -property "isValidMember"
        out-xmlFile -itemToExport $office365GrantSendOnBehalfTo -itemNameToExport $xmlFiles.office365GrantSendOnBehalfToEvalXML.value
    }
    else
    {
        out-logfile -string "No grant send on behalf to evaluation to export."
    }

    Out-logfile -string "Record Counts."

    $functionObject = New-Object PSObject -Property @{
        OnPremisesMemberCount = $exchangeDLMembershipSMTP.count
        AzureADMemberCount = $azureADDlMembership.count
        Office365DLMemberCount = $office365DLMembership.count
        OnPremisesAcceptMessagesFromSendersOrMembersCount = $exchangeAcceptMessagesSMTP.count
        Office365AcceptMessagesFromSendersOrMembersCount = $office365AcceptMessagesFromSendersOrMembers.count
        OnPremisesRejectMessagesFromSendersOrMembersCount = $exchangeRejectMessagesSMTP.count
        Office365RejectMessagesFromSendersOrMembersCount = $office365RejectMessagesFromSendersOrMembers.count
        OnPremisesModeratedByCount = $exchangeModeratedBySMTP.count
        Office365ModeratedByCount = $office365ModeratedBy.count
        OnPremisesManagedByCount = $exchangeManagedBySMTP.count
        Office365ManagedByCount = $office365ManagedBy.count
        OnPremisesBypassModerationFromSendersOrMembers = $exchangeBypassModerationSMTP.count
        Office365BypassModerationFromSendersOrMembers = $office365BypassModerationFromSendersOrMembers.count
        OnPremisesGrantSendOnBehalfTo = $exchangeGrantSendOnBehalfToSMTP.count
        Office365GrantSendOnBehalfTo = $office365GrantSendOnBehalfTo.count
        OnPremisesSendAsRightsOnGroup = $exchangeSendAsSMTP.count
        Office365SendAsRightsOnGroup = $allOffice365SendAsAccessOnGroup.count
        OnPremisesSendAsRightsOnOtherObjects = $allObjectsSendAsAccessNormalized.Count
        Office365SendAsRightsOnOtherObjects = $allOffice365SendAsAccess.count
        OnPremisesFullMailboxAccessRights = $allObjectsFullMailboxAccess.count
        Office365FullMailboxAccessRights = $allOffice365FullMailboxAccess.count
        OnPremsiesMailboxFolderRights = $allMailboxesFolderPermissions.count
        Office365MailboxFolderRights = $allOffice365MailboxFolderPermissions.count
        OnPremisesMemberOfOtherObjects = $allGroupsMemberOf.count
        Office365MemberOfOtherObjects = $allOffice365MemberOf.count
        OnPremsiesAcceptMessagesFromSendersOrMembersOtherObjects = $allGroupsAccept.count
        Office365AcceptMessagesFromSendersOrMembersOtherObjects = $allOffice365Accept.count
        OnPremisesRejectMessagesFromSendersOrMembersOtherObjects = $allGroupsReject.count
        Office365RejectMessagesFromSendersOrMembersOtherObjects = $allOffice365Reject.count
        OnPremiseManagedByOtherObjects = $allGroupsManagedBy.count
        OnPremisesCoManagedByOtherObjects = $allGroupsCoManagedByBL.Count
        Office365ManagedByOtherObjects = $allOffice365ManagedBy.count
        OnPremisesBypassModerationFromSendersOrMembersOtherObjects = $allGroupsBypassModeration.count
        Office365BypassModerationFromSendersOrMembersOtherObjects = $allOffice365BypassModeration.count
        OnPremisesGrantSendOnBehalfToOtherObjects = $allGroupsGrantSendOnBehalfTo.count
        Office365GrantSendOnBehalfToOtherObjects = $allOffice365GrantSendOnBehalfTo.count
        OnPremisesMailboxForwardingAddress = $allUsersForwardingAddress.count
        Office365MailboxForwardingAddress = $allOffice365ForwardingAddress.count
        }

    out-logfile -string $functionObject

    out-xmlfile -itemToExport $functionObject -itemNameToExport $xmlFiles.summaryCountsXML.value

    #=============================================================================================================================================
    #=============================================================================================================================================
    #=============================================================================================================================================

    out-logfile -string "Building the HTML report for export."

    out-logfile -string "Define CSS for the report."

    $style = @"
body {
    color:#333333;
    font-family:Calibri,Tahoma;
    font-size: 10pt;
}

h1 {
    text-align:center;
}

h2 {
    border-top:1px solid #666666;
}

th {
    font-weight:bold;
    color:#eeeeee;
    background-color:#333333;
    cursor:pointer;
}

.odd  { background-color:#ffffff; }

.even { background-color:#dddddd; }

.paginate_enabled_next, .paginate_enabled_previous {
    cursor:pointer; 
    border:1px solid #222222; 
    background-color:#dddddd; 
    padding:2px; 
    margin:4px;
    border-radius:2px;
}

.paginate_disabled_previous, .paginate_disabled_next {
    color:#666666; 
    cursor:pointer;
    background-color:#dddddd; 
    padding:2px; 
    margin:4px;
    border-radius:2px;
}

.dataTables_info { margin-bottom:4px; }

.sectionheader { cursor:pointer; }

.sectionheader:hover { color:red; }

.grid { width:100% }

.red {
    color:red;
    font-weight:bold;
} 

.green {
    color:green;
    font-weight:bold;
} 
"@
    
    out-logfile -string "Split the on premises data from the Office 365 data."

    $onPremMemberEval = $office365MemberEval | where-object {$_.isPresentOnPremises -eq "Source"}

    $onPremMemberEval = $onPremMemberEval | sort-object "isValidMember"

    out-logfile -string "Split the cloud data from the on premises data."

    $office365MemberEval = $office365MemberEval | where-object {$_.isPresentInExchangeOnline -eq "Source"}

    $office365MemberEval = $office365MemberEval | sort-object "isValidMember"

    out-logfile -string "Generate HTML fragment for Office365MemberEval."

    if ($office365MemberEval.count -gt 0)
    {
        out-logfile -string $office365MemberEval

        $params = @{'As'='Table';
        'PreContent'='<h2>&diams; Member Analysis :: Office 365 -> Azure Active Directory -> Active Directory</h2>';
        'EvenRowCssClass'='even';
        'OddRowCssClass'='odd';
        'MakeTableDynamic'=$true;
        'TableCssClass'='grid';
        'MakeHiddenSection'=$true;
        'Properties'=   @{n='Member';e={$_.name}},
                        @{n='ExternalDirectoryObjectID';e={if ($_.externalDirectoryObjectID -ne $NULL){$_.externalDirectoryObjectID}else{""}}},
                        @{n='PrimarySMTPAddress';e={if ($_.primarySMTPAddress -ne $NULL){$_.primarySMTPAddress}else{""}}},
                        @{n='UserPrincipalName';e={if ($_.userPrincipalName -ne $NULL){$_.UserPrincipalName}else{""}}},
                        @{n='ObjectSID';e={if ($_.objectSID -ne $NULL){$_.objectSid}else{""}}},
                        @{n='PresentActiveDirectory';e={$_.isPresentOnPremises};css={if ($_.isPresentOnPremsies -eq "False") { 'red' }}},
                        @{n='PresentAzureActiveDirectory';e={$_.isPresentInAzure};css={if ($_.isPresentInAzure -eq "False") { 'red' }}},
                        @{n='PresentExchangeOnline';e={$_.isPresentInExchangeOnline};css={if ($_.isPresentInExchangeOnline -eq "False"){ 'red' }}},
                        @{n='ValidMember';e={$_.isValidMember};css={if ($_.isvalidMember -ne "True") { 'red' }}},
                        @{n='ErrorMessage';e={$_.ErrorMessage}}
        }

        $html_members_office365 = ConvertTo-EnhancedHTMLFragment -InputObject $office365MemberEval @params

        $htmlSections += $html_members_office365
    }

    if ($onPremMemberEval.count -gt 0)
    {
        out-logfile -string $onPremMemberEval

        $params = @{'As'='Table';
        'PreContent'='<h2>&diams; Member Analysis :: Active Directory -> Azure Active Directory -> Office 365</h2>';
        'EvenRowCssClass'='even';
        'OddRowCssClass'='odd';
        'MakeTableDynamic'=$true;
        'TableCssClass'='grid';
        'MakeHiddenSection'=$true;
        'Properties'=   @{n='Member';e={$_.name}},
                        @{n='ExternalDirectoryObjectID';e={if ($_.externalDirectoryObjectID -ne $NULL){$_.externalDirectoryObjectID}else{""}}},
                        @{n='PrimarySMTPAddress';e={if ($_.primarySMTPAddress -ne $NULL){$_.primarySMTPAddress}else{""}}},
                        @{n='UserPrincipalName';e={if ($_.userPrincipalName -ne $NULL){$_.UserPrincipalName}else{""}}},
                        @{n='ObjectSID';e={if ($_.objectSID -ne $NULL){$_.objectSid}else{""}}},
                        @{n='PresentActiveDirectory';e={$_.isPresentOnPremises};css={if ($_.isPresentOnPremsies -eq "False") { 'red' }}},
                        @{n='PresentAzureActiveDirectory';e={$_.isPresentInAzure};css={if ($_.isPresentInAzure -eq "False") { 'red' }}},
                        @{n='PresentExchangeOnline';e={$_.isPresentInExchangeOnline};css={if ($_.isPresentInExchangeOnline -eq "False"){ 'red' }}},
                        @{n='ValidMember';e={$_.isValidMember};css={if ($_.isvalidMember -ne "True") { 'red' }}},
                        @{n='ErrorMessage';e={$_.ErrorMessage}}
        }

        $html_members_onPrem = ConvertTo-EnhancedHTMLFragment -InputObject $onPremMemberEval @params

        $htmlSections += $html_members_onPrem
    }

    out-logfile -string "Generate report for proxy address verification."

    out-logfile -string "Split the on premises data from the Office 365 data."

    $onPremProxyAddressEval = $office365ProxyAddressesEval | where-object {$_.isPresentOnPremises -eq "Source"}

    out-logfile -string "Split the cloud data from the on premises data."

    $office365ProxyAddressesEval = $office365ProxyAddressesEval | where-object {$_.isPresentInExchangeOnline -eq "Source"}

    if ($office365ProxyAddressesEval.count -gt 0)
    {
        $params = @{'As'='Table';
        'PreContent'='<h2>&diams; Proxy Address Evaluation :: Office 365 -> Active Directory</h2>';
        'EvenRowCssClass'='even';
        'OddRowCssClass'='odd';
        'MakeTableDynamic'=$true;
        'TableCssClass'='grid';
        'MakeHiddenSection'=$true;
        'Properties'=   @{n='ProxyAddress';e={$_.proxyAddress}},
                        @{n='PresentActiveDirectory';e={$_.isPresentOnPremises};css={if ($_.isPresentOnPremises -eq "False") { 'red' }}},
                        @{n='PresentAzureActiveDirectory';e={$_.isPresentInAzure};css={if ($_.isPresentInAzure -eq "False") { 'red' }}},
                        @{n='PresentExchangeOnline';e={$_.isPresentInExchangeOnline};css={if ($_.isPresentInExchangeOnline -eq "False"){ 'red' }}},
                        @{n='ValidMember';e={$_.isValidMember};css={if ($_.isvalidMember -ne "True") { 'red' }}},
                        @{n='ErrorMessage';e={$_.ErrorMessage}}
        }

        $html_proxyAddresses = ConvertTo-EnhancedHTMLFragment -InputObject $office365ProxyAddressesEval @params

        $htmlSections += $html_proxyAddresses
    }

    if ($onPremProxyAddressEval.count -gt 0)
    {
        $params = @{'As'='Table';
        'PreContent'='<h2>&diams; Proxy Address Evaluation :: Active Directory -> Office 365</h2>';
        'EvenRowCssClass'='even';
        'OddRowCssClass'='odd';
        'MakeTableDynamic'=$true;
        'TableCssClass'='grid';
        'MakeHiddenSection'=$true;
        'Properties'=   @{n='ProxyAddress';e={$_.proxyAddress}},
                        @{n='PresentActiveDirectory';e={$_.isPresentOnPremises};css={if ($_.isPresentOnPremises -eq "False") { 'red' }}},
                        @{n='PresentAzureActiveDirectory';e={$_.isPresentInAzure};css={if ($_.isPresentInAzure -eq "False") { 'red' }}},
                        @{n='PresentExchangeOnline';e={$_.isPresentInExchangeOnline};css={if ($_.isPresentInExchangeOnline -eq "False"){ 'red' }}},
                        @{n='ValidMember';e={$_.isValidMember};css={if ($_.isvalidMember -ne "True") { 'red' }}},
                        @{n='ErrorMessage';e={$_.ErrorMessage}}
        }

        $html_proxyAddresses2 = ConvertTo-EnhancedHTMLFragment -InputObject $onPremProxyAddressEval @params

        $htmlSections += $html_proxyAddresses2
    }


    out-logfile -string "Generate report for attribute verification."

    if ($office365AttributeEval.count -gt 0)
    {
        $params = @{'As'='Table';
        'PreContent'='<h2>&diams; Single Value Attribute Evaluation</h2>';
        'EvenRowCssClass'='even';
        'OddRowCssClass'='odd';
        'MakeTableDynamic'=$true;
        'TableCssClass'='grid';
        'MakeHiddenSection'=$true;
        'Properties'=   @{n='Attribute';e={$_.Attribute}},
                        @{n='OnPremisesValue';e={$_.onpremisesvalue}},
                        @{n='IsValidInAzure';e={$_.isValidInAzure}},
                        @{n='AzureADValue';e={$_.AzureADValue}},
                        @{n='ExchangeOnlineValue';e={$_.ExchangeOnlineValue}},
                        @{n='isValidInExchangeOnline';e={$_.isValidInExchangeOnline};css={if ($_.isValidInExchangeOnline -eq "False") { 'red' }}},
                        @{n='IsValidMember';e={$_.IsValidMember};css={if ($_.IsValidMember -eq "False"){ 'red' }}},
                        @{n='ErrorMessage';e={$_.ErrorMessage}}
        }

        $html_attributes = ConvertTo-EnhancedHTMLFragment -InputObject $office365AttributeEval @params

        $htmlSections += $html_attributes
    }

    out-logfile -string "Build HTML for accept messages from senders or members."

    if ($office365AcceptMessagesFromSendersOrMembersEval.count -gt 0)
    {
        $params = @{'As'='Table';
        'PreContent'='<h2>&diams; Member Analysis :: Active Directory -> Office 365 Accept Messages From Senders or Members</h2>';
        'EvenRowCssClass'='even';
        'OddRowCssClass'='odd';
        'MakeTableDynamic'=$true;
        'TableCssClass'='grid';
        'MakeHiddenSection'=$true;
        'Properties'=   @{n='Member';e={$_.name}},
                        @{n='ExternalDirectoryObjectID';e={if ($_.externalDirectoryObjectID -ne $NULL){$_.externalDirectoryObjectID}else{""}}},
                        @{n='PrimarySMTPAddress';e={if ($_.primarySMTPAddress -ne $NULL){$_.primarySMTPAddress}else{""}}},
                        @{n='UserPrincipalName';e={if ($_.userPrincipalName -ne $NULL){$_.UserPrincipalName}else{""}}},
                        @{n='ObjectSID';e={if ($_.objectSID -ne $NULL){$_.objectSid}else{""}}},
                        @{n='PresentActiveDirectory';e={$_.isPresentOnPremises};css={if ($_.isPresentOnPremsies -eq "False") { 'red' }}},
                        @{n='PresentAzureActiveDirectory';e={$_.isPresentInAzure};css={if ($_.isPresentInAzure -eq "False") { 'red' }}},
                        @{n='PresentExchangeOnline';e={$_.isPresentInExchangeOnline};css={if ($_.isPresentInExchangeOnline -eq "False"){ 'red' }}},
                        @{n='ValidMember';e={$_.isValidMember};css={if ($_.isvalidMember -ne "True") { 'red' }}},
                        @{n='ErrorMessage';e={$_.ErrorMessage}}
        }

        $html_members_accept = ConvertTo-EnhancedHTMLFragment -InputObject $office365AcceptMessagesFromSendersOrMembersEval @params

        $htmlSections += $html_members_accept
    }

    out-logfile -string "Build HTML for reject messages from senders or members."

    if ($office365RejectMessagesFromSendrsOfMembersEval.count -gt 0)
    {
        $params = @{'As'='Table';
        'PreContent'='<h2>&diams; Member Analysis :: Active Directory -> Office 365 Reject Messages From Senders or Members</h2>';
        'EvenRowCssClass'='even';
        'OddRowCssClass'='odd';
        'MakeTableDynamic'=$true;
        'TableCssClass'='grid';
        'MakeHiddenSection'=$true;
        'Properties'=   @{n='Member';e={$_.name}},
                        @{n='ExternalDirectoryObjectID';e={if ($_.externalDirectoryObjectID -ne $NULL){$_.externalDirectoryObjectID}else{""}}},
                        @{n='PrimarySMTPAddress';e={if ($_.primarySMTPAddress -ne $NULL){$_.primarySMTPAddress}else{""}}},
                        @{n='UserPrincipalName';e={if ($_.userPrincipalName -ne $NULL){$_.UserPrincipalName}else{""}}},
                        @{n='ObjectSID';e={if ($_.objectSID -ne $NULL){$_.objectSid}else{""}}},
                        @{n='PresentActiveDirectory';e={$_.isPresentOnPremises};css={if ($_.isPresentOnPremsies -eq "False") { 'red' }}},
                        @{n='PresentAzureActiveDirectory';e={$_.isPresentInAzure};css={if ($_.isPresentInAzure -eq "False") { 'red' }}},
                        @{n='PresentExchangeOnline';e={$_.isPresentInExchangeOnline};css={if ($_.isPresentInExchangeOnline -eq "False"){ 'red' }}},
                        @{n='ValidMember';e={$_.isValidMember};css={if ($_.isvalidMember -ne "True") { 'red' }}},
                        @{n='ErrorMessage';e={$_.ErrorMessage}}
        }

        $html_members_reject = ConvertTo-EnhancedHTMLFragment -InputObject $office365RejectMessagesFromSendrsOfMembersEval @params

        $htmlSections += $html_members_reject
    }

    out-logfile -string "Build HTML for bypass moderation from senders or members."

    if ($office365BypassModerationFromSendersOrMembersEval.count -gt 0)
    {
        $params = @{'As'='Table';
        'PreContent'='<h2>&diams; Member Analysis :: Active Directory -> Office 365 Bypass Moderation From Senders Or Members</h2>';
        'EvenRowCssClass'='even';
        'OddRowCssClass'='odd';
        'MakeTableDynamic'=$true;
        'TableCssClass'='grid';
        'MakeHiddenSection'=$true;
        'Properties'=   @{n='Member';e={$_.name}},
                        @{n='ExternalDirectoryObjectID';e={if ($_.externalDirectoryObjectID -ne $NULL){$_.externalDirectoryObjectID}else{""}}},
                        @{n='PrimarySMTPAddress';e={if ($_.primarySMTPAddress -ne $NULL){$_.primarySMTPAddress}else{""}}},
                        @{n='UserPrincipalName';e={if ($_.userPrincipalName -ne $NULL){$_.UserPrincipalName}else{""}}},
                        @{n='ObjectSID';e={if ($_.objectSID -ne $NULL){$_.objectSid}else{""}}},
                        @{n='PresentActiveDirectory';e={$_.isPresentOnPremises};css={if ($_.isPresentOnPremsies -eq "False") { 'red' }}},
                        @{n='PresentAzureActiveDirectory';e={$_.isPresentInAzure};css={if ($_.isPresentInAzure -eq "False") { 'red' }}},
                        @{n='PresentExchangeOnline';e={$_.isPresentInExchangeOnline};css={if ($_.isPresentInExchangeOnline -eq "False"){ 'red' }}},
                        @{n='ValidMember';e={$_.isValidMember};css={if ($_.isvalidMember -ne "True") { 'red' }}},
                        @{n='ErrorMessage';e={$_.ErrorMessage}}
        }

        $html_members_bypass = ConvertTo-EnhancedHTMLFragment -InputObject $office365BypassModerationFromSendersOrMembersEval @params

        $htmlSections += $html_members_bypass
    }

    out-logfile -string "Generate HTML for moderated by"

    if ($office365ModeratedByEval.count -gt 0)
    {
        $params = @{'As'='Table';
        'PreContent'='<h2>&diams; Member Analysis :: Active Directory -> Office 365 ModeratedBy</h2>';
        'EvenRowCssClass'='even';
        'OddRowCssClass'='odd';
        'MakeTableDynamic'=$true;
        'TableCssClass'='grid';
        'MakeHiddenSection'=$true;
        'Properties'=   @{n='Member';e={$_.name}},
                        @{n='ExternalDirectoryObjectID';e={if ($_.externalDirectoryObjectID -ne $NULL){$_.externalDirectoryObjectID}else{""}}},
                        @{n='PrimarySMTPAddress';e={if ($_.primarySMTPAddress -ne $NULL){$_.primarySMTPAddress}else{""}}},
                        @{n='UserPrincipalName';e={if ($_.userPrincipalName -ne $NULL){$_.UserPrincipalName}else{""}}},
                        @{n='ObjectSID';e={if ($_.objectSID -ne $NULL){$_.objectSid}else{""}}},
                        @{n='PresentActiveDirectory';e={$_.isPresentOnPremises};css={if ($_.isPresentOnPremsies -eq "False") { 'red' }}},
                        @{n='PresentAzureActiveDirectory';e={$_.isPresentInAzure};css={if ($_.isPresentInAzure -eq "False") { 'red' }}},
                        @{n='PresentExchangeOnline';e={$_.isPresentInExchangeOnline};css={if ($_.isPresentInExchangeOnline -eq "False"){ 'red' }}},
                        @{n='ValidMember';e={$_.isValidMember};css={if ($_.isvalidMember -ne "True") { 'red' }}},
                        @{n='ErrorMessage';e={$_.ErrorMessage}}
        }

        $html_members_moderatedby = ConvertTo-EnhancedHTMLFragment -InputObject $office365ModeratedByEval @params

        $htmlSections += $html_members_moderatedby
    }

    out-logfile -string "Generated HTML for managed by."

    if ($office365ManagedByEval.count -gt 0)
    {
        $params = @{'As'='Table';
        'PreContent'='<h2>&diams; Member Analysis :: Active Directory -> Office 365 ManagedBy</h2>';
        'EvenRowCssClass'='even';
        'OddRowCssClass'='odd';
        'MakeTableDynamic'=$true;
        'TableCssClass'='grid';
        'MakeHiddenSection'=$true;
        'Properties'=   @{n='Member';e={$_.name}},
                        @{n='ExternalDirectoryObjectID';e={if ($_.externalDirectoryObjectID -ne $NULL){$_.externalDirectoryObjectID}else{""}}},
                        @{n='PrimarySMTPAddress';e={if ($_.primarySMTPAddress -ne $NULL){$_.primarySMTPAddress}else{""}}},
                        @{n='UserPrincipalName';e={if ($_.userPrincipalName -ne $NULL){$_.UserPrincipalName}else{""}}},
                        @{n='ObjectSID';e={if ($_.objectSID -ne $NULL){$_.objectSid}else{""}}},
                        @{n='PresentActiveDirectory';e={$_.isPresentOnPremises};css={if ($_.isPresentOnPremsies -eq "False") { 'red' }}},
                        @{n='PresentAzureActiveDirectory';e={$_.isPresentInAzure};css={if ($_.isPresentInAzure -eq "False") { 'red' }}},
                        @{n='PresentExchangeOnline';e={$_.isPresentInExchangeOnline};css={if ($_.isPresentInExchangeOnline -eq "False"){ 'red' }}},
                        @{n='ValidMember';e={$_.isValidMember};css={if ($_.isvalidMember -ne "True") { 'red' }}},
                        @{n='ErrorMessage';e={$_.ErrorMessage}}
        }

        $html_members_managedBY = ConvertTo-EnhancedHTMLFragment -InputObject $office365ManagedByEval @params

        $htmlSections += $html_members_managedBy
    }

    out-logfile -string "Build HTML for grant send on behalf to."

    if ($office365GrantSendOnBehalfToEval.count -gt 0)
    {
        $params = @{'As'='Table';
        'PreContent'='<h2>&diams; Member Analysis :: Active Directory -> Office 365 Grant Send On Behalf To</h2>';
        'EvenRowCssClass'='even';
        'OddRowCssClass'='odd';
        'MakeTableDynamic'=$true;
        'TableCssClass'='grid';
        'MakeHiddenSection'=$true;
        'Properties'=   @{n='Member';e={$_.name}},
                        @{n='ExternalDirectoryObjectID';e={if ($_.externalDirectoryObjectID -ne $NULL){$_.externalDirectoryObjectID}else{""}}},
                        @{n='PrimarySMTPAddress';e={if ($_.primarySMTPAddress -ne $NULL){$_.primarySMTPAddress}else{""}}},
                        @{n='UserPrincipalName';e={if ($_.userPrincipalName -ne $NULL){$_.UserPrincipalName}else{""}}},
                        @{n='ObjectSID';e={if ($_.objectSID -ne $NULL){$_.objectSid}else{""}}},
                        @{n='PresentActiveDirectory';e={$_.isPresentOnPremises};css={if ($_.isPresentOnPremsies -eq "False") { 'red' }}},
                        @{n='PresentAzureActiveDirectory';e={$_.isPresentInAzure};css={if ($_.isPresentInAzure -eq "False") { 'red' }}},
                        @{n='PresentExchangeOnline';e={$_.isPresentInExchangeOnline};css={if ($_.isPresentInExchangeOnline -eq "False"){ 'red' }}},
                        @{n='ValidMember';e={$_.isValidMember};css={if ($_.isvalidMember -ne "True") { 'red' }}},
                        @{n='ErrorMessage';e={$_.ErrorMessage}}
        }

        $html_members_grantsend = ConvertTo-EnhancedHTMLFragment -InputObject $office365GrantSendOnBehalfToEval @params

        $htmlSections += $html_members_grantsend
    }


    if ($htmlSections.count -gt 0)
    {
        $params = @{'CssStyleSheet'=$style;
        'Title'="Distribution List Health Report for $groupSMTPAddress";
        'PreContent'="<h1>Distribution List Health Report for $groupSMTPAddress</h1>";
        'HTMLFragments'=$htmlSections}
        ConvertTo-EnhancedHTML @params |
        Out-File -FilePath c:\temp\test.html
    }
    else
    {
        out-logfile -string "No HTML report to generate - no data provided."
    }
    
    

    #=============================================================================================================================================
    #=============================================================================================================================================
    #=============================================================================================================================================

    <#
    $functionObject = New-Object PSObject -Property @{
        OnPremisesMemberCount = $exchangeDLMembershipSMTP.count
        AzureADMemberCount = $azureADDlMembership.count
        Office365DLMemberCount = $office365DLMembership.count
        OnPremisesAcceptMessagesFromSendersOrMembersCount = $exchangeAcceptMessagesSMTP.count
        Office365AcceptMessagesFromSendersOrMembersCount = $office365AcceptMessagesFromSendersOrMembers.count
        OnPremisesRejectMessagesFromSendersOrMembersCount = $exchangeRejectMessagesSMTP.count
        Office365RejectMessagesFromSendersOrMembersCount = $office365RejectMessagesFromSendersOrMembers.count
        OnPremisesModeratedByCount = $exchangeModeratedBySMTP.count
        Office365ModeratedByCount = $office365ModeratedBy.count
        OnPremisesManagedByCount = $exchangeManagedBySMTP.count
        Office365ManagedByCount = $office365ManagedBy.count
        OnPremisesBypassModerationFromSendersOrMembers = $exchangeBypassModerationSMTP.count
        Office365BypassModerationFromSendersOrMembers = $office365BypassModerationFromSendersOrMembers.count
        OnPremisesGrantSendOnBehalfTo = $exchangeGrantSendOnBehalfToSMTP.count
        Office365GrantSendOnBehalfTo = $office365GrantSendOnBehalfTo.count
        OnPremisesSendAsRightsOnGroup = $exchangeSendAsSMTP.count
        Office365SendAsRightsOnGroup = $allOffice365SendAsAccessOnGroup.count
        OnPremisesSendAsRightsOnOtherObjects = $allObjectsSendAsAccessNormalized.Count
        Office365SendAsRightsOnOtherObjects = $allOffice365SendAsAccess.count
        OnPremisesFullMailboxAccessRights = $allObjectsFullMailboxAccess.count
        Office365FullMailboxAccessRights = $allOffice365FullMailboxAccess.count
        OnPremsiesMailboxFolderRights = $allMailboxesFolderPermissions.count
        Office365MailboxFolderRights = $allOffice365MailboxFolderPermissions.count
        OnPremisesMemberOfOtherObjects = $allGroupsMemberOf.count
        Office365MemberOfOtherObjects = $allOffice365MemberOf.count
        OnPremsiesAcceptMessagesFromSendersOrMembersOtherObjects = $allGroupsAccept.count
        Office365AcceptMessagesFromSendersOrMembersOtherObjects = $allOffice365Accept.count
        OnPremisesRejectMessagesFromSendersOrMembersOtherObjects = $allGroupsReject.count
        Office365RejectMessagesFromSendersOrMembersOtherObjects = $allOffice365Reject.count
        OnPremiseManagedByOtherObjects = $allGroupsManagedBy.count
        OnPremisesCoManagedByOtherObjects = $allGroupsCoManagedByBL.Count
        Office365ManagedByOtherObjects = $allOffice365ManagedBy.count
        OnPremisesBypassModerationFromSendersOrMembersOtherObjects = $allGroupsBypassModeration.count
        Office365BypassModerationFromSendersOrMembersOtherObjects = $allOffice365BypassModeration.count
        OnPremisesGrantSendOnBehalfToOtherObjects = $allGroupsGrantSendOnBehalfTo.count
        Office365GrantSendOnBehalfToOtherObjects = $allOffice365GrantSendOnBehalfTo.count
        OnPremisesMailboxForwardingAddress = $allUsersForwardingAddress.count
        Office365MailboxForwardingAddress = $allOffice365ForwardingAddress.count
        }#>
    

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