
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

    The SMTP address of the distribution list to be migrated.

    .PARAMETER userName

    At minimum this must be a domain administrator in the domain where the group resides assuming the object has no dependencies on other forests or trees within active directory.
    In a multi forest environment where the group may contain objects from multiple forests recommend an enterprise administrator be utilized.

    .PARAMETER password

    The password for the administrator account specified in userName.

    .PARAMETER globalCatalogServer

    A global catalog server in the domain where the group resides. 
    
    .PARAMETER logFolder

    The location where logging for the migration should occur including all XML outputs for backups.

	.OUTPUTS

    Logs all activities and backs up all original data to the log folder directory.

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
        [boolean]$retainOffice365Settings=$false,
        [Parameter(Mandatory = $true)]
        [string]$dnNoSyncOU = $NULL,
        [Parameter(Mandatory = $false)]
        [boolean]$retainOriginalGroup = $FALSE,
        [Parameter(Mandatory = $false)]
        [boolean]$enableHybridMailflow = $FALSE
    )

    #Define global variables.

    $global:logFile=$NULL #This is the global variable for the calculated log file name
    $global:staticFolderName="\DLMigration"

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
    [array]$exchangeDLMembershipSMTP=$NULL #Array of DL membership from AD.
    [array]$exchangeRejectMessagesSMTP=$NULL #Array of members with reject permissions from AD.
    [array]$exchangeAcceptMessageSMTP=$NULL #Array of members with accept permissions from AD.
    [array]$exchangeManagedBySMTP=$NULL #Array of members with manage by rights from AD.
    [array]$exchangeModeratedBySMTP=$NULL #Array of members  with moderation rights.
    [array]$exchangeBypassModerationSMTP=$NULL #Array of objects with bypass moderation rights from AD.
    [array]$exchangeGrantSendOnBehalfToSMTP=$NULL

    #Define XML files to contain backups.

    [string]$originalDLConfigurationADXML = "originalDLConfigurationADXML" #Export XML file of the group attibutes direct from AD.
    [string]$originalDLConfigurationObjectXML = "originalDLConfigurationObjectXML" #Export of the ad attributes after selecting objects (allows for NULL objects to be presented as NULL)
    [string]$office365DLConfigurationXML = "office365DLConfigurationXML"
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
    [string]$allGroupsGrantSendOnBehalfTo = "allGroupsGrantSendOnBehalfToXML"
    [string]$allOffice365UniversalAcceptXML="allOffice365UniversalAcceptXML"
    [string]$allOffice365UniversalRejectXML="allOffice365UniversalRejectXML"
    [string]$allOffice365UniversalGrantSendOnBehalfToXML="allOffice365UniversalGrantSendOnBehalfToXML"



    #The following variables hold information regarding other groups in the environment that have dependnecies on the group to be migrated.

    [array]$allGroupsMemberOf=$NULL #Complete AD information for all groups the migrated group is a member of.
    [array]$allGroupsReject=$NULL #Complete AD inforomation for all groups that the migrated group has reject mesages from.
    [array]$allGroupsAccept=$NULL #Complete AD information for all groups that the migrated group has accept messages from.
    [array]$allGroupsBypassModeration=$NULL #Complete AD information for all groups that the migrated group has bypass moderations.
    [array]$allUsersForwardingAddress=$NULL #All users on premsies that have this group as a forwarding DN.
    [array]$allGroupsGrantSendOnBehalfTo=$NULL #All dependencies on premsies that have grant send on behalf to.

    #The following variables hold information regarding Office 365 objects that have dependencies on the migrated DL.

    [array]$allOffice365MemberOf=$NULL
    [array]$allOffice365Accept=$NULL
    [array]$allOffice365Reject=$NULL
    [array]$allOffice365BypassModeration=$NULL
    [array]$allOffice365ForwardingAddress=$NULL
    [array]$allOffice365GrantSendOnBehalfTo=$NULL
    [array]$allOffice365UniversalAccept=$NULL
    [array]$allOffice365UniversalReject=$NULL
    [array]$allOffice365UniversalGrantSendOnBehalfTo=$NULL

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

    Out-LogFile -string "********************************************************************************"

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "VARIABLES"
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

    $originalDLConfiguration = Get-OriginalDLConfiguration -groupSMTPAddress $groupSMTPAddress -globalCatalogServer $globalCatalogWithPort -parameterSet $dlPropertySet -errorAction STOP

    Out-LogFile -string "Log original DL configuration."
    out-logFile -string $originalDLConfiguration

    Out-LogFile -string "Create an XML file backup of the on premises DL Configuration"

    Out-XMLFile -itemToExport $originalDLConfiguration -itemNameToExport $originalDLConfigurationADXML

    #At thispoint the dl configuration has only those attributes populated.  We need the entire list including NULLS for work.

    $originalDLConfiguration = $originalDLConfiguration | select-object -property $dlPropertySet

    Out-LogFile -string "Log original DL configuration."
    out-logFile -string $originalDLConfiguration

    Out-LogFile -string "Create an XML file backup of the on premises DL Configuration"

    Out-XMLFile -itemToExport $originalDLConfiguration -itemNameToExport $originalDLConfigurationObjectXML

    Out-LogFile -string "Capture the original office 365 distribution list information."

    $office365DLConfiguration=Get-O365DLConfiguration -groupSMTPAddress $groupSMTPAddress

    Out-LogFile -string $office365DLConfiguration

    Out-LogFile -string "Create an XML file backup of the office 365 DL configuration."

    Out-XMLFile -itemToExport $office365DLConfiguration -itemNameToExport $office365DLConfigurationXML

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END GET ORIGINAL DL CONFIGURATION LOCAL AND CLOUD"
    Out-LogFile -string "********************************************************************************"

    Out-LogFile -string "Perform a safety check to ensure that the distribution list is directory sync."

    Invoke-Office365SafetyCheck -o365dlconfiguration $office365DLConfiguration

    #At this time we have the DL configuration on both sides and have checked to ensure it is dir synced.
    #Membership of attributes is via DN - these need to be normalized to SMTP addresses in order to find users in Office 365.

    #Start with DL membership and normallize.

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "BEGIN NORMALIZE DNS FOR ALL ATTRIBUTES"
    Out-LogFile -string "********************************************************************************"

    Out-LogFile -string "Invoke get-NormalizedDN to normalize the members DN to Office 365 identifier."

    if ($originalDLConfiguration.members -ne $NULL)
    {
        foreach ($DN in $originalDLConfiguration.members)
        {
            $exchangeDLMembershipSMTP+=get-normalizedDN -globalCatalogServer $globalCatalogWithPort -DN $DN
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
            $exchangeRejectMessagesSMTP+=get-normalizedDN -globalCatalogServer $globalCatalogWithPort -DN $DN
        }
    }

    Out-LogFile -string "REJECT GROUPS"

    if ($originalDLConfiguration.dlMemRejectPerms -ne $NULL)
    {
        foreach ($DN in $originalDLConfiguration.dlMemRejectPerms)
        {
            $exchangeRejectMessagesSMTP+=get-normalizedDN -globalCatalogServer $globalCatalogWithPort -DN $DN
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
            $exchangeAcceptMessageSMTP+=get-normalizedDN -globalCatalogServer $globalCatalogWithPort -DN $DN
        }
    }

    Out-LogFile -string "ACCEPT GROUPS"

    if ($originalDLConfiguration.dlMemSubmitPerms -ne $NULL)
    {
        foreach ($DN in $originalDLConfiguration.dlMemSubmitPerms)
        {
            $exchangeAcceptMessageSMTP+=get-normalizedDN -globalCatalogServer $globalCatalogWithPort -DN $DN
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
            $exchangeManagedBySMTP+=get-normalizedDN -globalCatalogServer $globalCatalogWithPort -DN $DN
        }
    }

    Out-LogFile -string "Process CoMANAGERS"

    if ($originalDLConfiguration.msExchCoManagedByLink -ne $NULL)
    {
        foreach ($DN in $originalDLConfiguration.msExchCoManagedByLink)
        {
            $exchangeManagedBySMTP+=get-normalizedDN -globalCatalogServer $globalCatalogWithPort -DN $DN
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
            $exchangeModeratedBySMTP+=get-normalizedDN -globalCatalogServer $globalCatalogWithPort -DN $DN
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
            $exchangeBypassModerationSMTP+=get-normalizedDN -globalCatalogServer $globalCatalogWithPort -DN $DN
        }
    }

    Out-LogFile -string "Invoke get-NormalizedDN to normalize the bypass moderation groups members DN to Office 365 identifier."

    Out-LogFile -string "Process BYPASS GROUPS"

    if ($originalDLConfiguration.msExchBypassModerationFromDLMembersLink -ne $NULL)
    {
        foreach ($DN in $originalDLConfiguration.msExchBypassModerationFromDLMembersLink)
        {
            $exchangeBypassModerationSMTP+=get-normalizedDN -globalCatalogServer $globalCatalogWithPort -DN $DN
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
            $exchangeGrantSendOnBehalfToSMTP+=get-normalizedDN -globalCatalogServer $globalCatalogWithPort -DN $DN
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

    out-logfile -string ("The number of objects included in the member migration: "+$exchangeDLMembershipSMTP.count)
    out-logfile -string ("The number of objects included in the reject memebers: "+$exchangeRejectMessagesSMTP.count)
    out-logfile -string ("The number of objects included in the accept memebers: "+$exchangeAcceptMessageSMTP.count)
    out-logfile -string ("The number of objects included in the managedBY memebers: "+$exchangeManagedBySMTP.count)
    out-logfile -string ("The number of objects included in the moderatedBY memebers: "+$exchangeModeratedBySMTP.count)
    out-logfile -string ("The number of objects included in the bypassModeration memebers: "+$exchangeBypassModerationSMTP.count)
    out-logfile -string ("The number of objects included in the grantSendOnBehalfTo memebers: "+$exchangeGrantSendOnBehalfToSMTP.count)

    #At this point we have obtained all the information relevant to the individual group.
    #It is possible that this group was a member of - or other groups have a dependency on this group.
    #We will implement a function to track those dependen$ocies.

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "BEGIN RECORD DEPENDENCIES ON MIGRATED GROUP"
    Out-LogFile -string "********************************************************************************"

    out-logfile -string "Get all the groups that this user is a member of - normalize to canonicalname."

    if ($originalDLConfiguration.memberOf -ne $NULL)
    {
        out-logfile -string "Calling get-CanonicalName."

        foreach ($DN in $originalDLConfiguration.memberof)
        {
            $allGroupsMemberOf += get-canonicalname -globalCatalog $globalCatalogWithPort -dn $DN
        }
    }

    if ($allGroupsMemberOf -ne $NULL)
    {
        out-logFile -string "The group to be migrated is a member of the following groups."
        out-logfile -string $allGroupsMemberOf
        out-logfile -string ("The number of groups that the migrated DL is a member of = "+$allGroupsMemberOf.count)
    }
    else 
    {
        out-logfile -string "The group is not a member of any other groups on premises."
    }

    #At this time we need to test groups to determine if there are any restrictions that the migrated DL has on them.

    Out-LogFile -string "Calling get-groupDependency for AcceptMessagesFrom"

    $allGroupsAccept = get-groupdependency -globalCatalogServer $globalCatalogWithPort -DN $originalDLConfiguration.distinguishedname -attributeType $acceptMessagesFromDLMembers

    if ($allGroupsAccept -ne $NULL)
    {
        #Groups were found that the migrated group had accept permissions.

        out-logfile -string "Groups were found that the distribution list to be migrated had accept messages from members set."
        out-logfile -string $allGroupsAccept
        out-logfile -string ("The number of other groups with accept rights = "+$allGroupsAccept.count)
    }
    else
    {
        out-logfile -string "No groups were found with accept rights for the migrated DL."
    }

    #At this time we need to test groups to determine if there are any restrictions that the migrated DL has on them.

    Out-LogFile -string "Calling get-groupDependency for Reject Messages From"

    $allGroupsReject = get-groupdependency -globalCatalogServer $globalCatalogWithPort -DN $originalDLConfiguration.distinguishedname -attributeType $rejectMessagesFromDLMembers

    if ($allGroupsReject -ne $NULL)
    {
        #Groups were found that the migrated group had accept permissions.
     
        out-logfile -string "Groups were found that the distribution list to be migrated had reject messages from members set."
        out-logfile -string $allGroupsReject
        out-logfile -string ("The number of other groups with accept rights = "+$allGroupsReject.count)
    }
    else
    {
        out-logfile -string "No groups were found with reject rights for the migrated DL."
    }

    #At this time we need to test groups to determine if there are any restrictions that the migrated DL has on them.

    Out-LogFile -string "Calling get-groupDependency for Bypass Moderation"
     
    $allGroupsBypassModeration = get-groupdependency -globalCatalogServer $globalCatalogWithPort -DN $originalDLConfiguration.distinguishedname -attributeType $bypassModerationFromDL

    if ($allGroupsBypassModeration -ne $NULL)
    {
        #Groups were found that the migrated group had accept permissions.

        out-logfile -string "Groups were found that the distribution list to be migrated had reject messages from members set."
        out-logfile -string $allGroupsBypassModeration
        out-logfile -string ("The number of other groups with accept rights = "+$allGroupsBypassModeration.count)
    }
    else
    {
        out-logfile -string "No groups were found with reject rights for the migrated DL."
    }

    #At this time we need to test users and determine if any of them have forwardingAddress set.

    $allUsersForwardingAddress = Get-GroupDependency -globalCatalogServer $globalCatalogWithPort -dn $originalDLConfiguration.distinguishedname -attributeType $forwardingAddressForDL -attributeUserorGroup "User"

    if ( $allUsersForwardingAddress -ne $NULL)
    {
        #Groups were found that the migrated group had accept permissions.

        out-logfile -string "Users were found that were set to forward to the distribution group that is being migrated."
        out-logfile -string  $allUsersForwardingAddress
        out-logfile -string ("The number of other groups with accept rights = "+$allUsersForwardingAddress.count)
    }
    else
    {
        out-logfile -string "No groups were found with the forwarding to the migrated DL."
    }

    $allGroupsGrantSendOnBehalfTo = get-groupdependency -globalCatalog $globalCatalogWithPort -dn $originalDLConfiguration.distinguishedname -attributeType $grantSendOnBehalfToDL

    if ($allGroupsGrantSendOnBehalfTo -ne $NULL)
    {
        #Groups were found that the migrated group had accept permissions.

        out-logfile -string "Groups were found where this group was granted permissions to send on behalf to."
        out-logfile -string  $allGroupsGrantSendOnBehalfTo 
        out-logfile -string ("The number of other groups with accept rights = "+$allGroupsGrantSendOnBehalfTo.count)
    }
    else
    {
        out-logfile -string "No groups were found with the grant send on behalf to the migrated DL."
    }
    

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

                test-o365Recipient -externalDirectoryObjectID $member.externalDirectoryObjectID -recipientSMTPAddress "None" -userPrincipalName "None"
            }
            elseif (($member.PrimarySMTPAddressOrUPN -ne $NULL) -and ($member.recipientoruser -eq "Recipient"))
            {
                out-LogFile -string "Testing based on Primary SMTP Address"
                out-logfile -string $member.PrimarySMTPAddressOrUPN
                out-logfile -string $member.recipientOrUser

                test-o365Recipient -externalDirectoryObjectID "None" -recipientSMTPAddress $member.PrimarySMTPAddressOrUPN -userPrincipalName "None"
            }
            elseif (($member.PrimarySMTPAddressOrUPN -ne $NULL) -and ($member.recipientoruser -eq "User"))
            {
                out-LogFile -string "Testing based on user principal name."
                out-logfile -string $member.PrimarySMTPAddressOrUPN
                out-logfile -string $member.recipientOrUser
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

                test-o365Recipient -externalDirectoryObjectID $member.externalDirectoryObjectID -recipientSMTPAddress "None" -userPrincipalName "None"
            }
            elseif (($member.PrimarySMTPAddressOrUPN -ne $NULL) -and ($member.recipientoruser -eq "Recipient"))
            {
                out-LogFile -string "Testing based on Primary SMTP Address"
                out-logfile -string $member.PrimarySMTPAddressOrUPN
                out-logfile -string $member.recipientOrUser

                test-o365Recipient -externalDirectoryObjectID "None" -recipientSMTPAddress $member.PrimarySMTPAddressOrUPN -userPrincipalName "None"
            }
            elseif (($member.PrimarySMTPAddressOrUPN -ne $NULL) -and ($member.recipientoruser -eq "User"))
            {
                out-LogFile -string "Testing based on user principal name."
                out-logfile -string $member.PrimarySMTPAddressOrUPN
                out-logfile -string $member.recipientOrUser
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

                test-o365Recipient -externalDirectoryObjectID $member.externalDirectoryObjectID -recipientSMTPAddress "None" -userPrincipalName "None"
            }
            elseif (($member.PrimarySMTPAddressOrUPN -ne $NULL) -and ($member.recipientoruser -eq "Recipient"))
            {
                out-LogFile -string "Testing based on Primary SMTP Address"
                out-logfile -string $member.PrimarySMTPAddressOrUPN
                out-logfile -string $member.recipientOrUser

                test-o365Recipient -externalDirectoryObjectID "None" -recipientSMTPAddress $member.PrimarySMTPAddressOrUPN -userPrincipalName "None"
            }
            elseif (($member.PrimarySMTPAddressOrUPN -ne $NULL) -and ($member.recipientoruser -eq "User"))
            {
                out-LogFile -string "Testing based on user principal name."
                out-logfile -string $member.PrimarySMTPAddressOrUPN
                out-logfile -string $member.recipientOrUser
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

                test-o365Recipient -externalDirectoryObjectID $member.externalDirectoryObjectID -recipientSMTPAddress "None" -userPrincipalName "None"
            }
            elseif (($member.PrimarySMTPAddressOrUPN -ne $NULL) -and ($member.recipientoruser -eq "Recipient"))
            {
                out-LogFile -string "Testing based on Primary SMTP Address"
                out-logfile -string $member.PrimarySMTPAddressOrUPN
                out-logfile -string $member.recipientOrUser

                test-o365Recipient -externalDirectoryObjectID "None" -recipientSMTPAddress $member.PrimarySMTPAddressOrUPN -userPrincipalName "None"
            }
            elseif (($member.PrimarySMTPAddressOrUPN -ne $NULL) -and ($member.recipientoruser -eq "User"))
            {
                out-LogFile -string "Testing based on user principal name."
                out-logfile -string $member.PrimarySMTPAddressOrUPN
                out-logfile -string $member.recipientOrUser
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

                test-o365Recipient -externalDirectoryObjectID $member.externalDirectoryObjectID -recipientSMTPAddress "None" -userPrincipalName "None"
            }
            elseif (($member.PrimarySMTPAddressOrUPN -ne $NULL) -and ($member.recipientoruser -eq "Recipient"))
            {
                out-LogFile -string "Testing based on Primary SMTP Address"
                out-logfile -string $member.PrimarySMTPAddressOrUPN
                out-logfile -string $member.recipientOrUser

                test-o365Recipient -externalDirectoryObjectID "None" -recipientSMTPAddress $member.PrimarySMTPAddressOrUPN -userPrincipalName "None"
            }
            elseif (($member.PrimarySMTPAddressOrUPN -ne $NULL) -and ($member.recipientoruser -eq "User"))
            {
                out-LogFile -string "Testing based on user principal name."
                out-logfile -string $member.PrimarySMTPAddressOrUPN
                out-logfile -string $member.recipientOrUser
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

                test-o365Recipient -externalDirectoryObjectID $member.externalDirectoryObjectID -recipientSMTPAddress "None" -userPrincipalName "None"
            }
            elseif (($member.PrimarySMTPAddressOrUPN -ne $NULL) -and ($member.recipientoruser -eq "Recipient"))
            {
                out-LogFile -string "Testing based on Primary SMTP Address"
                out-logfile -string $member.PrimarySMTPAddressOrUPN
                out-logfile -string $member.recipientOrUser

                test-o365Recipient -externalDirectoryObjectID "None" -recipientSMTPAddress $member.PrimarySMTPAddressOrUPN -userPrincipalName "None"
            }
            elseif (($member.PrimarySMTPAddressOrUPN -ne $NULL) -and ($member.recipientoruser -eq "User"))
            {
                out-LogFile -string "Testing based on user principal name."
                out-logfile -string $member.PrimarySMTPAddressOrUPN
                out-logfile -string $member.recipientOrUser
            }
        }
    }

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END VALIDATE RECIPIENTS IN CLOUD"
    Out-LogFile -string "********************************************************************************"

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

        $allOffice365MemberOf = Get-O365GroupDependency -dn $office365DLConfiguration.distinguishedName -attributeType $office365Members

        out-logfile -string ("The number of groups in Office 365 cloud only that the DL is a member of = "+$allOffice365MemberOf.count)

        $allOffice365Accept = Get-O365GroupDependency -dn $office365DLConfiguration.distinguishedName -attributeType $office365AcceptMessagesFrom

        out-logfile -string ("The number of groups in Office 365 cloud only that the DL has accept rights = "+$allOffice365Accept.count)

        $allOffice365Reject = Get-O365GroupDependency -dn $office365DLConfiguration.distinguishedName -attributeType $office365RejectMessagesFrom

        out-logfile -string ("The number of groups in Office 365 cloud only that the DL has reject rights = "+$allOffice365Reject.count)

        $allOffice365BypassModeration = Get-O365GroupDependency -dn $office365DLConfiguration.distinguishedName -attributeType $office365BypassModerationFrom

        out-logfile -string ("The number of groups in Office 365 cloud only that the DL has grant send on behalf to rights = "+$allOffice365BypassModeration.count)

        $allOffice365GrantSendOnBehalfTo = Get-O365GroupDependency -dn $office365DLConfiguration.distinguishedName -attributeType $office365GrantSendOnBehalfTo

        out-logfile -string ("The number of groups in Office 365 cloud only that the DL has reject rights = "+$allOffice365GrantSendOnBehalfTo.count)

        $allOffice365ForwardingAddress = Get-O365GroupDependency -dn $office365DLConfiguration.distinguishedName -attributeType $office365ForwardingAddress

        out-logfile -string ("The number of groups in Office 365 cloud only that the DL has forwarding on mailboxes = "+$allOffice365ForwardingAddress.count)

        $allOffice365UniversalAccept = Get-O365GroupDependency -dn $office365DLConfiguration.distinguishedName -attributeType $office365AcceptMessagesFrom -groupType "Unified"

        out-logfile -string ("The number of universal groups in the Office 365 cloud that the DL has accept rights on = "+$allOffice365UniversalAccept.count)

        $allOffice365UniversalReject = Get-O365GroupDependency -dn $office365DLConfiguration.distinguishedName -attributeType $office365RejectMessagesFrom -groupType "Unified"

        out-logfile -string ("The number of universal groups in the Office 365 cloud that the DL has accept rights on = "+$allOffice365UniversalReject.count)

        $allOffice365UniversalGrantSendOnBehalfTo = Get-O365GroupDependency -dn $office365DLConfiguration.distinguishedName -attributeType $office365GrantSendOnBehalfTo -groupType "Unified"

        out-logfile -string ("The number of universal groups in the Office 365 cloud that the DL has accept rights on = "+$allOffice365UniversalGrantSendOnBehalfTo.count)
        
    }
    else 
    {
        out-logfile -string "Administrator opted out of recording Office 365 dependencies."
    }

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END RETAIN OFFICE 365 GROUP DEPENDENCIES"
    Out-LogFile -string "********************************************************************************"

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "START Disable on premises distribution group."
    Out-LogFile -string "********************************************************************************"

    #Disable-OriginalDL -dn $originalDLConfiguration.distinguishedName -globalCatalogServer $globalCatalogServer -parameterSet $dlPropertySetToClear

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END VALIDATE RECIPIENTS IN CLOUD"
    Out-LogFile -string "********************************************************************************"

    Out-LogFile -string "================================================================================"
    Out-LogFile -string "END START-DISTRIBUTIONLISTMIGRATION"
    Out-LogFile -string "================================================================================"
}