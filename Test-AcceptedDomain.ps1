<#
    .SYNOPSIS

    This function tests each accepted domain on the group to ensure it appears in Office 365.

    .DESCRIPTION

    This function tests each accepted domain on the group to ensure it appears in Office 365.

    .EXAMPLE

    Test-AcceptedDomain -originalDLConfiguration $originalDLConfiguration

    #>
    Function Test-AcceptedDomain
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $originalDLConfiguration
        )

        $functionOnMicrosoftDomain = ""
        $functionNameTest = "mail.onmicrosoft.com"

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Define variables that will be utilzed in the function.

        [array]$originalDLAddresses=@()
        [array]$originalDLDomainNames=@()

        #Initiate the test.
        
        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN Test-AcceptedDomain"
        Out-LogFile -string "********************************************************************************"

        foreach ($address in $originalDLConfiguration.proxyAddresses)
        {
            Out-logfile -string "Testing proxy address for SMTP"
            out-logfile -string $address

            if ($address -like "smtp*")
            {
                out-logfile -string ("Address is smtp address: "+$address)

                $tempAddress=$address.split("@")

                $originalDLDomainNames+=$tempAddress[1]
            }
            else 
            {
                out-logfile -string ("Address is not an SMTP Address - skip.")
            }
        }

        #It is possible that the group does not have proxy address but just mail - this is now a supported scenario.
        #To get this far the object has to have mail.

        out-logfile -string ("The mail address is: "+$originalDLConfiguration.mail)
        $tempAddress=$originalDLConfiguration.mail.split("@")
        $originalDLDomainNames+=$tempAddress[1]
        
        $originalDLDomainNames=$originalDLDomainNames | select-object -Unique

        out-logfile -string "Unique domain names on the group."
        out-logfile -string $originalDLDomainNames

        foreach ($domain in $originalDLDomainNames)
        {
            out-logfile -string "Testing Office 365 for Domain Name."

            if (get-o365acceptedDomain -identity $domain)
            {
                out-logfile -string ("Domain exists in Office 365. "+$domain)
            }
            else 
            {
                out-logfile -string $domain
                out-logfile -string "Group cannot be migrated until the domain is an accepted domain in Office 365 or removed from the group."    
                out-logfile -string "Email address exists on group that is not in Office 365." -isError:$TRUE
            }
        }

        out-logfile -string "Find and return the onmicrosoft.com domain for other functions."

        try {
            $functionOnMicrosoftDomain = get-o365acceptedDomain | where {$_.domainName -like "*$functionNameTest"} -errorAction Stop
        }
        catch {
            out-logfile -string $_
            out-logfile -string "Unable to capture accepted domains for interpretation -> error." -isError:$TRUE
        }

        Out-LogFile -string "END Test-AcceptedDomain"
        Out-LogFile -string "********************************************************************************"

        return $functionOnMicrosoftDomain.domainName
    }