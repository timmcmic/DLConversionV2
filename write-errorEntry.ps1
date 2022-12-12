<#
    .SYNOPSIS

    This function writes the error entry to the log file.
    
    .DESCRIPTION

    This function writes the error entry to the log file.

    #>
    Function write-errorEntry
    {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $errorEntry
        )

        out-logfile -string "====="
        out-logfile -string ("Alias: "+$errorEntry.alias)
        out-logfile -string ("Name: "+$errorEntry.name)
        out-logfile -string ("PrimarySMTPAddressOrUPN: "+$errorEntry.primarySMTPAddressOrUPN)
        out-logfile -string ("RecipientType: "+$errorEntry.RecipientType)
        out-logfile -string ("GroupType: "+$errorEntry.GroupType)
        out-logfile -string ("RecipientOrUser: "+$errorEntry.recipientoruser)
        out-logfile -string ("ExternalDirectoryObjectID:" +$errorEntry.externalDirectoryObjectID)
        out-logfile -string ("OnPremADAttribute: "+$errorEntry.onPremADAttribute)
        out-logfile -string ("DN: "+$errorEntry.DN)
        out-logfile -string ("isAlreadyMigrated: "+$errorEntry.isAlreadyMigrated)
        out-logfile -string ("isError: "+$errorEntry.isError)
        out-logfile -string ("isErrorMessage: "+$errorEntry.isErrorMessage)
        out-logfile -string "====="
    }