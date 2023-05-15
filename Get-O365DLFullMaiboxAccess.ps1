<#
    .SYNOPSIS

    This function searches the collected data for all Office 365 full mailbox access permissions.

    .DESCRIPTION

     This function searches the collected data for all Office 365 full mailbox access permissions.

    .PARAMETER GroupSMTPAddress

    The mail attribute of the group to search.

    .PARAMETER collectedData

    The precollected data utilized for evaluation.

    .OUTPUTS

    Returns all full mailbox access permissions for the migrated group.

    .EXAMPLE

    Get-O365DLFullMaiboxAccess -groupSMTPAddress Address -collectedData DataArray

    #>
    Function Get-O365DLFullMaiboxAccess
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

        [array]$functionFullMailboxAccess=@()
        $functionMailboxes=$NULL
        $functionRecipient=$NULL

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN Get-O365DLFullMaiboxAccess"
        Out-LogFile -string "********************************************************************************"

        #Get the recipient using the exchange online powershell session.

        if ($collectedData -eq $NULL)
        {
            try {
                out-logfile -string "Getting recipient..."
    
                #$functionRecipient = get-ExoRecipient -identity $groupSMTPAddress
                $functionRecipient = get-o365Recipient -identity $groupSMTPAddress
            }
            catch {
                out-logfile -string $_ -isError:$TRUE
            }
    
            #Get all of the mailboxes to test.
    
            try {
                out-logfile -string "Getting all Office 365 mailboxes."
    
                #$functionMailboxes = get-exomailbox -resultsize unlimited
                $functionMailboxes = get-o365mailbox -resultsize unlimited
            }
            catch {
                out-logfile -string $_ -isError:$TRUE
            }
            
            try 
            {
                Out-LogFile -string "Using Exchange Online to locate all of the full mailbox access rights in Office 365."
    
                $ProgressDelta = 100/($functionMailboxes.count); $PercentComplete = 0; $MbxNumber = 0
    
                foreach ($mailbox in $functionMailboxes)
                {
                    $MbxNumber++
    
                    write-progress -activity "Processing Recipient" -status $mailbox.primarySMTPAddress -PercentComplete $PercentComplete
    
                    $PercentComplete += $ProgressDelta
    
                    #$functionFullMailboxAccess+=get-exoMailboxPermission -identity $mailbox.identity | where {$_.user -eq $functionRecipient.identity}
                    $functionFullMailboxAccess+=get-o365MailboxPermission -identity $mailbox.identity | where {$_.user -eq $functionRecipient.identity}
                }
            }
            catch 
            {
                Out-LogFile -string $_ -isError:$TRUE
            }
    
            write-progress -activity "Processing Recipient" -completed
        }
        elseif ($collectedData -ne $NULL)
        {
            try {
                out-logfile -string "Getting recipient..."
    
                #$functionRecipient = get-ExoRecipient -identity $groupSMTPAddress
                $functionRecipient = get-o365Group -identity $groupSMTPAddress
            }
            catch {
                out-logfile -string $_ -isError:$TRUE
            }

            out-logfile "Obtaining all full mailbox access permissions in Office 365."

            $functionFullMailboxAccess = $collectedData | where {$_.user.contains($functionRecipient.identity)}
        }

        Out-LogFile -string "END Get-O365DLFullMaiboxAccess"
        Out-LogFile -string "********************************************************************************"
        
        if ($functionFullMailboxAccess.count -gt 0)
        {
            return $functionFullMailboxAccess
        }
    }