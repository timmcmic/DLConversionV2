
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


Function restore-MigratedDistributionList
{
    <#
    .SYNOPSIS

    This function utilizes the migration backup files to re-construct the group on premises to rollback a migration.

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
        #Local Active Director Domain Controller Parameters
        [Parameter(Mandatory = $true)]
        [string]$globalCatalogServer,
        [Parameter(Mandatory = $true)]
        [pscredential]$activeDirectoryCredential,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Basic","Negotiate")]
        $activeDirectoryAuthenticationMethod="Negotiate",
        #Define other mandatory parameters
        [Parameter(Mandatory = $true)]
        [string]$logFolderPath,
        [Parameter(Mandatory = $true)]
        [string]$dataPath
    )

    #================================================================================

    function getRemoveObject
    {
        Param
        (
            #Local Active Director Domain Controller Parameters
            [Parameter(Mandatory = $true)]
            [string]$identity,
            [Parameter(Mandatory = $true)]
            [string]$xmlExportName,
            [Parameter(Mandatory = $false)]
            [boolean]$deleteRequired=$FALSE
        )

        $testADObject = Get-ADObject -filter "mail -eq `"$identity`"" -properties * -server $coreVariables.globalCatalogWithPort.value -credential $activeDirectoryCredential -authType $activeDirectoryAuthenticationMethod -errorAction STOP

        if ($NULL -eq $testADObject)
        {
            out-logfile -string "An object was not located in the directory with the imported mail address - this is ok."
        }
        else
        {
            out-logfile -string "An object was located in the directory with the imported mail address - prompt administrator to remove it later."
            out-xmlFile -itemToExport $testADObject -itemNameToExport $xmlExportName
        }

        out-logfile -string "Prompt administrator to allow for deletion of existing object with the mail address."

        if ($NULL -ne $testADObject)
        {
            if ($deleteRequired -eq $TRUE)
            {
                $promptString = ("Delete the ad object: "+$testADObject.mail+" Type: "+$testADObject.objectClass)

                $adminAnswer = $wshell.popUp($promptString,0,"Remove AD Object Required",32+4)
            }
            else 
            {
                $promptString = ("Delete the ad object: "+$testADObject.mail+" Type: "+$testADObject.objectClass)

                $adminAnswer = $wshell.popUp($promptString,0,"Remove AD Object Optional",32+4)
            }
        }
        else 
        {
            out-logfile -string "No need to prompt administrator - no object to remove."
        }

        switch ($adminAnswer)
        {
            6 {
                out-logfile -string "Administrator selected yes to proceed with delete."
                out-logfile -string $adminAnswer.tostring()

                try {
                    remove-ADObject -identity $testADObject.distinguishedName -server $coreVariables.globalCatalogWithPort.value -credential $activeDirectoryCredential -authType $activeDirectoryAuthenticationMethod -confirm:$FALSE -errorAction STOP 
                }
                catch {
                    out-logfile -string $_
                    out-logfile -string "Unable to remove the AD object that has the same SMTP address as the restored group."
                }

            }
            7 {
                if ($deleteRequired -eq $TRUE)
                {
                    out-logfile -string "Administrator selected no to proceed with delete."
                    out-logfile -string "Deleting the AD object holding the same address to be deleted is required."
                    out-logfile -string $adminAnswer.toString() -isError:$TRUE
                }
                else
                {
                    out-logfile -string "Administrator selected no to proceed with delete."
                    out-logfile -string "Deleting this object is not required for restoration to proceed."
                    out-logfile -string $adminAnswer.toString()
                }
            }
        }

        $testADObject = $NULL
    }

    #================================================================================

    #================================================================================

    function setAttributesOnGroup
    {
        out-logfile -string "Resetting the attributes of the group to match the backup information."

        foreach ($property in $importedDLConfiguration.psObject.properties)
        {
            out-logfile -string ("Evaluating property: "+$property.name)

            if ($dlPropertiesToClearModern.contains($property.name))
            {
                out-logfile -string "The property is a writeable property contained in the backup set."

                if (($property.Value.count) -gt 1)
                {
                    out-logfile -string "Multivalued property - use add."

                    foreach ($value in $property.Value)
                    {
                        out-logfile -string ("Adding value: "+$value+" to property "+$property.name)

                        try {
                            set-ADObject -identity $originalDLConfiguration.objectGUID -add @{$property.Name = $value} -server $coreVariables.globalCatalogWithPort.value -credential $activeDirectoryCredential -authType $activeDirectoryAuthenticationMethod -errorAction STOP
                        }
                        catch {
                            out-logfile -string $_

                            $functionObject = New-Object PSObject -Property @{
                                PropertyName = $property.Name
                                PropertyValue = $value
                                Operation = "Add"
                                ErrorDetails = $_
                                ErrorCommon = "Unable to update original group property."
                            }

                            $onPremReplaceErrors += $functionObject
                        }
                    }
                }
                else 
                {
                    out-logfile -string "Single value property - use replace."

                    try {
                        set-ADObject -identity $originalDLConfiguration.objectGUID -Replace @{$property.Name = $value} -server $coreVariables.globalCatalogWithPort.value -credential $activeDirectoryCredential -authType $activeDirectoryAuthenticationMethod -errorAction STOP
                    }
                    catch {
                        out-logfile -string $_

                        $functionObject = New-Object PSObject -Property @{
                            PropertyName = $property.Name
                            PropertyValue = $value
                            Operation = "Replace"
                            ErrorDetails = $_
                            ErrorCommon = "Unable to update original group property."
                        }

                        $onPremReplaceErrors += $functionObject
                    }
                }
            }
            else 
            {
                out-logfile -string ("The property is not a writeable property - skip.")
            }
        }
    }


    #Initialize telemetry collection.

    $appInsightAPIKey = "63d673af-33f4-401c-931e-f0b64a218d89"
    $traceModuleName = "DLConversion"

    if ($allowTelemetryCollection -eq $TRUE)
    {
        start-telemetryConfiguration -allowTelemetryCollection $allowTelemetryCollection -appInsightAPIKey $appInsightAPIKey -traceModuleName $traceModuleName
    }

    #Create telemetry values.

    $telemetryDLConversionV2Version = $NULL
    $telemetryOSVersion = (Get-CimInstance Win32_OperatingSystem).version
    $telemetryStartTime = get-universalDateTime
    $telemetryEndTime = $NULL
    [double]$telemetryElapsedSeconds = 0
    $telemetryEventName = "Restore-MigratedDistributionList"

    $windowTitle = ("Restore-MigratedDistributionList "+$groupSMTPAddress)
    $host.ui.RawUI.WindowTitle = $windowTitle

    #Define global variables.

    $global:logFile=$NULL #This is the global variable for the calculated log file name
    [string]$global:staticFolderName="\DLMigration\"    

    #Define variables utilized in the core function that are not defined by parameters.

    $coreVariables = @{ 
        activeDirectoryPowershellModuleName = @{ "Value" = "ActiveDirectory" ; "Description" = "Static active directory powershell module name" }
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

    [array]$dlPropertiesToClearModern='Description','groupType',$onPremADAttributes.onPremAcceptMessagesFromSenders.Value,'DisplayName','DisplayNamePrintable',$onPremADAttributes.onPremRejectMessagesfromDLMembers.Value,$onPremADAttributes.onPremAcceptMessagesfromDLMembers.Value,'extensionAttribute1','extensionAttribute10','extensionAttribute11','extensionAttribute12','extensionAttribute13','extensionAttribute14','extensionAttribute15','extensionAttribute2','extensionAttribute3','extensionAttribute4','extensionAttribute5','extensionAttribute6','extensionAttribute7','extensionAttribute8','extensionAttribute9','legacyExchangeDN','mail','mailNickName','msExchRecipientDisplayType','msExchRecipientTypeDetails','msExchRemoteRecipientType',$onPremADAttributes.onPremBypassModerationFromDL.Value,$onPremADAttributes.onPremBypassModerationFromSenders.value,$onPremADAttributes.onPremCoManagedBy.value,'msExchEnableModeration','msExchExtensionCustomAttribute1','msExchExtensionCustomAttribute2','msExchExtensionCustomAttribute3','msExchExtensionCustomAttribute4','msExchExtensionCustomAttribute5','msExchGroupDepartRestriction','msExchGroupJoinRestriction','msExchHideFromAddressLists',$onPremADAttributes.onPremModeratedBy.value,'msExchModerationFlags','msExchRequireAuthToSendTo','msExchSenderHintTranslations','oofReplyToOriginator','proxyAddresses',$onPremADAttributes.onPremGrantSendOnBehalfTo.Value,'reportToOriginator','reportToOwner',$onPremADAttributes.onPremRejectMessagesFromSenders.value,'msExchArbitrationMailbox','msExchPoliciesIncluded','msExchUMDtmfMap','msExchVersion','showInAddressBook','msExchAddressBookFlags','msExchBypassAudit','msExchGroupExternalMemberCount','msExchGroupMemberCount','msExchGroupSecurityFlags','msExchLocalizationFlags','msExchMailboxAuditEnable','msExchMailboxAuditLogAgeLimit','msExchMailboxFolderSet','msExchMDBRulesQuota','msExchPoliciesIncluded','msExchProvisioningFlags','msExchRecipientSoftDeletedStatus','msExchRoleGroupType','msExchTransportRecipientSettingsFlags','msExchUMDtmfMap','msExchUserAccountControl','msExchVersion','sAMAccountName' #Properties Exchange 2016 or newer schema.

    #Define XML files to contain backups.

    $xmlFiles = @{
        originalDLConfigurationADXML = @{ "Value" =  "originalDLConfigurationADXML.xml" ; "Description" = "XML file that exports the original DL configuration"}
        originalDLConfigurationADXMLOutput = @{ "Value" =  "originalDLConfigurationADXML" ; "Description" = "XML file that exports the original DL configuration"}
        originalDLConfigurationUpdatedXML = @{ "Value" =  "originalDLConfigurationUpdatedXML" ; "Description" = "XML file that exports the updated DL configuration"}
        adObjectWithAddressXML = @{ "Value" =  "adObjectWithAddressXML" ; "Description" = "XML file that exports the updated DL configuration"}
        routingContactXML = @{ "Value" =  "routingContactXML" ; "Description" = "XML file that exports the updated DL configuration"}
    }

    #On premises variables for the distribution list to be migrated.

    $importedDLConfiguration=$NULL #This holds the on premises DL configuration for the group to be migrated.
    $originalDLConfiguraiton = $NULL
    $testADObject = $NULL

    #Define new arrays to check for errors instead of failing.

    [array]$onPremReplaceErrors=@()

    #Define other needed variables.

    $wshell = New-Object -ComObject Wscript.Shell
    $symbolToReplace = "@"
    $replacementString = "-MigratedByScript@"
    $blackSlash = "\"
    $originalGroupFound = $FALSE

    #Log start of DL migration to the log file.

    new-LogFile -groupSMTPAddress ("Restore_"+(get-date -format FileDateTime)) -logFolderPath $logFolderPath

    out-logfile -string "Testing for supported version of Powershell engine."

    test-powershellVersion

    out-logfile -string "********************************************************************************"
    out-logfile -string "NOTICE"
    out-logfile -string "Telemetry collection is now enabled by default."
    out-logfile -string "For information regarding telemetry collection see https://timmcmic.wordpress.com/2022/11/14/4288/"
    out-logfile -string "Administrators may opt out of telemetry collection by using -allowTelemetryCollection value FALSE"
    out-logfile -string "Telemetry collection is appreciated as it allows further development and script enhancement."
    out-logfile -string "********************************************************************************"

    #Output all parameters bound or unbound and their associated values.

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "PARAMETERS"
    Out-LogFile -string "********************************************************************************"

    write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

    Out-LogFile -string "================================================================================"
    Out-LogFile -string "BEGIN RESTORE-MIGRATEDDISTRIBUTIONLIST"
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
    $dataPath = remove-stringSpace -stringToFix $dataPath

    if($dataPath.remove(0,($dataPath.length - 1)) -ne "\")
    {
        out-logfile -string "Data path does not have trailing \"
        $dataPath = $dataPath + $blackSlash
        out-logfile -string $dataPath
    }

    $importDataFile = $dataPath + $xmlFiles.originalDLConfigurationADXML.Value

    out-logfile -string ("Calculdated data file for import: "+$importDataFile)

    Out-LogFile -string "********************************************************************************"

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string " RECORD VARIABLES"
    Out-LogFile -string "********************************************************************************"

    write-hashTable -hashTable $xmlFiles
    write-hashTable -hashTable $onPremADAttributes
    write-hashTable -hashTable $coreVariables
    
    Out-LogFile -string "********************************************************************************"

    #If exchange server information specified - create the on premises powershell session.

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "ESTABLISH POWERSHELL SESSIONS"
    Out-LogFile -string "********************************************************************************"

    out-logfile -string "Calling Test-PowershellModule to validate the DL Conversion Module version installed."

    $telemetryDLConversionV2Version = Test-PowershellModule -powershellModuleName $corevariables.dlConversionPowershellModule.value -powershellVersionTest:$TRUE

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END ESTABLISH POWERSHELL SESSIONS"
    Out-LogFile -string "********************************************************************************"

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "BEGIN RESTORATION OF DISTRIBUTION LIST"
    Out-LogFile -string "********************************************************************************"

    #At this point we are ready to capture the original DL configuration.  We'll use the ad provider to gather this information.
    #Test the path and make sure it exists.

    out-logfile -string "Testing to ensure that the original DL configuration XML is accessiable at the path provided."

    if (Test-Path $importDataFile -pathType Leaf)
    {
        out-logfile -string "The original DL Configuration was found in the data path provided."
    }
    else 
    {
        out-logfile -string $_
        out-logfile -string "The original DL Configuration was not found in the data path provided." -isError:$TRUE
    }

    #Import the XML file.

    out-logfile -string "Importing the original DL configuration from the data path provided."

    try
    {
        $importedDLConfiguration = import-clixml -path $importDataFile -errorAction STOP
    }
    catch
    {
        out-logfile -string $_
        out-logfile -string "Unable to import the original DL configuration XML file." -isError:$TRUE
    }

    out-logfile -string "The original DL configuration was successfully imported."

    #Test to see if hybrid mail flow was enabled and request administrator remove object if dynamic DL is present.

    out-logfile -string "Using the mail field imported - test to ensure that no other objects exist in the directory."

    $testMail = $importedDLConfiguration.mail
    out-logfile -string ("SMTP address of imported configuration: "+$testMail)

    getRemoveObject -identity $testMail -deleteRequired:$TRUE -xmlExportName $xmlFiles.adObjectWithAddressXML.Value

    #Search the directory for the mail contact that is created post migration - prompt administrator for removal.  This is not required to proceed.

    $testMail = $importedDLConfiguration.mail.replace($symbolToReplace,$replacementString)
    out-logfile -string ("SMTP address of routing contact calculated: "+$testMail)

    getRemoveObject -identity $testMail -xmlExportName $xmlFiles.routingContactXML.value

    #Determine if the original group can be located in the directory.  By default the group is retained.

    out-logfile -string "Attempting to locate the original group object by objectGUID."
    out-logfile -string $importedDLConfiguration.objectGUID

    try
    {
        $originalDLConfiguration = Get-ADObject -identity $importedDLConfiguration.objectGUID -properties * -server $coreVariables.globalCatalogWithPort.value -credential $activeDirectoryCredential -authType $activeDirectoryAuthenticationMethod -errorAction STOP
    }
    catch
    {
        out-logfile -string "Unable to query Active Directory for the presence of the original group."
        out-logfile -string $_
    }

    if ($NULL -ne $originalDLConfiguration)
    {
        out-logfile -string "The original group was found in Active Directory."
        $originalGroupFound = $TRUE
        out-xmlFile -itemToExport $originalDLConfiguration -itemNameToExport $xmlFiles.originalDLConfigurationADXMLOutput.value
    }

    if ($originalGroupFound -eq $TRUE)
    {
        out-logfile -string "Resetting properties of the original group to match backup."

        #First order of business - rename the group.

        out-logfile -string "Rename the original group to match the CN of the imported group information."

        try
        {
            rename-ADObject -identity $originalDLConfiguration.objectGUID -newName $importedDLConfiguration.cn -server $coreVariables.globalCatalogWithPort.value -credential $activeDirectoryCredential -authType $activeDirectoryAuthenticationMethod -errorAction STOP
        }
        catch {
            out-logfile -string $_
        }

        #Second order of business reset the attributes.
        #If the attribute in the file is contained in the AD attributes array then reset it.

        setAttributesOnGroup
    }

    exit

    try
    {
        $originalDLConfiguration = Get-ADObjectConfiguration -groupSMTPAddress $groupSMTPAddress -globalCatalogServer $corevariables.globalCatalogWithPort.value -parameterSet $dlPropertySet -errorAction STOP -adCredential $activeDirectoryCredential
    }
    catch
    {
        out-logfile -string $_ -isError:$TRUE
    }

    #Testing the returned DL configuration to determine if it is a group.  If the object was found by SMTP address is not a group then exit.

    if ($originalDLConfiguration.groupType -eq $NULL)
    {
        out-logfile -string "Object found by SMTP address is not a group." -isError:$TRUE
    }
    else 
    {
        out-logfile -string "Object located by mail address and group type is present - proceed."
        out-logfile -string $originalDLConfiguration.groupType.tostring()
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

    if ($allObjectSendAsAccess -ne $NULL)
    {
        out-logfile -string $allObjectSendAsAccess

        out-xmlFile -itemToExport $allObjectSendAsAccess -itemNameToExport $xmlFiles.allGroupsSendAsXML.value
    }
    else 
    {
        $allObjectsSendAsAccess=@()
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

    if ($allObjectsFullMailboxAccess -ne $null)
    {
        out-logfile -string $allObjectsFullMailboxAccess

        out-xmlFile -itemToExport $allObjectsFullMailboxAccess -itemNameToExport $xmlFiles.allGroupsFullMailboxAccessXML.value
    }
    else
    {
        $allObjectsFullMailboxAccess = @()
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

    if ($allMailboxesFolderPermissions -ne $NULL)
    {
        out-logfile -string $allMailboxesFolderPermissions

        out-xmlFile -itemToExport $allMailboxesFolderPermissions -itemNameToExport $xmlFiles.allMailboxesFolderPermissionsXML.value
    }
    else
    {
        $allMailboxesFolderPermissions=@()
    }

    #If there are any sendAs or mailbox access permissiosn for the group.
    #The group should be retained for saftey and only manually deleted if the administrator understands ramiifactions.
    #In testing disabling the group will allow the permissions to continue functioning - deleting the group would loose it.
    #Overrideing the administrators decision to delete the group.

    if (($allObjectSendAsAccess.Count -ne 0) -or ($allObjectsFullMailboxAccess.count -ne 0) -or ($allMailboxesFolderPermissions.count -ne 0))
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
            $office365DLConfiguration=Get-O365DLConfiguration -groupSMTPAddress $groupSMTPAddress -isFirstPass:$TRUE -errorAction STOP
        }
        catch 
        {
            out-logFile -string $_ -isError:$TRUE
        }
        try 
        {
            $office365GroupConfiguration = get-o365GroupConfiguration -groupSMTPAddress $groupSMTPAddress -errorAction STOP
        }
        catch {
            out-logfile -string $_ -isError:$TRUE
        }
    }
    else 
    {
        $office365DLConfiguration="DistributionListIsNonSynced"
        $office365GroupConfiguration="DistributionListIsNonSynced"
    }

    
    
    Out-LogFile -string $office365DLConfiguration

    Out-LogFile -string "Create an XML file backup of the office 365 DL configuration."

    Out-XMLFile -itemToExport $office365DLConfiguration -itemNameToExport $xmlFiles.office365DLConfigurationXML.value

    out-logfile -string $office365GroupConfiguration

    out-logfile -string "Create an XML file backup of the office 365 group cofniguration."

    out-xmlfile -itemToExport $office365GroupConfiguration -itemNameToExport $xmlFiles.office365GroupConfigurationXML.value

    <#

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

    if ($azureADDLConfiguration -ne $NULL)
    {
        out-logfile -string $azureADDLConfiguration

        out-logfile -string "Create an XML file backup of the Azure AD DL Configuration"

        out-xmlFile -itemToExport $azureADDLConfiguration -itemNameToExport $xmlFiles.azureDLConfigurationXML.value
    }

    #>

    out-logfile -string "Capture the original Graph AD distribution list informaiton"

    if ($allowNonSyncedGroup -eq $FALSE)
    {
        try{
            $msGraphDLConfiguration = get-msGraphDLConfiguration -office365DLConfiguration $office365DLConfiguration -errorAction STOP
        }
        catch{
            out-logfile -string $_
            out-logfile -string "Unable to obtain Azure Active Directory DL Configuration" -isError:$TRUE
        }
    }

    if ($msGraphDLConfiguration -ne $NULL)
    {
        out-logfile -string $msGraphDlConfiguration

        out-logfile -string "Create an XML file backup of the Azure AD DL Configuration"

        out-xmlFile -itemToExport $msGraphDLConfiguration -itemNameToExport $xmlFiles.msGraphDLConfigurationXML.value
    }

    out-logfile -string "Recording Graph DL membership."

    if ($allowNonSyncedGroup -eq $FALSE)
    {
        try {
            $msGraphDLMembership = get-msGraphMembership -groupobjectID $msGraphDLConfiguration.id -errorAction STOP
        }
        catch {
            out-logfile -string "Unable to obtain Azure AD DL Membership."
            out-logfile -string $_ -isError:$TRUE
        }
    }

    if ($NULL -ne $msGraphDLMembership)
    {
        out-logfile -string "Creating an XML file backup of the Azure AD DL Configuration"

        out-xmlFile -itemToExport $msGraphDLMembership -itemNameToExport $xmlFiles.msGraphDLMembershipXML.value
    }
    else {
        $msGraphDLMembership=@()
    }

    <#
    out-logfile -string "Recording Azure AD DL membership."

    if ($allowNonSyncedGroup -eq $FALSE)
    {
        try {
            $azureADDLMembership = get-AzureADMembership -groupobjectID $azureADDLConfiguration.objectID -errorAction STOP
        }
        catch {
            out-logfile -string "Unable to obtain Azure AD DL Membership."
            out-logfile -string $_
        }
    }

    if ($azureADDLMembership -ne $NULL)
    {
        out-logfile -string "Creating an XML file backup of the Azure AD DL Configuration"

        out-xmlFile -itemToExport $azureADDLMembership -itemNameToExport $xmlFiles.azureDLMembershipXML.value
    }

    #>


    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END GET ORIGINAL DL CONFIGURATION LOCAL AND CLOUD"
    Out-LogFile -string "********************************************************************************"

    if ($allowNonSyncedGroup -eq $FALSE)
    {
        Out-LogFile -string "Perform a safety check to ensure that the distribution list is directory sync."

        try 
        {
            Invoke-Office365SafetyCheck -o365dlconfiguration $office365DLConfiguration -azureADDLConfiguration $msGraphDLConfiguration -errorAction STOP
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

    $telemetryFunctionStartTime = get-universalDateTime

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
                $normalizedTest = get-normalizedDN -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -isMember:$TRUE -activeDirectoryAttribute $onPremADAttributes.onPremMembers.Value -activeDirectoryAttributeCommon $onPremADAttributes.onPremMembersCommon.Value -groupSMTPAddress $groupSMTPAddress -skipNestedGroupCheck $skipNestedGroupCheck -errorAction STOP -cn "None"

                out-logfile -string $normalizedTest

                if ($normalizedTest.isError -eq $TRUE)
                {
                    $global:preCreateErrors+=$normalizedTest
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
                $normalizedTest = get-normalizedDN -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -activeDirectoryAttribute $onPremADAttributes.onPremRejectMessagesFromSenders.value -activeDirectoryAttributeCommon $onPremADAttributes.onPremRejectMessagesFromSendersCommon.value -groupSMTPAddress $groupSMTPAddress -errorAction STOP -cn "None"

                out-logfile -string $normalizedTest

                if ($normalizedTest.isError -eq $TRUE)
                {
                    $global:preCreateErrors+=$normalizedTest
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
                $normalizedTest=get-normalizedDN -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -activeDirectoryAttribute $onPremADAttributes.onPremRejectMessagesFromDLMembers.value -activeDirectoryAttributeCommon $onPremADAttributes.onPremRejectMessagesFromDLMembersCommon.value -groupSMTPAddress $groupSMTPAddress -errorAction STOP -cn "None"

                out-logfile -string $normalizedTest

                if ($normalizedTest.isError -eq $TRUE)
                {
                    $global:preCreateErrors+=$normalizedTest
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
                $normalizedTest=get-normalizedDN -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -activeDirectoryAttribute $onPremADAttributes.onPremRejectMessagesFromDLMembers.value -activeDirectoryAttributeCommon $onPremADAttributes.onPremRejectMessagesFromDLMembersCommon.value -groupSMTPAddress $groupSMTPAddress -errorAction STOP -cn "None"

                out-logfile -string $normalizedTest

                if ($normalizedTest.isError -eq $TRUE)
                {
                    $global:preCreateErrors+=$normalizedTest
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
                $normalizedTest=get-normalizedDN -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -activeDirectoryAttribute $onPremADAttributes.onPremAcceptMessagesFromDLMembers.value -activeDirectoryAttributeCommon $onPremADAttributes.onPremAcceptMessagesFromDLMembersCommon.value -groupSMTPAddress $groupSMTPAddress -errorAction STOP -cn "None"

                out-logfile -string $normalizedTest

                if ($normalizedTest.isError -eq $TRUE)
                {
                    $global:preCreateErrors+=$normalizedTest
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
                $normalizedTest=get-normalizedDN -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -activeDirectoryAttribute $onPremADAttributes.onPremManagedBy.Value -activeDirectoryAttributeCommon $onPremADAttributes.onPremManagedByCommon.Value -groupSMTPAddress $groupSMTPAddress -errorAction STOP -cn "None"

                out-logfile -string $normalizedTest

                if ($normalizedTest.isError -eq $TRUE)
                {
                    $global:preCreateErrors+=$normalizedTest
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
                $normalizedTest = get-normalizedDN -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -activeDirectoryAttribute $onPremADAttributes.onPremCoManagedBy.Value -activeDirectoryAttributeCommon $onPremADAttributes.onPremCoManagedByCommon.Value -groupSMTPAddress $groupSMTPAddress -errorAction STOP -cn "None"

                out-logfile -string $normalizedTest

                if ($normalizedTest.isError -eq $TRUE)
                {
                    $global:preCreateErrors+=$normalizedTest
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
                $object.isError=$TRUE
                $object.isErrorMessage = "GROUP_NO_LONGER_SECURITY_EXCEPTION: A group was found on the owners attribute that is no longer a security group.  Security group is required.  Remove group or change group type to security."
                
                out-logfile -string object

                $global:preCreateErrors+=$object

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
                    $object.isError=$TRUE
                    $object.isErrorMessage = "GROUP_OVERRIDE_MANAGER_NOT_ALLOWED: The group being migrated was found on the Owners attribute.  The administrator has requested migration as Distribution not Security.  To remain an owner the group must be migrated as Security - remove override or remove owner."

                    out-logfile -string $object
    
                    $global:preCreateErrors+=$object
        
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
                $normalizedTest = get-normalizedDN -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -activeDirectoryAttribute $onPremADAttributes.onPremModeratedBy.Value -activeDirectoryAttributeCommon $onPremADAttributes.onPremModeratedByCommon.Value -groupSMTPAddress $groupSMTPAddress -errorAction STOP -cn "None"

                out-logfile -string $normalizedTest

                if ($normalizedTest.isError -eq $TRUE)
                {
                    $global:preCreateErrors+=$normalizedTest
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
                $normalizedTest = get-normalizedDN -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -activeDirectoryAttribute $onPremADAttributes.onPremBypassModerationFromSenders.Value -activeDirectoryAttributeCommon $onPremADAttributes.onPremBypassModerationFromSendersCommon.Value -groupSMTPAddress $groupSMTPAddress -errorAction STOP -cn "None"

                out-logfile -string $normalizedTest

                if ($normalizedTest.isError -eq $TRUE)
                {
                    $global:preCreateErrors+=$normalizedTest
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
                $normalizedTest = get-normalizedDN -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -activeDirectoryAttribute $onPremADAttributes.onPremBypassModerationFromDL.Value -activeDirectoryAttributeCommon $onPremADAttributes.onPremBypassModerationFromDLCommon.Value -groupSMTPAddress $groupSMTPAddress -errorAction STOP -cn "None"

                out-logfile -string $normalizedTest

                if ($normalizedTest.isError -eq $TRUE)
                {
                    $global:preCreateErrors+=$normalizedTest
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
                $normalizedTest=get-normalizedDN -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN $DN -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -activeDirectoryAttribute $onPremADAttributes.onPremGrantSendOnBehalfTo.Value -activeDirectoryAttributeCommon $onPremADAttributes.onPremGrantSendOnBehalfToCommon.Value -groupSMTPAddress $groupSMTPAddress -errorAction STOP -cn "None"

                out-logfile -string $normalizedTest

                if ($normalizedTest.isError -eq $TRUE)
                {
                    $global:preCreateErrors+=$normalizedTest
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
                $normalizedTest=get-normalizedDN -globalCatalogServer $corevariables.globalCatalogWithPort.value -DN "None" -adCredential $activeDirectoryCredential -originalGroupDN $originalDLConfiguration.distinguishedName -activeDirectoryAttribute "SendAsDependency" -activeDirectoryAttributeCommon "SendAsDependency" -groupSMTPAddress $groupSMTPAddress -errorAction STOP -CN:$permission.Identity

                out-logfile -string $normalizedTest

                if ($normalizedTest.isError -eq $TRUE)
                {
                    $global:preCreateErrors+=$normalizedTest
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

    $telemetryFunctionStartTime = get-universalDateTime

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

    if ($customRoutingDomain -eq "")
    {
        out-logfile -string "Determine the mail onmicrosoft domain necessary for cross premises routing."
        try {
            $mailOnMicrosoftComDomain = Get-MailOnMicrosoftComDomain -errorAction STOP
        }
        catch {
            out-logfile -string $_
            out-logfile -string "Unable to obtain the onmicrosoft.com domain." -errorAction STOP    
        }
    }
    else 
    {
        out-logfile -string "The administrtor has specified a custome routing domain - maybe for legacy tenant implementations."

        $mailOnMicrosoftComDomain = $customRoutingDomain
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
                    $member.isError = $TRUE
                    $member.isErrorMessage = "OFFICE_365_DEPENDENCY_NOT_FOUND_EXCEPTION: A group dependency was not found in Office 365.  Please either ensure the dependency is present or remove the dependency from the group."

                    out-logfile -string $member

                    $global:testOffice365Errors += $member
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
                    $member.isError = $TRUE
                    $member.isErrorMessage = "OFFICE_365_DEPENDENCY_NOT_FOUND_EXCEPTION: A group dependency was not found in Office 365.  Please either ensure the dependency is present or remove the dependency from the group."

                    out-logfile -string $member

                    $global:testOffice365Errors += $member
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
                    $member.isError = $TRUE
                    $member.isErrorMessage = "OFFICE_365_DEPENDENCY_NOT_FOUND_EXCEPTION: A group dependency was not found in Office 365.  Please either ensure the dependency is present or remove the dependency from the group."

                    out-logfile -string $member

                    $global:testOffice365Errors += $member
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
                    $member.isError = $TRUE
                    $member.isErrorMessage = "OFFICE_365_DEPENDENCY_NOT_FOUND_EXCEPTION: A group dependency was not found in Office 365.  Please either ensure the dependency is present or remove the dependency from the group."

                    out-logfile -string $member

                    $global:testOffice365Errors += $member
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

    out-logfile -string "Begin evaluating all moderated by members."

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
                    $member.isError = $TRUE
                    $member.isErrorMessage = "OFFICE_365_DEPENDENCY_NOT_FOUND_EXCEPTION: A group dependency was not found in Office 365.  Please either ensure the dependency is present or remove the dependency from the group."

                    out-logfile -string $member

                    $global:testOffice365Errors += $member
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
                    $member.isError = $TRUE
                    $member.isErrorMessage = "OFFICE_365_DEPENDENCY_NOT_FOUND_EXCEPTION: A group dependency was not found in Office 365.  Please either ensure the dependency is present or remove the dependency from the group."

                    out-logfile -string $member

                    $global:testOffice365Errors += $member
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
                    $member.isError = $TRUE
                    $member.isErrorMessage = "OFFICE_365_DEPENDENCY_NOT_FOUND_EXCEPTION: A group dependency was not found in Office 365.  Please either ensure the dependency is present or remove the dependency from the group."

                    out-logfile -string $member

                    $global:testOffice365Errors += $member
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
                    $member.isError = $TRUE
                    $member.isErrorMessage = "OFFICE_365_DEPENDENCY_NOT_FOUND_EXCEPTION: A group dependency was not found in Office 365.  Please either ensure the dependency is present or remove the dependency from the group."

                    out-logfile -string $member

                    $global:testOffice365Errors += $member
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
                    $member.isError = $TRUE
                    $member.isErrorMessage = "OFFICE_365_DEPENDENCY_NOT_FOUND_EXCEPTION: A group dependency was not found in Office 365.  Please either ensure the dependency is present or remove the dependency from the group."

                    out-logfile -string $member

                    $global:testOffice365Errors += $member
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

    out-logfile -string "Test DL name prefix and suffix name constraints."

    try{
        test-dlNameLength -DLConfiguration $originalDLConfiguration -prefix $dlNamePrefix -suffix $dlNameSuffix -errorAction STOP
    }
    catch {
        out-logfile -string $_
        out-logfile -string "Unable to validate the DL name suffix prefix length constraints" -isError:$TRUE
    }

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END VALIDATE RECIPIENTS IN CLOUD"
    Out-LogFile -string "********************************************************************************"

    $telemetryFunctionEndTime = get-universalDateTime

    $telemetryValidateCloudRecipients = get-elapsedTime -startTime $telemetryFunctionStartTime -endTime $telemetryFunctionEndTime

    out-logfile -string ("Time to validate recipients in cloud: "+ $telemetryValidateCloudRecipients.toString())

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
            out-logfile -string "Pre-requiste checks failed.  Please refer to the previous list of items that require addressing for migration to proceed." -isError:$TRUE
        }
        else
        {
            out-logfile -string "Pre-requiste checks failed.  Please refer to the previous list of items that require addressing for migration to proceed."
        }  
    }

    if ($isHealthCheck -eq $TRUE)
    {
        return
    }

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
        out-logfile -string "Calling get canonical name."

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

    #Exit #Debug exit

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
                    $allOffice365SendAsAccess = Get-O365DLSendAs -groupSMTPAddress $groupSMTPAddress -isTrustee:$TRUE -office365GroupConfiguration $office365GroupConfiguration -errorAction STOP
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
                    $allOffice365FullMailboxAccess = Get-O365DLFullMaiboxAccess -groupSMTPAddress $office365DLConfiguration.externalDirectoryObjectID
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
            $office365DLConfigurationPostMigration=new-office365dl -originalDLConfiguration $originalDLConfiguration -office365DLConfiguration $office365DLConfiguration -grouptypeoverride $groupTypeOverride -errorAction STOP

            #Set the global DL info to Office365DLConfiguration so that if there is a failure the DL can be removed.

            out-logfile -string "Setting DL cleanup information - if a failure occurs delete the stub DL."

            $global:DLCleanupInfo = $office365DLConfigurationPostMigration

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
            set-Office365DLMV -originalDLConfiguration $originalDLConfiguration -office365DLConfiguration $office365DLConfiguration -office365GroupConfiguration $office365GroupConfiguration -office365DLConfigurationPostMigration $office365DLConfigurationPostMigration -exchangeDLMembership $exchangeDLMembershipSMTP -exchangeRejectMessage $exchangeRejectMessagesSMTP -exchangeAcceptMessage $exchangeAcceptMessagesSMTP -exchangeModeratedBy $exchangeModeratedBySMTP -exchangeManagedBy $exchangeManagedBySMTP -exchangeBypassMOderation $exchangeBypassModerationSMTP -exchangeGrantSendOnBehalfTo $exchangeGrantSendOnBehalfToSMTP -errorAction STOP -groupTypeOverride $groupTypeOverride -exchangeSendAsSMTP $exchangeSendAsSMTP -mailOnMicrosoftComDomain $mailOnMicrosoftComDomain -allowNonSyncedGroup $allowNonSyncedGroup -allOffice365SendAsAccessOnGroup $allOffice365SendAsAccessOnGroup -isFirstAttempt:$TRUE

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
            $office365DLConfigurationPostMigration = Get-O365DLConfiguration -groupSMTPAddress $office365DLConfigurationPostMigration.GUID -errorAction STOP

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
            set-Office365DL -originalDLConfiguration $originalDLConfiguration -office365DLConfiguration $office365DLConfiguration -groupTypeOverride $groupTypeOverride -office365DLConfigurationPostMigration $office365DLConfigurationPostMigration -isFirstAttempt:$TRUE -prefix $dlNamePrefix -suffix $dlNameSuffix
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
            $office365DLConfigurationPostMigration = Get-O365DLConfiguration -groupSMTPAddress $office365DLConfigurationPostMigration.GUID -errorAction STOP

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

    $global:DLMoveCleanup.originalDLConfiguration = $originalDLConfiguration

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
    
    if (($global:threadNumber -eq 0) -or ($global:threadNumber -eq 1))
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

    #If group deletion via graph is allowed - do it at this time.

    out-logfile -string "If delete via graph is in use - process the deletion via graph."

    if ($removeGroupViaGraph -eq $TRUE)
    {
        out-logfile -string "Remove group via graph is enabled."

        try {
            remove-groupViaGraph -groupObjectID $office365DLConfiguration.externalDirectoryObjectID -errorAction STOP

            out-logfile -string "Group removal via graph was successful."
        }
        catch {
            out-logfile -string $_
            out-logfile -string "Unable to remove the group via graph - this is a hard failure."
            out-logfile -string "Since the group is already gone - assume handeled via ad connect and continue."
        }
    }

    #Start the process of syncing the deletion to the cloud if the administrator has provided credentials.
    #Note:  If this is not done we are subject to sitting and waiting for it to complete.

    if (($global:threadNumber -eq 0) -or ($global:threadNumber -eq 1))
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

    $telemetryFunctionStartTime = get-universalDateTime

    out-logfile -string "Monitoring Exchange Online for distribution list deletion."

    if ($totalThreadCount -gt 0)
    {
        out-logfile -string "Calling test-CloudDLPresent with AD Connect information."

        try {

            if ($coreVariables.useAADConnect.value -eq $TRUE)
            {
                out-logfile -string "Invoking test-cloudDLPresent using AD Connect information since multi-threaded."

                test-CloudDLPresent -groupSMTPAddress $office365DLConfiguration.externalDirectoryObjectID -aadConnectPowershellSessionName $coreVariables.aadConnectPowershellSessionName.value -errorAction SilentlyContinue
            }
            else 
            {
                out-logfile -string "Invoking test-cloudDLPresent without using AD Connect information since not specified with multi-threaded migration."

                test-CloudDLPresent -groupSMTPAddress $office365DLConfiguration.externalDirectoryObjectID -errorAction SilentlyContinue            
            }
        }
        catch {
            out-logfile -string $_ -isError:$TRUE
        }
    }
    else 
    {
        try {
            out-logfile -string "Invoking test-cloudDLPresent with no ADConnect information (single threaded)."

            test-CloudDLPresent -groupSMTPAddress $office365DLConfiguration.externalDirectoryObjectID -errorAction SilentlyContinue
        }
        catch {
            out-logfile -string $_ -isError:$TRUE
        }
    }

    $telemetryFunctionEndTime = get-universalDateTime

    $telemetryTimeToRemoveDL = get-elapsedTime -startTime $telemetryFunctionStartTime -endTime $telemetryFunctionEndTime

    out-logfile -string ("Elapsed time to remove the Office 365 Distribution List: "+$telemetryTimeToRemoveDL.tostring())

    #At this point we have validated that the group is gone from office 365.
    
    #EXIT #Debug Exit.

    start-sleepProgress -sleepSeconds 30 -sleepString "Holding post DL creation for 30 seconds to allow buffer for cache purge before resetting attributes that may collid with the origianl group."

    $telemetryFunctionStartTime = get-universalDateTime

    #Now it is time to set the multi valued attributes on the DL in Office 365.
    #Setting these first must occur since moderators have to be established before moderation can be enabled.

    out-logFile -string "Setting the multivalued attributes of the migrated group for the first pass."

    out-logfile -string $office365DLConfigurationPostMigration.primarySMTPAddress

    [int]$loopCounter=0
    [boolean]$stopLoop = $FALSE
    
    do {
        try {
            set-Office365DLMV -originalDLConfiguration $originalDLConfiguration -office365DLConfiguration $office365DLConfiguration -office365GroupConfiguration $office365GroupConfiguration -office365DLConfigurationPostMigration $office365DLConfigurationPostMigration -exchangeDLMembership $exchangeDLMembershipSMTP -exchangeRejectMessage $exchangeRejectMessagesSMTP -exchangeAcceptMessage $exchangeAcceptMessagesSMTP -exchangeModeratedBy $exchangeModeratedBySMTP -exchangeManagedBy $exchangeManagedBySMTP -exchangeBypassMOderation $exchangeBypassModerationSMTP -exchangeGrantSendOnBehalfTo $exchangeGrantSendOnBehalfToSMTP -errorAction STOP -groupTypeOverride $groupTypeOverride -exchangeSendAsSMTP $exchangeSendAsSMTP -mailOnMicrosoftComDomain $mailOnMicrosoftComDomain -allowNonSyncedGroup $allowNonSyncedGroup -allOffice365SendAsAccessOnGroup $allOffice365SendAsAccessOnGroup 

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
            $office365DLConfigurationPostMigration = Get-O365DLConfiguration -groupSMTPAddress $office365DLConfigurationPostMigration.GUID -errorAction STOP

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
            set-Office365DL -originalDLConfiguration $originalDLConfiguration -office365DLConfiguration $office365DLConfiguration -groupTypeOverride $groupTypeOverride -office365DLConfigurationPostMigration $office365DLConfigurationPostMigration -prefix $dlNamePrefix -suffix $dlNameSuffix
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
            $office365DLConfigurationPostMigration = Get-O365DLConfiguration -groupSMTPAddress $office365DLConfigurationPostMigration.GUID -errorAction STOP

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

    #out-logfile -string "Debug error for testing move to original OU." -isError:$TRUE

    $stopLoop = $FALSE
    [int]$loopCounter = 0

    do {
        try{
            $office365DLMembershipPostMigration = @(get-O365DLMembership -groupSMTPAddress $office365DLConfigurationPostMigration.guid -errorAction STOP)

            #Membership obtained - export.

            out-logFile -string "Write the new DL membership to XML."
            out-logfile -string $office365DLMembershipPostMigration

            out-xmlFile -itemToExport $office365DLMembershipPostMigration -itemNametoExport $xmlFiles.office365DLMembershipPostMigrationXML.value

            #Exports complete - stop loop

            $stopLoop=$TRUE
        }
        catch{
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

    $telemetryFunctionEndTime = get-universalDateTime

    $telemetryCreateOffice365DL = get-elapsedTime -startTime $telemetryFunctionStartTime -endTime $telemetryFunctionEndTime

    out-logfile -string ("Time elapsed to fully create Office 365 DL: "+$telemetryCreateOffice365DL.toString())

    #The DL has no been fully created - any failures from this point should not remove the stub DL.

    out-logfile -string "At this point do not delete the stub DL created in the cloud - the DL is now complete as best possible."

    $global:DlCleanupInfo = $NULL

    out-logfile -string "At this point do not move the DL back to the sync OU in the event of a failure."

    $global:DLMoveCleanup.originalDLConfiguration = $NULL

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

                move-toNonSyncOU -DN $originalDLConfigurationUpdated.distinguishedName -ou $tempOUSubstring -globalCatalogServer $globalCatalogServer -adCredential $activeDirectoryCredential -dlPostCreate $true -errorAction STOP

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

    if ($customRoutingDomain -eq "")
    {
        out-logfile -string "Calling new-routing contact without custom routing domain."
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
    }
    else
    {
        out-logfile -string "Calling new-routingContact with custom domain."
        do {
            try {
                new-routingContact -originalDLConfiguration $originalDLConfiguration -office365DlConfiguration $office365DLConfigurationPostMigration -globalCatalogServer $globalCatalogServer -adCredential $activeDirectoryCredential -customRoutingDomain $customRoutingDomain
    
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
    }
    
    

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

    #Moving the creation of hybrid mail flow here to ensure that mail routing happens at the next ad replication cycle.

    if ($enableHybridMailflow -eq $TRUE)
    {
        $commandEndTime = get-date

        if (($commandEndTime - $commandStartTime).totalHours -gt $kerberosRunTime)
        {
            out-logfile -string "Re-importing the exchange on premises powershell session due to kerberos timeout."

            session-toImport
        }

        #The first step is to upgrade the contact to a full mail contact and remove the target address from proxy addresses.

        $isTestError="No"

        out-logfile -string "The administrator has enabled hybrid mail flow."

        if (($global:threadNumber -eq 1) -or ($global:threadNumber -eq 0))
        {
            out-logfile -string "Enable mail contact:  Thread 1."

            try{
                $isTestError=Enable-MailRoutingContact -globalCatalogServer $globalCatalogServer -routingContactConfig $routingContactConfiguration -routingXMLFile $xmlFiles.routingContactXML.value
            }
            catch{
                out-logfile -string $_
                $isTestError="Yes"
                $errorMessageDetail=$_
            }
        }
        elseif($global:threadNumber -gt 1)
        {
            out-logfile -string "Enable mail contact:  Not thread 1 delay"

            start-sleepProgress -sleepstring "Sleep before attempting enable mail contact." -sleepSeconds ($global:threadNumber * $createMailContactDelay)

            try{
                $isTestError=Enable-MailRoutingContact -globalCatalogServer $globalCatalogServer -routingContactConfig $routingContactConfiguration -routingXMLFile $xmlFiles.routingContactXML.value
            }
            catch{
                out-logfile -string $_
                $isTestError="Yes"
                $errorMessageDetail=$_
            }
        }

        if ($isTestError -eq "Yes")
        {
            $isErrorObject = new-Object psObject -property @{
                errorMessage = "Unable to enable the mail routing contact as a full recipient.  Manually enable the mail routing contact."
                errorMessaegDetail = $errorMessageDetail
            }

            out-logfile -string $isErrorObject

            $global:generalErrors+=$isErrorObject
        }

        #The mail contact has been created and upgrade.  Now we need to capture the updated configuration.

        try{
            $routingContactConfiguration = Get-ADObjectConfiguration -dn $routingContactConfiguration.distinguishedName -globalCatalogServer $corevariables.globalCatalogWithPort.value -parameterSet $dlPropertySet -errorAction STOP -adCredential $activeDirectoryCredential 
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

            out-logfile -string "Determine if on premises values are missing and Office 365 values need to be substituted in."

            if ($originalDLConfiguration.name -eq $NULL)
            {
                out-logfile -string "On premises name value is missing - utilize Office 365 values."
                out-logfile -string $office365DLConfiguration.DisplayName
                $originalDLConfiguration.name = $office365DLConfiguration.DisplayName
                out-logfile -string $originalDLConfiguration.name 
            }

            if ($originalDLConfiguration.mailNickName -eq $NULL)
            {
                out-logfile -string "On premises mail nickname value missing - utilize Office 365 values."
                out-logfile -string $office365DLConfiguration.alias
                $originalDLConfiguration.mailNickName = $office365DLConfiguration.alias
                out-logfile -string $originalDLConfiguration.mailNickName
            }

            if ($originalDLConfiguration.mail -eq $NULL)
            {
                out-logfile -string "On premises mail value is missing - utilize Office 365 values."
                out-logfile -string $office365DLConfiguration.primarySMTPAddress
                $originalDLConfiguration.mail = $office365DLConfiguration.primarySMTPAddress
                out-logfile -string $originalDLConfiguration.mail
            }

            if ($originalDLConfiguration.displayName -eq $NULL)
            {
                out-logfile -string "On premises display name value is missing - utilize Office 365 values."
                out-logfile -string $office365DLConfiguration.displayName
                $originalDLConfiguration.displayName = $office365DLConfiguration.displayName
                out-logfile -string $originalDLConfiguration.displayName
            }

            out-logfile -string "Creating the mail dynamic group..."

            $isTestError=Enable-MailDyamicGroup -globalCatalogServer $globalCatalogServer -originalDLConfiguration $originalDLConfiguration -routingContactConfig $routingContactConfiguration

            <#

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

            #>
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

            $global:generalErrors+=$isErrorObject
        }

        [boolean]$stopLoop=$FALSE
        [int]$loopCounter=0

        do {
            try{
                $routingDynamicGroupConfig = Get-ADObjectConfiguration -groupSMTPAddress $groupSMTPAddress -globalCatalogServer $corevariables.globalCatalogWithPort.value -parameterSet $dlPropertySet -errorAction STOP -adCredential $activeDirectoryCredential

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
        
                    $global:generalErrors+=$isErrorObject

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

    $telemetryFunctionStartTime = get-universalDateTime

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
                    $isTestError=start-replaceOnPrem -routingContact $routingContactConfiguration -attributeOperation $onPremADAttributes.onPremRejectMessagesFromSenders.Value -canonicalObject $member -adCredential $activeDirectoryCredential -globalCatalogServer $globalCatalogServer -errorAction STOP
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
                    $isTestError=start-replaceOnPrem -routingContact $routingContactConfiguration -attributeOperation $onPremADAttributes.onPremAcceptMessagesFromSenders.Value -canonicalObject $member -adCredential $activeDirectoryCredential -globalCatalogServer $globalCatalogServer -errorAction STOP
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

    out-logfile -string ("Time elapsed replacing Office 365 dependencies: "+$telemetryReplaceOffice365Dependency.toString())

    #At this time the group has been migrated.
    #All on premises settings have been reconciled.
    #All cloud settings have been reconciled.
    #If exchange hybrid mail flow was enabled - the routing components were completed.

    #If the administrator has choosen to migrate and request upgrade to Office 365 group - trigger the ugprade.

    if ($triggerUpgradeToOffice365Group -eq $TRUE)
    {
        <#
        out-logfile -string "Administrator has choosen to trigger modern group upgrade."

        try{
            $isTestError="No"

            $isTestError=start-upgradeToOffice365Group -groupSMTPAddress $groupSMTPAddress
        }
        catch{
            out-logfile -string $_
            $isTestError="Yes"
        }
        #>

        $isTestError = "No"

        Out-logfile -string "Trigger upgrade to Office 365 Group is no longer supported in this function call."
        out-logfile -string "Use convert-Office365DLtoUnifiedGroup to convert this migrted DL to an Office 365 Group <or> start-Office365GroupMigration to migrate directly to an Office 365 Group."
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

        $global:generalErrors+=$isErrorObject
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

        $global:generalErrors+=$isErrorObject
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
   
   if (($global:threadNumber -eq 0) -or ($global:threadNumber -eq 1))
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

   if (($global:threadNumber -eq 0) -or ($global:threadNumber -eq 1))
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

   #Update 3/27/2024 - removed this section of code.
   #Status file cleanup of entire directory occurs right at the beginning of thread 1.
   #Should in theory be no need to remove individual status files.
   #This could cause a timing issue as other threads complete and remove their status files.
   
   <#

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

   #>

    out-logfile -string "Calling function to disconnect all powershell sessions."

    disable-allPowerShellSessions

    Out-LogFile -string "================================================================================"
    Out-LogFile -string "END START-DISTRIBUTIONLISTMIGRATION"
    Out-LogFile -string "================================================================================"

    if (($global:office365ReplacePermissionsErrors.count -gt 0) -or ($global:postCreateErrors.count -gt 0) -or ($onPremReplaceErrors.count -gt 0) -or ($office365ReplaceErrors.count -gt 0) -or ($global:office365ReplacePermissionsErrors.count -gt 0) -or ($global:generalErrors.count -gt 0))
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
        out-logfile -string ("General Errors: "+$global:generalErrors.count)
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
        
        if ($global:generalErrors.count -gt 0)
        {
            foreach ($generalError in $global:generalErrors)
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
        MSGraphAuthentication = $telemetryMSGraphAuthentication
        MSGraphUsers = $telemetryMSGraphUsers
        MSGraphGroups = $telemetryMSGraphGroups
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
        out-logfile -string "Telemetry1"
        out-logfile -string $traceModuleName
        out-logfile -string "Telemetry2"
        out-logfile -string $telemetryEventName
        out-logfile -string "Telemetry3"
        out-logfile -string $telemetryEventMetrics
        out-logfile -string "Telemetry4"
        out-logfile -string $telemetryEventProperties
        send-TelemetryEvent -traceModuleName $traceModuleName -eventName $telemetryEventName -eventMetrics $telemetryEventMetrics -eventProperties $telemetryEventProperties
    }

    if ($telemetryError -eq $TRUE)
    {
        out-logfile -string "" -isError:$TRUE
    }

    Start-ArchiveFiles -isSuccess:$TRUE -logFolderPath $logFolderPath
}