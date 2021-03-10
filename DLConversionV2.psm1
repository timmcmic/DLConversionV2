
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

    Get-ExPerfwiz

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
        [string]$exchangeAuthenticationMethod="Basic"
    )

    #Define variables utilized in the core function that are not defined by parameters.

    [string]$logFile=$NULL #Establishes the log file that will be utilized by called functions to log information.
    [string]$xmlFile=$NULL
    [boolean]$useOnPremsiesExchange=$FALSE #Determines if function will utilize onpremises exchange during migration.
    [boolean]$useAADConnect=$FALSE #Determines if function will utilize aadConnect during migration.
    [string]$exchangeOnPremisesPowershellSessionName="ExchangeOnPremises" #Defines universal name for on premises Exchange Powershell session.
    [string]$aadConnectPowershellSessionName="AADConnect" #Defines universal name for aadConnect powershell session.
    [string]$ADGlobalCatalogPowershellSessionName="ADGlobalCatalog" #Defines universal name for ADGlobalCatalog powershell session.

    #Static variables utilized for the Exchange On-Premsies Powershell.
   
    [string]$exchangeServerConfiguration = "Microsoft.Exchange"
    [boolean]$exchangeServerAllowRedirection = $TRUE
    [string]$exchangeServerURI = "https://"+$exchangeServer+"/powershell"

    #On premises variables for the distribution list to be migrated.

    $originalDLConfiguration=$NULL #This holds the on premises DL configuration for the group to be migrated.
    [string]$originalDLConfigurationXML = "originalDLConfigurationXML"

    #Cloud variables for the distribution list to be migrated.

    $office365DLConfiguration = $NULL #This holds the office 365 DL configuration for the group to be migrated.

    #Log start of DL migration to the log file.

    new-LogFile -groupSMTPAddress $groupSMTPAddress -logfolderpath $logFolderPath

    Out-LogFile -string "================================================================================"
    Out-LogFile -string "BEGIN START-DISTRIBUTIONLISTMIGRATION"
    Out-LogFile -string "================================================================================"

    #Output parameters to the log file for recording.
    #For parameters that are optional if statements determine if they are populated for recording.

    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************************************************************************"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "PARAMETERS"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************************************************************************"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string ("GroupSMTPAddress = "+$groupSMTPAddress)
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string ("GlobalCatalogServer = "+$globalCatalogServer)
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string ("ActiveDirectoryUserName = "+$activeDirectoryCredential.UserName.tostring())
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string ("LogFolderPath = "+$logFolderPath)

    if ($aadConnectServer -ne "")
    {
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string ("AADConnectServer = "+$aadConnectServer)
    }

    if ($aadConnectCredential -ne $null)
    {
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string ("AADConnectUserName = "+$aadConnectCredential.UserName.tostring())
    }

    if ($exchangeServer -ne "")
    {
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string ("ExchangeServer = "+$exchangeServer)
    }

    if ($exchangecredential -ne $null)
    {
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string ("ExchangeUserName = "+$exchangeCredential.UserName.toString())
    }

    if ($exchangeOnlineCredential -ne $null)
    {
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string ("ExchangeOnlineUserName = "+ $exchangeOnlineCredential.UserName.toString())
    }

    if ($exchangeOnlineCertificateThumbPrint -ne "")
    {
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string ("ExchangeOnlineCertificateThumbprint = "+$exchangeOnlineCertificateThumbPrint)
    }

    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string ("ExchangeAuthenticationMethod = "+$exchangeAuthenticationMethod)

    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************************************************************************"

    #Perform paramter validation manually.

    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************************************************************************"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "ENTERING PARAMTER VALIDATION"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************************************************************************"

    #Test to ensure that if any of the aadConnect parameters are passed - they are passed together.

    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "Validating that both AADConnectServer and AADConnectCredential are specified"
   
    if (($aadConnectServer -eq "") -and ($aadConnectCredential -ne $null))
    {
        #The credential was specified but the server name was not.

        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "ERROR:  AAD Connect Server is required when specfying AAD Connect Credential" -isError:$TRUE
    }
    elseif (($aadConnectCredential -eq $NULL) -and ($aadConnectServer -ne ""))
    {
        #The server name was specified but the credential was not.

        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "ERROR:  AAD Connect Credential is required when specfying AAD Connect Server" -isError:$TRUE
    }
    elseif (($aadConnectCredential -ne $NULL) -and ($aadConnectServer -ne ""))
    {
        #The server name and credential were specified for AADConnect.

        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "AADConnectServer and AADConnectCredential were both specified."
    
        #Set useAADConnect to TRUE since the parameters necessary for use were passed.
        
        $useAADConnect=$TRUE

        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string ("Set useAADConnect to TRUE since the parameters necessary for use were passed. - "+$useAADConnect)
    }
    else
    {
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string ("Neither AADConnect Server or AADConnect Credentials specified - retain useAADConnect FALSE - "+$useAADConnect)
    }

    #Validate that both the exchange credential and exchange server are presented together.

    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "Validating that both ExchangeServer and ExchangeCredential are specified."

    if (($exchangeServer -eq "") -and ($exchangeCredential -ne $null))
    {
        #The exchange credential was specified but the exchange server was not specified.

        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "ERROR:  Exchange Server is required when specfying Exchange Credential." -isError:$TRUE
    }
    elseif (($exchangeCredential -eq $NULL) -and ($exchangeServer -ne ""))
    {
        #The exchange server was specified but the exchange credential was not.

        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "ERROR:  Exchange Credential is required when specfying Exchange Server." -isError:$TRUE
    }
    elseif (($exchangeCredential -ne $NULL) -and ($exchangetServer -ne ""))
    {
        #The server name and credential were specified for Exchange.

        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "The server name and credential were specified for Exchange."

        #Set useOnPremisesExchange to TRUE since the parameters necessary for use were passed.

        $useOnPremsiesExchange=$TRUE

        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string ("Set useOnPremsiesExchanget to TRUE since the parameters necessary for use were passed - "+$useOnPremsiesExchange)
    }
    else
    {
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string ("Neither Exchange Server or Exchange Credentials specified - retain useOnPremisesExchange FALSE - "+$useOnPremsiesExchange)
    }

    #Validate that only one method of engaging exchange online was specified.

    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "Validating that Exchange Credentials are not specified with Exchange Certificate Thumbprint"

    if (($exchangeOnlineCredential -ne $NULL) -and ($exchangeOnlineCertificateThumbPrint -ne ""))
    {
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "ERROR:  Only one method of cloud authentication can be specified.  Use either cloud credentials or cloud certificate thumbprint." -isError:$TRUE
    }
    else
    {
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "Only one method of Exchange Online authentication specified."
    }

    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "END PARAMETER VALIDATION"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************************************************************************"

    #If exchange server information specified - create the on premises powershell session.

    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************************************************************************"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "ESTABLISH POWERSHELL SESSIONS"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************************************************************************"

   #Test to determine if the exchange online powershell module is installed.
   #The exchange online session has to be established first or the commandlet set from on premises fails.

   Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "Calling Test-ExchangeOnlinePowershell to ensure modules are installed."
    
   Test-ExchangeOnlinePowerShell

   #Create the connection to exchange online.

   Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "Calling New-ExchangeOnlinePowershellSession to create session to office 365."

   if ($exchangeOnlineCredential -ne $NULL)
   {
       #User specified non-certifate authentication credentials.

       New-ExchangeOnlinePowershellSession -exchangeOnlineCredentials $exchangeOnlineCredential
   }

   #Now we can determine if exchange on premises is utilized and if so establish the connection.
   
    if ($useOnPremsiesExchange -eq $TRUE)
    {
        try 
        {
            Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "Calling New-PowerShellSession"

            $sessiontoImport=new-PowershellSession -credentials $exchangecredential -powershellSessionName $exchangeOnPremisesPowershellSessionName -connectionURI $exchangeServerURI -authenticationType $exchangeAuthenticationMethod -configurationName $exchangeServerConfiguration -allowredirection $exchangeServerAllowRedirection -requiresImport:$TRUE
        }
        catch 
        {
            Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "ERROR:  Unable to create powershell session." -isError:$TRUE
        }
        try 
        {
            Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "Calling import-PowerShellSession"

            import-powershellsession -powershellsession $sessionToImport
        }
        catch 
        {
            Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "ERROR:  Unable to create powershell session." -isError:$TRUE
        } 
    }
    else
    {
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "No on premises Exchange specified - skipping setup of powershell session."
    }

    #If the administrator has specified aad connect information - establish the powershell session.

    if ($useAADConnect -eq $TRUE)
    {
        New-PowershellSession -Server $aadConnectServer -Credentials $aadConnectCredential -PowershellSessionName $aadConnectPowershellSessionName
    }

    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "Establish powershell session to the global catalog server specified."

    new-powershellsession -server $globalCatalogServer -credentials $activeDirectoryCredential -powershellsessionname $ADGlobalCatalogPowershellSessionName

    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************************************************************************"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "END ESTABLISH POWERSHELL SESSIONS"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************************************************************************"

    #At this point we are ready to capture the original DL configuration.  We'll use the global catalog powershell session to do this.

    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "Getting the original DL Configuration"

    $originalDLConfiguration = Get-OriginalDLConfiguration -powershellSessionName $ADGlobalCatalogPowershellSessionName -groupSMTPAddress $groupSMTPAddress

    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "Create an XML file backup of the on premises DL Configuration"

    Out-XMLFile -itemToExport $originalDLConfiguration -itemNameToExport $originalDLConfigurationXML

    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "================================================================================"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "END START-DISTRIBUTIONLISTMIGRATION"
    Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "================================================================================"
}