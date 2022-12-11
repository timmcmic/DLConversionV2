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
            [AllowNull()]
            $serverNames
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        $functionParameterSetName = $PsCmdlet.ParameterSetName
        $aadConnectParameterSetName = 'AADConnect'
        $aadConnectParameterSetNameMulti = 'AADConnectMulti'
        $functionTrueFalse = $false

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN start-parameterValidation"
        Out-LogFile -string "********************************************************************************"

        out-logfile -string ("The parameter set name for validation: "+$functionParameterSetName)

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

                Out-LogFile -string ("Set useAADConnect to TRUE since the parameters necessary for use were passed. - "+$coreVariables.useAADConnect.value)
            }
            else
            {
                Out-LogFile -string ("Neither AADConnect Server or AADConnect Credentials specified - retain useAADConnect FALSE - "+$coreVariables.useAADConnect.value)
            }
        }

        if ($functionParameterSetName -eq $aadConnectParameterSetNameMulti)
        {
            Out-LogFile -string "AADConnectServer and AADConnectCredential were both specified." 

            foreach ($credential in $aadConnectCredential)
            {
                if ($credential.gettype().name -eq "PSCredential")
                {
                    out-logfile -string ("Tested credential: "+$credential.userName)
                }
                else 
                {
                    out-logfile -string "ADConnect credential not valid..  All credentials must be PSCredential types." -isError:$TRUE    
                }
            }

            if ($aadConnectCredential.count -lt $serverNames.count)
            {
                out-logfile -string "ERROR:  Must specify one ad connect credential for each migratione server." -isError:$TRUE
            }
            else 
            {
                out-logfile -string "The number of ad connect credentials matches the server count."    
            }
        }
        
        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "END start-parameterValidation"
        Out-LogFile -string "********************************************************************************"

        if ($functionTrueFalse -eq $TRUE)
        {
            return $functionTrueFalse
        }
    }