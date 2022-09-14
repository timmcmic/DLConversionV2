<#
    .SYNOPSIS

    This function utilizes exchange on premises and searches for all send as rights across all recipients.

    .DESCRIPTION

    This function utilizes exchange on premises and searches for all send as rights across all recipients.

    .PARAMETER originalDLConfiguration

    The mail attribute of the group to search.

    .OUTPUTS

    Returns a list of all objects with send-As rights and exports them.

    .EXAMPLE

    get-o365dlconfiguration -groupSMTPAddress Address

    #>
    Function get-onPremFolderPermissions
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $originalDLConfiguration,
            [Parameter(Mandatory=$false)]
            $collectedData=$NULL
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Declare function variables.

        [array]$functionFolderRightsUsers=@()
        [int]$functionCounter=0

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN get-onPremFolderPermissions"
        Out-LogFile -string "********************************************************************************"

        out-logfile -string "Test for folder permissions."

        out-logfile -string "Filter all permissions for objects that are no longer vaild"
        out-logfile -string ("Pre collected data count: "+$collectedData.count)

        $collectedData = $collectedData | where {$_.user.adrecipient -ne $NULL}

        out-logfile -string ("Post collected data count: "+$collecteddata.count)

        $functionFolderRightsUsers = $collectedData | where {$_.user.ADRecipient.primarySMTpAddress.contains($originalDLConfiguration.mail)}

        

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "END get-onPremFolderPermissions"
        Out-LogFile -string "********************************************************************************" 

        if ($functionFolderRightsUsers.count -gt 0)
        {
            out-logfile -string $functionFolderRightsUsers
            return $functionFolderRightsUsers
        }
    }