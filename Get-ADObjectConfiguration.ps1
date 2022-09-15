<#
    .SYNOPSIS

    This function gets the original DL configuration for the on premises group using AD providers.

    .DESCRIPTION

    This function gets the original DL configuration for the on premises group using AD providers.

    .PARAMETER parameterSet

    These are the parameters that the GET will gather from AD for the DL.  This should be the full map.

    .PARAMETER GroupSMTPAddress

    The mail attribute of the group to search.

    .PARAMETER GlobalCatalog

    The global catalog to utilize for the query.

    .OUTPUTS

    Returns the DL configuration from the LDAP / AD call to the calling function.

    .EXAMPLE

    Get-ADObjectConfiguration -powershellsessionname NAME -groupSMTPAddress Address

    #>
    Function Get-ADObjectConfiguration
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true,ParameterSetName = "BySMTPAddress")]
            [string]$groupSMTPAddress="None",
            [Parameter(Mandatory = $true,ParameterSetName = "ByDN")]
            [string]$dn="None",
            [Parameter(Mandatory = $true,ParameterSetName = "BySMTPAddress")]
            [Parameter(Mandatory = $true,ParameterSetName = "ByDN")]
            [string]$globalCatalogServer,
            [Parameter(Mandatory = $true,ParameterSetName = "BySMTPAddress")]
            [Parameter(Mandatory = $true,ParameterSetName = "ByDN")]
            [array]$parameterSet,
            [Parameter(Mandatory = $TRUE,ParameterSetName = "BySMTPAddress")]
            [Parameter(Mandatory = $true,ParameterSetName = "ByDN")]
            $adCredential,
            [Parameter(Mandatory = $true,ParameterSetName = "BySMTPAddress")]
            [Parameter(Mandatory = $true,ParameterSetName = "ByDN")]
            [boolean]$isValidTest=$FALSE
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Declare function variables.

        $functionDLConfiguration=$NULL #Holds the return information for the group query.

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN Get-ADObjectConfiguration"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        Out-LogFile -string ("GroupSMTPAddress = "+$groupSMTPAddress)
        Out-LogFile -string ("GlobalCatalogServer = "+$globalCatalogServer)
        OUt-LogFile -string ("Parameter Set:")
        
        foreach ($parameterIncluded in $parameterSet)
        {
            Out-Logfile -string $parameterIncluded
        }

        out-logfile -string ("Credential user name = "+$adCredential.UserName)

        #Get the group using LDAP / AD providers.
        
        try 
        {
            Out-LogFile -string "Using AD / LDAP provider to get original DL configuration"

            if ($groupSMTPAddress -ne "None")
            {
                out-logfile -string ("Searching by mail address "+$groupSMTPAddress)
                out-logfile -string ("Imported Address Length: "+$groupsmtpAddress.length.toString())

                #Ensure that there are no spaces contained in the string (account for import errors.)

                out-logfile -string ("Spaces Removed Address Length: "+$groupsmtpAddress.length.toString())

                $functionDLConfiguration=Get-ADObject -filter "mail -eq `"$groupSMTPAddress`"" -properties $parameterSet -server $globalCatalogServer -credential $adCredential -errorAction STOP
            }
            elseif ($DN -ne "None")
            {
                out-logfile -string ("Searching by distinguished name "+$dn)

                $functionDLConfiguration=get-adObject -identity $DN -properties $parameterSet -server $globalCatalogServer -credential $adCredential -errorAction STOP
            }
            else 
            {
                out-logfile -string "No value query found for local object." -isError:$TRUE    
            }
            

            #If the ad provider command cannot find the group - the variable is NULL.  An error is not thrown.

            if (($functionDLConfiguration -eq $NULL)  -and ($isValidTest -eq $FALSE))
            {
                throw "The group cannot be found in Active Directory by email address."
            }
            elseif (($functionDLConfiguration -eq $NULL)  -and ($isValidTest -eq $TRUE)) 
            {
                out-logfile -string "Function called to validate recipient - not found."
                out-logfile -string "Returning as this is not an error in this function"
            }

            Out-LogFile -string "Original DL configuration found and recorded."
        }
        catch 
        {
            Out-LogFile -string $_ -isError:$TRUE
        }

        Out-LogFile -string "END Get-ADObjectConfiguration"
        Out-LogFile -string "********************************************************************************"
        
        #This function is designed to open local and remote powershell sessions.
        #If the session requires import - for example exchange - return the session for later work.
        #If not no return is required.

        if ($functionDLConfiguration.count -gt 0)
        {
            out-logfile -string "Multiple active directory objects were detected with the same mail address property."

            foreach ($object in $functionDLConfiguration)
            {
                out-logfile -string "=========="
                out-logfile -string $object.distinguishedName
                out-logfile -string $object.mail
                out-logfile -string "=========="
            }

            out-logfile -string "Administrator action required - the previous objects have the same windows mail address."
            out-logfile -string "Please correct the duplicate mail addresses so that only the distribution list has the mail address."
            out-logfile -string "" -isError:$TRUE
        }
        else 
        {
            out-logfile -string "Single object detected - returning DL configuration."
        }
        
        if ($functionDLConfiguration -ne $NULL)
        {
            return $functionDLConfiguration
        } 
    }