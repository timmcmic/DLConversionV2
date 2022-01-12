<#
    .SYNOPSIS

    This function determines the hybrid mail.onmicrosoft.com domain name.
    This function is required to support additions of onmicrosoft.com domain names which can be used as addresses but not for routing.

    .DESCRIPTION

    This function determines the hybrid mail.onmicrosoft.com domain name.

    .EXAMPLE

    Get-MailOnMicrosoftComDomain

    #>
    Function Get-MailOnMicrosoftComDomain
     {
        [cmdletbinding()]

        #Define variables that will be utilzed in the function.

        [string]$functionDomainName = ""
        [array]$functionAcceptedDomains = @()
        [string]$functionDomainString = "mail.onmicrosoft.com"
        
        #Initiate the test.
        
        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN Get-MailOnMicrosoftComDomain"
        Out-LogFile -string "********************************************************************************"

        $functionAcceptedDomains = get-o365acceptedDomain

        foreach ($domain in $functionAcceptedDomains)
        {
            out-logfile -string ("Testing Domain: "+$domain.domainName)

            if ($domain.domainName.contains($functionDomainString))
            {
                out-logfile -string ("Mail.onmicrosoft.com domain name found: "+$domain.domainName)
                $functionDomainName = $domain.domainName
            }
            else 
            {
                out-logfile -string ("Domain is not mail.onmicrosoft.com: "+$domain.domainName)    
            }
        }

        Out-LogFile -string "END Get-MailOnMicrosoftComDomain"
        Out-LogFile -string "********************************************************************************"

        return $functionDomainName
    }