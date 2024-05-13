
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

    .PARAMETER LOGFOLDERPATH

    Log folder to record operations log file to.

    .PARAMETER DATAPATH 

    Folder that contains the original dl configuration XML file.

   
    .OUTPUTS

    Logs all activities and backs up all original data to the log folder directory.
    Recreates the distribution group in active directory.

    .NOTES

    The following blog posts maintain documentation regarding this module.

    https://timmcmic.wordpress.com.  

    Refer to the first pinned blog post that is the table of contents.

    
    .EXAMPLE

    restore-migratedDistributionlist -globalCatalogServer GC -activeDirectoryCredential cred -logFolderPath Path -dataPath Path

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
        #Define Microsoft Graph Parameters
        [Parameter(Mandatory = $false)]
        [ValidateSet("China","Global","USGov","USGovDod")]
        [string]$msGraphEnvironmentName="Global",
        [Parameter(Mandatory=$true)]
        [string]$msGraphTenantID="",
        [Parameter(Mandatory=$false)]
        [string]$msGraphCertificateThumbprint="",
        [Parameter(Mandatory=$false)]
        [string]$msGraphApplicationID="",
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

    $global:blogURL = "https://timmcmic.wordpress.com"

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
    $telemetryMSGraphAuthentication = $NULL
    $telemetryMSGraphUsers = $NULL
    $telemetryMSGraphGroups = $NULL

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
        msGraphAuthenticationPowershellModuleName = @{ "Value" = "Microsoft.Graph.Authentication" ; "Description" = "Static ms graph powershell name authentication" }
        msGraphUsersPowershellModuleName = @{ "Value" = "Microsoft.Graph.Users" ; "Description" = "Static ms graph powershell name users" }
        msGraphGroupsPowershellModuleName = @{ "Value" = "Microsoft.Graph.Groups" ; "Description" = "Static ms graph powershell name groups" }
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

    [array]$dlPropertiesToClearModern='Member','Description','groupType',$onPremADAttributes.onPremAcceptMessagesFromSenders.Value,'DisplayName','DisplayNamePrintable',$onPremADAttributes.onPremRejectMessagesfromDLMembers.Value,$onPremADAttributes.onPremAcceptMessagesfromDLMembers.Value,'extensionAttribute1','extensionAttribute10','extensionAttribute11','extensionAttribute12','extensionAttribute13','extensionAttribute14','extensionAttribute15','extensionAttribute2','extensionAttribute3','extensionAttribute4','extensionAttribute5','extensionAttribute6','extensionAttribute7','extensionAttribute8','extensionAttribute9','legacyExchangeDN','mail','mailNickName','msExchRecipientDisplayType','msExchRecipientTypeDetails','msExchRemoteRecipientType',$onPremADAttributes.onPremBypassModerationFromDL.Value,$onPremADAttributes.onPremBypassModerationFromSenders.value,$onPremADAttributes.onPremCoManagedBy.value,'msExchEnableModeration','msExchExtensionCustomAttribute1','msExchExtensionCustomAttribute2','msExchExtensionCustomAttribute3','msExchExtensionCustomAttribute4','msExchExtensionCustomAttribute5','msExchGroupDepartRestriction','msExchGroupJoinRestriction','msExchHideFromAddressLists',$onPremADAttributes.onPremModeratedBy.value,'msExchModerationFlags','msExchRequireAuthToSendTo','msExchSenderHintTranslations','oofReplyToOriginator','proxyAddresses',$onPremADAttributes.onPremGrantSendOnBehalfTo.Value,'reportToOriginator','reportToOwner','unauthorig','msExchArbitrationMailbox','msExchPoliciesIncluded','msExchUMDtmfMap','msExchVersion','showInAddressBook','msExchAddressBookFlags','msExchBypassAudit','msExchGroupExternalMemberCount','msExchGroupMemberCount','msExchGroupSecurityFlags','msExchLocalizationFlags','msExchMailboxAuditEnable','msExchMailboxAuditLogAgeLimit','msExchMailboxFolderSet','msExchMDBRulesQuota','msExchPoliciesIncluded','msExchProvisioningFlags','msExchRecipientSoftDeletedStatus','msExchRoleGroupType','msExchTransportRecipientSettingsFlags','msExchUMDtmfMap','msExchUserAccountControl','msExchVersion','sAMAccountName' #Properties Exchange 2016 or newer schema.
    [array]$backLinkAttributes = 'publicDelegatesBL','msExchCoManagedObjectsBL','msExchBypassModerationFromDLMembersBL','memberOf','dLMemSubmitPermsBL','dLMemRejectPermsBL'

    #Define XML files to contain backups.

    $xmlFiles = @{
        originalDLConfigurationADXML = @{ "Value" =  "originalDLConfigurationADXML.xml" ; "Description" = "XML file that exports the original DL configuration"}
        originalDLConfigurationADXMLOutput = @{ "Value" =  "originalDLConfigurationADXML" ; "Description" = "XML file that exports the original DL configuration"}
        originalDLConfigurationUpdatedXML = @{ "Value" =  "originalDLConfigurationUpdatedXML" ; "Description" = "XML file that exports the updated DL configuration"}
        adObjectWithAddressXML = @{ "Value" =  "adObjectWithAddressXML" ; "Description" = "XML file that exports the updated DL configuration"}
        routingContactXML = @{ "Value" =  "routingContactXML" ; "Description" = "XML file that exports the updated DL configuration"}
        importedDLXML = @{ "Value" =  "importedDLXML" ; "Description" = "XML file that exports the updated DL configuration"}

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

    [boolean]$removeGroupViaGraph = $true

     #Establish required MS Graph Scopes

     $msGraphScopesRequired = @("User.Read.All", "Group.Read.All")

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
    $msGraphTenantID = remove-stringSpace -stringToFix $msGraphTenantID
    $msGraphCertificateThumbprint = remove-stringSpace -stringToFix $msGraphCertificateThumbprint
    $msGraphApplicationID = remove-stringSpace -stringToFix $msGraphApplicationID

    if($dataPath.remove(0,($dataPath.length - 1)) -ne "\")
    {
        out-logfile -string "Data path does not have trailing \"
        $dataPath = $dataPath + $blackSlash
        out-logfile -string $dataPath
    }

    $importDataFile = $dataPath + $xmlFiles.originalDLConfigurationADXML.Value

    out-logfile -string ("Calculdated data file for import: "+$importDataFile)

    if ($msGraphCertificateThumbprint -eq "")
    {
        out-logfile -string "Validation all components available for MSGraph Cert Auth"

        start-parameterValidation -msGraphCertificateThumbPrint $msGraphCertificateThumbprint -msGraphTenantID $msGraphTenantID -msGraphApplicationID $msGraphApplicationID
    }
    else
    {
        out-logfile -string "MS graph cert auth is not being utilized - assume interactive auth."
    }

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

    out-logfile -string "Calling Test-PowershellModule to validate the Microsoft Graph Authentication versions installed."

    $telemetryMSGraphAuthentication = test-powershellModule -powershellmodulename $corevariables.msgraphauthenticationpowershellmodulename.value -powershellVersionTest:$TRUE
 
    out-logfile -string "Calling Test-PowershellModule to validate the Microsoft Graph Users versions installed."
 
    $telemetryMSGraphUsers = test-powershellModule -powershellmodulename $corevariables.msgraphuserspowershellmodulename.value -powershellVersionTest:$TRUE
 
    out-logfile -string "Calling Test-PowershellModule to validate the Microsoft Graph Users versions installed."
 
    $telemetryMSGraphGroups = test-powershellModule -powershellmodulename $corevariables.msgraphgroupspowershellmodulename.value -powershellVersionTest:$TRUE

    Out-LogFile -string "Calling nea-msGraphPowershellSession to create new connection to msGraph active directory."

    if ($msGraphCertificateThumbprint -ne "")
    {
        #User specified thumbprint authentication.

            try {
                new-msGraphPowershellSession -msGraphCertificateThumbprint $msGraphCertificateThumbprint -msGraphApplicationID $msGraphApplicationID -msGraphTenantID $msGraphTenantID -msGraphEnvironmentName $msGraphEnvironmentName -msGraphScopesRequired $msGraphScopesRequired
            }
            catch {
                out-logfile -string "Unable to create the msgraph connection using certificate."
                out-logfile -string $_ -isError:$TRUE
            }
    }
    elseif ($msGraphTenantID -ne "")
    {
            try
            {
                new-msGraphPowershellSession -msGraphTenantID $msGraphTenantID -msGraphEnvironmentName $msGraphEnvironmentName -msGraphScopesRequired $msGraphScopesRequired
            }
            catch
            {
                out-logfile -=string "Unable to create the msgraph connection using tenant ID and credentials."
            }
    }   

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

    try 
    {
        out-xmlFile -itemTOExport $importedDLConfiguration -itemNameTOExport $xmlFiles.importedDLXML.value -errorAction Stop
    }
    catch 
    {
        out-logfile -string $_ -isError:$TRUE
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

        try {
            out-xmlFile -itemToExport $originalDLConfiguration -itemNameToExport $xmlFiles.originalDLConfigurationADXMLOutput.value -errorAction STOP
        }
        catch {
            out-logfile -string $_ -isError:$TRUE
        }

        out-logfile -string "Remove the group via graph to allow for soft matching during next AD Sync cycle."

        try {
            $mgGroup = get-mgGroup -filter "OnPremisesSecurityIdentifier eq '$($originalDLConfiguration.objectSID)'" -errorAction Stop
        }
        catch {
            out-logfile -string "Error capturing the group via graph - this may or may not be an issue."
            out-logfile -string $_
        }

        if ($null -ne $mgGroup)
        {
            out-logfile -string "Group was found by on premsies object SID in Entra ID - remove to allow for soft match."
            try {
                remove-mgGroup -GroupId $mgGroup.id -confirm:$false
            }
            catch {
                out-logfile -string "Error removing the group via graph - this may or may not be an issue."
                out-logfile $_ -isError:$TRUE
            }
        }
        else 
        {
            out-logfile -string "The group was not found by onPremisesObjectSID in Entra ID."
        }       
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

        out-logfile -string "Resetting the attributes of the group to match the backup information."

        foreach ($property in $importedDLConfiguration.psObject.properties)
        {
            out-logfile -string ("Evaluating property: "+$property.name)

            if ($dlPropertiesToClearModern.toLower().contains($property.name.toLower()))
            {
                out-logfile -string "The property is a writeable property contained in the backup set."

                if (($property.Value.count) -gt 1)
                {
                    out-logfile -string "Multivalued property - use add."

                    foreach ($value in $property.Value)
                    {
                        out-logfile -string ("Adding value: "+$value+" to property "+$property.name)

                        try {
                            set-ADObject -identity $originalDLConfiguration.objectGUID -add @{$property.Name = $value.toString()} -server $coreVariables.globalCatalogWithPort.value -credential $activeDirectoryCredential -authType $activeDirectoryAuthenticationMethod -errorAction STOP
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

                    if ($null -ne $property.value)
                    {
                        out-logfile -string "Single value property is not null."

                        try {
                            set-ADObject -identity $originalDLConfiguration.objectGUID -Replace @{$property.Name = $property.value} -server $coreVariables.globalCatalogWithPort.value -credential $activeDirectoryCredential -authType $activeDirectoryAuthenticationMethod -errorAction STOP
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
                    else 
                    {
                        out-logfile -string "Single value property is null - skip."
                    }
                  
                }
            }
            else 
            {
                out-logfile -string ("The property is not a writeable property - skip.")
            }
        }

        try
        {
            $originalDLConfiguration = Get-ADObject -identity $importedDLConfiguration.objectGUID -properties * -server $coreVariables.globalCatalogWithPort.value -credential $activeDirectoryCredential -authType $activeDirectoryAuthenticationMethod -errorAction STOP
        }
        catch
        {
            out-logfile -string $_ -isError:$TRUE
        }
    }
    else 
    {
        out-logfile -string "The original group no longer exists - recreate the group."

        try 
        {
            new-ADGroup -Description $importedDLConfiguration.description -displayName $importedDlConfiguration.displayName -groupCategory "Distribution" -groupScope "Universal" -path (get-OULocation -originalDLConfiguration $importedDLConfiguration) -name $importedDLConfiguration.name -server $coreVariables.globalCatalogWithPort.value -credential $activeDirectoryCredential -authType $activeDirectoryAuthenticationMethod -otherAttributes @{mail = $importedDLConfiguration.mail} -errorAction STOP
        }
        catch 
        {
            out-logfile -string $_
            out-logfile -string "Unable to restore the distribution list by creating a new group." -isError:$TRUE
        }

        try 
        {
            $tempMail = $importedDLConfiguration.mail
            $originalDLConfiguration = Get-ADObject -filter "mail -eq `"$tempMail`"" -properties * -server $coreVariables.globalCatalogWithPort.value -credential $activeDirectoryCredential -authType $activeDirectoryAuthenticationMethod -errorAction STOP
        }
        catch 
        {
            out-logfile -string $_
            out-logfile -string "Unable to obtain the newly created group by mail address."
        }

        out-logfile -string "Resetting the attributes of the group to match the backup information."

        foreach ($property in $importedDLConfiguration.psObject.properties)
        {
            out-logfile -string ("Evaluating property: "+$property.name)

            if ($dlPropertiesToClearModern.toLower().contains($property.name.toLower()))
            {
                out-logfile -string "The property is a writeable property contained in the backup set."

                if (($property.Value.count) -gt 1)
                {
                    out-logfile -string "Multivalued property - use add."

                    foreach ($value in $property.Value)
                    {
                        out-logfile -string ("Adding value: "+$value+" to property "+$property.name)

                        try {
                            set-ADObject -identity $originalDLConfiguration.objectGUID -add @{$property.Name = $value.toString()} -server $coreVariables.globalCatalogWithPort.value -credential $activeDirectoryCredential -authType $activeDirectoryAuthenticationMethod -errorAction STOP
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

                    if ($null -ne $property.value)
                    {
                        out-logfile -string "Single value property is not null."

                        try {
                            set-ADObject -identity $originalDLConfiguration.objectGUID -Replace @{$property.Name = $property.value} -server $coreVariables.globalCatalogWithPort.value -credential $activeDirectoryCredential -authType $activeDirectoryAuthenticationMethod -errorAction STOP
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
                    else 
                    {
                        out-logfile -string "Single value property is null - skip."
                    }
                  
                }
            }
            else 
            {
                out-logfile -string ("The property is not a writeable property - skip.")
            }
        }

        out-logfile -string "This group was recreated - attempt to reset other backlink attributes."

        foreach ($property in $importedDLConfiguration.psObject.properties)
        {
            out-logfile -string ("Evaluating property: "+$property.name)

            if ($backLinkAttributes.toLower().contains($property.name.toLower()))
            {
                out-logfile -string "This multivalued property exists on the object - convert the property to the non-backlink"

                switch ($property.name)
                {
                    $onPremADAttributes.onPremGrantSendOnBehalfToBL.Value {
                        $attribute = $onPremADAttributes.onPremGrantSendOnBehalfTo.value
                    }
                    $onPremADAttributes.onPremCoManagedByBL.Value {
                        $attribute = $onPremADAttributes.onPremCoManagedBy.value
                    }
                    $onPremADAttributes.onPremBypassModerationFromDLMembersBL.Value {
                        $attribute = $onPremADAttributes.onPremBypassModerationFromSenders.value
                    }
                    $onPremADAttributes.onPremMemberOf.Value {
                        $attribute = $onPremADAttributes.onPremMembers.Value
                    }
                    $onPremADAttributes.onPremAcceptMessagesFromDLMembersBL.value {
                        $attribute = $onPremADAttributes.onPremAcceptMessagesFromDLMembers.value
                    }
                    $onPremADAttributes.onPremRejectMessagesFromDLMembersBL.Value {
                        $attribute = $onPremADAttributes.onPremRejectMessagesFromDLMembers.value
                    }
                }

                out-logfile -string ("Attribute to modify: "+$attribute)

                if (($property.Value.count) -gt 1)
                {
                    out-logfile -string "Multivalued property - use add."

                    foreach ($value in $property.Value)
                    {
                        out-logfile -string ("Adding value: "+$value+" to property "+$property.name)

                        try {
                            set-ADObject -identity $value -add @{$attribute = $originalDLConfiguration.distinguishedName} -credential $activeDirectoryCredential -authType $activeDirectoryAuthenticationMethod -errorAction STOP
                        }
                        catch {
                            out-logfile -string $_

                            $functionObject = New-Object PSObject -Property @{
                                PropertyName = $attribute
                                PropertyValue = $value
                                Operation = "Add"
                                ErrorDetails = $_
                                ErrorCommon = "Unable to add the new list to this attribute on another object."
                            }

                            $onPremReplaceErrors += $functionObject
                        }
                    }
                }
                else 
                {
                    out-logfile -string "Single value property - use replace."

                    if ($null -ne $property.value)
                    {
                        out-logfile -string "Single value property is not null."

                        try {
                            set-ADObject -identity $value -Replace @{$attribute = $originalDLConfiguration.distinguishedName} -credential $activeDirectoryCredential -authType $activeDirectoryAuthenticationMethod -errorAction STOP
                        }
                        catch {
                            out-logfile -string $_
    
                            $functionObject = New-Object PSObject -Property @{
                                PropertyName = $attribute
                                PropertyValue = $value
                                Operation = "Replace"
                                ErrorDetails = $_
                                ErrorCommon = "Unable to add the new list to this attribute on another object."
                            }
    
                            $onPremReplaceErrors += $functionObject
                        }
                    }
                    else 
                    {
                        out-logfile -string "Single value property is null - skip."
                    }
                  
                }
            }
            else 
            {
                out-logfile -string ("The property is not a writeable property - skip.")
            }
        }

        try
        {
            $originalDLConfiguration = Get-ADObject -identity $originalDLConfiguration.distinguishedName -properties * -server $coreVariables.globalCatalogWithPort.value -credential $activeDirectoryCredential -authType $activeDirectoryAuthenticationMethod -errorAction STOP
        }
        catch
        {
            out-logfile -string $_ -isError:$TRUE
        }
    }

    try
    {
        out-xmlFile -itemToExport $originalDLConfiguration -itemNameTOExport $xmlFiles.originalDLConfigurationUpdatedXML.Value
    }
    catch {
        out-logfile -string $_ -isError:$TRUE
    }

    out-logfile -string "Output any error information detected."

    if ($onPremReplaceErrors.count -gt 0)
    {
        out-logfile -string ""
        out-logfile -string "+++++"
        out-logfile -string "++++++++++"
        out-logfile -string "RESTORATION ERRORS OCCURED - REFER TO LIST BELOW FOR ERRORS"
        out-logfile -string ("On-Premises Replace Errors :"+$onPremReplaceErrors.count)
        out-logfile -string "++++++++++"
        out-logfile -string "+++++"
        out-logfile -string ""

        if ($onPremReplaceErrors.count -gt 0)
        {
            foreach ($onPremReplaceError in $onPremReplaceErrors)
            {
                out-logfile -string "====="
                out-logfile -string "Replace On Premises Errors:"
                out-logfile -string ("Property Name: "+$onPremReplaceError.propertyName)
                out-logfile -string ("Property Value: "+$onPremReplaceError.propertyValue)
                out-logfile -string ("Operation: "+$onPremReplaceError.operation)
                out-logfile -string ("ErrorDetails: "+$onPremReplaceError.errorDetails)
                out-logfile -string ("ErrorCommon: "+$onPremReplaceError.errorCommon)
                out-logfile -string "====="
            }
        }

        out-logfile -string ""
        out-logfile -string "+++++"
        out-logfile -string "++++++++++"
        out-logfile -string "Errors were encountered in the distribution list creation process requiring administrator review."
        out-logfile -string "Although the restoration may have been successful - manual actions may need to be taken to full complete the migration."
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
        MSGraphAuthentication = $telemetryMSGraphAuthentication
        MSGraphUsers = $telemetryMSGraphUsers
        MSGraphGroups = $telemetryMSGraphGroups
        OSVersion = $telemetryOSVersion
        MigrationStartTimeUTC = $telemetryStartTime
        MigrationEndTimeUTC = $telemetryEndTime
        MigrationErrors = $telemetryError
    }

    if (($allowTelemetryCollection -eq $TRUE) -and ($allowDetailedTelemetryCollection -eq $FALSE))
    {
        $telemetryEventMetrics = @{
            MigrationElapsedSeconds = $telemetryElapsedSeconds
        }
    }
    elseif (($allowTelemetryCollection -eq $TRUE) -and ($allowDetailedTelemetryCollection -eq $TRUE))
    {
        $telemetryEventMetrics = @{
            MigrationElapsedSeconds = $telemetryElapsedSeconds
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