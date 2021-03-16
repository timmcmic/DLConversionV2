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
            [string]$DN
        )

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
        
        #Get the specific user using ad providers.
        
        try 
        {
            Out-LogFile -string "Attempting to get the canonical name of the object."

            $functionTest = get-adgroup -filter {distinguishedname -eq $dn} -properties canonicalName -errorAction STOP

            if ($functionTest -eq $NULL)
            {
                throw "The array member cannot be found by DN in Active Directory."
            }

            Out-LogFile -string "The array member was found by DN."
        }
        catch 
        {
            Out-LogFile -string $_ -isError:$TRUE
        }

        try
        {
            #Now that we have the canonicalName - record it and build just the domain name portion of it for reference.

            #Split the string at / -> results in the domain name being in position 0.

            $functionDomain=$functiontest.canonicalName.split("/")

            $functionObject = New-Object PSObject -Property @{
                canonicalName = $group.canonicalName
                canonicalDomainName = $functionDomain[0]
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