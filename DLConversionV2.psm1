
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

    .PARAMETER groupSMTPAddress

    *REQUIRED*
    The SMTP address of the distribution list to be migrated.

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
        [boolean]$useCollectedFolderPermissionsOffice365=$FALSE
    )

    #Define global variables.

    $global:logFile=$NULL #This is the global variable for the calculated log file name
    [string]$global:staticFolderName="\DLMigration\"
    [string]$global:staticAuditFolderName="\AuditData\"
    [string]$global:importFile=$logFolderPath+$global:staticAuditFolderName
    [int]$global:unDoStatus=0

    #Define variables utilized in the core function that are not defined by parameters.

    [boolean]$useOnPremsiesExchange=$FALSE #Determines if function will utilize onpremises exchange during migration.
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
    [array]$dlPropertySetToClear = 'authOrig','DisplayName','DisplayNamePrintable',$rejectMessagesFromDLMembers,$acceptMessagesFromDLMembers,'extensionAttribute1','extensionAttribute10','extensionAttribute11','extensionAttribute12','extensionAttribute13','extensionAttribute14','extensionAttribute15','extensionAttribute2','extensionAttribute3','extensionAttribute4','extensionAttribute5','extensionAttribute6','extensionAttribute7','extensionAttribute8','extensionAttribute9','legacyExchangeDN','mail','mailNickName','msExchRecipientDisplayType','msExchRecipientTypeDetails','msExchRemoteRecipientType',$bypassModerationFromDL,'msExchBypassModerationLink','msExchCoManagedByLink','msExchEnableModeration','msExchExtensionCustomAttribute1','msExchExtensionCustomAttribute2','msExchExtensionCustomAttribute3','msExchExtensionCustomAttribute4','msExchExtensionCustomAttribute5','msExchGroupDepartRestriction','msExchGroupJoinRestriction','msExchHideFromAddressLists','msExchModeratedByLink','msExchModerationFlags','msExchRequireAuthToSendTo','msExchSenderHintTranslations','oofReplyToOriginator','proxyAddresses',$grantSendOnBehalfToDL,'reportToOriginator','reportToOwner','unAuthOrig','msExchArbitrationMailbox','msExchPoliciesIncluded','msExchUMDtmfMap','msExchVersion','showInAddressBook','msExchAddressBookFlags','msExchBypassAudit','msExchGroupExternalMemberCount','msExchGroupMemberCount','msExchGroupSecurityFlags','msExchLocalizationFlags','msExchMailboxAuditEnable','msExchMailboxAuditLogAgeLimit','msExchMailboxFolderSet','msExchMDBRulesQuota','msExchPoliciesIncluded','msExchProvisioningFlags','msExchRecipientSoftDeletedStatus','msExchRoleGroupType','msExchTransportRecipientSettingsFlags','msExchUMDtmfMap','msExchUserAccountControl','msExchVersion'

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
    [array]$exchangeAcceptMessageSMTP=@() #Array of members with accept permissions from AD.
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
    [string]$allOffice365UniversalAcceptXML="allOffice365UniversalAcceptXML"
    [string]$allOffice365UniversalRejectXML="allOffice365UniversalRejectXML"
    [string]$allOffice365UniversalGrantSendOnBehalfToXML="allOffice365UniversalGrantSendOnBehalfToXML"
    [string]$allOffice365MemberOfXML="allOffice365MemberOfXML"
    [string]$allOffice365AcceptXML="allOffice365AcceptXML"
    [string]$allOffice365RejectXML="allOffice365RejectXML"
    [string]$allOffice365BypassModerationXML="allOffice365BypassModerationXML"
    [string]$allOffice365ForwardingAddressXML="allOffice365ForwardingAddressXML"
    [string]$allOffice365GrantSendOnBehalfToXML="allOffice365GrantSentOnBehalfToXML"
    [string]$allOffice365ManagedByXML="allOffice365ManagedByXML"
    [string]$allOffic365SendAsAccessXML = "allOffice365SendAsAccessXML"
    [string]$allOffice365FullMailboxAccessXML = "allOffice365FullMailboxAccessXML"
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

    #The following variables hold information regarding Office 365 objects that have dependencies on the migrated DL.

    [array]$allOffice365MemberOf=$NULL
    [array]$allOffice365Accept=$NULL
    [array]$allOffice365Reject=$NULL
    [array]$allOffice365BypassModeration=$NULL
    [array]$allOffice365ForwardingAddress=$NULL
    [array]$allOffice365ManagedBy=$NULL
    [array]$allOffice365GrantSendOnBehalfTo=$NULL
    [array]$allOffice365UniversalAccept=$NULL
    [array]$allOffice365UniversalReject=$NULL
    [array]$allOffice365UniversalGrantSendOnBehalfTo=$NULL
    [array]$allOffice365ManagedBy=$NULL
    [array]$allOffice365FullMailboxAccess=$NULL
    [array]$allOffice365SendAsAccess=$NULL

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
    out-logFile -string ("Initial use of Exchange On Prem = "+$useOnPremsiesExchange)
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

    Out-LogFile -string ("DL property set to be cleared = ")

    foreach ($dlProperty in $dlPropertySetToClear)
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

        $useOnPremsiesExchange=$TRUE

        Out-LogFile -string ("Set useOnPremsiesExchanget to TRUE since the parameters necessary for use were passed - "+$useOnPremsiesExchange)
    }
    else
    {
        Out-LogFile -string ("Neither Exchange Server or Exchange Credentials specified - retain useOnPremisesExchange FALSE - "+$useOnPremsiesExchange)
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

    if (($useOnPremsiesExchange -eq $False) -and ($enableHybridMailflow -eq $true))
    {
        out-logfile -string "Exchange on premsies information must be provided in order to enable hybrid mail flow." -isError:$TRUE
    }

    if (($auditSendAsOnPrem -eq $TRUE ) -and ($useOnPremsiesExchange -eq $FALSE))
    {
        out-logfile -string "In order to audit send as on premsies an Exchange Server must be specified." -isError:$TRUE
    }

    if (($auditFullMailboxAccessOnPrem -eq $TRUE) -and ($useOnPremsiesExchange -eq $FALSE))
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

    #If exchange server information specified - create the on premises powershell session.

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "ESTABLISH POWERSHELL SESSIONS"
    Out-LogFile -string "********************************************************************************"

   #Test to determine if the exchange online powershell module is installed.
   #The exchange online session has to be established first or the commandlet set from on premises fails.

   Out-LogFile -string "Calling Test-PowerShellModule to validate the Exchange Module is installed."

   Test-PowershellModule -powershellModuleName $exchangeOnlinePowershellModuleName

   Out-LogFile -string "Calling Test-PowerShellModule to validate the Active Directory is installed."

   Test-PowershellModule -powershellModuleName $activeDirectoryPowershellModuleName

   #Create the connection to exchange online.

   Out-LogFile -string "Calling New-ExchangeOnlinePowershellSession to create session to office 365."

   if ($exchangeOnlineCredential -ne $NULL)
   {
      #User specified non-certifate authentication credentials.

        try {
            New-ExchangeOnlinePowershellSession -exchangeOnlineCredentials $exchangeOnlineCredential -exchangeOnlineEnvironmentName $exchangeOnlineEnvironmentName
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
            new-ExchangeOnlinePowershellSession -exchangeOnlineCertificateThumbPrint $exchangeOnlineCertificateThumbPrint -exchangeOnlineAppId $exchangeOnlineAppID -exchangeOnlineOrganizationName $exchangeOnlineOrganizationName -exchangeOnlineEnvironmentName $exchangeOnlineEnvironmentName
        }
        catch {
            out-logfile -string "Unable to create the exchange online connection using certificate."
            out-logfile -string $_ -isError:$TRUE
        }
   }

   #exit #debug exit

   #Now we can determine if exchange on premises is utilized and if so establish the connection.
   
   Out-LogFile -string "Determine if Exchange On Premises specified and create session if necessary."

    if ($useOnPremsiesExchange -eq $TRUE)
    {
        try 
        {
            Out-LogFile -string "Calling New-PowerShellSession"

            $sessiontoImport=new-PowershellSession -credentials $exchangecredential -powershellSessionName $exchangeOnPremisesPowershellSessionName -connectionURI $exchangeServerURI -authenticationType $exchangeAuthenticationMethod -configurationName $exchangeServerConfiguration -allowredirection $exchangeServerAllowRedirection -requiresImport:$TRUE
        }
        catch 
        {
            Out-LogFile -string "ERROR:  Unable to create powershell session." -isError:$TRUE
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

    if ($useAADConnect -eq $TRUE)
    {
        try 
        {
            out-logfile -string "Creating powershell session to the AD Connect server."

            New-PowershellSession -Server $aadConnectServer -Credentials $aadConnectCredential -PowershellSessionName $aadConnectPowershellSessionName
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

        new-powershellsession -server $globalCatalogServer -credentials $activeDirectoryCredential -powershellsessionname $ADGlobalCatalogPowershellSessionName
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
        $originalDLConfiguration = Get-ADObjectConfiguration -groupSMTPAddress $groupSMTPAddress -globalCatalogServer $globalCatalogWithPort -parameterSet $dlPropertySet -errorAction STOP -adCredential $activeDirectoryCredential
    }
    catch
    {
        out-logfile -string $_ -isError:$TRUE
    }
    
    Out-LogFile -string "Log original DL configuration."
    out-logFile -string $originalDLConfiguration

    Out-LogFile -string "Create an XML file backup of the on premises DL Configuration"

    Out-XMLFile -itemToExport $originalDLConfiguration -itemNameToExport $originalDLConfigurationADXML

    Out-LogFile -string "Determine if administrator desires to audit send as."

    if ($retainSendAsOnPrem -eq $TRUE)
    {
        out-logfile -string "Administrator has choosen to audit on premsies send as."
        out-logfile -string "NOTE:  THIS IS A LONG RUNNING OPERATION."

        if ($useCollectedSendAsOnPrem -eq $TRUE)
        {
            out-logfile -string "Administrator has selected to import previously gathered permissions."

            
            $importFilePath=Join-path $importFile $retainOnPremRecipientSendAsXML

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

        out-xmlFile -itemToExport $allObjectSendAsAccess -itemNameToExport $allGroupsSendAsXML
    }

    Out-LogFile -string "Determine if administrator desires to audit full mailbox access."

    if ($retainFullMailboxAccessOnPrem -eq $TRUE)
    {
        out-logfile -string "Administrator has choosen to audit on premsies full mailbox access."
        out-logfile -string "NOTE:  THIS IS A LONG RUNNING OPERATION."

        $allObjectsFullMailboxAccess = Get-onPremFullMailboxAccess -originalDLConfiguration $originalDLConfiguration
    }
    else
    {
        out-logfile -string "Administrator has choosen to not audit on premises full mailbox access."
    }

    #Record what was returned.

    if ($allObjectsFullMailboxAccess.count -ne 0)
    {
        out-logfile -string $allObjectsFullMailboxAccess

        out-xmlFile -itemToExport $allObjectsFullMailboxAccess -itemNameToExport $allGroupsFullMailboxAccessXML
    }

    #If there are any sendAs or mailbox access permissiosn for the group.
    #The group should be retained for saftey and only manually deleted if the administrator understands ramiifactions.
    #In testing disabling the group will allow the permissions to continue functioning - deleting the group would loose it.
    #Overrideing the administrators decision to delete the group.

    if (($allObjectSendAsAccess -ne 0) -or ($allObjectsFullMailboxAccess -ne 0))
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

    Out-XMLFile -itemToExport $office365DLConfiguration -itemNameToExport $office365DLConfigurationXML

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END GET ORIGINAL DL CONFIGURATION LOCAL AND CLOUD"
    Out-LogFile -string "********************************************************************************"

    Out-LogFile -string "Perform a safety check to ensure that the distribution list is directory sync."

    try 
    {
        Invoke-Office365SafetyCheck -o365dlconfiguration $office365DLConfiguration -errorAction STOP
    }
    catch 
    {
        out-logFile -string $_ -isError:$TRUE
    }
    
    #At this time we have the DL configuration on both sides and have checked to ensure it is dir synced.
    #Membership of attributes is via DN - these need to be normalized to SMTP addresses in order to find users in Office 365.

    #Start with DL membership and normallize.

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "BEGIN NORMALIZE DNS FOR ALL ATTRIBUTES"
    Out-LogFile -string "********************************************************************************"

    Out-LogFile -string "Invoke get-NormalizedDN to normalize the members DN to Office 365 identifier."

    if ($originalDLConfiguration.member -ne $NULL)
    {
        foreach ($DN in $originalDLConfiguration.member)
        {
            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try 
            {
                $exchangeDLMembershipSMTP+=get-normalizedDN -globalCatalogServer $globalCatalogWithPort -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -isMember:$TRUE -errorAction STOP
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

    if ($originalDLConfiguration.unAuthOrig -ne $NULL)
    {
        foreach ($DN in $originalDLConfiguration.unAuthOrig)
        {
            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try 
            {
                $exchangeRejectMessagesSMTP+=get-normalizedDN -globalCatalogServer $globalCatalogWithPort -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -errorAction STOP
            }
            catch 
            {
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }

    Out-LogFile -string "REJECT GROUPS"

    if ($originalDLConfiguration.dlMemRejectPerms -ne $NULL)
    {
        foreach ($DN in $originalDLConfiguration.dlMemRejectPerms)
        {
            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try 
            {
                $exchangeRejectMessagesSMTP+=get-normalizedDN -globalCatalogServer $globalCatalogWithPort -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -errorAction STOP
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

    if ($originalDLConfiguration.AuthOrig -ne $NULL)
    {
        foreach ($DN in $originalDLConfiguration.AuthOrig)
        {
            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try 
            {
                $exchangeAcceptMessageSMTP+=get-normalizedDN -globalCatalogServer $globalCatalogWithPort -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -errorAction STOP
            }
            catch 
            {
                out-logFile -string $_ -isError:$TRUE
            }
        }
    }

    Out-LogFile -string "ACCEPT GROUPS"

    if ($originalDLConfiguration.dlMemSubmitPerms -ne $NULL)
    {
        foreach ($DN in $originalDLConfiguration.dlMemSubmitPerms)
        {
            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try 
            {
                $exchangeAcceptMessageSMTP+=get-normalizedDN -globalCatalogServer $globalCatalogWithPort -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -errorAction STOP
            }
            catch 
            {
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }

    if ($exchangeAcceptMessageSMTP -ne $NULL)
    {
        Out-LogFile -string "The following objects are members of the accept messages from senders:"
        
        out-logfile -string $exchangeAcceptMessageSMTP
    }
    else
    {
        out-logFile -string "This group has no accept message from restrictions."    
    }
    
    Out-LogFile -string "Invoke get-NormalizedDN to normalize the managedBy members DN to Office 365 identifier."

    Out-LogFile -string "Process MANAGEDBY"

    if ($originalDLConfiguration.managedBy -ne $NULL)
    {
        foreach ($DN in $originalDLConfiguration.managedBy)
        {
            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try 
            {
                $exchangeManagedBySMTP+=get-normalizedDN -globalCatalogServer $globalCatalogWithPort -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -errorAction STOP
            }
            catch 
            {
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }

    Out-LogFile -string "Process CoMANAGERS"

    if ($originalDLConfiguration.msExchCoManagedByLink -ne $NULL)
    {
        foreach ($DN in $originalDLConfiguration.msExchCoManagedByLink)
        {
            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try 
            {
                $exchangeManagedBySMTP+=get-normalizedDN -globalCatalogServer $globalCatalogWithPort -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -errorAction STOP
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

    Out-LogFile -string "Invoke get-NormalizedDN to normalize the moderatedBy members DN to Office 365 identifier."

    Out-LogFile -string "Process MODERATEDBY"

    if ($originalDLConfiguration.msExchModeratedByLink -ne $NULL)
    {
        foreach ($DN in $originalDLConfiguration.msExchModeratedByLink)
        {
            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try 
            {
                $exchangeModeratedBySMTP+=get-normalizedDN -globalCatalogServer $globalCatalogWithPort -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -errorAction STOP
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

    if ($originalDLConfiguration.msExchBypassModerationLink -ne $NULL)
    {
        foreach ($DN in $originalDLConfiguration.msExchBypassModerationLink)
        {
            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try 
            {
                $exchangeBypassModerationSMTP+=get-normalizedDN -globalCatalogServer $globalCatalogWithPort -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -errorAction STOP
            }
            catch 
            {
                out-logFile -string $_ -isError:$TRUE
            }
        }
    }

    Out-LogFile -string "Invoke get-NormalizedDN to normalize the bypass moderation groups members DN to Office 365 identifier."

    Out-LogFile -string "Process BYPASS GROUPS"

    if ($originalDLConfiguration.msExchBypassModerationFromDLMembersLink -ne $NULL)
    {
        foreach ($DN in $originalDLConfiguration.msExchBypassModerationFromDLMembersLink)
        {
            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try 
            {
                out-logfile -string $activeDirectoryCredential.userName
                $exchangeBypassModerationSMTP+=get-normalizedDN -globalCatalogServer $globalCatalogWithPort -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -errorAction STOP
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

    if ($originalDLConfiguration.publicDelegates -ne $NULL)
    {
        foreach ($DN in $originalDLConfiguration.publicDelegates)
        {
            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try 
            {
                $exchangeGrantSendOnBehalfToSMTP+=get-normalizedDN -globalCatalogServer $globalCatalogWithPort -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName  -errorAction STOP
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

    #At this time we have discovered all permissions based off the LDAP properties of the users.  The one remaining is what objects have SENDAS rights on this DL.

    out-logfile -string "Obtaining send as permissions."

    try 
    {
        $exchangeSendAsSMTP=get-GroupSendAsPermissions -globalCatalog $globalCatalogWithPort -dn $originalDLConfiguration.distinguishedName -adCredential $activeDirectoryCredential -adGlobalCatalogPowershellSessionName $adGlobalCatalogPowershellSessionName
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
    else 
    {
        $exchangeSendAsSMTP=@()
        out-logfile "The group has no grant send on behalf to."    
    }

    #exit #Debug Exit

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END NORMALIZE DNS FOR ALL ATTRIBUTES"
    Out-LogFile -string "********************************************************************************"

    out-logfile -string "/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
    out-logFile -string "Summary of group information:"
    out-logfile -string ("The number of objects included in the member migration: "+$exchangeDLMembershipSMTP.count)
    out-logfile -string ("The number of objects included in the reject memebers: "+$exchangeRejectMessagesSMTP.count)
    out-logfile -string ("The number of objects included in the accept memebers: "+$exchangeAcceptMessageSMTP.count)
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

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "BEGIN VALIDATE RECIPIENTS IN CLOUD"
    Out-LogFile -string "********************************************************************************"

    if ($exchangeDLMembershipSMTP -ne $NULL)
    {
        out-logfile -string "Ensuring each DL member is in Office 365 / Exchange Online"

        foreach ($member in $exchangeDLMembershipSMTP)
        {
            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            out-LogFile -string ("Testing = "+$member.primarySMTPAddressOrUPN)

            try{
                test-O365Recipient -member $member
            }
            catch{
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }

    if ($exchangeRejectMessagesSMTP -ne $NULL)
    {
        out-logfile -string "Ensuring each DL reject messages is in Office 365."

        foreach ($member in $exchangeRejectMessagesSMTP)
        {
            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            out-LogFile -string ("Testing = "+$member.primarySMTPAddressOrUPN)

            try{
                test-O365Recipient -member $member
            }
            catch{
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }

    if ($exchangeAcceptMessagesSMTP -ne $NULL)
    {
        out-logfile -string "Ensuring each DL accept messages is in Office 365 / Exchange Online"

        foreach ($member in $exchangeAcceptMessagesSMTP)
        {
            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            out-LogFile -string ("Testing = "+$member.primarySMTPAddressOrUPN)

            try{
                test-O365Recipient -member $member
            }
            catch{
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }

    if ($exchangeManagedBySMTP -ne $NULL)
    {
        out-logfile -string "Ensuring each DL managed by is in Office 365 / Exchange Online"

        foreach ($member in $exchangeManagedBySMTP)
        {
            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            out-LogFile -string ("Testing = "+$member.primarySMTPAddressOrUPN)

            try{
                test-O365Recipient -member $member
            }
            catch{
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }

    if ($exchangeModeratedBySMTP -ne $NULL)
    {
        out-logfile -string "Ensuring each DL moderated by is in Office 365 / Exchange Online"

        foreach ($member in $exchangeModeratedBySMTP)
        {
            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            out-LogFile -string ("Testing = "+$member.primarySMTPAddressOrUPN)

            try{
                test-O365Recipient -member $member
            }
            catch{
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }

    if ($exchangeBypassModerationSMTP -ne $NULL)
    {
        out-logfile -string "Ensuring each DL bypass moderation is in Office 365 / Exchange Online"

        foreach ($member in $exchangeBypassModerationSMTP)
        {
            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            out-LogFile -string ("Testing = "+$member.primarySMTPAddressOrUPN)

            try{
                test-O365Recipient -member $member
            }
            catch{
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }

    if ($exchangeGrantSendOnBehalfToSMTP -ne $NULL)
    {
        out-logfile -string "Ensuring each DL grant send on behalf to is in Office 365 / Exchange Online"

        foreach ($member in $exchangeGrantSendOnBehalfToSMTP)
        {
            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            out-LogFile -string ("Testing = "+$member.primarySMTPAddressOrUPN)

            try{
                test-O365Recipient -member $member
            }
            catch{
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END VALIDATE RECIPIENTS IN CLOUD"
    Out-LogFile -string "********************************************************************************"

    #It is possible that this group was a member of - or other groups have a dependency on this group.
    #We will implement a function to track those dependen$ocies.

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "BEGIN RECORD DEPENDENCIES ON MIGRATED GROUP"
    Out-LogFile -string "********************************************************************************"

    out-logfile -string "Get all the groups that this user is a member of - normalize to canonicalname."

    #Start with groups this DL is a member of remaining on premises.

    if ($originalDLConfiguration.memberOf -ne $NULL)
    {
        out-logfile -string "Calling get-CanonicalName."

        foreach ($DN in $originalDLConfiguration.memberof)
        {
            try 
            {
                $allGroupsMemberOf += get-canonicalname -globalCatalog $globalCatalogWithPort -dn $DN -adCredential $activeDirectoryCredential -errorAction STOP
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

    if ($originalDLConfiguration.altRecipientBL -ne $NULL)
    {
        out-logfile -string "Calling get-CanonicalName."

        foreach ($DN in $originalDLConfiguration.altRecipientBL)
        {
            try 
            {
                $allUsersForwardingAddress += get-canonicalname -globalCatalog $globalCatalogWithPort -dn $DN -adCredential $activeDirectoryCredential -errorAction STOP
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

    if ($originalDLConfiguration.dLMemRejectPermsBL -ne $NULL)
    {
        out-logfile -string "Calling get-CanonicalName."

        foreach ($DN in $originalDLConfiguration.dLMemRejectPermsBL)
        {
            try 
            {
                $allGroupsReject += get-canonicalname -globalCatalog $globalCatalogWithPort -dn $DN -adCredential $activeDirectoryCredential -errorAction STOP
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

    if ($originalDLConfiguration.dLMemSubmitPermsBL -ne $NULL)
    {
        out-logfile -string "Calling get-CanonicalName."

        foreach ($DN in $originalDLConfiguration.dLMemSubmitPermsBL)
        {
            try 
            {
                $allGroupsAccept += get-canonicalname -globalCatalog $globalCatalogWithPort -dn $DN -adCredential $activeDirectoryCredential -errorAction STOP
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

    #Handle all groups this object has bypass moderation permissions on.

    if ($originalDLConfiguration.msExchBypassModerationFromDLMembersBL -ne $NULL)
    {
        out-logfile -string "Calling get-CanonicalName."

        foreach ($DN in $originalDLConfiguration.msExchBypassModerationFromDLMembersBL)
        {
            try 
            {
                $allGroupsBypassModeration += get-canonicalname -globalCatalog $globalCatalogWithPort -dn $DN -adCredential $activeDirectoryCredential -errorAction STOP
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

    if ($originalDLConfiguration.publicDelegatesBL -ne $NULL)
    {
        out-logfile -string "Calling get-CanonicalName."

        foreach ($DN in $originalDLConfiguration.publicDelegatesBL)
        {
            try 
            {
                $allGroupsGrantSendOnBehalfTo += get-canonicalname -globalCatalog $globalCatalogWithPort -dn $DN -adCredential $activeDirectoryCredential -errorAction STOP
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

    if ($originalDLConfiguration.managedObjects -ne $NULL)
    {
        out-logfile -string "Calling get-CanonicalName."

        foreach ($DN in $originalDLConfiguration.managedObjects)
        {
            try 
            {
                $allGroupsManagedBy += get-canonicalname -globalCatalog $globalCatalogWithPort -dn $DN -adCredential $activeDirectoryCredential -errorAction STOP
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
    out-logfile -string "/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"


    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END RECORD DEPENDENCIES ON MIGRATED GROUP"
    Out-LogFile -string "********************************************************************************"

    Out-LogFile -string "Recording all gathered information to XML to preserve original values."

    if ($exchangeDLMembershipSMTP -ne $NULL)
    {
        Out-XMLFile -itemtoexport $exchangeDLMembershipSMTP -itemNameToExport $exchangeDLMembershipSMTPXML
    }
    else 
    {
        $exchangeDLMembershipSMTP=@()
    }

    if ($exchangeRejectMessagesSMTP -ne $NULL)
    {
        out-xmlfile -itemtoexport $exchangeRejectMessagesSMTP -itemNameToExport $exchangeRejectMessagesSMTPXML
    }
    else 
    {
        $exchangeRejectMessagesSMTP=@()
    }

    if ($exchangeAcceptMessageSMTP -ne $NULL)
    {
        out-xmlfile -itemtoexport $exchangeAcceptMessageSMTP -itemNameToExport $exchangeAcceptMessagesSMTPXML
    }
    else 
    {
        $exchangeAcceptMessageSMTP=@()
    }

    if ($exchangeManagedBySMTP -ne $NULL)
    {
        out-xmlfile -itemtoexport $exchangeManagedBySMTP -itemNameToExport $exchangeManagedBySMTPXML
    }
    else 
    {
        $exchangeManagedBySMTP=@()
    }

    if ($exchangeModeratedBySMTP -ne $NULL)
    {
        out-xmlfile -itemtoexport $exchangeModeratedBySMTP -itemNameToExport $exchangeModeratedBySMTPXML
    }
    else 
    {
        $exchangeModeratedBySMTP=@()
    }

    if ($exchangeBypassModerationSMTP -ne $NULL)
    {
        out-xmlfile -itemtoexport $exchangeBypassModerationSMTP -itemNameToExport $exchangeBypassModerationSMTPXML
    }
    else 
    {
        $exchangeBypassModerationSMTP=@()
    }

    if ($exchangeGrantSendOnBehalfToSMTP -ne $NULL)
    {
        out-xmlfile -itemToExport $exchangeGrantSendOnBehalfToSMTP -itemNameToExport $exchangeGrantSendOnBehalfToSMTPXML
    }
    else 
    {
        $exchangeGrantSendOnBehalfToSMTP=@()
    }

    if ($exchangeSendAsSMTP -ne $NULL)
    {
        out-xmlfile -itemToExport $exchangeSendAsSMTP -itemNameToExport $exchangeSendAsSMTPXML
    }
    else 
    {
        $exchangeSendAsSMTP=@()
    }

    if ($allGroupsMemberOf -ne $NULL)
    {
        out-xmlfile -itemtoexport $allGroupsMemberOf -itemNameToExport $allGroupsMemberOfXML
    }
    else 
    {
        $allGroupsMemberOf=@()
    }
    
    if ($allGroupsReject -ne $NULL)
    {
        out-xmlfile -itemtoexport $allGroupsReject -itemNameToExport $allGroupsRejectXML
    }
    else 
    {
        $allGroupsReject=@()
    }
    
    if ($allGroupsAccept -ne $NULL)
    {
        out-xmlfile -itemtoexport $allGroupsAccept -itemNameToExport $allGroupsAcceptXML
    }
    else 
    {
        $allGroupsAccept=@()
    }

    if ($allGroupsBypassModeration -ne $NULL)
    {
        out-xmlfile -itemtoexport $allGroupsBypassModeration -itemNameToExport $allGroupsBypassModerationXML
    }
    else 
    {
        $allGroupsBypassModeration=@()
    }

    if ($allUsersForwardingAddress -ne $NULL)
    {
        out-xmlFile -itemToExport $allUsersForwardingAddress -itemNameToExport $allUsersForwardingAddressXML
    }
    else 
    {
        $allUsersForwardingAddress=@()
    }

    if ($allGroupsManagedBy -ne $NULL)
    {
        out-xmlFile -itemToExport $allGroupsManagedBy -itemNameToExport $allGroupsManagedByXML
    }
    else 
    {
        $allGroupsManagedBy=@()
    }

    if ($allGroupsGrantSendOnBehalfTo -ne $NULL)
    {
        out-xmlFile -itemToExport $allGroupsGrantSendOnBehalfTo -itemNameToExport $allGroupsGrantSendOnBehalfToXML
    }
    else 
    {
        $allGroupsGrantSendOnBehalfTo =@()
    }

    #EXIT #Debug Exit

    #EXIT #Debug Exit

    #Ok so at this point we have preserved all of the information regarding the on premises DL.
    #It is possible that there could be cloud only objects that this group was made dependent on.
    #For example - the dirSync group could have been added as a member of a cloud only group - or another group that was migrated.
    #The issue here is that this gets VERY expensive to track - since some of the word to do do is not filterable.
    #With the LDAP improvements we no longer offert the option to track on premises - but the administrator can choose to track the cloud

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "START RETAIN OFFICE 365 GROUP DEPENDENCIES"
    Out-LogFile -string "********************************************************************************"

    if ($retainOffice365Settings -eq $TRUE)
    {
        out-logFile -string "Office 365 settings are to be retained."

        try {
            $allOffice365MemberOf = Get-O365GroupDependency -dn $office365DLConfiguration.distinguishedName -attributeType $office365Members -errorAction STOP
        }
        catch {
            out-logFile -string $_ -isError:$TRUE
        }

        out-logfile -string ("The number of groups in Office 365 cloud only that the DL is a member of = "+$allOffice365MemberOf.count)

        try {
            $allOffice365Accept = Get-O365GroupDependency -dn $office365DLConfiguration.distinguishedName -attributeType $office365AcceptMessagesFrom -errorAction STOP
        }
        catch {
            out-logFile -string $_ -isError:$TRUE
        }

        out-logfile -string ("The number of groups in Office 365 cloud only that the DL has accept rights = "+$allOffice365Accept.count)

        try {
            $allOffice365Reject = Get-O365GroupDependency -dn $office365DLConfiguration.distinguishedName -attributeType $office365RejectMessagesFrom -errorAction STOP
        }
        catch {
            out-logFile -string $_ -isError:$TRUE
        }

        out-logfile -string ("The number of groups in Office 365 cloud only that the DL has reject rights = "+$allOffice365Reject.count)

        try {
            $allOffice365BypassModeration = Get-O365GroupDependency -dn $office365DLConfiguration.distinguishedName -attributeType $office365BypassModerationFrom -errorAction STOP
        }
        catch {
            out-logFile -string $_ -isError:$TRUE
        }

        out-logfile -string ("The number of groups in Office 365 cloud only that the DL has grant send on behalf to righbypassModeration rights = "+$allOffice365BypassModeration.count)

        try {
            $allOffice365GrantSendOnBehalfTo = Get-O365GroupDependency -dn $office365DLConfiguration.distinguishedName -attributeType $office365GrantSendOnBehalfTo -errorAction STOP
        }
        catch {
            out-logFile -string $_ -isError:$TRUE
        }

        out-logfile -string ("The number of groups in Office 365 cloud only that the DL has grantSendOnBehalFto = "+$allOffice365GrantSendOnBehalfTo.count)

        try {
            $allOffice365ManagedBy = Get-O365GroupDependency -dn $office365DLConfiguration.distinguishedName -attributeType $office365ManagedBy -errorAction STOP
        }
        catch {
            out-logFile -string $_ -isError:$TRUE
        }

        out-logfile -string ("The number of groups in Office 365 cloud only that the DL has managedBY = "+$allOffice365ManagedBy.count)

        try {
            $allOffice365ForwardingAddress = Get-O365GroupDependency -dn $office365DLConfiguration.distinguishedName -attributeType $office365ForwardingAddress -errorAction STOP
        }
        catch {
            out-logFile -string $_ -isError:$TRUE
        }

        out-logfile -string ("The number of groups in Office 365 cloud only that the DL has forwarding on mailboxes = "+$allOffice365ForwardingAddress.count)

        try {
            $allOffice365UniversalAccept = Get-O365GroupDependency -dn $office365DLConfiguration.distinguishedName -attributeType $office365AcceptMessagesFrom -groupType "Unified" -errorAction STOP
        }
        catch {
            out-logFile -string $_ -isError:$TRUE
        }

        out-logfile -string ("The number of universal groups in the Office 365 cloud that the DL has accept rights on = "+$allOffice365UniversalAccept.count)

        try{
            $allOffice365UniversalReject = Get-O365GroupDependency -dn $office365DLConfiguration.distinguishedName -attributeType $office365RejectMessagesFrom -groupType "Unified" -errorAction STOP
        }
        catch{
            out-logFile -string $_ -isError:$TRUE
        }

        out-logfile -string ("The number of universal groups in the Office 365 cloud that the DL has reject rights on = "+$allOffice365UniversalReject.count)

        try {
            $allOffice365UniversalGrantSendOnBehalfTo = Get-O365GroupDependency -dn $office365DLConfiguration.distinguishedName -attributeType $office365GrantSendOnBehalfTo -groupType "Unified" -errorAction STOP
        }
        catch {
            out-logFile -string $_ -isError:$TRUE
        }

        if ($retainSendAsOffice365 -eq $TRUE)
        {
            try{
                $allOffice365SendAsAccess = Get-O365DLSendAs -groupSMTPAddress $groupSMTPAddress
            }
            catch{
                out-logfile -string $_ -isError:$TRUE
            }
        }

        if ($retainFullMailboxAccessOffice365 -eq $TRUE)
        {
            try {
                $allOffice365FullMailboxAccess = Get-O365DLFullMaiboxAccess -groupSMTPAddress $groupSMTPAddress
            }
            catch {
                out-logfile -string $_ -isError:$TRUE
            }
        }  

        out-logfile -string ("The number of universal groups in the Office 365 cloud that the DL has grant send on behalf rights on = "+$allOffice365UniversalGrantSendOnBehalfTo.count)

        if ($allOffice365MemberOf -ne $NULL)
        {
            out-logfile -string $allOffice365MemberOf
            out-xmlfile -itemtoexport $allOffice365MemberOf -itemNameToExport $allOffice365MemberofXML
        }
        else 
        {
            $allOffice365MemberOf=@()
        }

        if ($allOffice365Accept -ne $NULL)
        {
            out-logfile -string $allOffice365Accept
            out-xmlFile -itemToExport $allOffice365Accept -itemNameToExport $allOffice365AcceptXML
        }
        else 
        {
            $allOffice365Accept=@()    
        }

        if ($allOffice365Reject -ne $NULL)
        {
            out-logfile -string $allOffice365Reject
            out-xmlFile -itemToExport $allOffice365Reject -itemNameToExport $allOffice365RejectXML
        }
        else 
        {
            $allOffice365Reject=@()    
        }
        
        if ($allOffice365BypassModeration -ne $NULL)
        {
            out-logfile -string $allOffice365BypassModeration
            out-xmlFile -itemToExport $allOffice365BypassModeration -itemNameToExport $allOffice365BypassModerationXML
        }
        else 
        {
            $allOffice365BypassModeration=@()    
        }

        if ($allOffice365GrantSendOnBehalfTo -ne $NULL)
        {
            out-logfile -string $allOffice365GrantSendOnBehalfTo
            out-xmlfile -itemToExport $allOffice365GrantSendOnBehalfTo -itemNameToExport $allOffice365GrantSendOnBehalfToXML
        }
        else 
        {
            $allOffice365GrantSendOnBehalfTo=@()    
        }

        if ($allOffice365ManagedBy -ne $NULL)
        {
            out-logfile -string $allOffice365ManagedBy
            out-xmlFile -itemToExport $allOffice365ManagedBy -itemNameToExport $allOffice365ManagedByXML
        }
        else 
        {
            $allOffice365ManagedBy=@()    
        }

        if ($allOffice365ForwardingAddress -ne $NULL)
        {
            out-logfile -string $allOffice365ForwardingAddress
            out-xmlfile -itemToExport $allOffice365ForwardingAddress -itemNameToExport $allOffice365ForwardingAddressXML
        }
        else 
        {
            $allOffice365ForwardingAddress=@()    
        }

        if ($allOffice365UniversalAccept -ne $NULL)
        {
            out-logfile -string $allOffice365UniversalAccept
            out-xmlfile -itemToExport $allOffice365UniversalAccept -itemNameToExport $allOffice365UniversalAcceptXML
        }
        else 
        {
            $allOffice365UniversalAccept=@()    
        }

        if ($allOffice365UniversalReject -ne $NULL)
        {
            out-logfile -string $allOffice365UniversalReject
            out-xmlFIle -itemToExport $allOffice365UniversalReject -itemNameToExport $allOffice365UniversalRejectXML
        }
        else 
        {
            $allOffice365UniversalReject=@()    
        }

        if ($allOffice365UniversalGrantSendOnBehalfTo -ne $NULL)
        {
            out-logfile -string $allOffice365UniversalGrantSendOnBehalfTo
            out-xmlFile -itemToExport $allOffice365UniversalGrantSendOnBehalfTo -itemNameToExport $allOffice365UniversalGrantSendOnBehalfToXML
        }
        else 
        {
            $allOffice365UniversalGrantSendOnBehalfTo=@()    
        }

        if ($allOffice365SendAsAccess -ne $NULL)
        {
            out-logfile -string $allOffice365SendAsAccess
            out-xmlfile -itemToExport $allOffice365SendAsAccess -itemNameToExport $allOffic365SendAsAccessXML
        }
        else 
        {
            $allOffice365SendAsAccess=@()    
        }

        if ($allOffice365FullMailboxAccess -ne $NULL)
        {
            out-logfile -string $allOffice365FullMailboxAccess
            out-xmlFile -itemToExport $allOffice365FullMailboxAccess -itemNameToExport $allOffice365FullMailboxAccessXML
        }
        else 
        {
            $allOffice365FullMailboxAccess=@()    
        }
    }
    else 
    {
        out-logfile -string "Administrator opted out of recording Office 365 dependencies."
    }

    out-logfile -string "/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
    out-logfile -string ("Summary of dependencies found:")
    out-logfile -string ("The number of office 365 groups that the migrated DL is a member of = "+$allOffice365MemberOf.count)
    out-logfile -string ("The number of office 365 groups that this group is a manager of: = "+$allOffice365ManagedBy.count)
    out-logfile -string ("The number of office 365 groups that this group has grant send on behalf to = "+$allOffice365GrantSendOnBehalfTo.count)
    out-logfile -string ("The number of office 365 groups that have this group as bypass moderation = "+$allOffice365BypassModeration.count)
    out-logfile -string ("The number of office 365 groups with accept permissions = "+$allOffice365Accept.count)
    out-logfile -string ("The number of office 365 groups with reject permissions = "+$allOffice365BypassModeration.count)
    out-logfile -string ("The number of office 365 mailboxes forwarding to this group is = "+$allOffice365ForwardingAddress.count)
    out-logfile -string ("The number of office 365 unified groups with accept permissions = "+$allOffice365UniversalAccept.count)
    out-logfile -string ("The number of office 365 unified groups with grant send on behalf to permissions = "+$allOffice365UniversalGrantSendOnBehalfTo.count)
    out-logfile -string ("The number of office 365 unified groups with reject permissions = "+$allOffice365UniversalReject.count)
    out-logfile -string ("The number of office 365 recipients with send as = "+$allOffice365SendAsAccess.count)
    out-logfile -string ("The number of office 365 recipients with full mailbox access = "+$allOffice365FullMailboxAccess.count)
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

    try {
        move-toNonSyncOU -dn $originalDLConfiguration.distinguishedName -OU $dnNoSyncOU -globalCatalogServer $globalCatalogServer -adCredential $activeDirectoryCredential -errorAction STOP
    }
    catch {
        out-logfile -string $_ -isError:$TRUE
    }

    #$Capture the moved DL configuration (since attibutes change upon move.)

    try {
        $originalDLConfigurationUpdated = Get-ADObjectConfiguration -groupSMTPAddress $groupSMTPAddress -globalCatalogServer $globalCatalogWithPort -parameterSet $dlPropertySet -errorAction STOP -adCredential $activeDirectoryCredential 
    }
    catch {
        out-logFile -string $_ -isError:$TRUE
    }

    out-LogFile -string $originalDLConfigurationUpdated
    out-xmlFile -itemToExport $originalDLConfigurationUpdated -itemNameTOExport $originalDLConfigurationUpdatedXML

    $global:unDoStatus=$global:unDoStatus+1

    out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

    #Replicate domain controllers so that the change is received as soon as possible.   

    out-logfile -string "Starting sleep before invoking AD replication - 15 seconds."
    start-sleep -seconds 15
    out-logfile -string "Invoking AD replication."

    try {
        invoke-ADReplication -globalCatalogServer $globalCatalogServer -powershellSessionName $ADGlobalCatalogPowershellSessionName -errorAction STOP
    }
    catch {
        out-logfile -string $_ -isError:$TRUE
    }

    #Start the process of syncing the deletion to the cloud if the administrator has provided credentials.
    #Note:  If this is not done we are subject to sitting and waiting for it to complete.

    if ($useAADConnect -eq $TRUE)
    {
        out-logfile -string "Starting sleep before invoking AD Connect - one minute."
        start-sleep -seconds 60
        out-logfile -string "Invoking AD Connect."

        start-sleep -s 5
        invoke-ADConnect -powerShellSessionName $aadConnectPowershellSessionName

        out-logfile -string "Sleeping after ad connect instance to allow deletion to process."
        start-sleep -seconds 60
    }
    else 
    {
        out-logfile -string "AD Connect information not specified - allowing ad connect to run on normal cycle and process deletion."    
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

    out-logfile "Sleeping 30 seconds before creating the DL."
    start-sleep -seconds 30

    try {
        new-office365dl -originalDLConfiguration $originalDLConfiguration -grouptypeoverride $groupTypeOverride -errorAction STOP
    }
    catch {
        out-logFile -string $_ -isError:$TRUE
    }

    try {
        $office365DLConfigurationPostMigration = Get-O365DLConfiguration -groupSMTPAddress $originalDLConfiguration.mailnickname -errorAction STOP
    }
    catch {
        out-logfile -string $_ -isError:$TRUE
    }

    out-LogFile -string "Write new DL configuration to XML."

    out-Logfile -string $office365DLConfigurationPostMigration
    out-xmlFile -itemToExport $office365DLConfigurationPostMigration -itemNameToExport $office365DLConfigurationPostMigrationXML

    $global:unDoStatus=$global:unDoStatus+1

    out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

    start-sleep -seconds 5

    #EXIT #Debug Exit.

    #Now it is time to set the multi valued attributes on the DL in Office 365.
    #Setting these first must occur since moderators have to be established before moderation can be enabled.

    out-logFile -string "Setting the multivalued attributes of the migrated group."

    out-logfile -string $office365DLConfigurationPostMigration.primarySMTPAddress

    try {
        set-Office365DLMV -originalDLConfiguration $originalDLConfiguration -newDLPrimarySMTPAddress $office365DLConfigurationPostMigration.primarySMTPAddress -exchangeDLMembership $exchangeDLMembershipSMTP -exchangeRejectMessage $exchangeRejectMessagesSMTP -exchangeAcceptMessage $exchangeAcceptMessageSMTP -exchangeModeratedBy $exchangeModeratedBySMTP -exchangeManagedBy $exchangeManagedBySMTP -exchangeBypassMOderation $exchangeBypassModerationSMTP -exchangeGrantSendOnBehalfTo $exchangeGrantSendOnBehalfToSMTP -errorAction STOP -groupTypeOverride $groupTypeOverride -exchangeSendAsSMTP $exchangeSendAsSMTP
    }
    catch {
        out-logFile -string $_ -isError:$TRUE
    }

    try {
        $office365DLConfigurationPostMigration = Get-O365DLConfiguration -groupSMTPAddress $originalDLConfiguration.mail -errorAction STOP
    }
    catch {
        out-logfile -string $_ -isError:$TRUE
    }

    out-LogFile -string "Write new DL configuration to XML."

    out-Logfile -string $office365DLConfigurationPostMigration
    out-xmlFile -itemToExport $office365DLConfigurationPostMigration -itemNameToExport $office365DLConfigurationPostMigrationXML

    $global:unDoStatus=$global:unDoStatus+1

    out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

    start-sleep -seconds 5

    #The distribution list has now been created.  There are single value attributes that we're now ready to update.

    try {
        set-Office365DL -originalDLConfiguration $originalDLConfiguration -groupTypeOverride $groupTypeOverride
    }
    catch {
        out-logfile -string $_ -isError:$TRUE
    }

    #EXIT #Debug Exit.

    $global:unDoStatus=$global:unDoStatus+1

    start-sleep -seconds 5

    out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

    out-logFile -string ("Capture the DL status post migration.")

    try {
        $office365DLConfigurationPostMigration = Get-O365DLConfiguration -groupSMTPAddress $originalDLConfiguration.mail -errorAction STOP
    }
    catch {
        out-logfile -string $_ -isError:$TRUE
    }

    out-LogFile -string "Write new DL configuration to XML."

    out-Logfile -string $office365DLConfigurationPostMigration
    out-xmlFile -itemToExport $office365DLConfigurationPostMigration -itemNameToExport $office365DLConfigurationPostMigrationXML

    out-logfile -string "Obtain the migrated DL membership and record it for validation."

    try{
        $office365DLMembershipPostMigration = get-O365DLMembership -groupSMTPAddress $originalDLConfiguration.mail -errorAction STOP
    }
    catch{
        out-LogFile -string $_ -isError:$TRUE
    }

    out-logFile -string "Write the new DL membership to XML."
    out-logfile -string office365DLMembershipPostMigration

    out-xmlFile -itemToExport office365DLMembershipPostMigration -itemNametoExport $office365DLMembershipPostMigrationXML

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

        try {
            set-newDLName -globalCatalogServer $globalCatalogServer -dlName $originalDLConfigurationUpdated.Name -dlSAMAccountName $originalDLConfigurationUpdated.SAMAccountName -dn $originalDLConfigurationUpdated.distinguishedName -adCredential $activeDirectoryCredential -errorAction STOP
        }
        catch {
            out-logfile -string $_ -isError:$TRUE
        }

        $global:unDoStatus=$global:unDoStatus+1

        out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

        try {
            $originalDLConfigurationUpdated = Get-ADObjectConfiguration -groupSMTPAddress $groupSMTPAddress -globalCatalogServer $globalCatalogWithPort -parameterSet $dlPropertySet -errorAction STOP -adCredential $activeDirectoryCredential 
        }
        catch {
            out-logFile -string $_ -isError:$TRUE
        }

        out-logfile -string $originalDLConfigurationUpdated
        out-xmlFile -itemToExport $originalDLConfigurationUpdated -itemNameTOExport $originalDLConfigurationUpdatedXML+$global:unDoStatus

        Out-LogFile -string "Administrator has choosen to regain the original group."
        out-logfile -string "Disabling the mail attributes on the group."

        try{
            Disable-OriginalDL -originalDLConfiguration $originalDLConfigurationUpdated -globalCatalogServer $globalCatalogServer -parameterSet $dlPropertySetToClear -adCredential $activeDirectoryCredential -errorAction STOP
        }
        catch{
            out-LogFile -string $_ -isError:$TRUE
        }

        $global:unDoStatus=$global:unDoStatus+1

        out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

        try {
            $originalDLConfigurationUpdated = Get-ADObjectConfiguration -dn $originalDLConfigurationUpdated.distinguishedName -globalCatalogServer $globalCatalogWithPort -parameterSet $dlPropertySet -errorAction STOP -adCredential $activeDirectoryCredential 
        }
        catch {
            out-logFile -string $_ -isError:$TRUE
        }

        out-logfile -string $originalDLConfigurationUpdated
        out-xmlFile -itemToExport $originalDLConfigurationUpdated -itemNameTOExport $originalDLConfigurationUpdatedXML+$global:unDoStatus

        Out-LogFile -string "Move the original group back to the OU it came from.  The group will no longer be soft matched."

        try {
            move-toNonSyncOU -DN $originalDLConfigurationUpdated.distinguishedName -ou $originalDLConfiguration.distinguishedname.substring($originalDLConfiguration.distinguishedName.indexof("OU")) -globalCatalogServer $globalCatalogServer -adCredential $activeDirectoryCredential
        }
        catch {
            out-logfile -string $_ -isError:$TRUE
        }

        try {
            $tempOU=$originalDLConfiguration.distinguishedName.substring($originalDLConfiguration.distinguishedName.indexof("OU"))
            $tempNameArray=$originalDLConfigurationUpdated.distinguishedName.split(",")
            $tempDN=$tempNameArray[0]+","+$tempOU
            $originalDLConfigurationUpdated = Get-ADObjectConfiguration -dn $tempDN -globalCatalogServer $globalCatalogWithPort -parameterSet $dlPropertySet -errorAction STOP -adCredential $activeDirectoryCredential 
        }
        catch {
            out-logFile -string $_ -isError:$TRUE
        }

        out-logfile -string $originalDLConfigurationUpdated
        out-xmlFile -itemToExport $originalDLConfigurationUpdated -itemNameTOExport $originalDLConfigurationUpdatedXML+$global:unDoStatus

        $global:unDoStatus=$global:unDoStatus+1

        out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())
    }

    #Now it is time to create the routing contact.

    try {
        new-routingContact -originalDLConfiguration $originalDLConfiguration -office365DlConfiguration $office365DLConfigurationPostMigration -globalCatalogServer $globalCatalogServer -adCredential $activeDirectoryCredential
    }
    catch {
        out-logfile -string $_ -isError:$TRUE
    }

    try {
        $tempOU=$originalDLConfiguration.distinguishedName.substring($originalDLConfiguration.distinguishedName.indexof("OU"))
        out-logfile -string $tempOU
        $tempName=$originalDLConfiguration.cn
        out-logfile -string $tempName
        $tempName=$tempname.replace(' ','')
        out-logfile -string $tempname
        $tempName=$tempName+"-MigratedByScript"
        out-logfile -string $tempName
        $tempName="CN="+$tempName
        out-logfile -string $tempName
        $tempDN=$tempName+","+$tempOU
        out-logfile -string $tempDN
        $routingContactConfiguration = Get-ADObjectConfiguration -dn $tempDN -globalCatalogServer $globalCatalogWithPort -parameterSet $dlPropertySet -errorAction STOP -adCredential $activeDirectoryCredential 
    }
    catch {
        out-logFile -string $_ -isError:$TRUE
    }

    out-logfile -string $routingContactConfiguration
    out-xmlFile -itemToExport $routingContactConfiguration -itemNameTOExport $routingContactXML

    $global:unDoStatus=$global:unDoStatus+1

    out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

    #At this time the contact is created - issuing a replication of domain controllers and sleeping one minute.
    #We've gotta get the contact pushed out so that cross domain operations function - otherwise reconciling memership fails becuase the contacts not available.

    out-logfile -string "Starting sleep before invoking AD replication - 15 seconds."
    start-sleep -seconds 15
    out-logfile -string "Invoking AD replication."

    try {
        invoke-ADReplication -globalCatalogServer $globalCatalogServer -powershellSessionName $ADGlobalCatalogPowershellSessionName -errorAction STOP
    }
    catch {
        out-logfile -string $_ -isError:$TRUE
    }

    $forLoopCounter=0 #Restting loop counter for next series of operations.

    #At this time we are ready to begin resetting the on premises dependencies.

    out-logfile -string ("Starting on premies DL members.")

    if ($allGroupsMemberOf.count -gt 0)
    {
        foreach ($member in $allGroupsMemberOf)
        {  
            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            out-logfile -string ("Processing member = "+$member.canonicalName)
            out-logfile -string ("Routing contact DN = "+$routingContactConfiguration.distinguishedName)
            out-logfile -string ("Attribute Operation = "+$onPremMemberOf)

            if ($member.distinguishedName -ne $originalDLConfiguration.distinguishedName)
            {
                try{
                    start-replaceOnPrem -routingContact $routingContactConfiguration -attributeOperation $onPremMemberOf -canonicalObject $member -adCredential $activeDirectoryCredential -globalCatalogServer $globalCatalogServer -errorAction STOP
                }
                catch{
                    out-logfile -string $_ -isError:$TRUE
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

    $global:unDoStatus=$global:unDoStatus+1

    out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

    out-logfile -string ("Starting on premises reject messages from.")

    if ($allGroupsReject.Count -gt 0)
    {
        foreach ($member in $allGroupsReject)
        {  
            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            out-logfile -string ("Processing member = "+$member.canonicalName)
            out-logfile -string ("Routing contact DN = "+$routingContactConfiguration.distinguishedName)
            out-logfile -string ("Attribute Operation = "+$onPremUnAuthOrig)

            if ($member.distinguishedname -ne $originalDLConfiguration.distinguishedname)
            {
                try{
                    start-replaceOnPrem -routingContact $routingContactConfiguration -attributeOperation $onPremUnAuthOrig -canonicalObject $member -adCredential $activeDirectoryCredential -globalCatalogServer $globalCatalogServer -errorAction STOP
                }
                catch{
                    out-logfile -string $_ -isError:$TRUE
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

    $global:unDoStatus=$global:unDoStatus+1

    out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

    out-logfile -string ("Starting on premises accept messages from.")

    if ($allGroupsAccept.Count -gt 0)
    {
        foreach ($member in $allGroupsAccept)
        {  
            out-logfile -string ("Processing member = "+$member.canonicalName)
            out-logfile -string ("Routing contact DN = "+$routingContactConfiguration.distinguishedName)
            out-logfile -string ("Attribute Operation = "+$onPremAuthOrig)

            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            if ($member.distinguishedName -ne $originalDLConfiguration.distinguishedname)
            {
                try{
                    start-replaceOnPrem -routingContact $routingContactConfiguration -attributeOperation $onPremAuthOrig -canonicalObject $member -adCredential $activeDirectoryCredential -globalCatalogServer $globalCatalogServer -errorAction STOP
                }
                catch{
                    out-logfile -string $_ -isError:$TRUE
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

    $global:unDoStatus=$global:unDoStatus+1

    out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

    out-logfile -string ("Starting on premises bypass moderation.")

    if ($allGroupsBypassModeration.Count -gt 0)
    {
        foreach ($member in $allGroupsBypassModeration)
        {  
            out-logfile -string ("Processing member = "+$member.canonicalName)
            out-logfile -string ("Routing contact DN = "+$routingContactConfiguration.distinguishedName)
            out-logfile -string ("Attribute Operation = "+$onPremmsExchBypassModerationLink)

            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            if ($member.distinguishedname -ne $originalDLConfiguration.distinguishedName)
            {
                try{
                    start-replaceOnPrem -routingContact $routingContactConfiguration -attributeOperation $onPremmsExchBypassModerationLink -canonicalObject $member -adCredential $activeDirectoryCredential -globalCatalogServer $globalCatalogServer -errorAction STOP
                }
                catch{
                    out-logfile -string $_ -isError:$TRUE
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

    $global:unDoStatus=$global:unDoStatus+1

    out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())
    
    out-logfile -string ("Starting on premises grant send on behalf to.")

    if ($allGroupsGrantSendOnBehalfTo.Count -gt 0)
    {
        foreach ($member in $allGroupsGrantSendOnBehalfTo)
        {  
            out-logfile -string ("Processing member = "+$member.canonicalName)
            out-logfile -string ("Routing contact DN = "+$routingContactConfiguration.distinguishedName)
            out-logfile -string ("Attribute Operation = "+$onPremPublicDelegate)

            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            if ($member.distinguishedname -ne $originalDLConfiguration.distinguishedname)
            {
                try{
                    start-replaceOnPrem -routingContact $routingContactConfiguration -attributeOperation $onPremPublicDelegate -canonicalObject $member -adCredential $activeDirectoryCredential -globalCatalogServer $globalCatalogServer -errorAction STOP
                }
                catch{
                    out-logfile -string $_ -isError:$TRUE
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

    $global:unDoStatus=$global:unDoStatus+1

    out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

    #Managed by is a unique animal.
    #Managed by is represented by the single valued AD attribute and the multi-evalued exchange attribute.
    #From an exchange standpoint - as long as the member is in one of them it works.
    #We will use the multi-valued attriute so we can recycle the same code.

    out-logfile -string ("Starting on premises managed by.")

    if ($allGroupsManagedBy.Count -gt 0)
    {
        foreach ($member in $allGroupsManagedBy)
        {  
            out-logfile -string ("Processing member = "+$member.canonicalName)
            out-logfile -string ("Routing contact DN = "+$routingContactConfiguration.distinguishedName)
            out-logfile -string ("Attribute Operation = "+$onPremMSExchCoManagedByLink)

            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            if ($member.distinguishedname -ne $originalDLConfiguration.distinguishedname)
            {
                try{
                    start-replaceOnPrem -routingContact $routingContactConfiguration -attributeOperation $onPremMSExchCoManagedByLink -canonicalObject $member -adCredential $activeDirectoryCredential -globalCatalogServer $globalCatalogServer -errorAction STOP
                }
                catch{
                    out-logfile -string $_ -isError:$TRUE
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

    $global:unDoStatus=$global:unDoStatus+1

    out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

    #Forwarding address is a single value replacemet.
    #Created separate function for single values and have called that function here.

    out-logfile -string ("Starting on premises forwarding.")

    if ($allUsersForwardingAddress.Count -gt 0)
    {
        foreach ($member in $allUsersForwardingAddress)
        {  
            out-logfile -string ("Processing member = "+$member.canonicalName)
            out-logfile -string ("Routing contact DN = "+$routingContactConfiguration.distinguishedName)
            out-logfile -string ("Attribute Operation = "+$onPremAltRecipient)

            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try{
                start-replaceOnPremSV -routingContact $routingContactConfiguration -attributeOperation $onPremAltRecipient -canonicalObject $member -adCredential $activeDirectoryCredential -globalCatalogServer $globalCatalogServer -errorAction STOP
            }
            catch{
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }
    else 
    {
        out-logfile -string "No on premsies grant send on behalf to evaluate."    
    }

    $global:unDoStatus=$global:unDoStatus+1

    out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

    #It's now time to beging updating the individual office 365 distribution groups that had dependencies on the migrated groups.

    $forLoopCounter=0 #Resetting loop counter now that we're switching to cloud operations.

    out-logfile -string "Processing Office 365 Accept Messages From"

    if ($allOffice365Accept.count -gt 0)
    {
        foreach ($member in $allOffice365Accept)
        {
            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try{
                start-ReplaceOffice365 -office365Attribute $office365AcceptMessagesFrom -office365Member $member -groupSMTPAddress $groupSMTPAddress -errorAction STOP
            }
            catch{
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }
    else 
    {
        out-LogFile -string "There were no Office 365 groups with accept permissions."    
    }

    $global:unDoStatus=$global:unDoStatus+1

    out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

    out-logfile -string "Processing Office 365 Reject Messages From"

    if ($allOffice365Reject.count -gt 0)
    {
        foreach ($member in $allOffice365Reject)
        {
            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try{
                start-ReplaceOffice365 -office365Attribute $office365RejectMessagesFrom -office365Member $member -groupSMTPAddress $groupSMTPAddress -errorAction STOP
            }
            catch{
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }
    else 
    {
        out-LogFile -string "There were no Office 365 groups with reject permissions."    
    }

    $global:unDoStatus=$global:unDoStatus+1

    out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

    out-logfile -string "Processing Office 365 Bypass Moderation From Users"

    if ($allOffice365BypassModeration.count -gt 0)
    {
        foreach ($member in $allOffice365BypassModeration)
        {
            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try{
                start-ReplaceOffice365 -office365Attribute $office365BypassModerationusers -office365Member $member -groupSMTPAddress $groupSMTPAddress -errorAction STOP
            }
            catch{
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }
    else 
    {
        out-LogFile -string "There were no Office 365 groups with bypass moderation permissions."    
    }

    $global:unDoStatus=$global:unDoStatus+1

    out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

    out-logfile -string "Processing Office 365 Grant Send On Behalf To Users"

    if ($allOffice365GrantSendOnBehalfTo.count -gt 0)
    {
        foreach ($member in $allOffice365GrantSendOnBehalfTo)
        {
            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try{
                start-ReplaceOffice365 -office365Attribute $office365GrantSendOnBehalfTo -office365Member $member -groupSMTPAddress $groupSMTPAddress -errorAction STOP
            }
            catch{
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }
    else 
    {
        out-LogFile -string "There were no Office 365 groups with grant send on behalf to permissions."    
    }

    $global:unDoStatus=$global:unDoStatus+1

    out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

    out-logfile -string "Processing Office 365 Bypass Moderation From Users"

    if ($allOffice365BypassModeration.count -gt 0)
    {
        foreach ($member in $allOffice365BypassModeration)
        {
            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try{
                start-ReplaceOffice365 -office365Attribute $office365BypassModerationusers -office365Member $member -groupSMTPAddress $groupSMTPAddress -errorAction STOP
            }
            catch{
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }
    else 
    {
        out-LogFile -string "There were no Office 365 groups with bypass moderation permissions."    
    }

    $global:unDoStatus=$global:unDoStatus+1

    out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

    out-logfile -string "Processing Office 365 Managed By"

    if ($allOffice365ManagedBy.count -gt 0)
    {
        foreach ($member in $allOffice365ManagedBy)
        {
            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try{
                start-ReplaceOffice365 -office365Attribute $office365ManagedBy -office365Member $member -groupSMTPAddress $groupSMTPAddress -errorAction STOP
            }
            catch{
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }
    else 
    {
        out-LogFile -string "There were no Office 365 managed by permissions."    
    }

    $global:unDoStatus=$global:unDoStatus+1

    out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

    #Start the process of updating the unified group dependencies.

    out-logfile -string "Processing Office 365 Unified Accept From"

    if ($allOffice365UniversalAccept.count -gt 0)
    {
        foreach ($member in $allOffice365UniversalAccept)
        {
            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try{
                start-ReplaceOffice365Unified -office365Attribute $office365UnifiedAccept -office365Member $member -groupSMTPAddress $groupSMTPAddress -errorAction STOP
            }
            catch{
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }
    else 
    {
        out-LogFile -string "There were no Office 365 accept from permissions."    
    }

    $global:unDoStatus=$global:unDoStatus+1

    out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

    out-logfile -string "Processing Office 365 Unified Reject From"

    if ($allOffice365UniversalReject.count -gt 0)
    {
        foreach ($member in $allOffice365UniversalReject)
        {
            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try{
                start-ReplaceOffice365Unified -office365Attribute $office365UnifiedReject -office365Member $member -groupSMTPAddress $groupSMTPAddress -errorAction STOP
            }
            catch{
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }
    else 
    {
        out-LogFile -string "There were no Office 365 reject from permissions."    
    }

    $global:unDoStatus=$global:unDoStatus+1

    out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

    out-logfile -string "Processing Office 365 Grant Send On Behalf To"

    if ($allOffice365UniversalGrantSendOnBehalfTo.count -gt 0)
    {
        foreach ($member in $allOffice365UniversalGrantSendOnBehalfTo)
        {
            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            try{
                start-ReplaceOffice365Unified -office365Attribute $office365GrantSendOnBehalfTo -office365Member $member -groupSMTPAddress $groupSMTPAddress -errorAction STOP
            }
            catch{
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }
    else 
    {
        out-LogFile -string "There were no Office 365 grant send on behalf to permissions."    
    }

    $global:unDoStatus=$global:unDoStatus+1

    out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

    #Process any group memberships to the service.

    out-logfile -string ("Adding migrated group to any cloud only groups.")

    if ($allOffice365MemberOf.count -gt 0)
    {
        out-logfile -string "Adding cloud only group member."

        foreach ($member in $allOffice365MemberOf )
        {
            if ($forLoopCounter -eq 1000)
            {
                out-logFile -string "Throttling for 5 seconds at 1000 operations."
                start-sleep -seconds 5
                $forLoopCounter = 0
            }
            else 
            {
                $forLoopCounter++    
            }

            out-logfile -string ("Processing group = "+$member.primarySMTPAddress)
            try {
                start-replaceOffice365Members -office365Group $member -groupSMTPAddress $groupSMTPAddress -errorAction STOP
            }
            catch {
                out-logfile -string $_ -isError:$TRUE
            }
        }
    }
    else 
    {
        out-logfile -string "No cloud only groups had the migrated group as a member."
    }
    
    $global:unDoStatus=$global:unDoStatus+1

    out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

    out-logFile -string "Start replacing Office 365 permissions."

    try 
    {
        set-Office365DLPermissions -allSendAs $allOffice365SendAsAccess -allFullMailboxAccess $allOffice365FullMailboxAccess
    }
    catch 
    {
        out-logfile -string "Unable to set office 365 send as or full mailbox access permissions."
        out-logfile -string $_ -isError:$TRUE
    }

    if ($enableHybridMailflow -eq $TRUE)
    {
        #The first step is to upgrade the contact to a full mail contact and remove the target address from proxy addresses.

        out-logfile -string "The administrator has enabled hybrid mail flow."

        try{
            Enable-MailRoutingContact -globalCatalogServer $globalCatalogServer -routingContactConfig $routingContactConfiguration
        }
        catch{
            out-logfile -string $_ -isError:$TRUE
        }

        $global:unDoStatus=$global:unDoStatus+1

        out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

        #The mail contact has been created and upgrade.  Now we need to capture the updated configuration.

        try{
            $routingContactConfiguration = Get-ADObjectConfiguration -dn $tempDN -globalCatalogServer $globalCatalogWithPort -parameterSet $dlPropertySet -errorAction STOP -adCredential $activeDirectoryCredential 
        }
        catch{
            out-logfile -string $_ -isError:$TRUE
        }

        out-logfile -string $routingContactConfiguration
        out-xmlFile -itemToExport $routingContactConfiguration -itemNameTOExport $routingContactXML+$global:unDoStatus

        #The routing contact configuration has been updated and retained.
        #Now create the dynamic distribution group.  This gives us our address book object and our proxy addressed object that cannot collide with the previous object migrated.

        out-logfile -string "Enabling the dynamic distribution group to complete the mail routing scenario."

        try{
            Enable-MailDyamicGroup -globalCatalogServer $globalCatalogServer -originalDLConfiguration $originalDLConfiguration -routingContactConfig $routingContactConfiguration
        }
        catch{
            out-logfile -string $_ -isError:$TRUE
        }

        $global:unDoStatus=$global:unDoStatus+1

        out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

        try{
            $routingDynamicGroupConfig = $originalDLConfiguration = Get-ADObjectConfiguration -groupSMTPAddress $groupSMTPAddress -globalCatalogServer $globalCatalogWithPort -parameterSet $dlPropertySet -errorAction STOP -adCredential $activeDirectoryCredential
        }
        catch{
            out-logFile -string "Error obtaining dynamic group information post creation."
        }

        out-logfile -string $routingDynamicGroupConfig
        out-xmlfile -itemToExport $routingDynamicGroupConfig -itemNameToExport $routingDynamicGroupXML
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
            start-upgradeToOffice365Group -groupSMTPAddress $groupSMTPAddress
        }
        catch{
            out-logfile -string $_ -isError:$TRUE
        }
    }

    $global:unDoStatus=$global:unDoStatus+1

    out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

    #If the administrator has selected to not retain the group - remove it.

    if ($retainOriginalGroup -eq $FALSE)
    {
        out-logfile -string "Deleting the original group."

        remove-OnPremGroup -globalCatalogServer $globalCatalogServer -originalDLConfiguration $originalDLConfigurationUpdated -adCredential $activeDirectoryCredential -errorAction STOP
    }

    $global:unDoStatus=$global:unDoStatus+1

    out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

    #Trigger ad replication and triggering AD connect for all final updates.

    out-logfile -string "Starting sleep before invoking AD replication - 15 seconds."
    start-sleep -seconds 15
    out-logfile -string "Invoking AD replication."

    try {
        invoke-ADReplication -globalCatalogServer $globalCatalogServer -powershellSessionName $ADGlobalCatalogPowershellSessionName -errorAction STOP
    }
    catch {
        out-logfile -string $_ -isError:$TRUE
    }

    #Start the process of syncing the deletion to the cloud if the administrator has provided credentials.
    #Note:  If this is not done we are subject to sitting and waiting for it to complete.

    if ($useAADConnect -eq $TRUE)
    {
        out-logfile -string "Starting sleep before invoking AD Connect - one minute."
        start-sleep -seconds 30
        out-logfile -string "Invoking AD Connect."

        start-sleep -s 5
        invoke-ADConnect -powerShellSessionName $aadConnectPowershellSessionName
    }
    else 
    {
        out-logfile -string "AD Connect information not specified - allowing ad connect to run on normal cycle and process deletion."    
    }

    out-logfile -string "Calling function to disconnect all powershell sessions."

    disable-allPowerShellSessions

    Out-LogFile -string "================================================================================"
    Out-LogFile -string "END START-DISTRIBUTIONLISTMIGRATION"
    Out-LogFile -string "================================================================================"

    #Archive the files into a date time success folder.

    Start-ArchiveFiles -isSuccess:$TRUE -logFolderPath $logFolderPath
}
