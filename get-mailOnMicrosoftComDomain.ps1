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
        [string]$functionDomainString0 = "mail.onmicrosoft.com"
        [string]$functionDomainString1 = "microsoftonline.com"
        
        #Initiate the test.
        
        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN Get-MailOnMicrosoftComDomain"
        Out-LogFile -string "********************************************************************************"

        try{
            $functionAcceptedDomains = get-o365acceptedDomain -errorAction STOP
        }
        catch{
            out-logfile -string $_
            out-logfile -string "Error obtaining accepted domains." -isError:$TRUE
        }

        <#
        Commenting out the original code.

        Encountered a customer issue where they have not online a mail.onmicrosoft.com domain but also the legacy microsoftonline.com domain encountered in other situations.

        This causes a failure to occur 
        #>
        

        foreach ($domain in $functionAcceptedDomains)
        {
            out-logfile -string ("Testing Domain: "+$domain.domainName)

            if ($domain.domainName.contains($functionDomainString0))
            {
                out-logfile -string ("Mail.onmicrosoft.com domain name found: "+$domain.domainName)
                $functionDomainName = $domain.domainName
            }
            elseif ($domain.domainName.contains($functionDomainString1))
            {
                out-logfile -string ("Legacy microsoft online domain name found: "+$domain.domainName)
                $functionDomainName = $domain.domainName
            }
            else 
            {
                out-logfile -string ("Domain is not mail.onmicrosoft.com: "+$domain.domainName)    
            }
        }

        if ($functionDomainName -eq "")
        {
            out-logfile -string "No viable mail routing address was found."
            out-logfile -string "Contact support or post an issue on GITHUB." -isError:$true
        }

        Out-LogFile -string "END Get-MailOnMicrosoftComDomain"
        Out-LogFile -string "********************************************************************************"

        return $functionDomainName
    }