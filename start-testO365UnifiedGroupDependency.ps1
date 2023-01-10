<#
    .SYNOPSIS

    This function tests pre-requists for migrating directly to a Office 365 Unified Group.

    .DESCRIPTION

    This function tests pre-requists for migrating directly to a Office 365 Unified Group.

    .PARAMETER exchangeDLMembership

    The members of the distribution group.

    .PARAMETER exchangeBypassModerationSMTP

    All users with bypass moderation rights that cannot be mirrored in the service.

    .PARAMETER allObjectsSendAsNormalized

    All objects with send as rights that cannot be mirrored in the service.

    .OUTPUTS

    None

    .EXAMPLE

    sstart-replaceOffice365 -office365Attribute Attribute -office365Member groupMember -groupSMTPAddress smtpAddess

    #>
    Function start-testO365UnifiedGroupDependency
    {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $false)]
            $exchangeDLMembership=$NULL,
            [Parameter(Mandatory = $false)]
            $exchangeBypassModerationSMTP=$NULL,
            [Parameter(Mandatory = $false)]
            $allObjectSendAsNormalized=$NULL,
            [Parameter(Mandatory = $false)]
            $allOffice365ManagedBy=$NULL,
            [Parameter(Mandatory = $false)]
            $allOffice365SendAsAccess=$NULL,
            [Parameter(Mandatory = $false)]
            $allOffice365FullMailboxAccess=$NULL,
            [Parameter(Mandatory = $false)]
            $allOffice365MailboxFolderPermissions=$NULL
        )

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        $functionObjectClassContact = "Contact"
        $functionObjectClassGroup = "Group"

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN start-testO365UnifiedGroupDependency"
        Out-LogFile -string "********************************************************************************"

        if ($exchangeDLMembership -ne $NULL)
        {
            out-logfile -string "Evaluating Exchange DL Membership"

            foreach ($member in $exchangeDLMembership)
            {
                out-logfile -string ("Testing member: "+$member.name)

                if ($member.recipientType -eq $functionObjectClassContact)
                {
                    out-logfile -string "Member is a contact - record as error."

                    $member.isError = $true
                    $member.isErrorMessage = "Contacts may not be included in an Office 365 Unified Group.  Remove the contact in order to migrate to an Office 365 Unified Group."  

                    $global:preCreateErrors+=$member
                }
                elseif ($member.recipientType -eq $functionObjectClassGroup)
                {
                    out-logfile -string "Member is a group - record as error."

                    $member.isError = $TRUE
                    $member.isErrorMessage = "Groups may not be included in an Office 365 Unified Group.  Remove the group in order to migrate to an Office 365 Unified Group"

                    $global:preCreateErrors+=$member
                }
                else 
                {
                    out-logfile -string "Member is neither a group nor contact - allow the migrate to proceed."
                }
            }
        }

        if ($exchangeBypassModerationSMTP -ne $NULL)
        {
            out-logfile -string "Evaluating bypass moderation from senders or members of the on premises group."

            foreach ($member in $exchangeBypassModerationSMTP)
            {
                out-logfile -string ("Testing member: "+$member.name)

                $member.isError = $TRUE
                $member.isErrorMessage = "Office 365 Unified Groups do not have BypassModerationFromSendersOrMembers.  To migrate to an Office 365 Unified Group the bypass moderation from senders or members must be cleared."

                $global:preCreateErrors+=$member
            }
        }

        if ($allObjectSendAsNormalized -ne $NULL)
        {
            out-logfile -string "Evaluating all send as rights discovered on recipient objects on premises.."

            foreach ($member in $allObjectSendAsNormalized)
            {
                out-logfile -string ("Testing member: "+$member.name)

                $member.isError = $TRUE
                $member.isErrorMessage = "In order to retain or mirror send as permissiosn the group must be a security group.  Office 365 Unified Groups are not securtiy groups.  Remove all send as rights for this group on premises to continue converation to an Office 365 Group."

                $global:preCreateErrors+=$member
            }
        }

        Out-LogFile -string "END start-testO365UnifiedGroupDependency"
        Out-LogFile -string "********************************************************************************"
    }