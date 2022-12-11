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
            [Parameter(Mandatory = $true,
            ParameterSetName = 'AADConnect')]
            $aadConnectServer,
            [Parameter(Mandatory = $true,
            ParameterSetName = 'AADConnect')]
            $aadConnectCredential
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        $functionParameterSetName = $PsCmdlet.ParameterSetName
        $aadConnectParameterSetName = 'AADConnect'
        $functionTrueFalse = $false

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN start-parameterValidation"
        Out-LogFile -string "********************************************************************************"

        out-logfile -string ("The parameter set name for validation: "+$functionParameterSetName)

        if ($functionParameterSetName -eq $aadConnectParameterSetName)
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
        
        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "END start-parameterValidation"
        Out-LogFile -string "********************************************************************************"

        if ($functionTrueFalse -eq $TRUE)
        {
            return $functionTrueFalse
        }
    }