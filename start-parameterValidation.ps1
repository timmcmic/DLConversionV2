<#
    .SYNOPSIS

    This function validates the parameters within the script.  Paramter validation is shared across functions.
    
    .DESCRIPTION

    This function validates the parameters within the script.  Paramter validation is shared across functions.

    #>
    Function start-parameterValidation
    {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true,ParameterSetName = 'AADConnect')]
            [Parameter(Mandatory = $true,ParameterSetName = 'AADConnectMulti')]
            [AllowNull()]
            $aadConnectServer,
            [Parameter(Mandatory = $true,ParameterSetName = 'AADConnect')]
            [Parameter(Mandatory = $true,ParameterSetName = 'AADConnectMulti')]
            [AllowNull()]
            $aadConnectCredential,
            [Parameter(Mandatory = $true,ParameterSetName = 'AADConnectMulti')]
            [Parameter(Mandatory = $true,ParameterSetName = 'ExchangeMulti')]
            [Parameter(Mandatory = $true,ParameterSetName = 'ExchangeOnlineMulti')]
            [Parameter(Mandatory = $true,ParameterSetName = 'AzureADMulti')]
            [Parameter(Mandatory = $true,ParameterSetName = 'MaxThreadCount')]
            [AllowNull()]
            $serverNames,
            [Parameter(Mandatory = $true,ParameterSetName = 'Exchange')]
            [Parameter(Mandatory = $true,ParameterSetName = 'ExchangeMulti')]
            [AllowNull()]
            $exchangeServer,
            [Parameter(Mandatory = $true,ParameterSetName = 'Exchange')]
            [Parameter(Mandatory = $true,ParameterSetName = 'ExchangeMulti')]
            [AllowNull()]
            $exchangeCredential,
            [Parameter(Mandatory = $true,ParameterSetName = 'ExchangeOnline')]
            [Parameter(Mandatory = $true,ParameterSetName = 'ExchangeOnlineMulti')]
            [AllowNull()]
            $exchangeOnlineCredential,
            [Parameter(Mandatory = $true,ParameterSetName = 'ExchangeOnline')]
            [Parameter(Mandatory = $true,ParameterSetName = 'ExchangeOnlineMulti')]
            [Parameter(Mandatory = $true,ParameterSetName = 'ExchangeOnlineCertAuth')]
            [AllowNull()]
            $exchangeOnlineCertificateThumbprint,
            [Parameter(Mandatory = $true,ParameterSetName = 'ExchangeOnlineCertAuth')]
            [AllowNull()]
            $exchangeOnlineOrganizationName,
            [Parameter(Mandatory = $true,ParameterSetName = 'ExchangeOnlineCertAuth')]
            [AllowNull()]
            $exchangeOnlineAppID,
            [Parameter(Mandatory = $true,ParameterSetName = 'AzureAD')]
            [Parameter(Mandatory = $true,ParameterSetName = 'AzureADMulti')]
            [AllowNull()]
            $azureADCredential,
            [Parameter(Mandatory = $true,ParameterSetName = 'AzureAD')]
            [Parameter(Mandatory = $true,ParameterSetName = 'AzureADMulti')]
            [Parameter(Mandatory = $true,ParameterSetName = 'AzureADCertAuth')]
            [AllowNull()]
            $azureADCertificateThumbprint,
            [Parameter(Mandatory = $true,ParameterSetName = 'AzureADCertAuth')]
            [AllowNull()]
            $azureTenantID,
            [Parameter(Mandatory = $true,ParameterSetName = 'AzureADCertAuth')]
            [AllowNull()]
            $azureApplicationID,
            [Parameter(Mandatory = $true,ParameterSetName = 'NoSyncOU')]
            [AllowNull()]
            $retainOriginalGroup,
            [Parameter(Mandatory = $true,ParameterSetName = 'NoSyncOU')]
            [AllowNull()]
            $doNotSyncOU,
            [Parameter(Mandatory = $true,ParameterSetName = 'HybridMailFlow')]
            [AllowNull()]
            $useOnPremisesExchange,
            [Parameter(Mandatory = $true,ParameterSetName = 'HybridMailFlow')]
            [AllowNull()]
            $enableHybridMailFlow,
            [Parameter(Mandatory = $true,ParameterSetName = 'ActiveDirectory')]
            [AllowNull()]
            $activeDirectoryCredential,
            [Parameter(Mandatory = $true,ParameterSetName = 'MaxThreadCount')]
            [AllowNull()]
            $maxThreadCount,
            [Parameter(Mandatory = $true,ParameterSetName = 'RemoteDriveLetter')]
            [AllowNull()]
            $remoteDriveLetter
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        $functionParameterSetName = $PsCmdlet.ParameterSetName
        $aadConnectParameterSetName = 'AADConnect'
        $aadConnectParameterSetNameMulti = 'AADConnectMulti'
        $exchangeParameterSetName = "Exchange"
        $exchangeParameterSetNameMulti = "ExchangeMulti"
        $exchangeOnlineParameterSetName = "ExchangeOnline"
        $exchangeOnlineParameterSetNameMulti = "ExchangeOnlineMulti"
        $exchangeOnlineParameterSetNameCertAuth = "ExchangeOnlineCertAuth"
        $azureADParameterSetName = "AzureAD"
        $azureADParameterSetNameMulti = "AzureADMulti"
        $azureADParameterSetNameCertAuth = "AzureCertAuth"
        $doNotSyncOUParameterSetName = "NoSyncOU"
        $hybridMailFlowParameterSetName = "HybridMailFlow"
        $activeDirectoryParameterSetName = "ActiveDirectory"
        $maxThreadCountParameterSetName = "MaxThreadCount"
        $remoteDriveLetterParameterSetName = "RemoteDriveLetter"
        $functionTrueFalse = $false

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN start-parameterValidation"
        Out-LogFile -string "********************************************************************************"

        out-logfile -string ("The parameter set name for validation: "+$functionParameterSetName)

        if ($functionParameterSetName -eq $remoteDriveLetterParameterSetName)
        {
            if ($remoteDriveLetter -eq $NULL)
            {
                out-logfile -string "A remote drive letter is required - specify S for example." -isError:$TRUE
            }
            else 
            {
                if ($remoteDriveLetter.count -gt 1)
                {
                    out-logfile -string "Please specify a single drive letter - for example S" -isError:$TRUE
                }
                else 
                {
                    out-logfile -string "Drive letter specified is a single character."
                    
                    if ([regex]::Match($remoteDriveLetter,"[a-zA-Z]"))
                    {
                        out-logfile -string "Drive letter specified is single and is a valid drive character."
                    }
                    else 
                    {
                        out-logfile -string "Please specify a valid character A-Z or a-z for the remote drive letter." -iserror:$TRUE
                    }
                }
            }
        }

        if ($functionParameterSetName -eq $maxThreadCountParameterSetName)
        {
            if ($serverNames.count -gt $maxThreadCount)
            {
                out-logfile -string ("More servers were specified than the hard coded thread count which is = "+$maxThreadCount.tostring()) -isError:$TRUE
            }
            else 
            {
                out-logfile -string "The number of servers provided is less than the max thread count."
            }
        }

        if ($functionParameterSetName -eq $activeDirectoryParameterSetName)
        {
            test-credentials -credentialsToTest $activeDirectoryCredential

            test-itemCount -itemsToCount $activeDirectoryCredential -itemsToCompareCount $serverNames
        }

        if ($functionParameterSetName -eq $hybridMailFLowParameterSetName)
        {
            if (($useOnPremisesExchange -eq $False) -and ($enableHybridMailflow -eq $true))
            {
                out-logfile -string "Exchange on premsies information must be provided in order to enable hybrid mail flow." -isError:$TRUE
            }
     
        }

        if ($functionParameterSetName -eq $doNotSyncOUParameterSetName)
        {
            if (($retainOriginalGroup -eq $FALSE) -and ($dnNoSyncOU -eq "NotSet"))
            {
                out-LogFile -string "A no SYNC OU is required if retain original group is false." -isError:$TRUE
            }
        }

        if ($functionParamterSetName -eq $azureADParameterSetNameCertAuth)
        {
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
                out-logfile -string "The azure tenant ID is required to use certificate authentication to Azure." -isError:$TRUE
            }
            else 
            {
                out-logfile -string "All components necessary for Exchange certificate thumbprint authentication were specified."    
            }
        }

        if ($functionParameterSetName -eq $azureADParameterSetName)
        {
            if (($azureADCredential -ne $NULL) -and ($azureCertificateThumbprint -ne ""))
            {
                Out-LogFile -string "ERROR:  Only one method of azure cloud authentication can be specified.  Use either azure cloud credentials or azure cloud certificate thumbprint." -isError:$TRUE
            }
            elseif (($azureADCredential -eq $NULL) -and ($azureCertificateThumbprint -eq ""))
            {
                out-logfile -string "ERROR:  One permissions method to connect to Azure AD must be specified." 
                out-logfile -string "https://timmcmic.wordpress.com/2022/09/18/office-365-distribution-list-migration-version-2-0-part-20/" -isError:$TRUE
            }
            else
            {
                Out-LogFile -string "Only one method of Azure AD specified."

                if ($functionParamterSetName -eq $azureADParameterSetNameMulti)
                {
                    out-logfile -string "Validating the exchange online credential array"

                    test-credentials -credentialsToTest $azureADCredential

                    test-itemCount -itemsToCount $azureADCredential -itemsToCompareCount $serverNames
                }
            }
        }

        if ($functionParameterSetName -eq $exchangeOnlineParameterSetNameCertAuth)
        {
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
        }

        if (($functionParameterSetName -eq $exchangeOnlineParameterSetName) -or ($functionParameterSetName -eq $exchangeOnlineParameterSetNameMulti))
        {
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

                if ($functionParamterSetName -eq $exchangeOnlineParameterSetNameMulti)
                {
                    out-logfile -string "Validating the exchange online credential array"

                    test-credentials -credentialsToTest $exchangeOnlineCredential

                    test-itemCount -itemsToCount $exchangeOnlineCredential -itemsToCompareCount $serverNames
                }
            } 
        }

        if (($functionParameterSetName -eq $exchangeParameterSetName) -or ($functionParameterSetName -eq $exchangeParamterSetNameMulti))
        {
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
            elseif (($exchangeCredential -ne $NULL) -and ($exchangeServer -ne ""))
            {
                #The server name and credential were specified for Exchange.

                Out-LogFile -string "The server name and credential were specified for Exchange."

                #Set useOnPremisesExchange to TRUE since the parameters necessary for use were passed.

                $functionTrueFalse=$TRUE

                if ($functionParamterSetName -eq $exchangeParameterSetNameMulti)
                {
                    test-credentials -credentialsToTest $exchangeCredential

                    test-itemCount -itemsToCount $exchangeCredential -itemsToCompareCount $serverNames
                }

                Out-LogFile -string "Set useOnPremsiesExchanget to TRUE since the parameters necessary for use were passed - "
            }
            else
            {
                Out-LogFile -string "Neither Exchange Server or Exchange Credentials specified - retain useOnPremisesExchange FALSE - "
            }
        }

        if (($functionParameterSetName -eq $aadConnectParameterSetName) -or ($functionParameterSetName -eq $aadConnectParameterSetNameMulti))
        {
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
                
                $functionTrueFalse=$TRUE

                if ($functionParameterSetName -eq $aadConnectParameterSetNameMulti)
                {
                    Out-LogFile -string "AADConnectServer and AADConnectCredential were both specified." 

                    test-credentials -credentialsToTest $aadConnectCredential

                    test-itemCount -itemsToCount $aadConnectCredential -itemsToCompareCount $serverNames
                }
            }
            else
            {
                Out-LogFile -string "Neither AADConnect Server or AADConnect Credentials specified." 
            }
        }
        
        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "END start-parameterValidation"
        Out-LogFile -string "********************************************************************************"

        return $functionTrueFalse
    }