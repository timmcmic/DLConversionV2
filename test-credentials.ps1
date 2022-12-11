<#
    .SYNOPSIS

    This function validates the parameters within the script.  Paramter validation is shared across functions.
    
    .DESCRIPTION

    This function validates the parameters within the script.  Paramter validation is shared across functions.

    #>
    Function test-credentials
    {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $credentialsToTest
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN start-testCredentials"
        Out-LogFile -string "********************************************************************************"

        foreach ($credential in $credentialsToTest)
        {
            if ($credential.gettype().name -eq "PSCredential")
            {
                out-logfile -string ("Tested credential: "+$credential.userName)
            }
            else 
            {
                out-logfile -string "Credential is not a valid PSCredential.  All credentials must be PSCredential types." -isError:$TRUE    
            }
        }
         
        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "END test-Credentials"
        Out-LogFile -string "********************************************************************************"
    }