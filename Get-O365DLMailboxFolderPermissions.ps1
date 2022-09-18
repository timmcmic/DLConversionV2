<#
    .SYNOPSIS

    This function uses the exchange online powershell session to gather the office 365 distribution list configuration.

    .DESCRIPTION

    This function uses the exchange online powershell session to gather the office 365 distribution list configuration.

    .PARAMETER GroupSMTPAddress

    The mail attribute of the group to search.

    .OUTPUTS

    Returns the PS object associated with the recipient from get-o365recipient

    .EXAMPLE

    Get-O365DLFullMaiboxAccess -groupSMTPAddress Address

    #>
    Function Get-O365DLMailboxFolderPermissions
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$groupSMTPAddress,
            [Parameter(Mandatory = $false)]
            $collectedData=$NULL
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Declare function variables.

        [array]$functionFolderAccess=@()

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN Get-O365DLMailboxFolderPermissions"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        Out-LogFile -string ("GroupSMTPAddress = "+$groupSMTPAddress)

        #Get the recipient using the exchange online powershell session.

        if ($collectedData -eq $NULL)
        {
            out-logfile -string "No folder permissions were provided for evaluation."
        }
        elseif ($collectedData -ne $NULL)
        {
            out-logfile -string "Filter all entries for objects that have been removed."
            out-logfile -string ("Pre count: "+$collectedData.count)

            $collectedData = $collectedData | where {$_.user.userPrincipalName -ne $NULL}

            out-logfile -string ("Post count: "+$collectedData.count)

            $functionFolderAccess = $collectedData | where {$_.user.tostring() -eq $groupSMTPAddress}
        }

        write-progress -activity "Processing Recipient" -completed

        Out-LogFile -string "END Get-O365DLMailboxFolderPermissions"
        Out-LogFile -string "********************************************************************************"
        
        if ($functionFolderAccess.count -gt 0)
        {
            return $functionFolderAccess
        }
    }