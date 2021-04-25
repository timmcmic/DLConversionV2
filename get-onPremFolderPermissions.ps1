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

        #Declare function variables.

        [array]$functionFolderRightsUsers=@()
        [int]$functionCounter=0

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN get-onPremFolderPermissions"
        Out-LogFile -string "********************************************************************************"

        try 
        {
            out-logfile -string "Test for folder permissions."

            $ProgressDelta = 100/($collectedData.count); $PercentComplete = 0; $MbxNumber = 0

            foreach ($recipient in $collectedData)
            {
                $MbxNumber++

                write-progress -activity "Processing Recipient" -status $recipient.identity -PercentComplete $PercentComplete

                $PercentComplete += $ProgressDelta

                if ($recipient.user.tostring() -notlike "*S-1-5-21*")
                {
                    write-host $recipient.user
                    write-host $originalDLConfiguration.samAccountName

                    if ($recipient.user.tostring() -eq $originalDLConfiguration.samAccountName)
                    {
                        out-logfile -string ("Mailbox folder permission found - recording."+$recipient.identity)
                        $functionFolderRightsUsers+=$recipient
                    }
                } 
            }
        }
        catch 
        {
            out-logfile -string "Error attempting to invoke command to gather all send as permissions."
            out-logfile -string $_ -isError:$TRUE
        }

        out-logfile -string $functionFolderRightsUsers

        write-progress -Activity "Processing Recipient" -Completed

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "END get-onPremFolderPermissions"
        Out-LogFile -string "********************************************************************************" 

        if ($functionFolderRightsUsers.count -gt 0)
        {
            return $functionFolderRightsUsers
        }
    }