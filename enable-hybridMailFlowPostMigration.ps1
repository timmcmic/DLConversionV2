<#
    .SYNOPSIS

    This function enables the administrator to create the hybrid mail flow objects post migration.

    .DESCRIPTION

    This function enables the administrator to create the hybrid mail flow objects post migration.

    .PARAMETER GroupSMTPAddress

    The mail attribute of the group to search.

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
            [Parameter(Mandatory = $true)]
            [string]$globalCatalogServer,
            [Parameter(Mandatory = $true)]
            [pscredential]$activeDirectoryCredential,
            [Parameter(Mandatory = $true)]
            [string]$logFolderPath,
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
            [string]$exchangeAuthenticationMethod="Basic"
        )

        #Declare function variables.

        [boolean]$useOnPremisesExchange=$FALSE #Determines if function will utilize onpremises exchange during migration.
        [string]$exchangeOnPremisesPowershellSessionName="ExchangeOnPremises" #Defines universal name for on premises Exchange Powershell session.
        [string]$exchangeOnlinePowershellModuleName="ExchangeOnlineManagement" #Defines the exchage management shell name to test for.
        [string]$activeDirectoryPowershellModuleName="ActiveDirectory" #Defines the active directory shell name to test for.
        [string]$dlConversionPowershellModule="DLConversionV2"
        [string]$globalCatalogPort=":3268"
        [string]$globalCatalogWithPort=$globalCatalogServer+$globalCatalogPort

        #Static variables utilized for the Exchange On-Premsies Powershell.
   
        [string]$exchangeServerConfiguration = "Microsoft.Exchange" #Powershell configuration.
        [boolean]$exchangeServerAllowRedirection = $TRUE #Allow redirection of URI call.
        [string]$exchangeServerURI = "https://"+$exchangeServer+"/powershell" #Full URL to the on premises powershell instance based off name specified parameter.

        #Declare logging variables.

        [string]$office365DLConfigurationXML = "office365DLConfigurationXML"
        [string]$routingContactXML="routingContactXML"
        [string]$routingDynamicGroupXML="routingDynamicGroupXML"

        #Create the log file.

        new-LogFile -groupSMTPAddress $groupSMTPAddress.trim() -logFolderPath $logFolderPath

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "enable-hybridMailFlowPostMigration"
        Out-LogFile -string "********************************************************************************"

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

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "PARAMETERS"
        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string ("GroupSMTPAddress = "+$groupSMTPAddress)
        out-logfile -string ("Group SMTP Address Length = "+$groupSMTPAddress.length.tostring())
        out-logfile -string ("Spaces Removed Group SMTP Address: "+$groupSMTPAddress)
        out-logfile -string ("Group SMTP Address Length = "+$groupSMTPAddress.length.toString())
        Out-LogFile -string ("GlobalCatalogServer = "+$globalCatalogServer)
        Out-LogFile -string ("ActiveDirectoryUserName = "+$activeDirectoryCredential.UserName.tostring())
        Out-LogFile -string ("LogFolderPath = "+$logFolderPath)

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

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string " RECORD VARIABLES"
        Out-LogFile -string "********************************************************************************"

        out-logfile -string ("Global Catalog Port = "+$globalCatalogPort)
        out-logfile -string ("Global catalog string used for function queries ="+$globalCatalogWithPort)
        out-logFile -string ("Initial use of Exchange On Prem = "+$useOnPremisesExchange)
        Out-LogFile -string ("Exchange on prem powershell session name = "+$exchangeOnPremisesPowershellSessionName)
        Out-LogFile -string ("AD Global catalog powershell session name = "+$ADGlobalCatalogPowershellSessionName)
        Out-LogFile -string ("Exchange powershell module name = "+$exchangeOnlinePowershellModuleName)
        Out-LogFile -string ("Active directory powershell modulename = "+$activeDirectoryPowershellModuleName)

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

        if ($useOnPremisesExchange -eq $False)
        {
            out-logfile -string "Exchange on premsies information must be provided in order to enable hybrid mail flow." -isError:$TRUE
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

        Test-PowershellModule -powershellModuleName $exchangeOnlinePowershellModuleName -powershellVersionTest:$TRUE

        Out-LogFile -string "Calling Test-PowerShellModule to validate the Active Directory is installed."

        Test-PowershellModule -powershellModuleName $activeDirectoryPowershellModuleName

        out-logfile -string "Calling Test-PowershellModule to validate the DL Conversion Module version installed."

        Test-PowershellModule -powershellModuleName $dlConversionPowershellModule -powershellVersionTest:$TRUE

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

        #Now we can determine if exchange on premises is utilized and if so establish the connection.
   
        Out-LogFile -string "Determine if Exchange On Premises specified and create session if necessary."

        if ($useOnPremisesExchange -eq $TRUE)
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

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "END ESTABLISH POWERSHELL SESSIONS"
        Out-LogFile -string "********************************************************************************"

        #This function assumes that we need to start from routing contact creation.
        #This should not be necessary as we should have already reached this point simply by completing the migration.

        try {
            
        }
        catch {
            
        }

        Out-LogFile -string "END enable-hybridMailFlowPostMigration"
        Out-LogFile -string "********************************************************************************"
    }