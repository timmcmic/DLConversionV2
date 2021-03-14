<#
    .SYNOPSIS

    This function is used to normalize the DN information of users on premises to SMTP addresses utilized in Office 365.

    .DESCRIPTION

    This function is used to normalize the DN information of users on premises to SMTP addresses utilized in Office 365.

    .PARAMETER GlobalCatalog

    The global catalog to make the query against.

    .PARAMETER DN

    The DN of the object to pass to normalize.

    .OUTPUTS

    Selects the mail address of the user by DN and returns the mail address.

    .EXAMPLE

    get-SMTPfromDN -globalCatalog GC -DN DN

    #>
    Function Get-SMTPfromDN
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

        [string]$functionSMTPAddress=$NULL #Holds the return information for the group query.
        [string]$globalCatalogServer=$globalCatalogServer+":3268"

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN GET-SMTPfromDN"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        Out-LogFile -string ("GlobalCatalogServer = "+$globalCatalogServer)
        OUt-LogFile -string ("DN Set = "+$DN)
        
        #Get the specific user using ad providers.
        
        try 
        {
            Out-LogFile -string "Using AD / LDAP provider to get the users SMTP Address"

            $functionSMTPAddress = Get-AzureADUser -filter "distinguishedname -eq '$DN'" -properties 'Mail' -server $globalCatalogServer -ErrorAction STOP

            #If the ad provider command cannot find the user - the variable is NULL.  An error is not thrown.

            if ($functionSMTPAddress -eq $NULL)
            {
                throw "The user cannot be found in Active Directory by DN."
            }

            Out-LogFile -string "The user was found by DN and mail attribute recorded."
        }
        catch 
        {
            Out-LogFile -string $_ -isError:$TRUE
        }

        Out-LogFile -string "END GET-SMTPfromDN"
        Out-LogFile -string "********************************************************************************"
        
        #This function is designed to open local and remote powershell sessions.
        #If the session requires import - for example exchange - return the session for later work.
        #If not no return is required.
        
        return $functionSMTPAddress
    }