<#
    .SYNOPSIS

    This function begins the process of replacing the Office 365 settings for groups that have been migrated that had cloud only dependencies.

    .DESCRIPTION

    This function begins the process of replacing the Office 365 settings for groups that have been migrated that had cloud only dependencies.

    .PARAMETER office365Attribute

    The office 365 attribute.

    .PARAMETER office365Member

    The member that is being added.

    .PARAMETER groupSMTPAddress

    The member that is being added.

    .OUTPUTS

    None

    .EXAMPLE

    sstart-replaceOffice365 -office365Attribute Attribute -office365Member groupMember -groupSMTPAddress smtpAddess

    #>
    Function start-ReplaceOffice365
    {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $office365Attribute,
            [Parameter(Mandatory = $true)]
            $office365Member,
            [Parameter(Mandatory = $true)]
            [string]$groupSMTPAddress
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        [string]$isTestError="No"

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN start-ReplaceOffice365"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        $functionCommand=$NULL
        $functionMailboxRecipientType = "UserMailbox"
        $functionDistributionGroupRecipientType = "MailUniversalDistributionGroup"
        $functionSecurityGroupRecipientType = "MailUniversalSecurityGroup"
        $functionMailUserRecipientType = "MailUser"
        $functionMailContactRecipientType = "MailContact"
        $functionUniveralRecipientDisplayType = "GroupMailbox"
        $functionDynamicDistributionGroupRecipientType = "DynamicDistributionGroup"
        $functionForwarding = "ForwardingAddress"

        $functionExternalDirectoryObjectID = $office365Member.externalDirectoryObjectID

        #Declare function variables.

        out-Logfile -string "Processing operation..."

        if ($office365Attribute -eq $functionForwarding)
        {
            out-logfile -string "Recipient is a mailbox with forwarding rights."

            $functionCommand="set-o365Mailbox -identity $functionExternalDirectoryObjectID -$office365Attribute `"$groupSMTPAddress`" -errorAction STOP"
            out-logfile -string ("The command to execute:  "+$functionCommand)
        }
        elseif (($office365Member.recipientType -eq $functionDistributionGroupRecipientType) -and ($office365Member.recipientTypeDetails -eq $functionUniveralRecipientDisplayType))
        {
            out-logfile -string "Recipient is a unified group."

            $functionCommand="set-o365UnifiedGroup -identity $functionExternalDirectoryObjectID -$office365Attribute @{add=`"$groupSMTPAddress`"} -errorAction STOP"
            out-logfile -string ("The command to execute:  "+$functionCommand)
        }
        elseif (($office365Member.recipientType -eq $functionDistributionGroupRecipientType) -or ($office365Member.recipientType -eq $functionSecurityGroupRecipientType))
        {
            out-logfile -string "Recipient is a mail enabled distribution group or mail enabled security group."

            $functionCommand="set-o365DistributionGroup -identity $functionExternalDirectoryObjectID -$office365Attribute @{add=`"$groupSMTPAddress`"} -errorAction STOP -bypassSecurityGroupManagerCheck"
            out-logfile -string ("The command to execute:  "+$functionCommand)
        }
        elseif ($office365Member.recipientType -eq $functionDynamicDistributionGroupRecipientType)
        {
            out-logfile -string "Recipient is a dynamic distribution group."

            $functionCommand="set-o365DynamicDistributionGroup -identity $functionExternalDirectoryObjectID -$office365Attribute @{add=`"$groupSMTPAddress`"} -errorAction STOP"
            out-logfile -string ("The command to execute:  "+$functionCommand)
        }
        elseif ($office365member.recipientType -eq $functionMailboxRecipientType)
        {
            out-logfile -string "Recipient is a mailbox."

            $functionCommand="set-o365Mailbox -identity $functionExternalDirectoryObjectID -$office365Attribute @{add=`"$groupSMTPAddress`"} -errorAction STOP"
            out-logfile -string ("The command to execute:  "+$functionCommand)
        }
        elseif ($office365Member.recipientType -eq $functionMailUserRecipientType)
        {
            out-logfile -string "Recipient is a mail user."

            $functionCommand="set-o365MailUser -identity $functionExternalDirectoryObjectID -$office365Attribute @{add=`"$groupSMTPAddress`"} -errorAction STOP"
            out-logfile -string ("The command to execute:  "+$functionCommand)
        }
        elseif ($office365Member.recipientType -eq $functionMailContactRecipientType)
        {
            out-logfile -string "Recipient is a mail user."

            $functionCommand="set-o365MailContact -identity $functionExternalDirectoryObjectID -$office365Attribute @{add=`"$groupSMTPAddress`"} -errorAction STOP"
            out-logfile -string ("The command to execute:  "+$functionCommand)
        }
        else 
        {
            out-logfile "There is no acceptable recipient type specified.  Manual intervention required."
            $isTestError="Yes"    
        }

        out-logfile -string "Recipient type is validated and correct command built."

        if ($isTestError -ne "Yes")
        {
            $scriptBlock = [scriptBlock]::create($functionCommand)

            out-logfile -string ("The script block to execute: "+$scriptBlock)
    
            try {
                & $scriptBlock
            }
            catch {
                out-logfile -string $_
                $isTestError="Yes"
            }
        }
        else
        {
            out-logfile -string "Previous error encountered - no command executed."
        }

        Out-LogFile -string "END start-replaceOffice365"
        Out-LogFile -string "********************************************************************************"

        return $isTestError
    }