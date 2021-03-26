
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

Function Start-DistributionListMigration 
{
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
        [string]$exchangeOnlineCertificateThumbPrint=$NULL,
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
        [string]$groupTypeOverride="None"
    )

    #Define global variables.

    $global:logFile=$NULL #This is the global variable for the calculated log file name
    $global:staticFolderName="\DLMigration"
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
    [array]$exchangeDLMembershipSMTP=@() #Array of DL membership from AD.
    [array]$exchangeRejectMessagesSMTP=@() #Array of members with reject permissions from AD.
    [array]$exchangeAcceptMessageSMTP=@() #Array of members with accept permissions from AD.
    [array]$exchangeManagedBySMTP=@() #Array of members with manage by rights from AD.
    [array]$exchangeModeratedBySMTP=@() #Array of members  with moderation rights.
    [array]$exchangeBypassModerationSMTP=@() #Array of objects with bypass moderation rights from AD.
    [array]$exchangeGrantSendOnBehalfToSMTP=@()

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
    [string]$allGroupsMemberOfXML = "allGroupsMemberOfXML"
    [string]$allGroupsRejectXML = "allGroupsRejectXML"
    [string]$allGroupsAcceptXML = "allGroupsAcceptXML"
    [string]$allGroupsBypassModerationXML = "allGroupsBypassModerationXML"
    [string]$allUsersForwardingAddressXML = "allUsersForwardingAddressXML"
    [string]$allGroupsGrantSendOnBehalfToXML = "allGroupsGrantSendOnBehalfToXML"
    [string]$allGroupsManagedByXML = "allGroupsManagedByXML"
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

    #The following variables hold information regarding other groups in the environment that have dependnecies on the group to be migrated.

    [array]$allGroupsMemberOf=$NULL #Complete AD information for all groups the migrated group is a member of.
    [array]$allGroupsReject=$NULL #Complete AD inforomation for all groups that the migrated group has reject mesages from.
    [array]$allGroupsAccept=$NULL #Complete AD information for all groups that the migrated group has accept messages from.
    [array]$allGroupsBypassModeration=$NULL #Complete AD information for all groups that the migrated group has bypass moderations.
    [array]$allUsersForwardingAddress=$NULL #All users on premsies that have this group as a forwarding DN.
    [array]$allGroupsGrantSendOnBehalfTo=$NULL #All dependencies on premsies that have grant send on behalf to.
    [array]$allGroupsManagedBy=$NULL

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

    #The following are the cloud parameters we query for to look for dependencies.

    [string]$office365AcceptMessagesFrom="AcceptMessagesOnlyFromDLMembers"
    [string]$office365BypassModerationFrom="BypassModerationFromDLMembers"
    [string]$office365CoManagers="CoManagedBy"
    [string]$office365GrantSendOnBehalfTo="GrantSendOnBehalfTo"
    [string]$office365ManagedBy="ManagedBy"
    [string]$office365Members="Members"
    [string]$office365RejectMessagesFrom="RejectMessagesFromDLMembers"
    [string]$office365ForwardingAddress="ForwardingAddress"

    #Cloud variables for the distribution list to be migrated.

    $office365DLConfiguration = $NULL #This holds the office 365 DL configuration for the group to be migrated.
    $office365DLConfigurationPostMigration = $NULL
    $office365DLMembershipPostMigration=$NULL

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

    Out-LogFile -string "Validating that Exchange Credentials are not specified with Exchange Certificate Thumbprint"

    if (($exchangeOnlineCredential -ne $NULL) -and ($exchangeOnlineCertificateThumbPrint -ne ""))
    {
        Out-LogFile -string "ERROR:  Only one method of cloud authentication can be specified.  Use either cloud credentials or cloud certificate thumbprint." -isError:$TRUE
    }
    else
    {
        Out-LogFile -string "Only one method of Exchange Online authentication specified."
    }

    #Validate that an OU was specified <if> retain group is not set to true.

    Out-LogFile -string "Validating that if retain original group is false a non-sync OU is specified."

    if (($retainOriginalGroup -eq $FALSE) -and ($dnNoSyncOU -eq "NotSet"))
    {
        out-LogFile -string "A no SYNC OU is required if retain original group is false." -isError:$TRUE
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

       New-ExchangeOnlinePowershellSession -exchangeOnlineCredentials $exchangeOnlineCredential
   }

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
    }
    else
    {
        Out-LogFile -string "No on premises Exchange specified - skipping setup of powershell session."
    }

    #If the administrator has specified aad connect information - establish the powershell session.

    Out-LogFile -string "Determine if AAD Connect information specified and establish session if necessary."

    if ($useAADConnect -eq $TRUE)
    {
        New-PowershellSession -Server $aadConnectServer -Credentials $aadConnectCredential -PowershellSessionName $aadConnectPowershellSessionName
    }

    #Establish powershell session to the global catalog server.

    Out-LogFile -string "Establish powershell session to the global catalog server specified."

    new-powershellsession -server $globalCatalogServer -credentials $activeDirectoryCredential -powershellsessionname $ADGlobalCatalogPowershellSessionName

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
            try 
            {
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
    out-logfile -string "/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"


    #Exit #Debug Exit.

    #At this point we have obtained all the information relevant to the individual group.
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

    if ($exchangeRejectMessagesSMTP -ne $NULL)
    {
        out-xmlfile -itemtoexport $exchangeRejectMessagesSMTP -itemNameToExport $exchangeRejectMessagesSMTPXML
    }

    if ($exchangeAcceptMessageSMTP -ne $NULL)
    {
        out-xmlfile -itemtoexport $exchangeAcceptMessageSMTP -itemNameToExport $exchangeAcceptMessagesSMTPXML
    }

    if ($exchangeManagedBySMTP -ne $NULL)
    {
        out-xmlfile -itemtoexport $exchangeManagedBySMTP -itemNameToExport $exchangeManagedBySMTPXML
    }

    if ($exchangeModeratedBySMTP -ne $NULL)
    {
        out-xmlfile -itemtoexport $exchangeModeratedBySMTP -itemNameToExport $exchangeModeratedBySMTPXML
    }

    if ($exchangeBypassModerationSMTP -ne $NULL)
    {
        out-xmlfile -itemtoexport $exchangeBypassModerationSMTP -itemNameToExport $exchangeBypassModerationSMTPXML
    }

    if ($exchangeGrantSendOnBehalfToSMTP -ne $NULL)
    {
        out-xmlfile -itemToExport $exchangeGrantSendOnBehalfToSMTP -itemNameToExport $exchangeGrantSendOnBehalfToSMTPXML
    }

    if ($allGroupsMemberOf -ne $NULL)
    {
        out-xmlfile -itemtoexport $allGroupsMemberOf -itemNameToExport $allGroupsMemberOfXML
    }
    
    if ($allGroupsReject -ne $NULL)
    {
        out-xmlfile -itemtoexport $allGroupsReject -itemNameToExport $allGroupsRejectXML
    }
    
    if ($allGroupsAccept -ne $NULL)
    {
        out-xmlfile -itemtoexport $allGroupsAccept -itemNameToExport $allGroupsAcceptXML
    }

    if ($allGroupsBypassModeration -ne $NULL)
    {
        out-xmlfile -itemtoexport $allGroupsBypassModeration -itemNameToExport $allGroupsBypassModerationXML
    }

    if ($allUsersForwardingAddress -ne $NULL)
    {
        out-xmlFile -itemToExport $allUsersForwardingAddress -itemNameToExport $allUsersForwardingAddressXML
    }

    if ($allGroupsManagedBy -ne $NULL)
    {
        out-xmlFile -itemToExport $allGroupsManagedBy -itemNameToExport $allGroupsManagedByXML
    }

    if ($allGroupsGrantSendOnBehalfTo -ne $NULL)
    {
        out-xmlFile -itemToExport $allGroupsGrantSendOnBehalfTo -itemNameToExport $allGroupsGrantSendOnBehalfToXML
    }

    #EXIT #Debug Exit
    
    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "BEGIN VALIDATE RECIPIENTS IN CLOUD"
    Out-LogFile -string "********************************************************************************"
    
    if ($exchangeDLMembershipSMTP -ne $NULL)
    {
        out-logfile -string "Ensuring each DL member is in Office 365 / Exchange Online"

        foreach ($member in $exchangeDLMembershipSMTP)
        {
            out-LogFile -string "Testing"
            out-logfile -string $member

            if (($member.externalDirectoryObjectID -ne $NULL) -and ($member.recipientOrUser -eq "Recipient"))
            {
                out-LogFile -string "Testing based on External Directory Object ID"
                out-logfile -string $member.ExternalDirectoryObjectID
                out-logfile -string $member.recipientOrUser

                try {
                    test-o365Recipient -externalDirectoryObjectID $member.externalDirectoryObjectID -recipientSMTPAddress "None" -userPrincipalName "None" -errorAction STOP
                }
                catch {
                    out-logFile -string $_ -isError:$TRUE
                }
            }
            elseif (($member.PrimarySMTPAddressOrUPN -ne $NULL) -and ($member.recipientoruser -eq "Recipient"))
            {
                out-LogFile -string "Testing based on Primary SMTP Address"
                out-logfile -string $member.PrimarySMTPAddressOrUPN
                out-logfile -string $member.recipientOrUser

                try {
                    test-o365Recipient -externalDirectoryObjectID "None" -recipientSMTPAddress $member.PrimarySMTPAddressOrUPN -userPrincipalName "None" -errorAction STOP
                }
                catch {
                    out-logfile -string $_ -isError:$TRUE
                }
            }
            elseif (($member.PrimarySMTPAddressOrUPN -ne $NULL) -and ($member.recipientoruser -eq "User"))
            {
                out-LogFile -string "Testing based on user principal name."
                out-logfile -string $member.PrimarySMTPAddressOrUPN
                out-logfile -string $member.recipientOrUser

                try {
                    test-o365Recipient -externalDirectoryObjectID "None" -recipientSMTPAddress "None" -userPrincipalName $member.PrimarySMTPAddressOrUPN -errorAction STOP
                }
                catch {
                    out-logfile -string $_ -isError:$TRUE
                }
            }
        }
    }

    if ($exchangeRejectMessagesSMTP -ne $NULL)
    {
        out-logfile -string "Ensuring each reject messages member is in Office 365 / Exchange Online"

        foreach ($member in $exchangeRejectMessagesSMTP)
        {
            out-LogFile -string "Testing"
            out-logfile -string $member

            if (($member.externalDirectoryObjectID -ne $NULL) -and ($member.recipientOrUser -eq "Recipient"))
            {
                out-LogFile -string "Testing based on External Directory Object ID"
                out-logfile -string $member.ExternalDirectoryObjectID
                out-logfile -string $member.recipientOrUser

                try {
                    test-o365Recipient -externalDirectoryObjectID $member.externalDirectoryObjectID -recipientSMTPAddress "None" -userPrincipalName "None" -errorAction STOP
                }
                catch {
                    out-logFile -string $_ -isError:$TRUE
                }
            }
            elseif (($member.PrimarySMTPAddressOrUPN -ne $NULL) -and ($member.recipientoruser -eq "Recipient"))
            {
                out-LogFile -string "Testing based on Primary SMTP Address"
                out-logfile -string $member.PrimarySMTPAddressOrUPN
                out-logfile -string $member.recipientOrUser

                try {
                    test-o365Recipient -externalDirectoryObjectID "None" -recipientSMTPAddress $member.PrimarySMTPAddressOrUPN -userPrincipalName "None" -errorAction STOP
                }
                catch {
                    out-logfile -string $_ -isError:$TRUE
                }
            }
            elseif (($member.PrimarySMTPAddressOrUPN -ne $NULL) -and ($member.recipientoruser -eq "User"))
            {
                out-LogFile -string "Testing based on user principal name."
                out-logfile -string $member.PrimarySMTPAddressOrUPN
                out-logfile -string $member.recipientOrUser

                try {
                    test-o365Recipient -externalDirectoryObjectID "None" -recipientSMTPAddress "None" -userPrincipalName $member.PrimarySMTPAddressOrUPN -errorAction STOP
                }
                catch {
                    out-logfile -string $_ -isError:$TRUE
                }
            }
        }
    }

    if ($exchangeAcceptMessageSMTP -ne $NULL)
    {
        out-logfile -string "Ensuring each accept messages member is in Office 365 / Exchange Online"

        foreach ($member in $exchangeAcceptMessageSMTP)
        {
            out-LogFile -string "Testing"
            out-logfile -string $member

            if (($member.externalDirectoryObjectID -ne $NULL) -and ($member.recipientOrUser -eq "Recipient"))
            {
                out-LogFile -string "Testing based on External Directory Object ID"
                out-logfile -string $member.ExternalDirectoryObjectID
                out-logfile -string $member.recipientOrUser

                try {
                    test-o365Recipient -externalDirectoryObjectID $member.externalDirectoryObjectID -recipientSMTPAddress "None" -userPrincipalName "None" -errorAction STOP
                }
                catch {
                    out-logFile -string $_ -isError:$TRUE
                }
            }
            elseif (($member.PrimarySMTPAddressOrUPN -ne $NULL) -and ($member.recipientoruser -eq "Recipient"))
            {
                out-LogFile -string "Testing based on Primary SMTP Address"
                out-logfile -string $member.PrimarySMTPAddressOrUPN
                out-logfile -string $member.recipientOrUser

                try {
                    test-o365Recipient -externalDirectoryObjectID "None" -recipientSMTPAddress $member.PrimarySMTPAddressOrUPN -userPrincipalName "None" -errorAction STOP
                }
                catch {
                    out-logfile -string $_ -isError:$TRUE
                }
            }
            elseif (($member.PrimarySMTPAddressOrUPN -ne $NULL) -and ($member.recipientoruser -eq "User"))
            {
                out-LogFile -string "Testing based on user principal name."
                out-logfile -string $member.PrimarySMTPAddressOrUPN
                out-logfile -string $member.recipientOrUser

                try {
                    test-o365Recipient -externalDirectoryObjectID "None" -recipientSMTPAddress "None" -userPrincipalName $member.PrimarySMTPAddressOrUPN -errorAction STOP
                }
                catch {
                    out-logfile -string $_ -isError:$TRUE
                }
            }
        }
    }

    if ($exchangeManagedBySMTP -ne $NULL)
    {
        out-logfile -string "Ensuring each managedBy messages member is in Office 365 / Exchange Online"

        foreach ($member in $exchangeManagedBySMTP)
        {
            out-LogFile -string "Testing"
            out-logfile -string $member

            if (($member.externalDirectoryObjectID -ne $NULL) -and ($member.recipientOrUser -eq "Recipient"))
            {
                out-LogFile -string "Testing based on External Directory Object ID"
                out-logfile -string $member.ExternalDirectoryObjectID
                out-logfile -string $member.recipientOrUser

                try {
                    test-o365Recipient -externalDirectoryObjectID $member.externalDirectoryObjectID -recipientSMTPAddress "None" -userPrincipalName "None" -errorAction STOP
                }
                catch {
                    out-logFile -string $_ -isError:$TRUE
                }
            }
            elseif (($member.PrimarySMTPAddressOrUPN -ne $NULL) -and ($member.recipientoruser -eq "Recipient"))
            {
                out-LogFile -string "Testing based on Primary SMTP Address"
                out-logfile -string $member.PrimarySMTPAddressOrUPN
                out-logfile -string $member.recipientOrUser

                try {
                    test-o365Recipient -externalDirectoryObjectID "None" -recipientSMTPAddress $member.PrimarySMTPAddressOrUPN -userPrincipalName "None" -errorAction STOP
                }
                catch {
                    out-logfile -string $_ -isError:$TRUE
                }
            }
            elseif (($member.PrimarySMTPAddressOrUPN -ne $NULL) -and ($member.recipientoruser -eq "User"))
            {
                out-LogFile -string "Testing based on user principal name."
                out-logfile -string $member.PrimarySMTPAddressOrUPN
                out-logfile -string $member.recipientOrUser

                try {
                    test-o365Recipient -externalDirectoryObjectID "None" -recipientSMTPAddress "None" -userPrincipalName $member.PrimarySMTPAddressOrUPN -errorAction STOP
                }
                catch {
                    out-logfile -string $_ -isError:$TRUE
                }
            }
        }
    }

    if ($exchangeModeratedBySMTP -ne $NULL)
    {
        out-logfile -string "Ensuring each moderatedby member is in Office 365 / Exchange Online"

        foreach ($member in $exchangeModeratedBySMTP)
        {
            out-LogFile -string "Testing"
            out-logfile -string $member

            if (($member.externalDirectoryObjectID -ne $NULL) -and ($member.recipientOrUser -eq "Recipient"))
            {
                out-LogFile -string "Testing based on External Directory Object ID"
                out-logfile -string $member.ExternalDirectoryObjectID
                out-logfile -string $member.recipientOrUser

                try {
                    test-o365Recipient -externalDirectoryObjectID $member.externalDirectoryObjectID -recipientSMTPAddress "None" -userPrincipalName "None" -errorAction STOP
                }
                catch {
                    out-logFile -string $_ -isError:$TRUE
                }
            }
            elseif (($member.PrimarySMTPAddressOrUPN -ne $NULL) -and ($member.recipientoruser -eq "Recipient"))
            {
                out-LogFile -string "Testing based on Primary SMTP Address"
                out-logfile -string $member.PrimarySMTPAddressOrUPN
                out-logfile -string $member.recipientOrUser

                try {
                    test-o365Recipient -externalDirectoryObjectID "None" -recipientSMTPAddress $member.PrimarySMTPAddressOrUPN -userPrincipalName "None" -errorAction STOP
                }
                catch {
                    out-logfile -string $_ -isError:$TRUE
                }
            }
            elseif (($member.PrimarySMTPAddressOrUPN -ne $NULL) -and ($member.recipientoruser -eq "User"))
            {
                out-LogFile -string "Testing based on user principal name."
                out-logfile -string $member.PrimarySMTPAddressOrUPN
                out-logfile -string $member.recipientOrUser

                try {
                    test-o365Recipient -externalDirectoryObjectID "None" -recipientSMTPAddress "None" -userPrincipalName $member.PrimarySMTPAddressOrUPN -errorAction STOP
                }
                catch {
                    out-logfile -string $_ -isError:$TRUE
                }
            }
        }
    }

    if ($exchangeBypassModerationSMTP -ne $NULL)
    {
        out-logfile -string "Ensuring each bypass moderation member is in Office 365 / Exchange Online"

        foreach ($member in $exchangeBypassModerationSMTP)
        {
            out-LogFile -string "Testing"
            out-logfile -string $member

            if (($member.externalDirectoryObjectID -ne $NULL) -and ($member.recipientOrUser -eq "Recipient"))
            {
                out-LogFile -string "Testing based on External Directory Object ID"
                out-logfile -string $member.ExternalDirectoryObjectID
                out-logfile -string $member.recipientOrUser

                try {
                    test-o365Recipient -externalDirectoryObjectID $member.externalDirectoryObjectID -recipientSMTPAddress "None" -userPrincipalName "None" -errorAction STOP
                }
                catch {
                    out-logFile -string $_ -isError:$TRUE
                }
            }
            elseif (($member.PrimarySMTPAddressOrUPN -ne $NULL) -and ($member.recipientoruser -eq "Recipient"))
            {
                out-LogFile -string "Testing based on Primary SMTP Address"
                out-logfile -string $member.PrimarySMTPAddressOrUPN
                out-logfile -string $member.recipientOrUser

                try {
                    test-o365Recipient -externalDirectoryObjectID "None" -recipientSMTPAddress $member.PrimarySMTPAddressOrUPN -userPrincipalName "None" -errorAction STOP
                }
                catch {
                    out-logfile -string $_ -isError:$TRUE
                }
            }
            elseif (($member.PrimarySMTPAddressOrUPN -ne $NULL) -and ($member.recipientoruser -eq "User"))
            {
                out-LogFile -string "Testing based on user principal name."
                out-logfile -string $member.PrimarySMTPAddressOrUPN
                out-logfile -string $member.recipientOrUser

                try {
                    test-o365Recipient -externalDirectoryObjectID "None" -recipientSMTPAddress "None" -userPrincipalName $member.PrimarySMTPAddressOrUPN -errorAction STOP
                }
                catch {
                    out-logfile -string $_ -isError:$TRUE
                }
            }
        }
    }
    

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END VALIDATE RECIPIENTS IN CLOUD"
    Out-LogFile -string "********************************************************************************"

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

        out-logfile -string ("The number of universal groups in the Office 365 cloud that the DL has grant send on behalf rights on = "+$allOffice365UniversalGrantSendOnBehalfTo.count)

        if ($allOffice365MemberOf -ne $NULL)
        {
            out-xmlfile -itemtoexport $allOffice365MemberOf -itemNameToExport $allOffice365MemberofXML
        }

        if ($allOffice365Accept -ne $NULL)
        {
            out-xmlFile -itemToExport $allOffice365Accept -itemNameToExport $allOffice365AcceptXML
        }

        if ($allOffice365Reject -ne $NULL)
        {
            out-xmlFile -itemToExport $allOffice365Reject -itemNameToExport $allOffice365RejectXML
        }
        
        if ($allOffice365BypassModeration -ne $NULL)
        {
            out-xmlFile -itemToExport $allOffice365BypassModeration -itemNameToExport $allOffice365BypassModerationXML
        }

        if ($allOffice365GrantSendOnBehalfTo -ne $NULL)
        {
            out-xmlfile -itemToExport $allOffice365GrantSendOnBehalfTo -itemNameToExport $allOffice365GrantSendOnBehalfToXML
        }

        if ($allOffice365ManagedBy -ne $NULL)
        {
            out-xmlFile -itemToExport $allOffice365ManagedBy -itemNameToExport $allOffice365ManagedByXML
        }

        if ($allOffice365ForwardingAddress -ne $NULL)
        {
            out-xmlfile -itemToExport $allOffice365ForwardingAddress -itemNameToExport $allOffice365ForwardingAddressXML
        }

        if ($allOffice365UniversalAccept -ne $NULL)
        {
            out-xmlfile -itemToExport $allOffice365UniversalAccept -itemNameToExport $allOffice365UniversalAcceptXML
        }

        if ($allOffice365UniversalReject -ne $NULL)
        {
            out-xmlFIle -itemToExport $allOffice365UniversalReject -itemNameToExport $allOffice365UniversalRejectXML
        }

        if ($allOffice365UniversalGrantSendOnBehalfTo -ne $NULL)
        {
            out-xmlFile -itemToExport $allOffice365UniversalGrantSendOnBehalfTo -itemNameToExport $allOffice365UniversalGrantSendOnBehalfToXML
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

    out-logfile -string "Starting sleep before invoking AD Connect - one minute."
    start-sleep -seconds 60
    out-logfile -string "Invoking AD Connect."

    try {
        invoke-ADConnect -powerShellSessionName $aadConnectPowershellSessionName -errorAction STOP
    }
    catch {
        out-logfile -string $_ -isError:$TRUE
    }

    out-logfile -string "Sleeping after ad connect instance to allow deletion to process."
    start-sleep -seconds 60
  
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

    $global:unDoStatus=$global:unDoStatus+1

    out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

    start-sleep -seconds 5

    #EXIT #Debug Exit.

    #The distribution list has now been created.  There are single value attributes that we're now ready to update.

    try {
        set-Office365DL -originalDLConfiguration $originalDLConfiguration -groupTypeOverride $groupTypeOverride
    }
    catch {
        out-logfile -string $_ -isError:$TRUE
    }

    $global:unDoStatus=$global:unDoStatus+1

    out-Logfile -string ("Global UNDO Status = "+$global:unDoStatus.tostring())

    start-sleep -seconds 5

    #EXIT #Debug Exit.

    #Now it is time to set the multi valued attributes on the DL in Office 365.

    out-logFile -string "Setting the multivalued attributes of the migrated group."

    try {
        set-Office365DLMV -originalDLConfiguration $originalDLConfiguration -exchangeDLMembership $exchangeDLMembershipSMTP -exchangeRejectMessage $exchangeRejectMessagesSMTP -exchangeAcceptMessage $exchangeAcceptMessageSMTP -exchangeModeratedBy $exchangeModeratedBySMTP -exchangeManagedBy $exchangeManagedBySMTP -exchangeBypassMOderation $exchangeBypassModerationSMTP -exchangeGrantSendOnBehalfTo $exchangeGrantSendOnBehalfToSMTP -errorAction STOP -groupTypeOverride $groupTypeOverride
    }
    catch {
        out-logFile -string $_ -isError:$TRUE
    }

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


    

    Out-LogFile -string "================================================================================"
    Out-LogFile -string "END START-DISTRIBUTIONLISTMIGRATION"
    Out-LogFile -string "================================================================================"
}