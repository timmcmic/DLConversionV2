
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
        [string]$groupSMTPAddress,
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
        [boolean]$retainFullMailboxAccessOnPrem=$FALSE,
        [Parameter(Mandatory = $false)]
        [boolean]$retainSendAsOnPrem=$FALSE,
        [Parameter(Mandatory = $false)]
        [boolean]$retainMailboxFolderPermsOnPrem=$FALSE,
        [Parameter(Mandatory = $false)]
        [boolean]$retainFullMailboxAccessOffice365=$FALSE,
        [Parameter(Mandatory = $false)]
        [boolean]$retainSendAsOffice365=$FALSE,
        [Parameter(Mandatory = $false)]
        [boolean]$retainMailboxFolderPermsOffice365=$FALSE,
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
        [Parameter(Mandatory = $false)]
        [int]$global:threadNumber=0,
        [Parameter(Mandatory = $false)]
        [int]$totalThreadCount=0
    )

    #Define global variables.

    $global:logFile=$NULL #This is the global variable for the calculated log file name
    [string]$global:staticFolderName="\DLMigration\"
    [string]$global:staticAuditFolderName="\AuditData\"
    [string]$global:importFile=$logFolderPath+$global:staticAuditFolderName
    [int]$global:unDoStatus=0
    [array]$importData=@()
    [string]$importFilePath=$NULL

    #Define variables utilized in the core function that are not defined by parameters.

    [boolean]$useOnPremisesExchange=$FALSE #Determines if function will utilize onpremises exchange during migration.
    [boolean]$useAADConnect=$FALSE #Determines if function will utilize aadConnect during migration.
    [string]$exchangeOnPremisesPowershellSessionName="ExchangeOnPremises" #Defines universal name for on premises Exchange Powershell session.
    [string]$aadConnectPowershellSessionName="AADConnect" #Defines universal name for aadConnect powershell session.
    [string]$ADGlobalCatalogPowershellSessionName="ADGlobalCatalog" #Defines universal name for ADGlobalCatalog powershell session.
    [string]$exchangeOnlinePowershellModuleName="ExchangeOnlineManagement" #Defines the exchage management shell name to test for.
    [string]$activeDirectoryPowershellModuleName="ActiveDirectory" #Defines the active directory shell name to test for.
    [string]$globalCatalogPort=":3268"
    [string]$globalCatalogWithPort=$globalCatalogServer+$globalCatalogPort

    #The variables below are utilized to define working parameter sets.
    #Some variables are assigned to single values - since these will be utilized with functions that query or set information.
    
    [string]$acceptMessagesFromDLMembers="dlMemSubmitPerms" #Attribute for the allow email members.
    [string]$rejectMessagesFromDLMembers="dlMemRejectPerms"
    [string]$bypassModerationFromDL="msExchBypassModerationFromDLMembersLink"
    [string]$forwardingAddressForDL="altRecipient"
    [string]$grantSendOnBehalfToDL="publicDelegates"
    #[array]$dlPropertySet = 'authOrig','canonicalName','cn','DisplayName','DisplayNamePrintable','distinguishedname',$rejectMessagesFromDLMembers,$acceptMessagesFromDLMembers,'extensionAttribute1','extensionAttribute10','extensionAttribute11','extensionAttribute12','extensionAttribute13','extensionAttribute14','extensionAttribute15','extensionAttribute2','extensionAttribute3','extensionAttribute4','extensionAttribute5','extensionAttribute6','extensionAttribute7','extensionAttribute8','extensionAttribute9','groupcategory','groupscope','legacyExchangeDN','mail','mailNickName','managedBy','memberof','msDS-ExternalDirectoryObjectId','msExchRecipientDisplayType','msExchRecipientTypeDetails','msExchRemoteRecipientType','members',$bypassModerationFromDL,'msExchBypassModerationLink','msExchCoManagedByLink','msExchEnableModeration','msExchExtensionCustomAttribute1','msExchExtensionCustomAttribute2','msExchExtensionCustomAttribute3','msExchExtensionCustomAttribute4','msExchExtensionCustomAttribute5','msExchGroupDepartRestriction','msExchGroupJoinRestriction','msExchHideFromAddressLists','msExchModeratedByLink','msExchModerationFlags','msExchRequireAuthToSendTo','msExchSenderHintTranslations','Name','objectClass','oofReplyToOriginator','proxyAddresses',$grantSendOnBehalfToDL,'reportToOriginator','reportToOwner','unAuthOrig'
    [array]$dlPropertySet = '*'
    [array]$dlPropertySetToClear = @()
    [array]$dlPropertiesToClearModern='authOrig','DisplayName','DisplayNamePrintable',$rejectMessagesFromDLMembers,$acceptMessagesFromDLMembers,'extensionAttribute1','extensionAttribute10','extensionAttribute11','extensionAttribute12','extensionAttribute13','extensionAttribute14','extensionAttribute15','extensionAttribute2','extensionAttribute3','extensionAttribute4','extensionAttribute5','extensionAttribute6','extensionAttribute7','extensionAttribute8','extensionAttribute9','legacyExchangeDN','mail','mailNickName','msExchRecipientDisplayType','msExchRecipientTypeDetails','msExchRemoteRecipientType',$bypassModerationFromDL,'msExchBypassModerationLink','msExchCoManagedByLink','msExchEnableModeration','msExchExtensionCustomAttribute1','msExchExtensionCustomAttribute2','msExchExtensionCustomAttribute3','msExchExtensionCustomAttribute4','msExchExtensionCustomAttribute5','msExchGroupDepartRestriction','msExchGroupJoinRestriction','msExchHideFromAddressLists','msExchModeratedByLink','msExchModerationFlags','msExchRequireAuthToSendTo','msExchSenderHintTranslations','oofReplyToOriginator','proxyAddresses',$grantSendOnBehalfToDL,'reportToOriginator','reportToOwner','unAuthOrig','msExchArbitrationMailbox','msExchPoliciesIncluded','msExchUMDtmfMap','msExchVersion','showInAddressBook','msExchAddressBookFlags','msExchBypassAudit','msExchGroupExternalMemberCount','msExchGroupMemberCount','msExchGroupSecurityFlags','msExchLocalizationFlags','msExchMailboxAuditEnable','msExchMailboxAuditLogAgeLimit','msExchMailboxFolderSet','msExchMDBRulesQuota','msExchPoliciesIncluded','msExchProvisioningFlags','msExchRecipientSoftDeletedStatus','msExchRoleGroupType','msExchTransportRecipientSettingsFlags','msExchUMDtmfMap','msExchUserAccountControl','msExchVersion'
    [array]$dlPropertiesToClearLegacy='authOrig','DisplayName','DisplayNamePrintable',$rejectMessagesFromDLMembers,$acceptMessagesFromDLMembers,'extensionAttribute1','extensionAttribute10','extensionAttribute11','extensionAttribute12','extensionAttribute13','extensionAttribute14','extensionAttribute15','extensionAttribute2','extensionAttribute3','extensionAttribute4','extensionAttribute5','extensionAttribute6','extensionAttribute7','extensionAttribute8','extensionAttribute9','legacyExchangeDN','mail','mailNickName','msExchRecipientDisplayType','msExchRecipientTypeDetails','msExchRemoteRecipientType',$bypassModerationFromDL,'msExchBypassModerationLink','msExchCoManagedByLink','msExchEnableModeration','msExchExtensionCustomAttribute1','msExchExtensionCustomAttribute2','msExchExtensionCustomAttribute3','msExchExtensionCustomAttribute4','msExchExtensionCustomAttribute5','msExchGroupDepartRestriction','msExchGroupJoinRestriction','msExchHideFromAddressLists','msExchModeratedByLink','msExchModerationFlags','msExchRequireAuthToSendTo','msExchSenderHintTranslations','oofReplyToOriginator','proxyAddresses',$grantSendOnBehalfToDL,'reportToOriginator','reportToOwner','unAuthOrig','msExchArbitrationMailbox','msExchPoliciesIncluded','msExchUMDtmfMap','msExchVersion','showInAddressBook','msExchAddressBookFlags','msExchBypassAudit','msExchGroupExternalMemberCount','msExchGroupMemberCount','msExchLocalizationFlags','msExchMailboxAuditEnable','msExchMailboxAuditLogAgeLimit','msExchMailboxFolderSet','msExchMDBRulesQuota','msExchPoliciesIncluded','msExchProvisioningFlags','msExchRecipientSoftDeletedStatus','msExchRoleGroupType','msExchTransportRecipientSettingsFlags','msExchUMDtmfMap','msExchUserAccountControl','msExchVersion'

    #Static variables utilized for the Exchange On-Premsies Powershell.
   
    [string]$exchangeServerConfiguration = "Microsoft.Exchange" #Powershell configuration.
    [boolean]$exchangeServerAllowRedirection = $TRUE #Allow redirection of URI call.
    [string]$exchangeServerURI = "https://"+$exchangeServer+"/powershell" #Full URL to the on premises powershell instance based off name specified parameter.

    #On premises variables for the distribution list to be migrated.

    $originalDLConfiguration=$NULL #This holds the on premises DL configuration for the group to be migrated.
    $originalDLConfigurationUpdated=$NULL #This holds the on premises DL configuration post the rename operations.
    $routingContactConfig=$NULL
    $routingDynamicGroupConfig=$NULL
    [array]$exchangeDLMembershipSMTP=@() #Array of DL membership from AD.
    [array]$exchangeRejectMessagesSMTP=@() #Array of members with reject permissions from AD.
    [array]$exchangeAcceptMessagesSMTP=@() #Array of members with accept permissions from AD.
    [array]$exchangeManagedBySMTP=@() #Array of members with manage by rights from AD.
    [array]$exchangeModeratedBySMTP=@() #Array of members  with moderation rights.
    [array]$exchangeBypassModerationSMTP=@() #Array of objects with bypass moderation rights from AD.
    [array]$exchangeGrantSendOnBehalfToSMTP=@()
    [array]$exchangeSendAsSMTP=@()

    #Define XML files to contain backups.

    [string]$originalDLConfigurationADXML = "originalDLConfigurationADXML" #Export XML file of the group attibutes direct from AD.
    [string]$originalDLConfigurationUpdatedXML = "originalDLConfigurationUpdatedXML"
    [string]$originalDLConfigurationObjectXML = "originalDLConfigurationObjectXML" #Export of the ad attributes after selecting objects (allows for NULL objects to be presented as NULL)
    [string]$office365DLConfigurationXML = "office365DLConfigurationXML"
    [string]$office365DLConfigurationPostMigrationXML = "office365DLConfigurationPostMigrationXML"
    [string]$office365DLMembershipPostMigrationXML = "office365DLMembershipPostMigrationXML"
    [string]$exchangeDLMembershipSMTPXML = "exchangeDLMemberShipSMTPXML"
    [string]$exchangeRejectMessagesSMTPXML = "exchangeRejectMessagesSMTPXML"
    [string]$exchangeAcceptMessagesSMTPXML = "exchangeAcceptMessagesSMTPXML"
    [string]$exchangeManagedBySMTPXML = "exchangeManagedBySMTPXML"
    [string]$exchangeModeratedBySMTPXML = "exchangeModeratedBYSMTPXML"
    [string]$exchangeBypassModerationSMTPXML = "exchangeBypassModerationSMTPXML"
    [string]$exchangeGrantSendOnBehalfToSMTPXML = "exchangeGrantSendOnBehalfToXML"
    [string]$exchangeSendAsSMTPXML = "exchangeSendASSMTPXML"
    [string]$allGroupsMemberOfXML = "allGroupsMemberOfXML"
    [string]$allGroupsRejectXML = "allGroupsRejectXML"
    [string]$allGroupsAcceptXML = "allGroupsAcceptXML"
    [string]$allGroupsBypassModerationXML = "allGroupsBypassModerationXML"
    [string]$allUsersForwardingAddressXML = "allUsersForwardingAddressXML"
    [string]$allGroupsGrantSendOnBehalfToXML = "allGroupsGrantSendOnBehalfToXML"
    [string]$allGroupsManagedByXML = "allGroupsManagedByXML"
    [string]$allGroupsSendAsXML = "allGroupSendAsXML"
    [string]$allGroupsFullMailboxAccessXML = "allGroupsFullMailboxAccessXML"
    [string]$allMailboxesFolderPermissionsXML = "allMailboxesFolderPermissionsXML"
    [string]$allOffice365UniversalAcceptXML="allOffice365UniversalAcceptXML"
    [string]$allOffice365UniversalRejectXML="allOffice365UniversalRejectXML"
    [string]$allOffice365UniversalGrantSendOnBehalfToXML="allOffice365UniversalGrantSendOnBehalfToXML"
    [string]$allOffice365MemberOfXML="allOffice365MemberOfXML"
    [string]$allOffice365AcceptXML="allOffice365AcceptXML"
    [string]$allOffice365RejectXML="allOffice365RejectXML"
    [string]$allOffice365BypassModerationXML="allOffice365BypassModerationXML"
    [string]$allOffice365GrantSendOnBehalfToXML="allOffice365GrantSentOnBehalfToXML"
    [string]$allOffice365ManagedByXML="allOffice365ManagedByXML"
    [string]$allOffice365DynamicAcceptXML="allOffice365DynamicAcceptXML"
    [string]$allOffice365DynamicRejectXML="allOffice365DynamicRejectXML"
    [string]$allOffice365DynamicBypassModerationXML="allOffice365DynamicBypassModerationXML"
    [string]$allOffice365DynamicGrantSendOnBehalfToXML="allOffice365DynamicGrantSentOnBehalfToXML"
    [string]$allOffice365DynamicManagedByXML="allOffice365DynamicManagedByXML"
    [string]$allOffice365ForwardingAddressXML="allOffice365ForwardingAddressXML"
    [string]$allOffic365SendAsAccessXML = "allOffice365SendAsAccessXML"
    [string]$allOffice365FullMailboxAccessXML = "allOffice365FullMailboxAccessXML"
    [string]$allOffice365MailboxesFolderPermissionsXML = 'allOffice365MailboxesFolderPermissionsXML'
    [string]$routingContactXML="routingContactXML"
    [string]$routingDynamicGroupXML="routingDynamicGroupXML"

    #Define the retention files.

    [string]$retainOffice365RecipientFullMailboxAccessXML="office365RecipientFullMailboxAccess.xml"
    [string]$retainMailboxFolderPermsOffice365XML="office365MailboxFolderPermissions.xml"
    [string]$retainOnPremRecipientFullMailboxAccessXML="onPremRecipientFullMailboxAccess.xml"
    [string]$retainOnPremMailboxFolderPermissionsXML="onPremailboxFolderPermissions.xml"
    [string]$retainOnPremRecipientSendAsXML="onPremRecipientSendAs.xml"

    #The following variables hold information regarding other groups in the environment that have dependnecies on the group to be migrated.

    [array]$allGroupsMemberOf=$NULL #Complete AD information for all groups the migrated group is a member of.
    [array]$allGroupsReject=$NULL #Complete AD inforomation for all groups that the migrated group has reject mesages from.
    [array]$allGroupsAccept=$NULL #Complete AD information for all groups that the migrated group has accept messages from.
    [array]$allGroupsBypassModeration=$NULL #Complete AD information for all groups that the migrated group has bypass moderations.
    [array]$allUsersForwardingAddress=$NULL #All users on premsies that have this group as a forwarding DN.
    [array]$allGroupsGrantSendOnBehalfTo=$NULL #All dependencies on premsies that have grant send on behalf to.
    [array]$allGroupsManagedBy=$NULL
    [array]$allObjectsFullMailboxAccess=$NULL
    [array]$allObjectSendAsAccess=$NULL
    [array]$allMailboxesFolderPermissions=@()

    #The following variables hold information regarding Office 365 objects that have dependencies on the migrated DL.

    #The following are for standard distribution groups.

    [array]$allOffice365MemberOf=$NULL
    [array]$allOffice365Accept=$NULL
    [array]$allOffice365Reject=$NULL
    [array]$allOffice365BypassModeration=$NULL
    [array]$allOffice365ManagedBy=$NULL
    [array]$allOffice365GrantSendOnBehalfTo=$NULL

    #The following are for universal distribution groups.

    [array]$allOffice365UniversalAccept=$NULL
    [array]$allOffice365UniversalReject=$NULL
    [array]$allOffice365UniversalGrantSendOnBehalfTo=$NULL

    #The following are for dynamic distribution groups.

    [array]$allOffice365DynamicAccept=$NULL
    [array]$allOffice365DynamicReject=$NULL
    [array]$allOffice365DynamicBypassModeration=$NULL
    [array]$allOffice365DynamicManagedBy=$NULL
    [array]$allOffice365DynamicGrantSendOnBehalfTo=$NULL

    #These are for other mail enabled objects.

    [array]$allOffice365ForwardingAddress=$NULL
    [array]$allOffice365FullMailboxAccess=$NULL
    [array]$allOffice365SendAsAccess=$NULL
    [array]$allOffice365MailboxFolderPermissions=$NULL

    #The following are the cloud parameters we query for to look for dependencies.

    [string]$office365AcceptMessagesFrom="AcceptMessagesOnlyFromDLMembers"
    [string]$office365BypassModerationFrom="BypassModerationFromDLMembers"
    [string]$office365CoManagers="CoManagedBy"
    [string]$office365GrantSendOnBehalfTo="GrantSendOnBehalfTo"
    [string]$office365ManagedBy="ManagedBy"
    [string]$office365Members="Members"
    [string]$office365RejectMessagesFrom="RejectMessagesFromDLMembers"
    [string]$office365ForwardingAddress="ForwardingAddress"

    [string]$office365AcceptMessagesUsers="AcceptMessagesOnlyFrom"
    [string]$office365RejectMessagesUsers="RejectMessagesFrom"
    [string]$office365BypassModerationusers="BypassModerationFromSendersOrMembers"

    [string]$office365UnifiedAccept="AcceptMessagesOnlyFromSendersOrMembers"
    [string]$office365UnifiedReject="RejectMessagesFromSendersOrMembers"


    #The following are the on premises parameters utilized for restoring depdencies.

    [string]$onPremUnAuthOrig="unauthorig"
    [string]$onPremAuthOrig="authOrig"
    [string]$onPremManagedBy="managedBy"
    [string]$onPremMSExchCoManagedByLink="msExchCoManagedByLink"
    [string]$onPremPublicDelegate="publicDelegates"
    [string]$onPremMsExchModeratedByLink="msExchModeratedByLink"
    [string]$onPremmsExchBypassModerationLink="msExchBypassModerationLink"
    [string]$onPremMemberOf="member"
    [string]$onPremAltRecipient="altRecipient"

    #Cloud variables for the distribution list to be migrated.

    $office365DLConfiguration = $NULL #This holds the office 365 DL configuration for the group to be migrated.
    $office365DLConfigurationPostMigration = $NULL
    $office365DLMembershipPostMigration=$NULL
    $routingContactConfiguraiton=$NULL

    #Declare some variables for string processing as items move around.

    [string]$tempOU=$NULL
    [array]$tempNameArrayArray=@()
    [string]$tempName=$NULL
    [string]$tempDN=$NULL

    #For loop counter.

    [int]$forLoopCounter=0

    #Exchange Schema Version

    [int]$exchangeRangeUpper=$NULL
    [int]$exchangeLegacySchemaVersion=15137

    #Define the sub folders for multi-threading.

    [array]$threadFolder="\Thread0","\Thread1","\Thread2","\Thread3","\Thread4","\Thread5","\Thread6","\Thread7","\Thread8","\Thread9","\Thread10"

    #Define the status directory.

    [string]$global:statusPath="\Status\"
    [string]$global:fullStatusPath=$NULL
    [int]$statusFileCount=0


    #If multi threaded - the log directory needs to be created for each thread.
    #Create the log folder path for status before changing the log folder path.

    if ($totalThreadCount -gt 0)
    {
        new-statusFile -logFolderPath $logFolderPath

        $logFolderPath=$logFolderPath+$threadFolder[$global:threadNumber]
    }

    #Ensure that no status files exist at the start of the run.

    if ($totalThreadCount -gt 0)
    {
        if ($global:threadNumber -eq 1)
        {
            remove-statusFiles -fullCleanup:$TRUE
        }
    }

    #Log start of DL migration to the log file.

    new-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath

    Out-LogFile -string "================================================================================"
    Out-LogFile -string "BEGIN START-DISTRIBUTIONLISTMIGRATION"
    Out-LogFile -string "================================================================================"

    #Output parameters to the log file for recording.
    #For parameters that are optional if statements determine if they are populated for recording.

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "PARAMETERS"
    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string ("GroupSMTPAddress = "+$groupSMTPAddress)
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
    Out-LogFile -string "********************************************************************************"

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string " RECORD VARIABLES"
    Out-LogFile -string "********************************************************************************"

    out-logfile -string ("Global Catalog Port = "+$globalCatalogPort)
    out-logfile -string ("Global catalog string used for function queries ="+$globalCatalogWithPort)
    out-logFile -string ("Initial use of Exchange On Prem = "+$useOnPremisesExchange)
    Out-LogFile -string ("Initial user of ADConnect = "+$useAADConnect)
    Out-LogFile -string ("Exchange on prem powershell session name = "+$exchangeOnPremisesPowershellSessionName)
    Out-LogFile -string ("AADConnect powershell session name = "+$aadConnectPowershellSessionName)
    Out-LogFile -string ("AD Global catalog powershell session name = "+$ADGlobalCatalogPowershellSessionName)
    Out-LogFile -string ("Exchange powershell module name = "+$exchangeOnlinePowershellModuleName)
    Out-LogFile -string ("Active directory powershell modulename = "+$activeDirectoryPowershellModuleName)
    out-logFile -string ("Static property for accept messages from members = "+$acceptMessagesFromDLMembers)
    out-logFile -string ("Static property for accept messages from members = "+$rejectMessagesFromDLMembers)
    Out-LogFile -string ("DL Properties to collect = ")

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

    Out-LogFile -string ("Exchange on prem powershell configuration = "+$exchangeServerConfiguration)
    Out-LogFile -string ("Exchange on prem powershell allow redirection = "+$exchangeServerAllowRedirection)
    Out-LogFile -string ("Exchange on prem powershell URL = "+$exchangeServerURI)
    Out-LogFile -string ("Exchange on prem DL active directory configuration XML = "+$originalDLConfigurationADXML)
    Out-LogFile -string ("Exchange on prem DL object configuration XML = "+$originalDLConfigurationObjectXML)
    Out-LogFile -string ("Office 365 DL configuration XML = "+$office365DLConfigurationXML)
    Out-LogFile -string ("Exchange DL members XML Name - "+$exchangeDLMembershipSMTPXML)
    Out-LogFile -string ("Exchange Reject members XML Name - "+$exchangeRejectMessagesSMTPXML)
    Out-LogFile -string ("Exchange Accept members XML Name - "+$exchangeAcceptMessagesSMTPXML)
    Out-LogFile -string ("Exchange ManagedBY members XML Name - "+$exchangeManagedBySMTPXML)
    Out-LogFile -string ("Exchange ModeratedBY members XML Name - "+$exchangeModeratedBySMTPXML)
    Out-LogFile -string ("Exchange BypassModeration members XML Name - "+$exchangeBypassModerationSMTPXML)
    out-logfile -string ("Exchange GrantSendOnBehalfTo members XML name - "+$exchangeGrantSendOnBehalfToSMTPXML)
    Out-LogFile -string ("All group members XML Name - "+$allGroupsMemberOfXML)
    Out-LogFile -string ("All Reject members XML Name - "+$allGroupsRejectXML)
    Out-LogFile -string ("All Accept members XML Name - "+$allGroupsAcceptXML)
    Out-LogFile -string ("All BypassModeration members XML Name - "+$allGroupsBypassModerationXML)
    out-logfile -string ("All Users Forwarding Address members XML Name - "+$allUsersForwardingAddressXML)
    out-logfile -string ("All groups Grand Send On Behalf To XML Name - "+$allGroupsGrantSendOnBehalfToXML)
    out-logfile -string ("Property in office 365 for accept members = "+$office365AcceptMessagesFrom)
    out-logfile -string ("Property in office 365 for bypassmoderation members = "+$office365BypassModerationFrom)
    out-logfile -string ("Property in office 365 for coManagers members = "+$office365CoManagers)
    out-logfile -string ("Property in office 365 for coManagers members = "+$office365GrantSendOnBehalfTo)
    out-logfile -string ("Property in office 365 for grant send on behalf to members = "+$office365GrantSendOnBehalfTo)
    out-logfile -string ("Property in office 365 for managed by members = "+$office365ManagedBy)
    out-logfile -string ("Property in office 365 for members = "+$office365Members)
    out-logfile -string ("Property in office 365 for reject messages from members = "+$office365RejectMessagesFrom)
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
        
        $useAADConnect=$TRUE

        Out-LogFile -string ("Set useAADConnect to TRUE since the parameters necessary for use were passed. - "+$useAADConnect)
    }
    else
    {
        Out-LogFile -string ("Neither AADConnect Server or AADConnect Credentials specified - retain useAADConnect FALSE - "+$useAADConnect)
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

        $useOnPremisesExchange=$TRUE

        Out-LogFile -string ("Set useOnPremsiesExchanget to TRUE since the parameters necessary for use were passed - "+$useOnPremisesExchange)
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

    #exit #Debug exit.

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

    if (($auditSendAsOnPrem -eq $TRUE ) -and ($useOnPremisesExchange -eq $FALSE))
    {
        out-logfile -string "In order to audit send as on premsies an Exchange Server must be specified." -isError:$TRUE
    }

    if (($auditFullMailboxAccessOnPrem -eq $TRUE) -and ($useOnPremisesExchange -eq $FALSE))
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

    
    Out-LogFile -string "================================================================================"
    Out-LogFile -string "END START-DISTRIBUTIONLISTMIGRATION"
    Out-LogFile -string "================================================================================"
}
