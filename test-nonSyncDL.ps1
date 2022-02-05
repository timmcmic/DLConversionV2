<#
    .SYNOPSIS

    This function loops until we detect that the cloud DL is no longer present.
    
    .DESCRIPTION

    This function loops until we detect that the cloud DL is no longer present.

    .PARAMETER groupSMTPAddress

    The SMTP Address of the group.

    .OUTPUTS

    None

    .EXAMPLE

    test-CloudDLPresent -groupSMTPAddress SMTPAddress

    #>
    Function test-nonSyncDL
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $originalDLConfiguration
        )

        [array]$functionErrors=@()


        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN TEST-NONSYNCDL"
        Out-LogFile -string "********************************************************************************"

        out-logfile -string "Testing mail attribute..."

        if ($originalDLConfiguration.mail -eq $NULL)
        {
            $isErrorObject = new-Object psObject -property @{
                Attribute = "Mail"
                ErrorMessage = ("Mail attribute missing on non-syncDL and is required.")
                ErrorMessageDetail = $_
            }

            $functionErrors+=$isErrorObject
        }
        else 
        {
            out-logfile -string "Attribute mail is present."    
        }

        out-logfile -string "Testing legacyExchangeDN attribute..."

        if ($originalDLCOnfiguration.legacyExchangeDN -eq $NULL)
        {
            $isErrorObject = new-Object psObject -property @{
                Attribute = "LegacyExchangeDN"
                ErrorMessage = ("LegacyExchangeDN attribute missing on non-syncDL and is required.")
                errorMessageDetail = $_
            }

            $functionErrors+=$isErrorObject
        }
        else 
        {
            out-logfile -string "Attribute legacyExchangeDN is present."    
        }

        out-logfile -string "Testing proxyAddresses attribute..."

        if ($originalDLCOnfiguration.proxyAddresses -eq $NULL)
        {
            $isErrorObject = new-Object psObject -property @{
                Attribute = "ProxyAddresses"
                ErrorMessage = ("ProxyAddresses attribute missing on non-syncDL and is required.")
                ErrorMessageDetail = $_
            }

            $functionErrors+=$isErrorObject
        }
        else 
        {
            out-logfile -string "Attribute proxyAddresses is present."    
        }

        out-logfile -string "Testing mailNickName attribute..."

        if ($originalDLCOnfiguration.mailNickName -eq $NULL)
        {
            $isErrorObject = new-Object psObject -property @{
                Attribute = "MailNickName"
                ErrorMessage = ("MailNickName attribute missing on non-syncDL and is required.")
                ErrorMessageDetail = $_
            }

            $functionErrors+=$isErrorObject
        }
        else 
        {
            out-logfile -string "Attribute mailNickName is present."    
        }

        if ($functionErrors.count -gt 0)
        {
            foreach ($error in $functionErrors)
            {
                out-logfile -string "Error detected in non sync DL."
                out-logfile -string $error.attribute
                out-logfile -string $error.errormessage
            }

            out-logfile -string "All errors must be corrected prior to non-sync DL migration." -isError:$TRUE
        }
        else 
        {
            out-logfile -string "No attribute validation errors found proceed with migration."
        }

        Out-LogFile -string "END TEST-NONSYNCDL"
        Out-LogFile -string "********************************************************************************"
    }