<#
    .SYNOPSIS

    This function utilizes a distinguished domain to calculate an active directory domain name.
    
    .DESCRIPTION

    This function converts a distinguished name into active directory domain name.

    .PARAMETER DN

    The DN of the object to pass to normalize.

    .OUTPUTS

    The FQDN of the active directory domain.

    .EXAMPLE

    Get-activeDirectoryDomainName -dn $DN

    .CREDITS

    Credit to the following website - code adapted from this location.
    http://lanlith.blogspot.com/2014/06/powershell-get-domain-from.html

    #>
    Function get-activeDirectoryDomainName
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$DN
        )

        #Declare function variables.

        [array]$functionSplitDomainName=@()
        [string]$functionCombinedDomainName=""

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN GET-ActiveDirectoryDomainName"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        out-logfile -string ("DN to convert: "+$DN)

        Out-LogFile -string "Converting the distringuished name."

        $functionSplitDomainName = $dn -Split "," | ? {$_ -like "DC=*"}

        foreach ($component in $functionSplitDomainName)
        {
            out-logfile -string $component
        }

        $functionCombinedDomainName = $functionSplitDomainName -join "." -replace ("DC=", "")

        out-logfile -string ("The FQDN of the object based on DN: "+$functionCombinedDomainName)

        Out-LogFile -string "END GET-ActiveDirectoryDomainName"
        Out-LogFile -string "********************************************************************************"
        
        #This function is designed to open local and remote powershell sessions.
        #If the session requires import - for example exchange - return the session for later work.
        #If not no return is required.
        
        return $functionCombinedDomainName
    }