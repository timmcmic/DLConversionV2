<#
    .SYNOPSIS

    This function enables the administrator to create the hybrid mail flow objects post migration.

    .DESCRIPTION

    This function enables the administrator to create the hybrid mail flow objects post migration.

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

    .PARAMETER LOGFOLDERPATH

    *REQUIRED*
    This is the logging directory for storing the migration log and all backup XML files.
    If running multiple SINGLE instance migrations use different logging directories.

    .OUTPUTS

    None

    .EXAMPLE

    enable-HybridMailFlow -groupSMTPAddress SMTPAddress -globalCatalogServer GC.domain.com -activeDirectoryCredential $cred -exchangeServer server.domain.com -exchangeServerCredential $cred -exchangeOnlineCredential $cred

    #>
    Function enable-hybridMailFlowPostMigration
     {
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
            [ValidateSet("Basic","Negotiate")]
            $activeDirectoryAuthenticationMethod="Negotiate",            
            #Exchange On-Premises Parameters
            [Parameter(Mandatory = $false)]
            [string]$exchangeServer=$NULL,
            [Parameter(Mandatory = $false)]
            [pscredential]$exchangeCredential=$NULL,
            [Parameter(Mandatory = $false)]
            [ValidateSet("Basic","Kerberos")]
            [string]$exchangeAuthenticationMethod="Kerberos",
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
            #Define other mandatory parameters
            [Parameter(Mandatory = $true)]
            [string]$logFolderPath,
            [Parameter(Mandatory = $true)]
            [string]$OU = "NotSet",
            #Define other optional paramters
            [Parameter(Mandatory = $false)]
            [string]$customRoutingDomain = ""
        )

        $global:blogURL = "https://timmcmic.wordpress.com"

        #Declare function variables.

        $global:logFile=$NULL #This is the global variable for the calculated log file name
        [string]$global:staticFolderName="\DLMigration\"

        $coreVariables = @{ 
            useOnPremisesExchange = @{ "Value" = $FALSE ; "Description" = "Boolean determines if Exchange on premises should be utilized" }
            exchangeOnPremisesPowershellSessionName = @{ "Value" = "ExchangeOnPremises" ; "Description" = "Static exchange on premises powershell session name" }
            exchangeOnlinePowershellModuleName = @{ "Value" = "ExchangeOnlineManagement" ; "Description" = "Static Exchange Online powershell module name" }
            activeDirectoryPowershellModuleName = @{ "Value" = "ActiveDirectory" ; "Description" = "Static active directory powershell module name" }
            dlConversionPowershellModule = @{ "Value" = "DLConversionV2" ; "Description" = "Static dlConversionv2 powershell module name" }
            msGraphAuthenticationModuleName = @{ "Value" = "Microsoft.Graph.Authentication" ; "Description" = "Static ms graph powershell name authentication" }
            msGraphUsersModuleName = @{ "Value" = "Microsoft.Graph.Users" ; "Description" = "Static ms graph powershell name users" }
            msGraphGroupsModuleName = @{ "Value" = "Microsoft.Graph.Groups" ; "Description" = "Static ms graph powershell name groups" }
            globalCatalogPort = @{ "Value" = ":3268" ; "Description" = "Global catalog port definition" }
            globalCatalogWithPort = @{ "Value" = ($globalCatalogServer+($corevariables.globalCatalogPort.value)) ; "Description" = "Global catalog server with port" }
        }

        #Static variables utilized for the Exchange On-Premsies Powershell.

        $onPremExchangePowershell = @{
            exchangeServerConfiguration = @{"Value" = "Microsoft.Exchange" ; "Description" = "Defines the Exchange Remote Powershell configuration"} 
            exchangeServerAllowRedirection = @{"Value" = $TRUE ; "Description" = "Defines the Exchange Remote Powershell redirection preference"} 
            exchangeServerURI = @{"Value" = "https://"+$exchangeServer+"/powershell" ; "Description" = "Defines the Exchange Remote Powershell connection URL"} 
            exchangeServerURIKerberos = @{"Value" = "http://"+$exchangeServer+"/powershell" ; "Description" = "Defines the Exchange Remote Powershell connection URL"} 
            exchangeOnPremisesPowershellSessionName = @{ "Value" = "ExchangePowershell" ; "Description" = "Exchange On-Premises powershell session name."}
        }
   

        #Declare logging variables.

        $xmlFiles = @{
            office365DLConfigurationXML = @{ "Value" =  "office365DLConfigurationXML" ; "Description" = "XML file that exports the Office 365 DL configuration"}
            routingContactXML= @{ "Value" = "routingContactXML" ; "Description" = "XML file holds the routing contact configuration when intially created"}
            routingDynamicGroupXML= @{ "Value" = "routingDynamicGroupXML" ; "Description" = "XML file holds the routing contact configuration when mail enabled"}
        }

        $routingContactConfig=$NULL
        $routingDynamicGroup=$NULL
        $office365DLConfiguration = $NULL

        $functionDynamicDL = "msExchDynamicDistributionList"

        #Create the log file.

        new-LogFile -groupSMTPAddress $groupSMTPAddress.trim() -logFolderPath $logFolderPath

        $traceFilePath = $logFolderPath + $global:staticFolderName

        out-logfile -string ("Trace file path: "+$traceFilePath)

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        write-hashTable -hashTable $xmlFiles
        write-hashTable -hashTable $onPremExchangePowershell
        write-hashTable -hashTable $coreVariables

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "enable-hybridMailFlowPostMigration"
        Out-LogFile -string "********************************************************************************"

        out-logfile -string "Set error action preference to continue to allow write-error in out-logfile to service exception retries."

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

        $groupSMTPAddress = remove-stringSpace -stringToFix $groupSMTPAddress
        $globalCatalogServer = remove-stringSpace -stringToFix $globalCatalogServer
        $logFolderPath = remove-stringSpace -stringToFix $logFolderPath 

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

        #Validate that both the exchange credential and exchange server are presented together.

        Out-LogFile -string "Validating that both ExchangeServer and ExchangeCredential are specified."

        if (($exchangeServer -eq "") -and ($exchangeCredential -ne $null))
        {
            #The exchange credential was specified but the exchange server was not specified.

            Out-LogFile -string "ERROR:  Exchange Server is required when specifying Exchange Credential." -isError:$TRUE
        }
        elseif (($exchangeCredential -eq $NULL) -and ($exchangeServer -ne ""))
        {
            #The exchange server was specified but the exchange credential was not.

            Out-LogFile -string "ERROR:  Exchange Credential is required when specifying Exchange Server." -isError:$TRUE
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

        #Validate that all information for the certificate connection has been provieed.

        if (($exchangeOnlineCertificateThumbPrint -ne "") -and ($exchangeOnlineOrganizationName -eq "") -and ($exchangeOnlineAppID -eq ""))
        {
            out-logfile -string "The exchange organization name and application ID are required when using certificate thumbprint authentication to Exchange Online." -isError:$TRUE
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

        if ($coreVariables.useOnPremisesExchange.value -eq $False)
        {
            out-logfile -string "Exchange on premises information must be provided in order to enable hybrid mail flow." -isError:$TRUE
        }

        if (Get-ADObjectConfiguration -groupSMTPAddress $groupSMTPAddress -globalCatalogServer $coreVariables.globalCatalogWithPort.value -parameterSet "*" -errorAction STOP -adCredential $activeDirectoryCredential -isValidTest:$TRUE)
        {
            $functionObjectTest = Get-ADObjectConfiguration -groupSMTPAddress $groupSMTPAddress -globalCatalogServer $coreVariables.globalCatalogWithPort.value -parameterSet "*" -errorAction STOP -adCredential $activeDirectoryCredential

            if ($functionObjectTest.objectClass[0] -eq $functionDynamicDL)
            {
                out-logfile -string "An existing dynamic DL was found with the same mail address as the migrated group."
                out-logfile -string "Removing this dynamic group and allowing enable to recreate it."

                remove-OnPremGroup -globalCatalogServer $coreVariables.globalCatalogWithPort.value -originalDLConfiguration $functionObjectTest -adCredential $activeDirectoryCredential -activeDirectoryAuthenticationMethod $activeDirectoryAuthenticationMethod
            }
            else 
            {
                out-logfile -string "An object exists with the same mail address as the migrated group.  Please review before proceeding." -isError:$TRUE
            }
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

        Test-PowershellModule -powershellModuleName $coreVariables.exchangeOnlinePowershellModuleName.value -powershellVersionTest:$TRUE

        Out-LogFile -string "Calling Test-PowerShellModule to validate the Active Directory is installed."

        Test-PowershellModule -powershellModuleName $coreVariables.activeDirectoryPowershellModuleName.value

        out-logfile -string "Calling Test-PowershellModule to validate the DL Conversion Module version installed."

        Test-PowershellModule -powershellModuleName $coreVariables.dlConversionPowershellModule.value -powershellVersionTest:$TRUE

        #Create the connection to exchange online.

        Out-LogFile -string "Calling New-ExchangeOnlinePowershellSession to create session to office 365."

        if ($exchangeOnlineCredential -ne $NULL)
        {
            #User specified non-certifate authentication credentials.

                try {
                    New-ExchangeOnlinePowershellSession -exchangeOnlineCredentials $exchangeOnlineCredential -exchangeOnlineEnvironmentName $exchangeOnlineEnvironmentName -debugLogPath $traceFilePath
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
                    new-ExchangeOnlinePowershellSession -exchangeOnlineCertificateThumbPrint $exchangeOnlineCertificateThumbPrint -exchangeOnlineAppId $exchangeOnlineAppID -exchangeOnlineOrganizationName $exchangeOnlineOrganizationName -exchangeOnlineEnvironmentName $exchangeOnlineEnvironmentName -debugLogPath $traceFilePath
                }
                catch {
                    out-logfile -string "Unable to create the exchange online connection using certificate."
                    out-logfile -string $_ -isError:$TRUE
                }
        }

        #Now we can determine if exchange on premises is utilized and if so establish the connection.
   
        Out-LogFile -string "Determine if Exchange On Premises specified and create session if necessary."

        if ($coreVariables.useOnPremisesExchange.value -eq $TRUE)
        {
            if ($exchangeAuthenticationMethod -eq "Basic")
            {
                try 
                {
                    Out-LogFile -string "Calling New-PowerShellSession"

                    $sessiontoImport=new-PowershellSession -credentials $exchangecredential -powershellSessionName $onPremExchangePowershell.exchangeOnPremisesPowershellSessionName.value -connectionURI $onPremExchangePowershell.exchangeServerURI.value -authenticationType $exchangeAuthenticationMethod -configurationName $onPremExchangePowershell.exchangeServerConfiguration.value -allowredirection $onPremExchangePowershell.exchangeServerAllowRedirection.value -requiresImport:$TRUE
                }
                catch 
                {
                    out-logfile -string $_
                    Out-LogFile -string "ERROR:  Unable to create powershell session." -isError:$TRUE
                }
            }
            elseif ($exchangeAuthenticationMethod -eq "Kerberos")
            {
                try 
                {
                    Out-LogFile -string "Calling New-PowerShellSession"

                    $sessiontoImport=new-PowershellSession -credentials $exchangecredential -powershellSessionName $onPremExchangePowershell.exchangeOnPremisesPowershellSessionName.value -connectionURI $onPremExchangePowershell.exchangeServerURIKerberos.value -authenticationType $exchangeAuthenticationMethod -configurationName $onPremExchangePowershell.exchangeServerConfiguration.value -allowredirection $onPremExchangePowershell.exchangeServerAllowRedirection.value -requiresImport:$TRUE
                }
                catch 
                {
                    out-logfile -string $_
                    Out-LogFile -string "ERROR:  Unable to create powershell session." -isError:$TRUE
                }
            }
            else 
            {
                out-logfile -string "Major issue creating on-premises Exchange powershell session - unknown - ending." -isError:$TRUE
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

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "END ESTABLISH POWERSHELL SESSIONS"
        Out-LogFile -string "********************************************************************************"

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

        #First step - gather the Office 365 DL Information.
        #The DL should be present in the service and previously migrated.

        try {
            out-logfile -string "Obtaining Office 365 Distribution List Configuration"

            $office365DLConfiguration = get-o365dlconfiguration -groupSMTPAddress $groupSMTPAddress -errorAction STOP
        }
        catch {
            out-logfile -string "Unable to obtain the distribution list information from Office 365."
            out-logfile -string $_ -isError:$TRUE
        }

        out-xmlFile -itemToExport $office365DLConfiguration -itemNameToExport $xmlFiles.office365DLConfigurationXML.value

        #Now that we have the configuration - we need to ensure dir sync is set to false.

        out-logfile -string "Testing to ensure that the distribution list is directory synchronized."

        out-logfile -string ("IsDirSynced: "+$office365DLConfiguration.isDirSynced)

        if ($office365DLConfiguration.isDirSynced -eq $FALSE)
        {
            out-logfile -string "The distribution list is cloud only - proceed."
        }
        else 
        {
            out-logfile -string "The distribution list is directory synchronized - this function may only run on cloud only groups." -isError:$TRUE    
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
            out-logfile -string "The administrator has specified a custom routing domain - maybe for legacy tenant implementations."

            $mailOnMicrosoftComDomain = $customRoutingDomain
        }

        #At this time test to ensure the routing contact is present.

        if ($office365DLConfiguration.recipientTypeDetails -ne "GroupMailbox")
        {
            out-logfile -string "Standard DL - use windows email address."

            $tempMailArray = $office365DLConfiguration.windowsEmailAddress.split("@")
        }
        else
        {
            out-logfile -string "Unified group - use primary SMTP address."

            $tempMailArray = $office365DLConfiguration.primarysmtpaddress.split("@")
        }

        foreach ($member in $tempMailArray)
        {
            out-logfile -string ("Temp Mail Address Member: "+$member)
        }

        $tempMailAddress = $tempMailArray[0]+"-MigratedByScript"

        out-logfile -string ("Temp routing contact address: "+$tempMailAddress)

        $tempMailAddress = $tempMailAddress+"@"+$tempMailArray[1]

        out-logfile -string ("Temp routing contact address: "+$tempMailAddress)

        try {
            $routingContactConfiguration = Get-ADObjectConfiguration -groupSMTPAddress $tempMailAddress -globalCatalogServer $coreVariables.globalCatalogWithPort.value -parameterSet "*" -errorAction STOP -adCredential $activeDirectoryCredential 

            out-logfile -string "Overriding OU selection by administrator - contact already exists.  Must be the same as contact."

            $OU = get-OULocation -originalDLConfiguration $routingContactConfiguration

            out-logfile -string "The routing contact was found and recorded."

            out-xmlFile -itemToExport $routingContactConfiguration -itemNameToExport $xmlFiles.routingContactXML.value
        }
        catch {
            out-logfile -string "The routing contact is not present - create the routing contact."
            out-logfile -string $_

            try{
                out-logfile -string "Creating the routing contact that is missing."

                new-routingContact -originalDLConfiguration $office365DLConfiguration -office365DlConfiguration $office365DLConfiguration -globalCatalogServer $globalCatalogServer -adCredential $activeDirectoryCredential -isRetry:$TRUE -isRetryOU $OU -customRoutingDomain $mailOnMicrosoftComDomain -activeDirectoryAuthenticationMethod $activeDirectoryAuthenticationMethod -errorAction STOP

                out-logfile -string "The routing contact was created successfully."
            }
            catch{
                out-logfile -string "The routing contact could not be created."
                out-logfile -string $_ 
            }
        }

        $loopCounter=0
        $stopLoop=$FALSE

        do {
            try {
                out-logfile -string "Re-obtaining the routing contact configuration."
    
                $routingContactConfiguration = Get-ADObjectConfiguration -groupSMTPAddress $tempMailAddress -globalCatalogServer $coreVariables.globalCatalogWithPort.value -parameterSet "*" -errorAction STOP -adCredential $activeDirectoryCredential 

                $stopLoop = $TRUE
            }
            catch {

                if ($loopCounter -lt 5)
                {
                    start-sleepProgress -sleepSeconds 5 -sleepString "Sleeping failed obtain contact..."
                    $loopCounter=$loopCounter+1
                }
                else
                {
                    out-logfile -string $_
                    out-logfile -string "Unable to obtain the routing contact information." -isError:$TRUE
                }
            }
        } until ($stopLoop -eq $TRUE)       

        out-xmlFile -itemToExport $routingContactConfiguration -itemNameToExport (($xmlFiles.routingContactXML.value)+"-Updated")

        #At this time the mail contact needs to be mail enabled.

        try {
            enable-mailRoutingContact -globalCatalogServer $globalCatalogServer -routingContactConfig $routingContactConfiguration -routingXMLFile $xmlFiles.routingcontactxml.Value -errorAction STOP
        }
        catch {
            out-logfile -string $_
            out-logfile -string "Unable to mail enable the routing contact." -isError:$TRUE
        }

        #Obtain the updated routing contact.

        try{
            out-logfile -string "Re-obtaining the routing contact configuration."

            $routingContactConfiguration = Get-ADObjectConfiguration -groupSMTPAddress $tempMailAddress -globalCatalogServer $coreVariables.globalCatalogWithPort.value -parameterSet "*" -errorAction STOP -adCredential $activeDirectoryCredential 
        }
        catch{
            out-logfile -string $_
            out-logfile -string "Unable to obtain the routing contact." -isError:$TRUE
        }

        out-xmlFile -itemToExport $routingContactConfiguration -itemNameToExport (($xmlFiles.routingContactXML.value)+"-Updated2")

        #The routing contact is now mail enabled.  Create the dynamic distribution group.

        try {
            out-logfile -string "Creating the dynamic distribution group for mail routing."

            Enable-MailDyamicGroup -globalCatalogServer $globalCatalogServer -originalDLConfiguration $office365DLConfiguration -routingContactConfig $routingContactConfiguration -isRetry:$TRUE -errorAction STOP
        }
        catch {
            out-logfile -string "Unable to create the dynamic distribution group."
            out-logfile -string $_ -isError:$TRUE
        }

        try{
            out-logfile -string "Re-obtaining the routing contact configuration."

            $routingDynamicGroup = Get-ADObjectConfiguration -groupSMTPAddress $groupSMTPAddress -globalCatalogServer $coreVariables.globalCatalogWithPort.value -parameterSet "*" -errorAction STOP -adCredential $activeDirectoryCredential 
        }
        catch{
            out-logfile -string $_
            out-logfile -string "Unable to obtain the routing contact." -isError:$TRUE
        }

        out-xmlFile -itemToExport $routingDynamicGroup -itemNameToExport $xmlFiles.routingDynamicGroupXML.value

        disable-allPowerShellSessions

        Out-LogFile -string "END enable-hybridMailFlowPostMigration"
        Out-LogFile -string "********************************************************************************"

        Start-ArchiveFiles -isSuccess:$TRUE -logFolderPath $logFolderPath
    }