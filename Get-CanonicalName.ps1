<#
    .SYNOPSIS

    This function returns the canonicalName associated with a distinguished name.
    
    .DESCRIPTION

    This function returns the canonicalName associated with a distinguished name.

    .PARAMETER GlobalCatalog

    The global catalog to make the query against.

    .PARAMETER DN

    The DN of the object to pass to normalize.

    .OUTPUTS

    The canonical name of a given object.

    .EXAMPLE

    get-canonicalName -globalCatalog GC -DN DN

    #>
    Function get-canonicalName
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$globalCatalogServer,
            [Parameter(Mandatory = $true)]
            [string]$DN,
            [Parameter(Mandatory = $true)]
            $adCredential
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Declare function variables.

        $functionTest=$NULL #Holds the return information for the group query.
        $functionObject=$NULL #This is used to hold the object that will be returned.
        $functionDomain=$NULL

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN GET-CanoicalName"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        Out-LogFile -string ("GlobalCatalogServer = "+$globalCatalogServer)
        OUt-LogFile -string ("DN Set = "+$DN)
        out-logfile -string ("Credential user name = "+$adCredential.UserName)
        
        #Get the specific user using ad providers.

        $stopLoop = $FALSE
        [int]$loopCounter = 0

        do {
            try 
            {
                Out-LogFile -string "Gathering the AD object based on distinguished name."
    
                $functionTest = get-adobject -filter {distinguishedname -eq $dn} -properties canonicalName -credential $adCredential -server $globalCatalogServer -errorAction STOP

                $stopLoop = $TRUE
            }
            catch 
            {
                if ($loopCounter -gt 4)
                {
                    out-logfile -string $_ -isError:$TRUE
                }
                else 
                {
                    out-logfile -string "Error getting AD object - sleep and retry."
                    
                    $loopCounter = $loopCounter +1

                    start-sleepProgress -sleepString "Error with get-adobject -> sleep and try again." -sleepSeconds 5

                }
                
            }
    
        } until ($stopLoop -eq $TRUE)
        
       
        try
        {
            #Now that we have the canonicalName - record it and build just the domain name portion of it for reference.

            #Split the string at / -> results in the domain name being in position 0.

            $functionDomain=$functiontest.canonicalName.split("/")

            $functionObject = New-Object PSObject -Property @{
                canonicalName = $functionTest.canonicalName
                canonicalDomainName = $functionDomain[0]
                distinguishedName = $functiontest.distinguishedName
            }
        }
        catch
        {
            Out-LogFile -string $_ -isError:$true  
        }

        Out-LogFile -string "END GET-CanonicalName"
        Out-LogFile -string "********************************************************************************"
        
        #This function is designed to open local and remote powershell sessions.
        #If the session requires import - for example exchange - return the session for later work.
        #If not no return is required.
        
        return $functionObject
    }