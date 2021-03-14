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

    get-normalizedDN -globalCatalog GC -DN DN

    #>
    Function Get-NormalizedDN
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
        [string]$functionSMTPAddress=$NULL
        [string]$globalCatalogServer=$globalCatalogServer+":3268"

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN GET-NormalizedDN"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        Out-LogFile -string ("GlobalCatalogServer = "+$globalCatalogServer)
        OUt-LogFile -string ("DN Set = "+$DN)
        
        #Get the specific user using ad providers.
        
        try 
        {
            Out-LogFile -string "Attempting to find the AD object associated with the member."

            $functionTest = get-adObject -filter "distinguishedname -eq '$dn'" -properties * -errorAction STOP

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
            #If the recipient has a mail address stamped we consider the object mail enabled.

            if ($functionTest.mail -ne $NULL)
            {
                #The mail address is not NULL.  Check to see if either of the custom atttributes used for migration are stamped.

                if ($functionTest.extensionAttribute1 -eq "MigratedByScript")
                {
                    Out-LogFile -string "The object was previously migrated - using migrated information."

                    $functionObject = New-Object PSObject -Property @{
                        Alias = $functionTest.mailNickName
                        Name = $functionTest.Name
                        PrimarySMTPAddressOrUPN = $functionTest.extensionAttribute2
                        GUID = $NULL
                        RecipientType = $functionTest.objectClass
                        RecipientOrUser = "Recipient"
                        isAlreadyMigrated = $true
                    }
                }
                else 
                {
                    Out-LogFile -string "The object was not previously migrated - using directory information."
                    
                    $functionObject = New-Object PSObject -Property @{
                        Alias = $functionTest.mailNickName
                        Name = $functionTest.Name
                        PrimarySMTPAddressOrUPN = $functionTest.mail
                        GUID = $NULL
                        RecipientType = $functionTest.objectClass
                        RecipientOrUser = "Recipient"
                        isAlreadyMigrated = $false
                    }
                }
            }
            elseif ($functionTest.objectClass -eq "User")
            {
                out-logFile -string "A user object was found that was not mail enabled."
                out-logfile -string "This is permissable assuming the user is in sync scope."

                New-Object PSObject -Property @{
                    Alias = ""
                    Name = $functionTest.Name
                    PrimarySMTPAddressOrUPN = $functionTest.UserprincipalName
                    GUID = $NULL
                    RecipientType = $functionTest.objectClass
                    RecipientOrUser = "User"
                    isAlreadyMigrated = $false
                }
            }
            else 
            {
                Out-LogFile -string "The following object "+$dn+" is not mail enabled and must be removed or mail enabled to continue." -isError:$true   
            }
        }
        catch
        {
            throw "Error in normalized DN."
        }

        Out-LogFile -string "END GET-NormalizedDN"
        Out-LogFile -string "********************************************************************************"
        
        #This function is designed to open local and remote powershell sessions.
        #If the session requires import - for example exchange - return the session for later work.
        #If not no return is required.
        
        return $functionSMTPAddress
    }