
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


Function Start-DistributionListMigration 
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

    .PARAMETER DONOTSYNCOU

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
    This settings triggers the migrated group to be upgraded to the modern Office 365 Group / Universal Group experience.

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

    Introduction to the Distribution List Migration Module version 2.0
    https://timmcmic.wordpress.com/2021/04/25/4116/

    Preparing to use the distribution list migration v2 module.
    https://timmcmic.wordpress.com/2021/04/26/office-365-distribution-list-migrations-version-2-0-part-2/

    Using the distribution list migration module v2 for simple migrations
    https://timmcmic.wordpress.com/2021/04/26/office-365-distribution-list-migrations-version-2-0-part-3-2/

    Retaining the original distribution group post migration…
    https://timmcmic.wordpress.com/2021/04/27/office-365-distribution-list-migrations-version-2-0-part-4/

    Gathering advanced dependencies for a group to be migrated…
    https://timmcmic.wordpress.com/2021/04/27/office-365-distribution-list-migrations-version-2-0-part-5/

    How does the module track distribution lists that have been migrated?
    https://timmcmic.wordpress.com/2021/04/28/office-365-distribution-list-migrations-version-2-0-part-6/

    Enabling hybrid mail flow for migrated distribution lists.
    https://timmcmic.wordpress.com/2021/04/28/office-365-distribution-list-migrations-version-2-0-part-7/

    https://timmcmic.wordpress.com/2021/09/01/office-365-distribution-list-migration-version-2-0-part-8/

    Introduction to batch migrations.
    https://timmcmic.wordpress.com/2021/09/02/office-365-distribution-list-migrations-version-2-0-part-9/

    https://timmcmic.wordpress.com/2021/09/27/office-365-distribution-list-migration-version-2-0-part-10/

    Improvements in Error Handling in version 2.4.8.x
    https://timmcmic.wordpress.com/2021/10/19/office-365-distribution-list-migration-version-2-0-part-11/

    Announcing multiple migration machine support.
    https://timmcmic.wordpress.com/2021/10/19/office-365-distribution-list-migration-version-2-0-part-12/

    Enabling support for partially mail enabled distribution groups.
    https://timmcmic.wordpress.com/2022/03/07/office-365-distribution-list-migration-version-2-0-part-13/

    Enabling hybrid mail flow post group migration.
    https://timmcmic.wordpress.com/2022/03/08/office-365-distribution-list-migration-version-2-0-part-14/

    Enabling migration support for non-synchronized groups.
    https://timmcmic.wordpress.com/2022/03/08/office-365-distribution-list-migration-version-2-0-part-15/

    Mail flow issues with centralized mail transport enabled and migrated distribution groups.
    https://timmcmic.wordpress.com/2022/03/13/office-365-distribution-list-migration-version-2-0-part-16/

    I need assistance with the migration module, have a suggestion, or want to request a feature?
    https://timmcmic.wordpress.com/2022/03/13/office-365-distribution-list-migration-version-2-0-part-17/

    New handling of recipient restrictions assigned to the migrated distribution group.
    https://timmcmic.wordpress.com/2022/03/27/office-365-distribution-list-migration-version-2-0-part-18/

    New handling of distribution group creation during migration to eliminate ambiguous references.
    https://timmcmic.wordpress.com/2022/03/27/office-365-distribution-list-migration-version-2-0-part-19/

    Adding a new method of verifying the distribution list is directory synchronized.
    https://timmcmic.wordpress.com/2022/09/18/office-365-distribution-list-migration-version-2-0-part-20/

    Preparing for the deprecation and disablement of Basic Authentication.
    https://timmcmic.wordpress.com/2022/09/18/office-365-distribution-list-migration-version-2-0-part-21/

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
        #Azure Active Directory Connect Parameters
        [Parameter(Mandatory = $false)]
        [string]$aadConnectServer=$NULL,
        [Parameter(Mandatory = $false)]
        [pscredential]$aadConnectCredential=$NULL,
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
        [Parameter(Mandatory = $true)]
        [string]$dnNoSyncOU = "NotSet",
        #Defining optional parameters for retention and upgrade
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
        #Define parameters for multi-threaded operations
        [Parameter(Mandatory = $false)]
        [int]$threadNumberAssigned=0,
        [Parameter(Mandatory = $false)]
        [int]$totalThreadCount=0,
        [Parameter(Mandatory = $FALSE)]
        [boolean]$isMultiMachine=$FALSE,
        [Parameter(Mandatory = $FALSE)]
        [string]$remoteDriveLetter=$NULL
    )

    $windowTitle = ("Start-DistributionListMigration "+$groupSMTPAddress)
    $host.ui.RawUI.WindowTitle = $windowTitle

     #Define the status directory.

     [string]$global:statusPath="\Status\"
     [string]$global:fullStatusPath=$NULL
     [int]$statusFileCount=0

    #Define global variables.

    $global:threadNumber=$threadNumberAssigned
    $global:logFile=$NULL #This is the global variable for the calculated log file name
    [string]$global:staticFolderName="\DLMigration\"
    [string]$global:staticAuditFolderName="\AuditData\"
    [string]$global:importFile=$logFolderPath+$global:staticAuditFolderName

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

    #Define the sub folders for multi-threading.

    [array]$threadFolder="\Thread0","\Thread1","\Thread2","\Thread3","\Thread4","\Thread5","\Thread6","\Thread7","\Thread8","\Thread9","\Thread10"

    #If multi threaded - the log directory needs to be created for each thread.
    #Create the log folder path for status before changing the log folder path.

    if ($totalThreadCount -gt 0)
    {
        new-statusFile -logFolderPath $logFolderPath

        $logFolderPath=$logFolderPath+$threadFolder[$global:threadNumber]
    }

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
        onPremAcceptMessagesFromDLMembers = @{"Value" = "dlMemSubmitPerms" ; "Description" = "LDAP Attribute for Accept Messages from DL Members" }
        onPremRejectMessagesFromDLMembers = @{"Value" = "dlMemRejectPerms" ; "Description" = "LDAP Attribute for Reject Messages from DL Members"}
        onPremBypassModerationFromDL = @{"Value" = "msExchBypassModerationFromDLMembersLink" ; "Description" = "LDAP Attribute for Bypass Moderation from DL Members"}
        onPremForwardingAddress = @{"Value" = "altRecipient" ; "Description" = "LDAP Attribute for ForwardingAddress"}
        onPremGrantSendOnBehalfTo = @{"Value" = "publicDelegates" ; "Description" = "LDAP Attribute for Grant Send on Behalf To"}
        onPremRejectMessagesFromSenders = @{"Value" = "unauthorig" ; "Description" = "LDAP Attribute for Reject Messages from Sender"}
        onPremAcceptMessagesFromSenders = @{"Value" = "authOrig" ; "Description" = "LDAp Attribute for Accept Messages From Sender"} 
        onPremManagedBy = @{"Value" = "managedBy" ; "Description" = "LDAP Attribute for Managed By"}
        onPremCoManagedBy = @{"Value" = "msExchCoManagedByLink" ; "Description" = "LDAP Attributes for Co Managers (Muiltivalued ManagedBy)"}
        onPremModeratedBy = @{"Value" = "msExchModeratedByLink" ; "Description" = "LDAP Attrbitute for Moderated By"}
        onPremBypassModerationFromSenders = @{"Value" = "msExchBypassModerationLink" ; "Description" = "LDAP Attribute for Bypass Moderation from Senders"}
        onPremMembers = @{"Value" = "member" ; "Description" = "LDAP Attribute for Distribution Group Members" }
        onPremForwardingAddressBL = @{"Value" = "altRecipientBL" ; "Description" = "LDAP Backlink Attribute for Forwarding Address"}
        onPremRejectMessagesFromDLMembersBL = @{"Value" = "dlMemRejectPermsBL" ; "Description" = "LDAP Backlink Attribute for Reject Messages from DL Members"}
        onPremAcceptMessagesFromDLMembersBL = @{"Value" = "dlMemSubmitPermsBL" ; "Description" = "LDAP Backlink Attribute for Accept Messages from DL Members"}
        onPremManagedObjects = @{"Value" = "managedObjects" ; "Description" = "LDAP Backlink Attribute for Managed By"}
        onPremMemberOf = @{"Value" = "memberOf" ; "Description" = "LDAP Backlink Attribute for Members"}
        onPremBypassModerationFromDLMembersBL = @{"Value" = "msExchBypassModerationFromDLMembersBL" ; "Description" = "LDAP Backlink Attribute for Bypass Moderation from DL Members"}
        onPremCoManagedByBL = @{"Value" = "msExchCoManagedObjectsBL" ; "Description" = "LDAP Backlink Attribute for Co Managers (Multivalued ManagedBY)"}
        onPremGrantSendOnBehalfToBL = @{"Value" = "publicDelegatesBL" ; "Description" = "LDAP Backlink Attribute for Grant Send On Behalf To"}
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

    #Static variables utilized for the Exchange On-Premsies Powershell.

    $onPremExchangePowershell = @{
        exchangeServerConfiguration = @{"Value" = "Microsoft.Exchange" ; "Description" = "Defines the Exchange Remote Powershell configuration"} 
        exchangeServerAllowRedirection = @{"Value" = $TRUE ; "Description" = "Defines the Exchange Remote Powershell redirection preference"} 
        exchangeServerURI = @{"Value" = "https://"+$exchangeServer+"/powershell" ; "Description" = "Defines the Exchange Remote Powershell connection URL"} 
        exchangeServerURIKerberos = @{"Value" = "http://"+$exchangeServer+"/powershell" ; "Description" = "Defines the Exchange Remote Powershell connection URL"} 
    }

    #Define XML files to contain backups.

    $xmlFiles = @{
        originalDLConfigurationADXML = @{ "Value" =  "originalDLConfigurationADXML" ; "Description" = "XML file that exports the original DL configuration"}
        originalDLConfigurationUpdatedXML = @{ "Value" =  "originalDLConfigurationUpdatedXML" ; "Description" = "XML file that exports the updated DL configuration"}
        office365DLConfigurationXML = @{ "Value" =  "office365DLConfigurationXML" ; "Description" = "XML file that exports the Office 365 DL configuration"}
        office365DLConfigurationPostMigrationXML = @{ "Value" =  "office365DLConfigurationPostMigrationXML" ; "Description" = "XML file that exports the Office 365 DL configuration post migration"}
        office365DLMembershipPostMigrationXML = @{ "Value" =  "office365DLMembershipPostMigrationXML" ; "Description" = "XML file that exports the Office 365 DL membership post migration"}
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
        azureDLConfigurationXML = @{"Value" = "azureADDL.xml" ; "Description" = "Export XML file holding the configuration from azure active directory"}
    }

    #Define the property sets that will be cleared on the on premises object.

    [array]$dlPropertySet = '*' #Clear all properties of a given object
    [array]$dlPropertySetToClear = #Holds the final array of attributes to be cleared.
    [array]$dlPropertiesToClearModern='authOrig','DisplayName','DisplayNamePrintable',$onPremADAttributes.onPremRejectMessagesfromDLMembers.Value,$onPremADAttributes.onPremAcceptMessagesfromDLMembers.Value,'extensionAttribute1','extensionAttribute10','extensionAttribute11','extensionAttribute12','extensionAttribute13','extensionAttribute14','extensionAttribute15','extensionAttribute2','extensionAttribute3','extensionAttribute4','extensionAttribute5','extensionAttribute6','extensionAttribute7','extensionAttribute8','extensionAttribute9','legacyExchangeDN','mail','mailNickName','msExchRecipientDisplayType','msExchRecipientTypeDetails','msExchRemoteRecipientType',$onPremADAttributes.onPremBypassModerationFromDL.Value,'msExchBypassModerationLink','msExchCoManagedByLink','msExchEnableModeration','msExchExtensionCustomAttribute1','msExchExtensionCustomAttribute2','msExchExtensionCustomAttribute3','msExchExtensionCustomAttribute4','msExchExtensionCustomAttribute5','msExchGroupDepartRestriction','msExchGroupJoinRestriction','msExchHideFromAddressLists','msExchModeratedByLink','msExchModerationFlags','msExchRequireAuthToSendTo','msExchSenderHintTranslations','oofReplyToOriginator','proxyAddresses',$onPremADAttributes.onPremGrantSendOnBehalfTo.Value,'reportToOriginator','reportToOwner','unAuthOrig','msExchArbitrationMailbox','msExchPoliciesIncluded','msExchUMDtmfMap','msExchVersion','showInAddressBook','msExchAddressBookFlags','msExchBypassAudit','msExchGroupExternalMemberCount','msExchGroupMemberCount','msExchGroupSecurityFlags','msExchLocalizationFlags','msExchMailboxAuditEnable','msExchMailboxAuditLogAgeLimit','msExchMailboxFolderSet','msExchMDBRulesQuota','msExchPoliciesIncluded','msExchProvisioningFlags','msExchRecipientSoftDeletedStatus','msExchRoleGroupType','msExchTransportRecipientSettingsFlags','msExchUMDtmfMap','msExchUserAccountControl','msExchVersion' #Properties Exchange 2016 or newer schema.
    [array]$dlPropertiesToClearLegacy='authOrig','DisplayName','DisplayNamePrintable',$onPremADAttributes.onPremRejectMessagesfromDLMembers.Value,$onPremADAttributes.onPremAcceptMessagesfromDLMembers.Value,'extensionAttribute1','extensionAttribute10','extensionAttribute11','extensionAttribute12','extensionAttribute13','extensionAttribute14','extensionAttribute15','extensionAttribute2','extensionAttribute3','extensionAttribute4','extensionAttribute5','extensionAttribute6','extensionAttribute7','extensionAttribute8','extensionAttribute9','legacyExchangeDN','mail','mailNickName','msExchRecipientDisplayType','msExchRecipientTypeDetails','msExchRemoteRecipientType',$onPremADAttributes.onPremBypassModerationFromDL.Value,'msExchBypassModerationLink','msExchCoManagedByLink','msExchEnableModeration','msExchExtensionCustomAttribute1','msExchExtensionCustomAttribute2','msExchExtensionCustomAttribute3','msExchExtensionCustomAttribute4','msExchExtensionCustomAttribute5','msExchGroupDepartRestriction','msExchGroupJoinRestriction','msExchHideFromAddressLists','msExchModeratedByLink','msExchModerationFlags','msExchRequireAuthToSendTo','msExchSenderHintTranslations','oofReplyToOriginator','proxyAddresses',$onPremADAttributes.onPremGrantSendOnBehalfTo.Value,'reportToOriginator','reportToOwner','unAuthOrig','msExchArbitrationMailbox','msExchPoliciesIncluded','msExchUMDtmfMap','msExchVersion','showInAddressBook','msExchAddressBookFlags','msExchBypassAudit','msExchGroupExternalMemberCount','msExchGroupMemberCount','msExchLocalizationFlags','msExchMailboxAuditEnable','msExchMailboxAuditLogAgeLimit','msExchMailboxFolderSet','msExchMDBRulesQuota','msExchPoliciesIncluded','msExchProvisioningFlags','msExchRecipientSoftDeletedStatus','msExchRoleGroupType','msExchTransportRecipientSettingsFlags','msExchUMDtmfMap','msExchUserAccountControl','msExchVersion' #Properties Exchange 2013 or older schema

    #On premises variables for the distribution list to be migrated.

    $originalDLConfiguration=$NULL #This holds the on premises DL configuration for the group to be migrated.
    $originalAzureADConfiguration=$NULL #This holds the azure ad DL configuration
    $originalDLConfigurationUpdated=$NULL #This holds the on premises DL configuration post the rename operations.
    $routingContactConfig=$NULL #Holds the mail routing contact configuration.
    $routingDynamicGroupConfig=$NULL #Holds the dynamic distribution list configuration used for mail routing.
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
    
    #Cloud variables for the distribution list to be migrated.

    $office365DLConfiguration = $NULL #This holds the office 365 DL configuration for the group to be migrated.
    $azureADDlConfiguration = $NULL #This holds the Azure AD DL configuration
    $office365DLConfigurationPostMigration = $NULL #This hold the Office 365 DL configuration post migration.
    $office365DLMembershipPostMigration=$NULL #This holds the Office 365 DL membership information post migration
    $routingContactConfiguraiton=$NULL #This is the empty routing contact configuration.

    #Declare some variables for string processing as items move around.

    [string]$tempOU=$NULL
    [array]$tempNameArrayArray=@()
    [string]$tempName=$NULL
    [string]$tempDN=$NULL

    #For loop counter.

    [int]$forLoopCounter=0

    #Exchange Schema Version

    [int]$exchangeRangeUpper=$NULL
    [int]$exchangeLegacySchemaVersion=15317 #Exchange 2016 Preview Schema - anything less is legacy.

    #Define new arrays to check for errors instead of failing.

    [array]$preCreateErrors=@()
    [array]$global:postCreateErrors=@()
    [array]$onPremReplaceErrors=@()
    [array]$office365ReplaceErrors=@()
    [array]$global:office365ReplacePermissionsErrors=@()
    [array]$global:onPremReplacePermissionsErrors=@()
    [array]$generalErrors=@()
    [string]$isTestError="No"


    [int]$forLoopTrigger=1000

    #To support the new feature for multiple onmicrosoft.com domains -> use this variable to hold the cross premsies routing domain.
    #This value can no longer be calculated off the address@domain.onmicrosoft.com value.

    [string]$mailOnMicrosoftComDomain = ""

    #Ensure that no status files exist at the start of the run.

    if ($totalThreadCount -gt 0)
    {
        if ($global:threadNumber -eq 1)
        {
            remove-statusFiles -fullCleanup:$TRUE
        }
    }

    #Log start of DL migration to the log file.

    new-LogFile -groupSMTPAddress $groupSMTPAddress.trim() -logFolderPath $logFolderPath

    #Output all parameters bound or unbound and their associated values.

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "PARAMETERS"
    Out-LogFile -string "********************************************************************************"

    write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

    Out-LogFile -string "================================================================================"
    Out-LogFile -string "BEGIN START-DISTRIBUTIONLISTMIGRATION"
    Out-LogFile -string "================================================================================"

    out-logfile -string "Set error action preference to continue to allow write-error in out-logfile to service exception retrys"

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

    if ($aadConnectServer -ne $NULL)
    {
        $aadConnectServer = remove-stringSpace -stringToFix $aadConnectServer
    }

    if ($exchangeServer -ne $NULL)
    {
        $exchangeServer=remove-stringSpace -stringToFix $exchangeServer
    }
    
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

    $exchangeAuthenticationMethod=remove-StringSpace -stringToFix $exchangeAuthenticationMethod
    
    $dnNoSyncOU = remove-StringSpace -stringToFix $dnNoSyncOU
    
    $groupTypeOverride=remove-stringSpace -stringToFix $groupTypeOverride
    
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

    if ($aadConnectCredential -ne $null)
    {
        Out-LogFile -string ("AADConnectUserName = "+$aadConnectCredential.UserName.tostring())
    }

    if ($exchangecredential -ne $null)
    {
        Out-LogFile -string ("ExchangeUserName = "+$exchangeCredential.UserName.toString())
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

    foreach ($dlProperty in $dlPropertySet)
    {
        Out-LogFile -string $dlProperty
    }

    Out-LogFile -string ("DL property set to be cleared legacy = ")

    foreach ($dlProperty in $dlPropertiesToClearLegacy)
    {
        Out-LogFile -string $dlProperty
    }

    Out-LogFile -string ("DL property set to be cleared modern = ")

    foreach ($dlProperty in $dlPropertiesToClearModern)
    {
        Out-LogFile -string $dlProperty
    }

    out-logfile -string ("Predefined thread folders = ")

    foreach ($property in $threadFolder)
    {
        out-logfile -string $property
    }

    out-logfile -string ("Exchange legacy schema version: "+$exchangeLegacySchemaVersion)

    out-logfile -string ("Global import file: "+$global:importFile)
    out-logfile -string ("Global staticFolderName: "+$global:staticFolderName)
    out-logfile -string ("Global threadNumber: "+$global:threadNumber)

    write-hashTable -hashTable $xmlFiles
    write-hashTable -hashTable $onPremExchangePowershell
    write-hashTable -hashTable $office365Attributes
    write-hashTable -hashTable $onPremADAttributes
    write-hashTable -hashTable $coreVariables
    
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
    
        #Set useAADConnect to TRUE since the parameters necessary for use were passed.
        
        $coreVariables.useAADConnect.value=$TRUE

        Out-LogFile -string ("Set useAADConnect to TRUE since the parameters necessary for use were passed. - "+$coreVariables.useAADConnect.value)
    }
    else
    {
        Out-LogFile -string ("Neither AADConnect Server or AADConnect Credentials specified - retain useAADConnect FALSE - "+$coreVariables.useAADConnect.value)
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

        #Set useOnPremisesExchange to TRUE since the parameters necessary for use were passed.

        $coreVariables.useOnPremisesExchange.value=$TRUE

        Out-LogFile -string ("Set useOnPremsiesExchanget to TRUE since the parameters necessary for use were passed - "+$coreVariables.useOnPremisesExchange.value)
    }
    else
    {
        Out-LogFile -string ("Neither Exchange Server or Exchange Credentials specified - retain useOnPremisesExchange FALSE - "+$coreVariables.useOnPremisesExchange.value)
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

    #Validate that only one method of engaging exchange online was specified.

    Out-LogFile -string "Validating Azure AD Credentials."

    if (($azureADCredential -ne $NULL) -and ($azureCertificateThumbprint -ne ""))
    {
        Out-LogFile -string "ERROR:  Only one method of azure cloud authentication can be specified.  Use either azure cloud credentials or azure cloud certificate thumbprint." -isError:$TRUE
    }
    elseif (($azureADCredential -eq $NULL) -and ($azureCertificateThumbprint -eq ""))
    {
        out-logfile -string "ERROR:  One permissions method to connect to Azure AD must be specified." -isError:$TRUE
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

    #Validate that all information for the certificate connection has been provieed.

    if (($azureCertificateThumbprint -ne "") -and ($azureTenantID -eq "") -and ($azureApplicationID -eq ""))
    {
        out-logfile -string "The azure tenant ID and Azure App ID are required when using certificate authentication to Azure." -isError:$TRUE
    }
    elseif (($azureCertificateThumbprint -ne "") -and ($AzureTenantID -ne "") -and ($azureApplicationID -eq ""))
    {
        out-logfile -string "The azure app id is required to use certificate authentication to Azure." -isError:$TRUE
    }
    elseif (($azureCertificateThumbprint -ne "") -and ($azureTenantID -eq "") -and ($azureApplicationID -ne ""))
    {
        out-logfile -string "The exchange organization name is required when using certificate thumbprint authentication." -isError:$TRUE
    }
    else 
    {
        out-logfile -string "All components necessary for Exchange certificate thumbprint authentication were specified."    
    }

    #exit #Debug exit.

    #Validate that an OU was specified <if> retain group is not set to true.

    Out-LogFile -string "Validating that if retain original group is false a non-sync OU is specified."

    if (($retainOriginalGroup -eq $FALSE) -and ($dnNoSyncOU -eq "NotSet"))
    {
        out-LogFile -string "A no SYNC OU is required if retain original group is false." -isError:$TRUE
    }

    if (($coreVariables.useOnPremisesExchange.value -eq $False) -and ($enableHybridMailflow -eq $true))
    {
        out-logfile -string "Exchange on premsies information must be provided in order to enable hybrid mail flow." -isError:$TRUE
    }

    if (($auditSendAsOnPrem -eq $TRUE ) -and ($coreVariables.useOnPremisesExchange.value -eq $FALSE))
    {
        out-logfile -string "In order to audit send as on premsies an Exchange Server must be specified." -isError:$TRUE
    }

    if (($auditFullMailboxAccessOnPrem -eq $TRUE) -and ($coreVariables.useOnPremisesExchange.value -eq $FALSE))
    {
        out-logfile -string "In order to audit full mailboxes access on premsies an Exchange Server must be specified." -isError:$TRUE
    }

    if (($retainSendAsOffice365 -eq $TRUE) -and ($retainOffice365Settings -eq $FALSE))
    {
        out-logfile -string "When retaining Office 365 Send As you must retain Office 365 settings." -isError:$TRUE
    }

    if (($retainFullMailboxAccessOffice365 -eq $TRUE) -and ($retainOffice365Settings -eq $FALSE))
    {
        out-logfile -string "When retaining Office 365 Full Mailbox Access you must retain Office 365 settings." -isError:$TRUE
    }

    if (($retainMailboxFolderPermsOffice365 -eq $TRUE) -and ($retainOffice365Settings -eq $FALSE))
    {
        out-logfile -string "When retaining Office 365 Mailbox Folder Permissions you must retain Office 365 settings." -isError:$TRUE
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


    Out-LogFile -string "END PARAMETER VALIDATION"
    Out-LogFile -string "********************************************************************************"

    Out-Logfile -string "Determine Exchange Schema Version"

    try{
        $exchangeRangeUpper = get-ExchangeSchemaVersion -globalCatalogServer $globalCatalogServer -adCredential $activeDirectoryCredential -errorAction STOP
        out-logfile -string ("The range upper for Exchange Schema is: "+ $exchangeRangeUpper)
    }
    catch{
        out-logfile -string "Error occured obtaining the Exchange Schema Version."
        out-logfile -string $_ -isError:$TRUE
    }
    
    if ($exchangeRangeUpper -ge $exchangeLegacySchemaVersion)
    {
        out-logfile -string "Modern exchange version detected - using modern parameters"
        $dlPropertySetToClear=$dlPropertiesToClearModern
    }
    else 
    {
        out-logfile -string "Legacy exchange versions detected - using legacy parameters"
        $dlPropertySetToClear = $dlPropertiesToClearLegacy   
    }

    Out-LogFile -string ("DL property set to be cleared after schema evaluation = ")

    foreach ($dlProperty in $dlPropertySetToClear)
    {
        Out-LogFile -string $dlProperty
    }

    # EXIT #Debug Exit

    #If exchange server information specified - create the on premises powershell session.

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "ESTABLISH POWERSHELL SESSIONS"
    Out-LogFile -string "********************************************************************************"

   #Test to determine if the exchange online powershell module is installed.
   #The exchange online session has to be established first or the commandlet set from on premises fails.

   Out-LogFile -string "Calling Test-PowerShellModule to validate the Exchange Module is installed."

   Test-PowershellModule -powershellModuleName $corevariables.exchangeOnlinePowershellModuleName.value -powershellVersionTest:$TRUE

   Out-LogFile -string "Calling Test-PowerShellModule to validate the Active Directory is installed."

   Test-PowershellModule -powershellModuleName $corevariables.activeDirectoryPowershellModuleName.value

   out-logfile -string "Calling Test-PowershellModule to validate the DL Conversion Module version installed."

   Test-PowershellModule -powershellModuleName $corevariables.dlConversionPowershellModule.value -powershellVersionTest:$TRUE

   out-logfile -string "Calling Test-PowershellModule to validate the AzureAD Powershell Module version installed."

   Test-PowershellModule -powershellModuleName $corevariables.azureActiveDirectoryPowershellModuleName.value -powershellVersionTest:$TRUE

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

   #Now we can determine if exchange on premises is utilized and if so establish the connection.
   
   Out-LogFile -string "Determine if Exchange On Premises specified and create session if necessary."

    if ($coreVariables.useOnPremisesExchange.value -eq $TRUE)
    {
        if ($exchangeAuthenticationMethod -eq "Basic")
        {
            try 
            {
                Out-LogFile -string "Calling New-PowerShellSession"

                $sessiontoImport=new-PowershellSession -credentials $exchangecredential -powershellSessionName $corevariables.exchangeOnPremisesPowershellSessionName.value -connectionURI $onPremExchangePowershell.exchangeServerURI.value -authenticationType $exchangeAuthenticationMethod -configurationName $onPremExchangePowershell.exchangeServerConfiguration.value -allowredirection $onPremExchangePowershell.exchangeServerAllowRedirection.value -requiresImport:$TRUE
            }
            catch 
            {
                Out-LogFile -string "ERROR:  Unable to create powershell session." -isError:$TRUE
            }
        }
        elseif ($exchangeAuthenticationMethod -eq "Kerberos")
        {
            try 
            {
                Out-LogFile -string "Calling New-PowerShellSession"

                $sessiontoImport=new-PowershellSession -credentials $exchangecredential -powershellSessionName $corevariables.exchangeOnPremisesPowershellSessionName.value -connectionURI $onPremExchangePowershell.exchangeServerURIKerberos.value -authenticationType $exchangeAuthenticationMethod -configurationName $onPremExchangePowershell.exchangeServerConfiguration.value -allowredirection $onPremExchangePowershell.exchangeServerAllowRedirection.value -requiresImport:$TRUE
            }
            catch 
            {
                Out-LogFile -string "ERROR:  Unable to create powershell session." -isError:$TRUE
            }
        }
        else 
        {
            out-logfile -string "Major issue creating on-premsies Exchange powershell session - unknown - ending." -isError:$TRUE
        }
        
        try 
        {
            Out-LogFile -string "Calling import-PowerShellSession"

            import-powershellsession -powershellsession $sessionToImport
        }
        catch 
        {
            Out-LogFile -string "ERROR:  Unable to create powershell session." -isError:$TRUE
        }
        try 
        {
            out-logfile -string "Calling set entire forest."

            enable-ExchangeOnPremEntireForest
        }
        catch 
        {
            Out-LogFile -string "ERROR:  Unable to view entire forest." -isError:$TRUE
        }
    }
    else
    {
        Out-LogFile -string "No on premises Exchange specified - skipping setup of powershell session."
    }

    #If the administrator has specified aad connect information - establish the powershell session.

    Out-LogFile -string "Determine if AAD Connect information specified and establish session if necessary."

    if ($coreVariables.useAADConnect.value -eq $TRUE)
    {
        try 
        {
            out-logfile -string "Creating powershell session to the AD Connect server."

            New-PowershellSession -Server $aadConnectServer -Credentials $aadConnectCredential -PowershellSessionName $coreVariables.aadConnectPowershellSessionName.value
        }
        catch 
        {
            out-logfile -string "Unable to create remote powershell session to the AD Connect server."
            out-logfile -string $_ -isError:$TRUE
        }
    }

    #Establish powershell session to the global catalog server.

    try 
    {
        Out-LogFile -string "Establish powershell session to the global catalog server specified."

        new-powershellsession -server $globalCatalogServer -credentials $activeDirectoryCredential -powershellsessionname $coreVariables.ADGlobalCatalogPowershellSessionName.value
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

    #If there are any sendAs or mailbox access permissiosn for the group.
    #The group should be retained for saftey and only manually deleted if the administrator understands ramiifactions.
    #In testing disabling the group will allow the permissions to continue functioning - deleting the group would loose it.
    #Overrideing the administrators decision to delete the group.

    if (($allObjectSendAsAccess -ne 0) -or ($allObjectsFullMailboxAccess -ne 0) -or ($allMailboxesFolderPermissions -ne 0))
    {
        out-logfile -string "Overriding any administrator action to delete the group as dependencies exist."
        $retainOriginalGroup = $TRUE
    }
    else 
    {
        out-logfile -string "Audit shows no dependencies for sendAs or full mailbox access - keeping administrator settings on group retention."    
    }

    #exit #Debug Exit

    Out-LogFile -string "Capture the original office 365 distribution list information."

    if ($allowNonSyncedGroup -eq $FALSE)
    {
        try 
        {
            $office365DLConfiguration=Get-O365DLConfiguration -groupSMTPAddress $groupSMTPAddress -errorAction STOP
        }
        catch 
        {
            out-logFile -string $_ -isError:$TRUE
        }
    }
    else 
    {
        $office365DLConfiguration="DistributionListIsNonSynced"
    }

    
    
    Out-LogFile -string $office365DLConfiguration

    Out-LogFile -string "Create an XML file backup of the office 365 DL configuration."

    Out-XMLFile -itemToExport $office365DLConfiguration -itemNameToExport $xmlFiles.office365DLConfigurationXML.value

    out-logfile -string "Capture the original Azure AD distribution list informaiton"

    if ($allowNonSyncedGroup -eq $FALSE)
    {
        try{
            $azureADDLConfiguration = get-AzureADDLConfiguration -office365DLConfiguration $office365DLConfiguration
        }
        catch{
            out-logfile -string $_
            out-logfile -string "Unable to obtain Azure Active Directory DL Configuration"
        }
    }

    out-logfile -string $azureADDLConfiguration

    out-logfile -string "Create an XML file backup of the Azure AD DL Configuration"

    out-xmlFile -itemToExport $azureADDLConfiguration -itemNameToExport $xmlFiles.azureDLConfigurationXML.value

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END GET ORIGINAL DL CONFIGURATION LOCAL AND CLOUD"
    Out-LogFile -string "********************************************************************************"

    if ($allowNonSyncedGroup -eq $FALSE)
    {
        Out-LogFile -string "Perform a safety check to ensure that the distribution list is directory sync."

        try 
        {
            Invoke-Office365SafetyCheck -o365dlconfiguration $office365DLConfiguration -azureADDLConfiguration $azureADDLConfiguration -errorAction STOP
        }
        catch 
        {
            out-logFile -string $_ -isError:$TRUE
        }
    }
    else 
    {
        out-logfile -string "The administrator is attempting to migrate a non-synced group.  Office 365 check skipped."
        
        try 
        {
            test-nonSyncDL -originalDLConfiguration $originalDLConfiguration -errorAction STOP    
        }
        catch 
        {
            out-logfile -string $_ -isError:$TRUE   
        }
    }

    
    #At this time we have the DL configuration on both sides and have checked to ensure it is dir synced.
    #Membership of attributes is via DN - these need to be normalized to SMTP addresses in order to find users in Office 365.

    #Start with DL membership and normallize.

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "BEGIN NORMALIZE DNS FOR ALL ATTRIBUTES"
    Out-LogFile -string "********************************************************************************"

    Out-LogFile -string "Invoke get-NormalizedDN to normalize the members DN to Office 365 identifier."

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
                $normalizedTest = get-normalizedDN -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -isMember:$TRUE -errorAction STOP -cn "None"

                if ($normalizedTest.isError -eq $TRUE)
                {
                    $isErrorObject = new-Object psObject -property @{
                        primarySMTPAddressOrUPN = $normalizedTest.name
                        externalDirectoryObjectID = $NULL
                        alias=$normalizedTest.alias
                        name=$normalizedTest.name
                        attribute = "Distribution List Membership (ADAttribute: Members)"
                        errorMessage = $normalizedTest.isErrorMessage
                    }

                    out-logfile -string $isErrorObject

                    $preCreateErrors+=$isErrorObject
                }
                else 
                {
                    $exchangeDLMembershipSMTP+=$normalizedTest
                }
                
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

    Out-LogFile -string "Invoke get-NormalizedDN to normalize the reject members DN to Office 365 identifier."

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
                $normalizedTest = get-normalizedDN -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -errorAction STOP -cn "None"

                if ($normalizedTest.isError -eq $TRUE)
                {
                    $isErrorObject = new-Object psObject -property @{
                        primarySMTPAddressOrUPN = $normalizedTest.name
                        externalDirectoryObjectID = $NULL
                        alias=$normalizedTest.alias
                        name=$normalizedTest.name
                        attribute = "RejectMessagesFrom (ADAttribute: UnAuthOrig)"
                        errorMessage = $normalizedTest.isErrorMessage
                        errorMessageDetail = ""
                    }

                    out-logfile -string $isErrorObject

                    $preCreateErrors+=$isErrorObject
                }
                else 
                {
                    $exchangeRejectMessagesSMTP+=$normalizedTest
                }
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
                $normalizedTest=get-normalizedDN -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -errorAction STOP -cn "None"

                if ($normalizedTest.isError -eq $TRUE)
                {
                    $isErrorObject = new-Object psObject -property @{
                        primarySMTPAddressOrUPN = $normalizedTest.name
                        externalDirectoryObjectID = $NULL
                        alias=$normalizedTest.alias
                        name=$normalizedTest.name
                        attribute = "RejectMessagesFromDLMembers (ADAttribute DLMemRejectPerms)"
                        errorMessage = $normalizedTest.isErrorMessage
                        errorMessageDetail = ""
                    }

                    out-logfile -string $isErrorObject

                    $preCreateErrors+=$isErrorObject
                }
                else {
                    $exchangeRejectMessagesSMTP+=$normalizedTest
                }
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
    
    Out-LogFile -string "Invoke get-NormalizedDN to normalize the accept members DN to Office 365 identifier."

    Out-LogFile -string "ACCEPT USERS"

    if ($originalDLConfiguration.($onPremADAttributes.onPremAcceptMessagesFromSenders.value) -ne $NULL)
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
                $normalizedTest=get-normalizedDN -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -errorAction STOP -cn "None"

                if ($normalizedTest.isError -eq $TRUE)
                {
                    $isErrorObject = new-Object psObject -property @{
                        primarySMTPAddressOrUPN = $normalizedTest.name
                        externalDirectoryObjectID = $NULL
                        alias=$normalizedTest.alias
                        name=$normalizedTest.name
                        attribute = "AcceptMessagesOnlyFrom (ADAttribute: AuthOrig)"
                        errorMessage = $normalizedTest.isErrorMessage
                        errorMessageDetail = ""
                    }

                    out-logfile -string $isErrorObject

                    $preCreateErrors+=$isErrorObject
                }
                else {
                    $exchangeAcceptMessagesSMTP+=$normalizedTest
                }
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
                $normalizedTest=get-normalizedDN -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -errorAction STOP -cn "None"

                if ($normalizedTest.isError -eq $TRUE)
                {
                    $isErrorObject = new-Object psObject -property @{
                        primarySMTPAddressOrUPN = $normalizedTest.name
                        externalDirectoryObjectID = $NULL
                        alias=$normalizedTest.alias
                        name=$normalizedTest.name
                        attribute = "AcceptMessagesOnlyFromDLMembers (ADAttribute: DLMemSubmitPerms)"
                        errorMessage = $normalizedTest.isErrorMessage
                        errorMessageDetail = ""
                    }

                    out-logfile -string $isErrorObject

                    $preCreateErrors+=$isErrorObject
                }
                else 
                {
                    $exchangeAcceptMessagesSMTP+=$normalizedTest
                }
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
    
    Out-LogFile -string "Invoke get-NormalizedDN to normalize the managedBy members DN to Office 365 identifier."

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
                $normalizedTest=get-normalizedDN -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -errorAction STOP -cn "None"

                if ($normalizedTest.isError -eq $TRUE)
                {
                    $isErrorObject = new-Object psObject -property @{
                        primarySMTPAddressOrUPN = $normalizedTest.name
                        externalDirectoryObjectID = $NULL
                        alias=$normalizedTest.alias
                        name=$normalizedTest.name
                        attribute = "Owners (ADAttribute: ManagedBy)"
                        errorMessage = $normalizedTest.isErrorMessage
                        errorMessageDetail = ""
                    }

                    out-logfile -string $isErrorObject

                    $preCreateErrors+=$isErrorObject
                }
                else 
                {
                    $exchangeManagedBySMTP+=$normalizedTest
                }
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
                $normalizedTest = get-normalizedDN -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -errorAction STOP -cn "None"

                if ($normalizedTest.isError -eq $TRUE)
                {
                    $isErrorObject = new-Object psObject -property @{
                        primarySMTPAddressOrUPN = $normalizedTest.name
                        externalDirectoryObjectID = $NULL
                        alias=$normalizedTest.alias
                        name=$normalizedTest.name
                        attribute = "Owners (ADAttribute: msExchCoManagedByLink"
                        errorMessage = $normalizedTest.isErrorMessage
                        errorMessageDetail = ""
                    }

                    out-logfile -string $isErrorObject

                    $preCreateErrors+=$isErrorObject
                }
                else 
                {
                    $exchangeManagedBySMTP+=$normalizedTest
                }
                
            }
            catch 
            {
                out-logFile -string $_ -isError:$TRUE
            }
        }
    }

    if ($exchangeManagedBySMTP -ne $NULL)
    {
        #First scan is to ensure that any of the groups listed on the managed by objects are still security.
        #It is possible someone added it to managed by and changed the group type after.

        foreach ($object in $exchangeManagedBySMTP)
        {
            #If the objec thas a non-null group type (is a group) and the value of the group type matches none of the secuity group types.
            #The object is a distribution list - no good.

            if (($object.groupType -ne $NULL) -and ($object.groupType -ne "-2147483640") -and ($object.groupType -ne "-2147483646") -and ($object.groupType -ne "-2147483644"))
            {
                $isErrorObject = new-Object psObject -property @{
                    primarySMTPAddressOrUPN = $object.primarySMTPAddressOrUPN
                    externalDirectoryObjectID = $object.externalDirectoryObjectID
                    alias=$normalizedTest.alias
                    name=$normalizedTest.name
                    attribute = "Test ManagedBy For Security Flag"
                    errorMessage = "A group was found on the owners attribute that is no longer a security group.  Security group is required.  Remove group or change group type to security."
                    errorMessageDetail = ""
                }

                out-logfile -string $isErrorObject

                $preCreateErrors+=$isErrorObject

                out-logfile -string "A distribution list (not security enabled) was found on managed by."
                out-logfile -string "The group must be converted to security or removed from managed by."
                out-logfile -string $object.primarySMTPAddressOrUPN
            }

            #The group is not a distribution list.
            #If the SMTP object of the managedBy object equals the original group - check to see if an override is found.
            #If an override of distribution is found - this is not OK since security is required.

            elseif (($object.primarySMTPAddressOrUPN -eq $originalDLConfiguration.mail) -and ($groupTypeOverride -eq "Distribution")) 
            {
                out-logfile -string "Group type override detected - group has managed by permissions."

                #Group type is not NULL / Group type is security value.

                if (($object.groupType -ne $NULL) -and (($object.groupType -eq "-2147483640") -or ($object.groupType -eq "-2147483646" -or ($object.groupType -eq "-2147483644"))))
                {
                    $isErrorObject = new-Object psObject -property @{
                        primarySMTPAddressOrUPN = $object.primarySMTPAddressOrUPN
                        externalDirectoryObjectID = $object.externalDirectoryObjectID
                        alias=$normalizedTest.alias
                        name=$normalizedTest.name
                        attribute = "Test ManagedBy For Group Override"
                        errorMessage = "The group being migrated was found on the Owners attribute.  The administrator has requested migration as Distribution not Security.  To remain an owner the group must be migrated as Security - remove override or remove owner."
                        errorMessageDetail = ""
                    }

                    out-logfile -string $isErrorObject
    
                    $preCreateErrors+=$isErrorObject
        
                    out-logfile -string "A security group has managed by rights on the distribution list."
                    out-logfile -string "The administrator has specified to override the group type."
                    out-logfile -string "The group override must be removed or the object removed from managedBY."
                    out-logfile -string $object.primarySMTPAddressOrUPN
                }
            }
        }

        Out-LogFile -string "The following objects are members of the managedBY:"
        
        out-logfile -string $exchangeManagedBySMTP
    }
    else 
    {
        out-logfile -string "The group has no managers."    
    }

    Out-LogFile -string "Invoke get-NormalizedDN to normalize the moderatedBy members DN to Office 365 identifier."

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
                $normalizedTest = get-normalizedDN -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -errorAction STOP -cn "None"

                if ($normalizedTest.isError -eq $TRUE)
                {
                    $isErrorObject = new-Object psObject -property @{
                        primarySMTPAddressOrUPN = $normalizedTest.name
                        externalDirectoryObjectID = $NULL
                        alias=$normalizedTest.alias
                        name=$normalizedTest.name
                        attribute = "ModeratedBy (ADAttribute: msExchModeratedByLink"
                        errorMessage = $normalizedTest.isErrorMessage
                        errorMessageDetail = ""
                    }

                    out-logfile -string $isErrorObject

                    $preCreateErrors+=$isErrorObject
                }
                else 
                {
                    $exchangeModeratedBySMTP+=$normalizedTest
                }
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

    Out-LogFile -string "Invoke get-NormalizedDN to normalize the bypass moderation users members DN to Office 365 identifier."

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
                $normalizedTest = get-normalizedDN -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -errorAction STOP -cn "None"

                if ($normalizedTest.isError -eq $TRUE)
                {
                    $isErrorObject = new-Object psObject -property @{
                        primarySMTPAddressOrUPN = $normalizedTest.name
                        externalDirectoryObjectID = $NULL
                        alias=$normalizedTest.alias
                        name=$normalizedTest.name
                        attribute = "BypassModerationFromSendersOrMembers (ADAttribute: msExchBypassModerationLink)"
                        errorMessage = $normalizedTest.isErrorMessage
                        errorMessageDetail = ""
                    }

                    out-logfile -string $isErrorObject

                    $preCreateErrors+=$isErrorObject
                }
                else 
                {
                    $exchangeBypassModerationSMTP+=$normalizedTest
                }
            }
            catch 
            {
                out-logFile -string $_ -isError:$TRUE
            }
        }
    }

    Out-LogFile -string "Invoke get-NormalizedDN to normalize the bypass moderation groups members DN to Office 365 identifier."

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
                $normalizedTest = get-normalizedDN -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -errorAction STOP -cn "None"

                if ($normalizedTest.isError -eq $TRUE)
                {
                    $isErrorObject = new-Object psObject -property @{
                        primarySMTPAddressOrUPN = $normalizedTest.name
                        externalDirectoryObjectID = $NULL
                        alias=$normalizedTest.alias
                        name=$normalizedTest.name
                        attribute = "BypassModerationFromSendersOrMembers (ADAttribute: msExchBypassModerationFromDLMembersLink"
                        errorMessage = $normalizedTest.isErrorMessage
                        errorMessageDetail = ""
                    }

                    out-logfile -string $isErrorObject

                    $preCreateErrors+=$isErrorObject
                }
                else 
                {
                    $exchangeBypassModerationSMTP+=$normalizedTest
                }
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
                $normalizedTest=get-normalizedDN -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName  -errorAction STOP -cn "None"

                if ($normalizedTest.isError -eq $TRUE)
                {
                    $isErrorObject = new-Object psObject -property @{
                        primarySMTPAddressOrUPN = $normalizedTest.name
                        externalDirectoryObjectID = $NULL
                        alias=$normalizedTest.alias
                        name=$normalizedTest.name
                        attribute = "GrantSendOnBehalfTo (ADAttribute: publicDelegates"
                        errorMessage = $normalizedTest.isErrorMessage
                        errorMessageDetail = ""
                    }

                    out-logfile -string $isErrorObject

                    $preCreateErrors+=$isErrorObject
                }
                else 
                {
                    $exchangeGrantSendOnBehalfToSMTP+=$normalizedTest
                }
                
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

    Out-LogFile -string "Invoke get-normalizedDN for any on premises object that the migrated group has send as permissions."

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
                $normalizedTest=get-normalizedDN -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN "None" -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -errorAction STOP -CN:$permission.Identity

                if ($normalizedTest.isError -eq $TRUE)
                {
                    $isErrorObject = new-Object psObject -property @{
                        primarySMTPAddressOrUPN = $normalizedTest.name
                        externalDirectoryObjectID = $NULL
                        alias=$normalizedTest.alias
                        name=$normalizedTest.name
                        attribute = "On Premsies Group not present in Office 365 - Migrated group has send as permissions."
                        errorMessage = $normalizedTest.isErrorMessage
                        errorMessageDetail = ""
                    }

                    out-logfile -string $isErrorObject

                    $preCreateErrors+=$isErrorObject
                }
                else {
                    $allObjectsSendAsAccessNormalized+=$normalizedTest
                }
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
        $exchangeSendAsSMTP=get-GroupSendAsPermissions -globalCatalog $corevariables.globalCatalogWithPort.value -dn $originalDLConfiguration.distinguishedName -adCredential $activeDirectoryCredential -adGlobalCatalogPowershellSessionName $coreVariables.ADGlobalCatalogPowershellSessionName.value
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
    out-logfile -string ("The number of groups on premsies that this group has send as rights on: "+$allObjectsSendAsAccessNormalized.Count)
    out-logfile -string ("The number of groups on premises that this group has full mailbox access on: "+$allObjectsFullMailboxAccess.count)
    out-logfile -string ("The number of mailbox folders on premises that this group has access to: "+$allMailboxesFolderPermissions.count)
    out-logfile -string "/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"

    #Exit #Debug Exit.

    #At this point we have obtained all the information relevant to the individual group.
    #Validate that the discovered dependencies are valid in Office 365.

    $forLoopCounter=0 #Resetting counter at next set of queries.

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "BEGIN VALIDATE RECIPIENTS IN CLOUD"
    Out-LogFile -string "********************************************************************************"

    out-logfile -string "Begin accepted domain validation."

    try {
        test-AcceptedDomain -originalDLConfiguration $originalDlConfiguration -errorAction STOP
    }
    catch {
        out-logfile $_
        out-logfile -string "Unable to capture accepted domains for validation." -isError:$TRUE
    }

    try {
        test-outboundConnector -overrideCentralizedMailTransportEnabled $overrideCentralizedMailTransportEnabled -errorAction STOP
    }
    catch {
        out-logfile -string $_
        out-logfile -string "Unable to test outbound connectors for centralized mail flow" -isError:$TRUE
    }

    try {
        $mailOnMicrosoftComDomain = Get-MailOnMicrosoftComDomain -errorAction STOP
    }
    catch {
        out-logfile -string $_
        out-logfile -string "Unable to obtain the onmicrosoft.com domain." -errorAction STOP    
    }

    out-logfile -string "Being validating all distribution list members."
    
    if ($exchangeDLMembershipSMTP.count -gt 0)
    {
        out-logfile -string "Ensuring each DL member is in Office 365 / Exchange Online"

        foreach ($member in $exchangeDLMembershipSMTP)
        {
            #Reset the failure.

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

            out-LogFile -string ("Testing = "+$member.primarySMTPAddressOrUPN)

            try{
                $isTestError=test-O365Recipient -member $member

                if ($isTestError -eq "Yes")
                {
                    $isErrorObject = new-Object psObject -property @{
                        PrimarySMTPAddressorUPN = $member.PrimarySMTPAddressorUPN
                        ExternalDirectoryObjectID = $member.ExternalDirectoryObjectID
                        Alias = $member.Alias
                        Name = $member.name
                        Attribute = "Member (ADAttribute: Members)"
                        ErrorMessage = "A member of the distribution list is not found in Office 365."
                        errorMessageDetail = ""
                    }

                    out-logfile -string $isErrorObject

                    $preCreateErrors+=$isErrorObject
                }
            }
            catch{
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }
    else 
    {
        out-logfile -string "There are no DL members to test."    
    }

    out-logfile -string "Begin evaluating all members with reject rights."

    if ($exchangeRejectMessagesSMTP.count -gt 0)
    {
        out-logfile -string "Ensuring each DL reject messages is in Office 365."

        foreach ($member in $exchangeRejectMessagesSMTP)
        {
            #Reset error variable.

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

            out-LogFile -string ("Testing = "+$member.primarySMTPAddressOrUPN)

            try{
                $isTestError=test-O365Recipient -member $member

                if ($isTestError -eq "Yes")
                {
                    $isErrorObject = new-Object psObject -property @{
                        PrimarySMTPAddressorUPN = $member.PrimarySMTPAddressorUPN
                        ExternalDirectoryObjectID = $member.ExternalDirectoryObjectID
                        Alias = $member.Alias
                        Name = $member.name
                        Attribute = "RejectMessagesFromSendersorMembers / RejectMessagesFrom / RejectMessagesFromDLMembers (ADAttributes: UnAuthOrig / DLMemRejectPerms)"
                        ErrorMessage = "A member of RejectMessagesFromSendersOrMembers was not found in Office 365."
                        errorMessageDetail = ""
                    }

                    out-logfile -string $isErrorObject

                    $preCreateErrors+=$isErrorObject
                }
            }
            catch{
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }
    else 
    {
        out-logfile -string "There are no reject members to test."    
    }

    out-logfile -string "Begin evaluating all members with accept rights."

    if ($exchangeAcceptMessagesSMTP.count -gt 0)
    {
        out-logfile -string "Ensuring each DL accept messages is in Office 365 / Exchange Online"

        foreach ($member in $exchangeAcceptMessagesSMTP)
        {
            #Reset error variable.

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

            out-LogFile -string ("Testing = "+$member.primarySMTPAddressOrUPN)

            try{
                $isTestError=test-O365Recipient -member $member

                if ($isTestError -eq "Yes")
                {
                    $isErrorObject = new-Object psObject -property @{
                        PrimarySMTPAddressorUPN = $member.PrimarySMTPAddressorUPN
                        ExternalDirectoryObjectID = $member.ExternalDirectoryObjectID
                        Alias = $member.Alias
                        Name = $member.name
                        Attribute = "AcceptMessagesOnlyFromSendersorMembers / AcceptMessagesOnlyFrom / AcceptMessagesOnlyFromDLMembers (ADAttributes: authOrig / DLMemSubmitPerms)"
                        ErrorMessage = "A member of AcceptMessagesOnlyFromSendersorMembers was not found in Office 365."
                        errorMessageDetail = ""
                    }

                    out-logfile -string $isErrorObject

                    $preCreateErrors+=$isErrorObject
                }
            }
            catch{
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }
    else 
    {
        out-logfile -string "There are no accept members to test."    
    }

    out-logfile -string "Begin evaluating all managed by members."

    if ($exchangeManagedBySMTP.count -gt 0)
    {
        out-logfile -string "Ensuring each DL managed by is in Office 365 / Exchange Online"

        foreach ($member in $exchangeManagedBySMTP)
        {
            #Reset Error Variable.

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

            out-LogFile -string ("Testing = "+$member.primarySMTPAddressOrUPN)

            try{
                $isTestError=test-O365Recipient -member $member

                if ($isTestError -eq "Yes")
                {
                    $isErrorObject = new-Object psObject -property @{
                        PrimarySMTPAddressorUPN = $member.PrimarySMTPAddressorUPN
                        ExternalDirectoryObjectID = $member.ExternalDirectoryObjectID
                        Alias = $member.Alias
                        Name = $member.name
                        Attribute = "Owners (ADAttributes: ManagedBy,msExchCoManagedByLink)"
                        ErrorMessage = "A member of owners was not found in Office 365."
                        errorMessageDetail = ""
                    }

                    out-logfile -string $isErrorObject

                    $preCreateErrors+=$isErrorObject
                }
            }
            catch{
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }
    else 
    {
        out-logfile -string "There were no managed by members to evaluate."    
    }

    out-logfile -string "Being evaluating all moderated by members."

    if ($exchangeModeratedBySMTP.count -gt 0)
    {
        out-logfile -string "Ensuring each DL moderated by is in Office 365 / Exchange Online"

        foreach ($member in $exchangeModeratedBySMTP)
        {
            #Reset error variable.

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

            out-LogFile -string ("Testing = "+$member.primarySMTPAddressOrUPN)

            try{
                $isTestError=test-O365Recipient -member $member

                if ($isTestError -eq "Yes")
                {
                    $isErrorObject = new-Object psObject -property @{
                        PrimarySMTPAddressorUPN = $member.PrimarySMTPAddressorUPN
                        ExternalDirectoryObjectID = $member.ExternalDirectoryObjectID
                        Alias = $member.Alias
                        Name = $member.name
                        Attribute = "ModeratedBy (ADAttributes: msExchModeratedByLink)"
                        ErrorMessage = "A member of moderatedBy was not found in Office 365."
                        errorMessageDetail = ""
                    }

                    out-logfile -string $isErrorObject

                    $preCreateErrors+=$isErrorObject
                }
            }
            catch{
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }
    else 
    {
        out-logfile -string "There were no moderated by members to evaluate."    
    }

    out-logfile -string "Being evaluating all bypass moderation members."

    if ($exchangeBypassModerationSMTP.count -gt 0)
    {
        out-logfile -string "Ensuring each DL bypass moderation is in Office 365 / Exchange Online"

        foreach ($member in $exchangeBypassModerationSMTP)
        {
            #Reset error variable.

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

            out-LogFile -string ("Testing = "+$member.primarySMTPAddressOrUPN)

            try{
                $isTestError=test-O365Recipient -member $member

                if ($isTestError -eq "Yes")
                {
                    $isErrorObject = new-Object psObject -property @{
                        PrimarySMTPAddressorUPN = $member.PrimarySMTPAddressorUPN
                        ExternalDirectoryObjectID = $member.ExternalDirectoryObjectID
                        Alias = $member.Alias
                        Name = $member.name
                        Attribute = "BypassModerationFromSendersorMembers (ADAttributes: msExchBypassModerationLink,msExchBypassModerationFromDLMembersLink)"
                        ErrorMessage = "A member of BypassModerationFromSendersorMembers was not found in Office 365."
                        errorMessageDetail = ""
                    }

                    out-logfile -string $isErrorObject

                    $preCreateErrors+=$isErrorObject
                }
            }
            catch{
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }
    else 
    {
        out-logfile -string "There were no bypass moderation members to evaluate."    
    }

    out-logfile -string "Begin evaluation of all grant send on behalf to members."

    if ($exchangeGrantSendOnBehalfToSMTP.count -gt 0)
    {
        out-logfile -string "Ensuring each DL grant send on behalf to is in Office 365 / Exchange Online"

        foreach ($member in $exchangeGrantSendOnBehalfToSMTP)
        {
            $isTestError = "No"

            if ($forLoopCounter -eq $forLoopTrigger)
            {
                start-sleepProgress -sleepString "Throttling for 5 seconds..." -sleepSeconds 5

                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            out-LogFile -string ("Testing = "+$member.primarySMTPAddressOrUPN)

            try{
                $isTestError=test-O365Recipient -member $member

                if ($isTestError -eq "Yes")
                {
                    $isErrorObject = new-Object psObject -property @{
                        PrimarySMTPAddressorUPN = $member.PrimarySMTPAddressorUPN
                        ExternalDirectoryObjectID = $member.ExternalDirectoryObjectID
                        Alias = $member.Alias
                        Name = $member.name
                        Attribute = "GrantSendOnBehalfTo (ADAttributes: publicDelegates)"
                        ErrorMessage = "A member of GrantSendOnBehalfTo was not found in Office 365."
                        errorMessageDetail = ""
                    }

                    out-logfile -string $isErrorObject

                    $preCreateErrors+=$isErrorObject
                }
            }
            catch{
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }
    else 
    {
        out-logfile -string "There were no grant send on behalf to members to evaluate."    
    }

    out-logfile -string "Begin evaluation all members with send as rights."

    if ($exchangeSendAsSMTP.count -gt 0)
    {
        out-logfile -string "Ensuring each DL send as is in Office 365."

        foreach ($member in $exchangeSendAsSMTP)
        {
            #Reset error variable.

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

            out-LogFile -string ("Testing = "+$member.primarySMTPAddressOrUPN)

            try{
                $isTestError=test-O365Recipient -member $member

                if ($isTestError -eq "Yes")
                {
                    $isErrorObject = new-Object psObject -property @{
                        PrimarySMTPAddressorUPN = $member.PrimarySMTPAddressorUPN
                        ExternalDirectoryObjectID = $member.ExternalDirectoryObjectID
                        Alias = $member.Alias
                        Name = $member.name
                        Attribute = "SendAs"
                        ErrorMessage = "A member with SendAs permissions was not found in Office 365."
                        errorMessageDetail = ""
                    }

                    out-logfile -string $isErrorObject

                    $preCreateErrors+=$isErrorObject
                }
            }
            catch{
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }
    else 
    {
        out-logfile -string "There were no members with send as rights."    
    }

    out-logfile -string "Begin evaluation of groups on premises that the group to be migrated has send as rights on."

    if ($allObjectsSendAsAccessNormalized.count -gt 0)
    {
        out-logfile -string "Ensuring that each group on premises that the migrated group has send as rights on is in Office 365."

        foreach ($member in $allObjectsSendAsAccessNormalized)
        {
            #Reset error variable.

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

            out-LogFile -string ("Testing = "+$member.primarySMTPAddressOrUPN)

            try{
                $isTestError=test-O365Recipient -member $member

                if ($isTestError -eq "Yes")
                {
                    $isErrorObject = new-Object psObject -property @{
                        PrimarySMTPAddressorUPN = $member.PrimarySMTPAddressorUPN
                        ExternalDirectoryObjectID = $member.ExternalDirectoryObjectID
                        Alias = $member.Alias
                        Name = $member.name
                        Attribute = "Group with SendAs"
                        ErrorMessage = "The group to be migrated has send as rights on an on premises object.  The object is not present in Office 365."
                        errorMessageDetail = ""
                    }

                    out-logfile -string $isErrorObject

                    $preCreateErrors+=$isErrorObject
                }
            }
            catch{
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }
    else 
    {
        out-logfile -string "There were no members with send as rights."    
    }

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END VALIDATE RECIPIENTS IN CLOUD"
    Out-LogFile -string "********************************************************************************"

    #It is possible that this group was a member of - or other groups have a dependency on this group.
    #We will implement a function to track those dependen$ocies.

    #At this time we have validated the on premises pre-requisits for group migration.
    #If anything is not in order - this code will provide the summary list to the customer and then trigger end.

    if ($preCreateErrors.count -gt 0)
    {
        out-logfile -string "+++++"
        out-logfile -string "Pre-requist checks failed.  Please refer to the following list of items that require addressing for migration to proceed."
        out-logfile -string "+++++"
        out-logfile -string ""

        foreach ($preReq in $preCreateErrors)
        {
            out-logfile -string "====="
            out-logfile -string ("Primary Email Address or UPN: " +$preReq.primarySMTPAddressOrUPN)
            out-logfile -string ("External Directory Object ID: " +$preReq.externalDirectoryObjectID)
            out-logfile -string ("Name: "+$preReq.name)
            out-logfile -string ("Alias: "+$preReq.Alias)
            out-logfile -string ("Attribute in Error: "+$preReq.attribute)
            out-logfile -string ("Error Message: "+$preReq.errorMessage)
            out-logfile -string ("Error Message Detail: "+$preReq.errorMessageDetail)
            out-logfile -string "====="
        }

        out-logfile -string "Pre-requist checks failed.  Please refer to the previous list of items that require addressing for migration to proceed." -isError:$TRUE
    }

    #Exit #Debug Exit

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "BEGIN RECORD DEPENDENCIES ON MIGRATED GROUP"
    Out-LogFile -string "********************************************************************************"

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

    out-logfile -string "/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
    out-logfile -string ("Summary of dependencies found:")
    out-logfile -string ("The number of groups that the migrated DL is a member of = "+$allGroupsMemberOf.count)
    out-logfile -string ("The number of groups that this group is a manager of: = "+$allGroupsManagedBy.count)
    out-logfile -string ("The number of groups that this group has grant send on behalf to = "+$allGroupsGrantSendOnBehalfTo.count)
    out-logfile -string ("The number of groups that have this group as bypass moderation = "+$allGroupsBypassModeration.count)
    out-logfile -string ("The number of groups with accept permissions = "+$allGroupsAccept.count)
    out-logfile -string ("The number of groups with reject permissions = "+$allGroupsReject.count)
    out-logfile -string ("The number of mailboxes forwarding to this group is = "+$allUsersForwardingAddress.count)
    out-logfile -string ("The number of groups this group is a co-manager on = "+$allGroupsCoManagedByBL.Count)
    out-logfile -string "/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"


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

            out-logfile -string "Resetting group type to security - this is required for send as permissions and may have been changed on premsies."

            $groupTypeOverride="Security"
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

            out-logfile -string "Resetting group type to security - this is required for mailbox permissions but may have changed on premises."

            $groupTypeOverride="Security"
        }
        else 
        {
            $allOffice365FullMailboxAccess=@()    
        }

        if ($allOffice365MailboxFolderPermissions -ne $NULL)
        {
            out-logfile -string $allOffice365MailboxFolderPermissions
            out-xmlfile -itemToExport $allOffice365MailboxFolderPermissions -itemNameToExport $xmlFiles.allOffice365MailboxesFolderPermissionsXML.value

            out-logfile -string "Resetting group type to security - this is required for mailbox folder permissions but may have changed on premsies."

            $groupTypeOverride="Security"
        }
        else 
        {
            $allOffice365MailboxFolderPermissions=@()    
        }
    }
    else 
    {
        out-logfile -string "Administrator opted out of recording Office 365 dependencies."
    }

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

    #EXIT #Debug Exit

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END RETAIN OFFICE 365 GROUP DEPENDENCIES"
    Out-LogFile -string "********************************************************************************"

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "START Remove on premises distribution group from office 365.."
    Out-LogFile -string "********************************************************************************"

    #At this stage we will move the group to the non-Sync OU and then re-record the attributes.
    #The move here will allow us to preserve the original groups with attributes until we know that the migration was successful.
    #We will use the move to the non-SYNC OU to trigger deletion.

    #EXIT #Debug exit

    #In this case we should write a status file for all threads.
    #When all threads have reached this point it is safe to have them all move their DLs to the non-Sync OU.

    #If there are multiple threads in use hold all of them for thread 

    out-logfile -string "Determine if multiple migration threads are in use..."

    if ($totalThreadCount -eq 0)
    {
        out-logfile -string "Multiple threads are not in use.  Continue functions..."
    }
    else 
    {
        out-logfile -string "Multiple threads are in use.  Hold at this point for all threads to reach the point of moving to non-Sync OU."

        try{
            out-statusFile -threadNumber $global:threadNumber -errorAction STOP
        }
        catch{
            out-logfile -string "Unable to write status file." -isError:$TRUE
        }

        do 
        {
            out-logfile -string "All threads are not ready - sleeping."
        } until ((get-statusFileCount) -eq  $totalThreadCount)
    }

    try {
        move-toNonSyncOU -dn $originalDLConfiguration.distinguishedName -OU $dnNoSyncOU -globalCatalogServer $globalCatalogServer -adCredential $activeDirectoryCredential -errorAction STOP
    }
    catch {
        out-logfile -string $_ -isError:$TRUE
    }

    #If there are multiple threads have all threads > 1 sleep for 15 seconds while thread one deletes all status files.
    #This should cover the 5 seconds that any other threads may be sleeping looking to read the status directory.

    if ($totalThreadCount -gt 0)
    {
        start-sleepProgress -sleepString "Starting sleep before removing individual status files.." -sleepSeconds 5

        out-logfile -string "Trigger cleanup of individual status files."

        try{
            remove-statusFiles -functionThreadNumber $global:threadNumber
        }
        catch{
            out-logfile -string "Unable to remove status files" -isError:$TRUE
        }

        start-sleepProgress -sleepString "Starting sleep after removing individual status files.." -sleepSeconds 5
    }

    #$Capture the moved DL configuration (since attibutes change upon move.)

    try {
        $originalDLConfigurationUpdated = Get-ADObjectConfiguration -groupSMTPAddress $groupSMTPAddress -globalCatalogServer $corevariables.globalCatalogWithPort.value -parameterSet $dlPropertySet -errorAction STOP -adCredential $activeDirectoryCredential 
    }
    catch {
        out-logFile -string $_ -isError:$TRUE
    }

    out-LogFile -string $originalDLConfigurationUpdated
    out-xmlFile -itemToExport $originalDLConfigurationUpdated -itemNameTOExport (($xmlFiles.originalDLConfigurationUpdatedXML.value)+"-MoveToNoSyncOU")

    #If there are multiple threads and we've reached this point - we're ready to write a status file.

    out-logfile -string "If thread number > 1 - write the status file here."

    if ($global:threadNumber -gt 1)
    {
        out-logfile -string "Thread number is greater than 1."

        try{
            out-statusFile -threadNumber $global:threadNumber -errorAction STOP
        }
        catch{
            out-logfile -string $_
            out-logfile -string "Unable to write status file." -isError:$TRUE
        }
    }
    else 
    {
        out-logfile -string "Thread number is 1 - do not write status at this time."    
    }

    #If there are multiple threads - only replicate the domain controllers and trigger AD connect if all threads have completed their work.

    out-logfile -string "Determine if multiple migration threads are in use..."

    if ($totalThreadCount -eq 0)
    {
        out-logfile -string "Multiple threads are not in use.  Continue functions..."
    }
    else 
    {
        out-logfile -string "Multiple threads are in use - depending on thread number take different actions."
        
        if ($global:threadNumber -eq 1)
        {
            out-logfile -string "This is the master thread responsible for triggering operations."
            out-logfile -string "Search status directory and count files - if file count = number of threads - 1 thread 1 can proceed."

            #Do the following until the count of the files in the directory = number of threads - 1.

            do 
            {
                out-logfile -string "Other threads are pending.  Sleep 5 seconds."
            } until ((get-statusFileCount) -eq ($totalThreadCount - 1))
        }
        elseif ($global:threadNumber -gt 1)
        {
            out-logfile -string "This is not the master thread responsible for triggering operations."
            out-logfile -string "Search directory and count files.  If the file count = number of threads proceed."

            do 
            {
                out-logfile -string "Thread 1 is not ready to trigger.  Sleep 5 seconds."
            } until ((get-statusFileCount) -eq  $totalThreadCount)
        }
    }

    #Replicate domain controllers so that the change is received as soon as possible.()
    
    if ($global:threadNumber -eq 0 -or ($global:threadNumber -eq 1))
    {
        start-sleepProgress -sleepString "Starting sleep before invoking AD replication - 15 seconds." -sleepSeconds 15

        out-logfile -string "Invoking AD replication."

        try {
            invoke-ADReplication -globalCatalogServer $globalCatalogServer -powershellSessionName $coreVariables.ADGlobalCatalogPowershellSessionName.value -errorAction STOP
        }
        catch {
            out-logfile -string $_
        }
    }

    #Start the process of syncing the deletion to the cloud if the administrator has provided credentials.
    #Note:  If this is not done we are subject to sitting and waiting for it to complete.

    if ($global:threadNumber -eq 0 -or ($global:threadNumber -eq 1))
    {
        if ($coreVariables.useAADConnect.value -eq $TRUE)
        {
            start-sleepProgress -sleepString "Starting sleep before invoking AD Connect - one minute." -sleepSeconds 60

            out-logfile -string "Invoking AD Connect."

            invoke-ADConnect -powerShellSessionName $coreVariables.aadConnectPowershellSessionName.value

            start-sleepProgress -sleepString "Starting sleep after invoking AD Connect - one minute." -sleepSeconds 60
        }   
        else 
        {
            out-logfile -string "AD Connect information not specified - allowing ad connect to run on normal cycle and process deletion."    
        }
    }   

    #The single functions have triggered operations.  Other threads may continue.

    if ($global:threadNumber -eq 1)
    {
        out-statusFile -threadNumber $global:threadNumber
        start-sleepProgress -sleepString "Starting sleep after writing file..." -sleepSeconds 3
    }

    #If this is the main thread - introduce a sleep for 10 seconds - allows the other threads to detect 5 files.
    #Reset the status directory for furture thread dependencies.

    if ($totalThreadCount -gt 0)
    {
        start-sleepProgress -sleepString "Starting sleep before removing individual status files.." -sleepSeconds 5

        out-logfile -string "Trigger cleanup of individual status files."

        try{
            remove-statusFiles -functionThreadNumber $global:threadNumber
        }
        catch{
            out-logfile -string "Unable to remove status files" -isError:$TRUE
        }

        start-sleepProgress -sleepString "Starting sleep after removing individual status files.." -sleepSeconds 5
    }
    
    #At this time we have processed the deletion to azure.
    #We need to wait for that deletion to occur in Exchange Online.

    out-logfile -string "Monitoring Exchange Online for distribution list deletion."

    try {
        test-CloudDLPresent -groupSMTPAddress $groupSMTPAddress -errorAction SilentlyContinue
    }
    catch {
        out-logfile -string $_ -isError:$TRUE
    }

    #At this point we have validated that the group is gone from office 365.
    #We can begin the process of recreating the distribution group in Exchange Online.

    out-logfile "Attempting to create the DL in Office 365."

    $stopLoop = $FALSE
    [int]$loopCounter = 0

    do {
        try {
            $office365DLConfigurationPostMigration=new-office365dl -originalDLConfiguration $originalDLConfiguration -office365DLConfiguration $office365DLConfiguration -grouptypeoverride $groupTypeOverride -errorAction STOP

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
                $stopLoop -eq $TRUE
            }
            else 
            {
                start-sleepProgress -sleepString "Unable to capture the Office 365 DL configuration.  Sleeping 15 seconds." -sleepSeconds 15

                $loopCounter = $loopCounter+1 
            }
        }   
    } while ($stopLoop -eq $false)

    #EXIT #Debug Exit.

    #Now it is time to set the multi valued attributes on the DL in Office 365.
    #Setting these first must occur since moderators have to be established before moderation can be enabled.

    out-logFile -string "Setting the multivalued attributes of the migrated group."

    out-logfile -string $office365DLConfigurationPostMigration.primarySMTPAddress

    [int]$loopCounter=0
    [boolean]$stopLoop = $FALSE
    
    do {
        try {
            set-Office365DLMV -originalDLConfiguration $originalDLConfiguration -office365DLConfiguration $office365DLConfiguration -office365DLConfigurationPostMigration $office365DLConfigurationPostMigration -exchangeDLMembership $exchangeDLMembershipSMTP -exchangeRejectMessage $exchangeRejectMessagesSMTP -exchangeAcceptMessage $exchangeAcceptMessagesSMTP -exchangeModeratedBy $exchangeModeratedBySMTP -exchangeManagedBy $exchangeManagedBySMTP -exchangeBypassMOderation $exchangeBypassModerationSMTP -exchangeGrantSendOnBehalfTo $exchangeGrantSendOnBehalfToSMTP -errorAction STOP -groupTypeOverride $groupTypeOverride -exchangeSendAsSMTP $exchangeSendAsSMTP -mailOnMicrosoftComDomain $mailOnMicrosoftComDomain -allowNonSyncedGroup $allowNonSyncedGroup -allOffice365SendAsAccessOnGroup $allOffice365SendAsAccessOnGroup 

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
            $office365DLConfigurationPostMigration = Get-O365DLConfiguration -groupSMTPAddress $office365DLConfigurationPostMigration.externalDirectoryObjectID -errorAction STOP

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
                $stopLoop -eq $TRUE
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
            set-Office365DL -originalDLConfiguration $originalDLConfiguration -office365DLConfiguration $office365DLConfiguration -groupTypeOverride $groupTypeOverride -office365DLConfigurationPostMigration $office365DLConfigurationPostMigration
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
            $office365DLConfigurationPostMigration = Get-O365DLConfiguration -groupSMTPAddress $office365DLConfigurationPostMigration.externalDirectoryObjectID -errorAction STOP

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
                $stopLoop -eq $TRUE
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
            $office365DLMembershipPostMigration = get-O365DLMembership -groupSMTPAddress $office365DLConfigurationPostMigration.externalDirectoryObjectID -errorAction STOP

            #Membership obtained - export.

            out-logFile -string "Write the new DL membership to XML."
            out-logfile -string office365DLMembershipPostMigration

            out-xmlFile -itemToExport office365DLMembershipPostMigration -itemNametoExport $xmlFiles.office365DLMembershipPostMigrationXML.value

            #Exports complete - stop loop

            $stopLoop=$TRUE
        }
        catch{
            if ($loopCounter -gt 10)
            {
                out-logfile -string "Unable to get Office 365 distribution list configuration after 10 tries."
                $stopLoop -eq $TRUE
            }
            else 
            {
                start-sleepProgress -sleepString "Unable to capture the Office 365 DL configuration.  Sleeping 15 seconds." -sleepSeconds 15
 
                $loopCounter = $loopCounter+1 
            }
        }
    } while ($stopLoop -eq $FALSE)

    #The distribution group has been created and both single and multi valued attributes have been updated.
    #The group is fully availablle in exchange online.
    #The group as this point sits in the non-sync OU.  This was to service the deletion.
    #The administrator may have reasons for keeping the group.
    #If they do the plan is to do two things.
    ###Rename the group by adding a ! to the name - this ensures that if the group is every accidentally mail enabled it will not soft match the migrated group.
    ###We'll stamp custom attribute flags on it to ensure that we know the group has been mirgated - in case it's a member of another group to be migrated.

    if ($retainOriginalGroup -eq $TRUE)
    {
        Out-LogFile -string "Administrator has choosen to retain the original group."
        out-logfile -string "Rename the group by adding the fixed character !"

        [int]$loopCounter=0
        [boolean]$stopLoop=$FALSE   

        do {
            try {
                set-newDLName -globalCatalogServer $globalCatalogServer -dlName $originalDLConfigurationUpdated.Name -dlSAMAccountName $originalDLConfigurationUpdated.SAMAccountName -dn $originalDLConfigurationUpdated.distinguishedName -adCredential $activeDirectoryCredential -errorAction STOP

                $stopLoop=$TRUE
            }
            catch {
                if($loopCounter -gt 4)
                {
                    out-logfile -string $_ -isError:$TRUE
                }
                else 
                {
                    start-sleepProgress -sleepString "Uanble to change DL name - try again." -sleepSeconds 5
                    $loopCounter = $loopCounter+1    
                }
            }
        } while ($stopLoop=$FALSE)

        [int]$loopCounter=0
        [boolean]$stopLoop=$FALSE

        do {
            try {
                $originalDLConfigurationUpdated = Get-ADObjectConfiguration -groupSMTPAddress $groupSMTPAddress -globalCatalogServer $corevariables.globalCatalogWithPort.value -parameterSet $dlPropertySet -errorAction STOP -adCredential $activeDirectoryCredential 

                $stopLoop=$TRUE
            }
            catch {
                if ($loopCounter -gt 4)
                {
                    out-logFile -string $_ -isError:$TRUE
                }
                else 
                {
                    start-sleepProgress -sleepString "Unable to obtain updated original DL Configuration - try again." -sleepSeconds 5

                    $loopCounter = $loopCounter+1
                }
            }
        } while ($stopLoop -eq $FALSE)

        out-logfile -string $originalDLConfigurationUpdated
        out-xmlFile -itemToExport $originalDLConfigurationUpdated -itemNameTOExport (($xmlFiles.originalDLConfigurationUpdatedXML.value)+"-RenamedDL")

        Out-LogFile -string "Administrator has choosen to regain the original group."
        out-logfile -string "Disabling the mail attributes on the group."

        [int]$loopCounter=0
        [boolean]$stopLoop=$FALSE
        
        do {
            try{
                Disable-OriginalDL -originalDLConfiguration $originalDLConfigurationUpdated -globalCatalogServer $globalCatalogServer -parameterSet $dlPropertySetToClear -adCredential $activeDirectoryCredential -useOnPremisesExchange $coreVariables.useOnPremisesExchange.value -errorAction STOP

                $stopLoop = $TRUE
            }
            catch{
                if ($loopCounter -gt 4)
                {
                    out-LogFile -string $_ -isError:$TRUE
                }
                else 
                {
                    start-sleepProgress -sleepString "Unable to disable distribution group - try again." -sleepSeconds 5

                    $loopCounter = $loopCounter + 1
                }
            }
        } while ($stopLoop -eq $false)

        [int]$loopCounter=0
        [boolean]$stopLoop=$FALSE
        
        do {
            try {
                $originalDLConfigurationUpdated = Get-ADObjectConfiguration -dn $originalDLConfigurationUpdated.distinguishedName -globalCatalogServer $corevariables.globalCatalogWithPort.value -parameterSet $dlPropertySet -errorAction STOP -adCredential $activeDirectoryCredential 

                $stopLoop = $TRUE
            }
            catch {
                if ($loopCounter -gt 4)
                {
                    out-logFile -string $_ -isError:$TRUE
                }
                else {
                    start-sleeProgress -sleepString "Attempt to gather updated DL configuration failed - try again." -sleepSeconds 5

                    $loopCounter = $loopCounter + 1
                } 
            }
        } while ($stopLoop -eq $FALSE)


        out-logfile -string $originalDLConfigurationUpdated
        out-xmlFile -itemToExport $originalDLConfigurationUpdated -itemNameTOExport (($xmlFiles.originalDLConfigurationUpdatedXML.value)+"-PostMailDisabledGroup")

        Out-LogFile -string "Move the original group back to the OU it came from.  The group will no longer be soft matched."

        [int]$loopCounter=0
        [boolean]$stopLoop=$FALSE

        do {
            try {
                #Discovered that it's possible someone used the name "Test Group".  This breaks the following DN search as OU appears in the name - WHOOPS
                #So we need to try to make the substring call more unique - as to avoid detecting OU in a name.
                #To do so - we know that the DN has ,OU= so the first substring we'll search is ,OU=. 
                #Then we'll do it again - this time for just OU.  And that should give us what we need for the OU.

                $tempOUSubstring = Get-OULocation -originalDLConfiguration $originalDLConfiguration -errorAction STOP

                move-toNonSyncOU -DN $originalDLConfigurationUpdated.distinguishedName -ou $tempOUSubstring -globalCatalogServer $globalCatalogServer -adCredential $activeDirectoryCredential -errorAction STOP

                $stopLoop = $TRUE
            }
            catch {
                if ($loopCounter -gt 4)
                {
                    out-logfile -string $_ -isError:$TRUE
                }
                else {

                    out-logfile -string $_
                    start-sleepProgress -sleepString "Unable to move the DL to a non-sync OU - try again." -sleepSeconds 5

                    $loopCounter = $loopCounter +1
                }
            }
        } while ($stopLoop -eq $FALSE)

        [int]$loopCounter = 0
        [boolean]$stopLoop = $FALSE

        do {
            try {
                $tempOU=get-OULocation -originalDLConfiguration $originalDLConfiguration
                $tempNameArray=$originalDLConfigurationUpdated.distinguishedName.split(",")
                $tempDN=$tempNameArray[0]+","+$tempOU
                $originalDLConfigurationUpdated = Get-ADObjectConfiguration -dn $tempDN -globalCatalogServer $corevariables.globalCatalogWithPort.value -parameterSet $dlPropertySet -errorAction STOP -adCredential $activeDirectoryCredential 

                $stopLoop = $TRUE
            }
            catch {
                if ($loopCounter -gt 4)
                {
                    out-logFile -string $_ -isError:$TRUE
                }
                else {
                    start-sleepProgress -sleepString "Unable to obtain moved DL configuration - try again." -sleepSeconds 5

                    $loopCounter = $loopCounter +1
                }
            }
        } while ($stopLoop = $FALSE)

        out-logfile -string $originalDLConfigurationUpdated
        out-xmlFile -itemToExport $originalDLConfigurationUpdated -itemNameTOExport (($xmlFiles.originalDLConfigurationUpdatedXML.value)+"-MoveToOriginalOU")
    }

    #Now it is time to create the routing contact.

    [int]$loopCounter = 0
    [boolean]$stopLoop = $FALSE
    
    do {
        try {
            new-routingContact -originalDLConfiguration $originalDLConfiguration -office365DlConfiguration $office365DLConfigurationPostMigration -globalCatalogServer $globalCatalogServer -adCredential $activeDirectoryCredential

            $stopLoop = $TRUE
        }
        catch {
            if ($loopCounter -gt 4)
            {
                out-logfile -string $_ -isError:$TRUE
            }
            else {
                start-sleepProgress -sleepString "Unable to create routing contact - try again." -sleepSeconds 5

                $loopCounter = $loopCounter +1
            }
        }
    } while ($stopLoop -eq $FALSE)

    $stopLoop = $FALSE
    [int]$loopCounter = 0

    do {
        try {
            $tempMailArray = $originalDLConfiguration.mail.split("@")

            foreach ($member in $tempMailArray)
            {
                out-logfile -string ("Temp Mail Address Member: "+$member)
            }

            $tempMailAddress = $tempMailArray[0]+"-MigratedByScript"

            out-logfile -string ("Temp routing contact address: "+$tempMailAddress)

            $tempMailAddress = $tempMailAddress+"@"+$tempMailArray[1]

            out-logfile -string ("Temp routing contact address: "+$tempMailAddress)

            $routingContactConfiguration = Get-ADObjectConfiguration -groupSMTPAddress $tempMailAddress -globalCatalogServer $corevariables.globalCatalogWithPort.value -parameterSet $dlPropertySet -errorAction STOP -adCredential $activeDirectoryCredential 

            $stopLoop=$TRUE
        }
        catch 
        {
            if ($loopCounter -gt 5)
            {
                out-logfile -string "Unable to obtain routing contact information post creation."
                out-logfile -string $_ -isError:$TRUE
            }
            else 
            {
                start-sleepProgress -sleepString "Unable to obtain routing contact after creation - sleep try again." -sleepSeconds 10
                $loopCounter = $loopCounter + 1                
            }
        }
    } while ($stopLoop -eq $FALSE)

    out-logfile -string $routingContactConfiguration
    out-xmlFile -itemToExport $routingContactConfiguration -itemNameTOExport $xmlFiles.routingContactXML.value

    #At this time the contact is created - issuing a replication of domain controllers and sleeping one minute.
    #We've gotta get the contact pushed out so that cross domain operations function - otherwise reconciling memership fails becuase the contacts not available.

    start-sleepProgress -sleepString "Starting sleep before invoking AD replication.  Sleeping 15 seconds." -sleepSeconds 15

    out-logfile -string "Invoking AD replication."

    try {
        invoke-ADReplication -globalCatalogServer $globalCatalogServer -powershellSessionName $coreVariables.ADGlobalCatalogPowershellSessionName.value -errorAction STOP
    }
    catch {
        out-logfile -string $_
    }

    $forLoopCounter=0 #Restting loop counter for next series of operations.

    #At this time we are ready to begin resetting the on premises dependencies.

    $isTestError = "No" #Reset error tracking.

    out-logfile -string ("Starting on premies DL members.")

    if ($allGroupsMemberOf.count -gt 0)
    {
        foreach ($member in $allGroupsMemberOf)
        {  
            $isTestError = "No" #Reset error tracking.

            if ($forLoopCounter -eq $forLoopTrigger)
            {
                start-sleepProgress -sleepString "Throttling for 5 seconds...." -sleepSeconds 5

                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            out-logfile -string ("Processing member = "+$member.canonicalName)
            out-logfile -string ("Routing contact DN = "+$routingContactConfiguration.distinguishedName)
            out-logfile -string ("Attribute Operation = "+$onPremADAttributes.onPremMembers.Value)

            if ($member.distinguishedName -ne $originalDLConfiguration.distinguishedName)
            {
                try{
                    $isTestError=start-replaceOnPrem -routingContact $routingContactConfiguration -attributeOperation $onPremADAttributes.onPremMembers.Value -canonicalObject $member -adCredential $activeDirectoryCredential -globalCatalogServer $globalCatalogServer -errorAction STOP
                }
                catch{
                    out-logfile -string $_
                    $isTestErrorDetail = $_
                    $isTestError="Yes"
                }

                if ($isTestError -eq "Yes")
                {
                    out-logfile -string "Error adding routing contact to on premises resource."

                    $isErrorObject = new-Object psObject -property @{
                        distinguishedName = $member.distinguishedName
                        canonicalDomainName = $member.canonicalDomainName
                        canonicalName=$member.canonicalName
                        attribute = "Distribution List Membership (ADAttribute: Members)"
                        errorMessage = "Unable to add mail routing contact to on premises distribution group.  Manual add required."
                        erroMessageDetail = $isTestErrorDetail
                    }

                    out-logfile -string $isErrorObject

                    $onPremReplaceErrors+=$isErrorObject
                }
            }
            else 
            {
                out-logfile -string "The original group had permissions to itself - skipping as it no longer exists."
            }
        }
    }
    else 
    {
        out-logfile -string "No on premises group memberships to process."    
    }

    out-logfile -string ("Starting on premises reject messages from.")

    if ($allGroupsReject.Count -gt 0)
    {
        foreach ($member in $allGroupsReject)
        {  
            $isTestError="No" #Reset error test.

            if ($forLoopCounter -eq $forLoopTrigger)
            {
                start-sleepProgress -sleepString "Throttling for 5 seconds...." -sleepSeconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            out-logfile -string ("Processing member = "+$member.canonicalName)
            out-logfile -string ("Routing contact DN = "+$routingContactConfiguration.distinguishedName)
            out-logfile -string ("Attribute Operation = "+$onPremADAttributes.onPremAcceptMessagesFromDLMembers.Value)

            if ($member.distinguishedname -ne $originalDLConfiguration.distinguishedname)
            {
                try{
                    $isTestError=start-replaceOnPrem -routingContact $routingContactConfiguration -attributeOperation $onPremADAttributes.onPremAcceptMessagesFromDLMembers.Value -canonicalObject $member -adCredential $activeDirectoryCredential -globalCatalogServer $globalCatalogServer -errorAction STOP
                }
                catch{
                    out-logfile -string $_
                    $isTestErrorDetail = $_
                    $isTestError="Yes"
                }

                if ($isTestError -eq "Yes")
                {
                    out-logfile -string "Error adding routing contact to on premises resource."

                    $isErrorObject = new-Object psObject -property @{
                        distinguishedName = $member.distinguishedName
                        canonicalDomainName = $member.canonicalDomainName
                        canonicalName=$member.canonicalName
                        attribute = "Distribution List RejectMessagesFromSendersOrMembers (ADAttribute: DLMemRejectPerms)"
                        errorMessage = "Unable to add mail routing contact to on premises distribution group.  Manual add required."
                        erroMessageDetail = $isTestErrorDetail
                    }

                    out-logfile -string $isErrorObject

                    $onPremReplaceErrors+=$isErrorObject
                }
            }
            else
            {
                out-logfile -string "The original group had permissions to itself - skipping as it no longer exists."
            }
        }
    }
    else 
    {
        out-logfile -string "No on premises reject permission to evaluate."    
    }

    out-logfile -string ("Starting on premises accept messages from.")

    if ($allGroupsAccept.Count -gt 0)
    {
        foreach ($member in $allGroupsAccept)
        {  
            $isTestError="No" #Reset test 

            out-logfile -string ("Processing member = "+$member.canonicalName)
            out-logfile -string ("Routing contact DN = "+$routingContactConfiguration.distinguishedName)
            out-logfile -string ("Attribute Operation = "+$onPremADAttributes.onPremRejectMessagesFromDLMembers.Value)

            if ($forLoopCounter -eq $forLoopTrigger)
            {
                start-sleepProgress -sleepString "Throttling for 5 seconds...." -sleepSeconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            if ($member.distinguishedName -ne $originalDLConfiguration.distinguishedname)
            {
                try{
                    $isTestError=start-replaceOnPrem -routingContact $routingContactConfiguration -attributeOperation $onPremADAttributes.onPremRejectMessagesFromDLMembers.Value -canonicalObject $member -adCredential $activeDirectoryCredential -globalCatalogServer $globalCatalogServer -errorAction STOP
                }
                catch{
                    out-logfile -string $_
                    $isTestErrorDetail = $_
                    $isTestError="Yes"
                }

                if ($isTestError -eq "Yes")
                {
                    out-logfile -string "Error adding routing contact to on premises resource."

                    $isErrorObject = new-Object psObject -property @{
                        distinguishedName = $member.distinguishedName
                        canonicalDomainName = $member.canonicalDomainName
                        canonicalName=$member.canonicalName
                        attribute = "Distribution List AcceptMessagesOnlyFromSendersorMembers (ADAttribute: DLMemSubmitPerms)"
                        errorMessage = "Unable to add mail routing contact to on premises distribution group.  Manual add required."
                        erroMessageDetail = $isTestErrorDetail
                    }

                    out-logfile -string $isErrorObject

                    $onPremReplaceErrors+=$isErrorObject
                }
            }
            else 
            {
                out-logfile -string "The original group had permissions to itself - skipping as it no longer exists."
            }
        }
    }
    else 
    {
        out-logfile -string "No on premsies accept permissions to evaluate."    
    }

    out-logfile -string ("Starting on premises co managed by BL.")

    if ($allGroupsCoManagedByBL.Count -gt 0)
    {
        foreach ($member in $allGroupsCoManagedByBL)
        {  
            $isTestError="No" #Reset error tracking.

            out-logfile -string ("Processing member = "+$member.canonicalName)
            out-logfile -string ("Routing contact DN = "+$routingContactConfiguration.distinguishedName)
            out-logfile -string ("Attribute Operation = "+$onPremADAttributes.onPremCoManagedBy.Value)

            if ($forLoopCounter -eq $forLoopTrigger)
            {
                start-sleepProgress -sleepString "Throttling for 5 seconds...." -sleepSeconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            if ($member.distinguishedName -ne $originalDLConfiguration.distinguishedname)
            {
                try{
                    $isTestError=start-replaceOnPrem -routingContact $routingContactConfiguration -attributeOperation $onPremADAttributes.onPremCoManagedBy.Value -canonicalObject $member -adCredential $activeDirectoryCredential -globalCatalogServer $globalCatalogServer -errorAction STOP
                }
                catch{
                    out-logfile -string $_
                    $isTestErrorDetail = $_
                    $isTestError="Yes"
                }

                if ($isTestError -eq "Yes")
                {
                    out-logfile -string "Error adding routing contact to on premises resource."

                    $isErrorObject = new-Object psObject -property @{
                        distinguishedName = $member.distinguishedName
                        canonicalDomainName = $member.canonicalDomainName
                        canonicalName=$member.canonicalName
                        attribute = "Distribution List ManagedBy (ADAttribute: MSExchCoManagedBy)"
                        errorMessage = "Unable to add mail routing contact to on premises distribution group.  Manual add required."
                        erroMessageDetail = $isTestErrorDetail
                    }

                    out-logfile -string $isErrorObject

                    $onPremReplaceErrors+=$isErrorObject
                }
            }
            else 
            {
                out-logfile -string "The original group was a co-manager of itself."
            }
        }
    }
    else 
    {
        out-logfile -string "No on premsies accept permissions to evaluate."    
    }

    out-logfile -string ("Starting on premises bypass moderation.")

    if ($allGroupsBypassModeration.Count -gt 0)
    {
        foreach ($member in $allGroupsBypassModeration)
        {  
            $isTestError="No" #Reset error tracking.

            out-logfile -string ("Processing member = "+$member.canonicalName)
            out-logfile -string ("Routing contact DN = "+$routingContactConfiguration.distinguishedName)
            out-logfile -string ("Attribute Operation = "+$onPremADAttributes.onPremBypassModerationFromSenders.Value)

            if ($forLoopCounter -eq $forLoopTrigger)
            {
                start-sleepProgress -sleepString "Throttling for 5 seconds...." -sleepSeconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            if ($member.distinguishedname -ne $originalDLConfiguration.distinguishedName)
            {
                try{
                    $isTestError=start-replaceOnPrem -routingContact $routingContactConfiguration -attributeOperation $onPremADAttributes.onPremBypassModerationFromSenders.Value -canonicalObject $member -adCredential $activeDirectoryCredential -globalCatalogServer $globalCatalogServer -errorAction STOP
                }
                catch{
                    out-logfile -string $_
                    $isTestErrorDetail = $_
                    $isTestError="Yes"
                }

                if ($isTestError -eq "Yes")
                {
                    out-logfile -string "Error adding routing contact to on premises resource."

                    $isErrorObject = new-Object psObject -property @{
                        distinguishedName = $member.distinguishedName
                        canonicalDomainName = $member.canonicalDomainName
                        canonicalName=$member.canonicalName
                        attribute = "Distribution List BypassModerationFromSendersOrMembers (ADAttribute: msExchBypassModerationFromDLMembers)"
                        errorMessage = "Unable to add mail routing contact to on premises distribution group.  Manual add required."
                        erroMessageDetail = $isTestErrorDetail
                    }

                    out-logfile -string $isErrorObject

                    $onPremReplaceErrors+=$isErrorObject
                }
            }
            else 
            {
                out-logfile -string "The original group had permissions to itself - skipping as it no longer exists."
            }
        }
    }
    else 
    {
        out-logfile -string "No on premsies accept permissions to evaluate."    
    }

    out-logfile -string ("Starting on premises grant send on behalf to.")

    if ($allGroupsGrantSendOnBehalfTo.Count -gt 0)
    {
        foreach ($member in $allGroupsGrantSendOnBehalfTo)
        {  
            $isTestError="No" #Reset error tracking

            out-logfile -string ("Processing member = "+$member.canonicalName)
            out-logfile -string ("Routing contact DN = "+$routingContactConfiguration.distinguishedName)
            out-logfile -string ("Attribute Operation = "+$onPremADAttributes.onPremGrantSendOnBehalfTo.value)

            if ($forLoopCounter -eq $forLoopTrigger)
            {
                start-sleepProgress -sleepString "Throttling for 5 seconds...." -sleepSeconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            if ($member.distinguishedname -ne $originalDLConfiguration.distinguishedname)
            {
                try{
                    $isTestError=start-replaceOnPrem -routingContact $routingContactConfiguration -attributeOperation $onPremADAttributes.onPremGrantSendOnBehalfTo.value -canonicalObject $member -adCredential $activeDirectoryCredential -globalCatalogServer $globalCatalogServer -errorAction STOP
                }
                catch{
                    out-logfile -string $_
                    $isTestErrorDetail = $_
                    $isTestError="Yes"
                }

                if ($isTestError -eq "Yes")
                {
                    out-logfile -string "Error adding routing contact to on premises resource."

                    $isErrorObject = new-Object psObject -property @{
                        distinguishedName = $member.distinguishedName
                        canonicalDomainName = $member.canonicalDomainName
                        canonicalName=$member.canonicalName
                        attribute = "Distribution List GrantSendOnBehalfTo (ADAttribute: PublicDelegates)"
                        errorMessage = "Unable to add mail routing contact to on premises distribution group.  Manual add required."
                        erroMessageDetail = $isTestErrorDetail
                    }

                    out-logfile -string $isErrorObject

                    $onPremReplaceErrors+=$isErrorObject
                }
            }
            else 
            {
                out-logfile -string "The original group had permissions to itself - skipping as it no longer exists."
            }
        }
    }
    else 
    {
        out-logfile -string "No on premsies grant send on behalf to evaluate."    
    }

    #Managed by is a unique animal.
    #Managed by is represented by the single valued AD attribute and the multi-evalued exchange attribute.
    #From an exchange standpoint - as long as the member is in one of them it works.
    #We will use the multi-valued attriute so we can recycle the same code.

    out-logfile -string ("Starting on premises managed by.")

    if ($allGroupsManagedBy.Count -gt 0)
    {
        foreach ($member in $allGroupsManagedBy)
        {  
            $isTestError="No" #Reset error tracking.

            out-logfile -string ("Processing member = "+$member.canonicalName)
            out-logfile -string ("Routing contact DN = "+$routingContactConfiguration.distinguishedName)
            out-logfile -string ("Attribute Operation = "+$onPremADAttributes.onPremCoManagedBy.Value)

            if ($forLoopCounter -eq $forLoopTrigger)
            {
                start-sleepProgress -sleepString "Throttling for 5 seconds...." -sleepSeconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            if ($member.distinguishedname -ne $originalDLConfiguration.distinguishedname)
            {
                #More than groups can have managed by set.
                #If the object is NOT a group - then we should skip it.

                if ($member.objectClass -eq "Group")
                {
                    out-logfile -string "Object class is group - proceed."          

                    try{
                        $isTestError=start-replaceOnPrem -routingContact $routingContactConfiguration -attributeOperation $onPremADAttributes.onPremCoManagedBy.Value -canonicalObject $member -adCredential $activeDirectoryCredential -globalCatalogServer $globalCatalogServer -errorAction STOP
                    }
                    catch{
                        out-logfile -string $_
                        $isTestErrorDetail = $_
                        $isTestError="Yes"
                    }

                    if ($isTestError -eq "Yes")
                    {
                        out-logfile -string "Error adding routing contact to on premises resource."

                        $isErrorObject = new-Object psObject -property @{
                            distinguishedName = $member.distinguishedName
                            canonicalDomainName = $member.canonicalDomainName
                            canonicalName=$member.canonicalName
                            attribute = "Distribution List ManagedBy (ADAttribute: managedBy)"
                            errorMessage = "Unable to add mail routing contact to on premises distribution group.  Manual add required."
                            erroMessageDetail = $isTestErrorDetail
                        }

                        out-logfile -string $isErrorObject

                        $onPremReplaceErrors+=$isErrorObject
                    }
                }
                else 
                {
                    out-logfile -string "Other objects than groups have this group as a manager.  Not processing the routing contact change as manager."
                    out-logfile -string "Automatically setting preserve group as to not break permissions on objects."    

                    $retainOriginalGroup = $TRUE

                    out-logfile -string ("Retain Original Group: "+$retainOriginalGroup)
                }
            }
            else 
            {
                out-logfile -string "The original group had permissions to itself - skipping as it no longer exists."
            }
        }
    }
    else 
    {
        out-logfile -string "No on premsies grant send on behalf to evaluate."    
    }

    #Forwarding address is a single value replacemet.
    #Created separate function for single values and have called that function here.

    out-logfile -string ("Starting on premises forwarding.")

    if ($allUsersForwardingAddress.Count -gt 0)
    {
        foreach ($member in $allUsersForwardingAddress)
        { 
            $isTestError="No" #Reset error tracking.

            out-logfile -string ("Processing member = "+$member.canonicalName)
            out-logfile -string ("Routing contact DN = "+$routingContactConfiguration.distinguishedName)
            out-logfile -string ("Attribute Operation = "+$onPremADAttributes.onPremForwardingAddress.Value)

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
                $isTestError=start-replaceOnPremSV -routingContact $routingContactConfiguration -attributeOperation $onPremADAttributes.onPremForwardingAddress.Value -canonicalObject $member -adCredential $activeDirectoryCredential -globalCatalogServer $globalCatalogServer -errorAction STOP
            }
            catch{
                out-logfile -string $_
                $isTestErrorDetail = $_
                $isTestError="Yes"
            }

            if ($isTestError -eq "Yes")
            {
                out-logfile -string "Error adding routing contact to on premises resource."

                $isErrorObject = new-Object psObject -property @{
                    distinguishedName = $member.distinguishedName
                    canonicalDomainName = $member.canonicalDomainName
                    canonicalName=$member.canonicalName
                    attribute = "Mailbox Attribute Forwarding Address (ADAttribute: forwardingAddress)"
                    errorMessage = "Unable to add mail routing contact to on premises mailbox object.  Manual add required."
                    erroMessageDetail = $isTestErrorDetail
                }

                out-logfile -string $isErrorObject

                $onPremReplaceErrors+=$isErrorObject
            }
        }
    }
    else 
    {
        out-logfile -string "No on premsies grant send on behalf to evaluate."    
    }

    $forLoopCounter=0 #Resetting loop counter now that we're switching to cloud operations.

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
    
    if ($allowNonSyncedGroup -eq $FALSE)
    {
        out-logFile -string "Start replacing Office 365 permissions."

        try 
        {
            set-Office365DLPermissions -allSendAs $allOffice365SendAsAccess -allFullMailboxAccess $allOffice365FullMailboxAccess -allFolderPermissions $allOffice365MailboxFolderPermissions -allOnPremSendAs $allObjectsSendAsAccessNormalized -originalGroupPrimarySMTPAddress $groupSMTPAddress -errorAction STOP
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

    if ($enableHybridMailflow -eq $TRUE)
    {
        #The first step is to upgrade the contact to a full mail contact and remove the target address from proxy addresses.

        $isTestError="No"

        out-logfile -string "The administrator has enabled hybrid mail flow."

        try{
            $isTestError=Enable-MailRoutingContact -globalCatalogServer $globalCatalogServer -routingContactConfig $routingContactConfiguration
        }
        catch{
            out-logfile -string $_
            $isTestError="Yes"
            $errorMessageDetail=$_
        }

        if ($isTestError -eq "Yes")
        {
            $isErrorObject = new-Object psObject -property @{
                errorMessage = "Unable to enable the mail routing contact as a full recipient.  Manually enable the mail routing contact."
                errorMessaegDetail = $errorMessageDetail
            }

            out-logfile -string $isErrorObject

            $generalErrors+=$isErrorObject
        }

        #The mail contact has been created and upgrade.  Now we need to capture the updated configuration.

        try{
            $routingContactConfiguration = Get-ADObjectConfiguration -dn $tempDN -globalCatalogServer $corevariables.globalCatalogWithPort.value -parameterSet $dlPropertySet -errorAction STOP -adCredential $activeDirectoryCredential 
        }
        catch{
            out-logfile -string $_ -isError:$TRUE
        }

        out-logfile -string $routingContactConfiguration
        out-xmlFile -itemToExport $routingContactConfiguration -itemNameTOExport (($xmlFiles.routingContactXML.value)+"-PostMailEnabledContact")

        #The routing contact configuration has been updated and retained.
        #Now create the dynamic distribution group.  This gives us our address book object and our proxy addressed object that cannot collide with the previous object migrated.

        out-logfile -string "Enabling the dynamic distribution group to complete the mail routing scenario."

        try{
            $isTestError="No"

            #It is possible that we may need to support a distribution list that is missing attributes.
            #The enable mail dynamic has a retry flag - which is designed to create the DL post migration if necessary.
            #We're going to overload this here - if any of the attributes necessary are set to NULL - then pass in the O365 config and the retry flag.
            #This is what the enable post migration does - bases this off the O365 object.

            if ( ($originalDLConfiguration.name -eq $NULL) -or ($originalDLConfiguration.mailNickName -eq $NULL) -or ($originalDLConfiguration.mail -eq $NULL) -or ($originalDLConfiguration.displayName -eq $NULL) )
            {
                out-logfile -string "Using Office 365 attributes for the mail dynamic group."
                $isTestError=Enable-MailDyamicGroup -globalCatalogServer $globalCatalogServer -originalDLConfiguration $office365DLConfiguration -routingContactConfig $routingContactConfiguration -isRetry:$TRUE
            }
            else
            {
                out-logfile -string "Using on premises attributes for the mail dynamic group."
                $isTestError=Enable-MailDyamicGroup -globalCatalogServer $globalCatalogServer -originalDLConfiguration $originalDLConfiguration -routingContactConfig $routingContactConfiguration
            }
        }
        catch{
            out-logfile -string $_
            $isTestErrorDetail = $_
            $isTestError="Yes"
        }

        if ($isTestError -eq "Yes")
        {
            $isErrorObject = new-Object psObject -property @{
                errorMessage = "Unable to create the mail dynamic distribution group to service hybrid mail routing.  Manually create the dynamic distribution group."
                erroMessageDetail = $isTestErrorDetail
            }

            out-logfile -string $isErrorObject

            $generalErrors+=$isErrorObject
        }

        [boolean]$stopLoop=$FALSE
        [int]$loopCounter=0

        do {
            try{
                $routingDynamicGroupConfig = $originalDLConfiguration = Get-ADObjectConfiguration -groupSMTPAddress $groupSMTPAddress -globalCatalogServer $corevariables.globalCatalogWithPort.value -parameterSet $dlPropertySet -errorAction STOP -adCredential $activeDirectoryCredential

                $stopLoop = $TRUE
            }
            catch{
                if($loopCounter -gt 10)
                {
                    out-logfile -string "Unable to obtain the routing group after multiple tries."

                    $isTestErrorDetail = $_

                    $isErrorObject = new-Object psObject -property @{
                        errorMessage = "Unable to obtain the routing group after multiple tries."
                        erroMessageDetail = $isTestErrorDetail
                    }
        
                    out-logfile -string $isErrorObject
        
                    $generalErrors+=$isErrorObject

                    $stopLoop=$TRUE
                }
                else 
                {
                    out-logfile -string "Unable to obtain the dynamic group - retrying..."
                    start-sleepProgress -sleepstring "Unable to obtain the dynamic group - retrying..." -sleepSeconds 10

                    $loopCounter = $loopCounter+1
                }
            }
        } while ($stopLoop -eq $FALSE)

        out-logfile -string $routingDynamicGroupConfig
        out-xmlfile -itemToExport $routingDynamicGroupConfig -itemNameToExport $xmlFiles.routingDynamicGroupXML.value
    }

    #At this time the group has been migrated.
    #All on premises settings have been reconciled.
    #All cloud settings have been reconciled.
    #If exchange hybrid mail flow was enabled - the routing components were completed.

    #If the administrator has choosen to migrate and request upgrade to Office 365 group - trigger the ugprade.

    if ($triggerUpgradeToOffice365Group -eq $TRUE)
    {
        out-logfile -string "Administrator has choosen to trigger modern group upgrade."

        try{
            $isTestError="No"

            $isTestError=start-upgradeToOffice365Group -groupSMTPAddress $groupSMTPAddress
        }
        catch{
            out-logfile -string $_
            $isTestError="Yes"
        }
    }
    else
    {
        $isTestError="No"
    }

    if ($isTestError -eq "Yes")
    {
        $isTestErrorDetail = $_

        $isErrorObject = new-Object psObject -property @{
            errorMessage = "Unable to trigger upgrade to Office 365 Unified / Modern group.  Administrator may need to manually perform the operation."
            erroMessageDetail = $isTestErrorDetail
        }

        out-logfile -string $isErrorObject

        $generalErrors+=$isErrorObject
    }

    #If the administrator has selected to not retain the group - remove it.

    if ($retainOriginalGroup -eq $FALSE)
    {
        $isTestError="No"

        out-logfile -string "Deleting the original group."

        $isTestError=remove-OnPremGroup -globalCatalogServer $globalCatalogServer -originalDLConfiguration $originalDLConfigurationUpdated -adCredential $activeDirectoryCredential -errorAction STOP
    }
    else
    {
        $isTestError = "No"
    }

    if ($isTestError -eq "Yes")
    {
        $isTestErrorDetail = $_

        $isErrorObject = new-Object psObject -property @{
            errorMessage = "Uanble to remove the on premises group at request of administrator.  Group may need to be manually removed."
            erroMessageDetail = $isTestErrorDetail
        }

        out-logfile -string $isErrorObject

        $generalErrors+=$isErrorObject
    }

   #If there are multiple threads and we've reached this point - we're ready to write a status file.

   out-logfile -string "If thread number > 1 - write the status file here."

   if ($global:threadNumber -gt 1)
   {
       out-logfile -string "Thread number is greater than 1."

       try{
           out-statusFile -threadNumber $global:threadNumber -errorAction STOP
       }
       catch{
           out-logfile -string $_
           out-logfile -string "Unable to write status file." -isError:$TRUE
       }
   }
   else 
   {
       out-logfile -string "Thread number is 1 - do not write status at this time."    
   }

   #If there are multiple threads - only replicate the domain controllers and trigger AD connect if all threads have completed their work.

   out-logfile -string "Determine if multiple migration threads are in use..."

   if ($totalThreadCount -eq 0)
   {
       out-logfile -string "Multiple threads are not in use.  Continue functions..."
   }
   else 
   {
       out-logfile -string "Multiple threads are in use - depending on thread number take different actions."
       
       if ($global:threadNumber -eq 1)
       {
           out-logfile -string "This is the master thread responsible for triggering operations."
           out-logfile -string "Search status directory and count files - if file count = number of threads - 1 thread 1 can proceed."

           #Do the following until the count of the files in the directory = number of threads - 1.

           do 
           {
               start-sleepProgress -sleepString "Other threads are pending.  Sleep 5 seconds." -sleepSeconds 5
           } until ((get-statusFileCount) -eq ($totalThreadCount - 1))
       }
       elseif ($global:threadNumber -gt 1)
       {
           out-logfile -string "This is not the master thread responsible for triggering operations."
           out-logfile -string "Search directory and count files.  If the file count = number of threads proceed."

           do 
           {               
               start-sleepProgress -sleepString "Thread 1 is not ready to trigger.  Sleep 5 seconds." -sleepSeconds 5

           } until ((get-statusFileCount) -eq  $totalThreadCount)
       }
   }

   #Replicate domain controllers so that the change is received as soon as possible.()
   
   if ($global:threadNumber -eq 0 -or ($global:threadNumber -eq 1))
   {
       start-sleepProgress -sleepString "Starting sleep before invoking AD replication - 15 seconds." -sleepSeconds 15

       out-logfile -string "Invoking AD replication."

       try {
           invoke-ADReplication -globalCatalogServer $globalCatalogServer -powershellSessionName $coreVariables.ADGlobalCatalogPowershellSessionName.value -errorAction STOP
       }
       catch {
           out-logfile -string $_
       }
   }

   #Start the process of syncing the deletion to the cloud if the administrator has provided credentials.
   #Note:  If this is not done we are subject to sitting and waiting for it to complete.

   if ($global:threadNumber -eq 0 -or ($global:threadNumber -eq 1))
   {
       if ($coreVariables.useAADConnect.value -eq $TRUE)
       {
           start-sleepProgress -sleepString "Starting sleep before invoking AD Connect - one minute." -sleepSeconds 60

           out-logfile -string "Invoking AD Connect."

           invoke-ADConnect -powerShellSessionName $coreVariables.aadConnectPowershellSessionName.value

           start-sleepProgress -sleepString "Starting sleep after invoking AD Connect - one minute." -sleepSeconds 60

       }   
       else 
       {
           out-logfile -string "AD Connect information not specified - allowing ad connect to run on normal cycle and process deletion."    
       }
   }   

   #The single functions have triggered operations.  Other threads may continue.

   if ($global:threadNumber -eq 1)
   {
       out-statusFile -threadNumber $global:threadNumber
   }

    #If this is the main thread - introduce a sleep for 10 seconds - allows the other threads to detect 5 files.
    #Reset the status directory for furture thread dependencies.

   if ($totalThreadCount -gt 0)
   {
        start-sleepProgress -sleepString "Sleep..." -sleepSeconds 10

        try{
        remove-statusFiles -functionThreadNumber $global:threadNumber
        }
        catch{
            out-logfile -string "Unable to remove status files" -isError:$TRUE
        }
   }

    out-logfile -string "Calling function to disconnect all powershell sessions."

    disable-allPowerShellSessions

    Out-LogFile -string "================================================================================"
    Out-LogFile -string "END START-DISTRIBUTIONLISTMIGRATION"
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
        out-logfile -string "" -isError:$TRUE

    }

    #Archive the files into a date time success folder.

    Start-ArchiveFiles -isSuccess:$TRUE -logFolderPath $logFolderPath
}