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
            $exchangeDLMembershipSMTP=$NULL,
            [Parameter(Mandatory = $false)]
            $exchangeBypassModerationSMTP=$NULL,
            [Parameter(Mandatory = $false)]
            $allObjectsSendAsAccessNormalized=$NULL,
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
        $functionObjectClassDynamic = "msExchDynamicDistributionList"

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN start-testO365UnifiedGroupDependency"
        Out-LogFile -string "********************************************************************************"

        if ($exchangeDLMembershipSMTP -ne $NULL)
        {
            out-logfile -string "Evaluating Exchange DL Membership"

            foreach ($member in $exchangeDLMembershipSMTP)
            {
                out-logfile -string ("Testing member: "+$member.name)

                if (($member.recipientType -eq $functionObjectClassContact) -and ($member.isAlreadyMigrated -eq $TRUE)
                {
                    out-logfile -string "Member is a contact associated with a previously migrated group - record as error."

                    $member.isError = $true
                    $member.isErrorMessage = "The contact found in this group is from a previously migrated group.  This would typically mean this was the parent group that had a child DL that was migrated.  Office 365 Groups do not support nested groups.  This contact will need to be removed for migration."  

                    $global:preCreateErrors+=$member
                }
                elseif ($member.recipientType -eq $functionObjectClassContact)
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
                elseif ($member.recipientType -eq $functionObjectClassDynamic)
                {
                    out-logfile -string "Member is a dynamic group group - record as error."

                    $member.isError = $TRUE
                    $member.isErrorMessage = "Dyanmic Groups may not be included in an Office 365 Unified Group.  Remove the group in order to migrate to an Office 365 Unified Group"

                    $global:preCreateErrors+=$member
                }
                else 
                {
                    out-logfile -string "Member is neither a group nor contact - allow the migrate to proceed."
                }
            }
        }
        else 
        {
            out-logfile -string "No distribution group members were provided on this function call."
        }

        if ($exchangeBypassModerationSMTP -ne $NULL)
        {
            out-logfile -string "Evaluating bypass moderation from senders or members of the on premises group."

            foreach ($member in $exchangeBypassModerationSMTP)
            {
                out-logfile -string ("Testing member: "+$member.name)
                out-logfile -string ("Bypass moderation error - invalid attribute.")

                $member.isError = $TRUE
                $member.isErrorMessage = "Office 365 Unified Groups do not have BypassModerationFromSendersOrMembers.  To migrate to an Office 365 Unified Group the bypass moderation from senders or members must be cleared."

                $global:preCreateErrors+=$member
            }
        }
        else
        {
            out-logfile -string "No bypass moderation from senders or members supplied in this function call."
        }

        if ($allObjectsSendAsAccessNormalized -ne $NULL)
        {
            out-logfile -string "Evaluating all send as rights discovered on recipient objects on premises.."

            foreach ($member in $allObjectsSendAsAccessNormalized)
            {
                out-logfile -string ("Testing member: "+$member.name)
                out-logfile -string ("Send as error - invalid permission.")

                $member.isError = $TRUE
                $member.isErrorMessage = "In order to retain or mirror send as permissiosn the group must be a security group.  Office 365 Unified Groups are not securtiy groups.  Remove all send as rights for this group on premises to continue converation to an Office 365 Group."

                $global:preCreateErrors+=$member
            }
        }
        else
        {
            out-logfile -string "No on premsies send as rights provided in this function call."
        }

        if ($allOffice365ManagedBy -ne $NULL)
        {
            out-logfile -string "Evaluating all Office 365 Managed By entries..."

            foreach ($member in $allOffice365ManagedBy)
            {
                out-logfile -string ("Testing member: "+$member.name)
                out-logfile -string "ManagedBy error - invalid permission"

                $functionObject = New-Object PSObject -Property @{
                    Alias = $member.alias
                    Name = $member.name
                    PrimarySMTPAddressOrUPN = $member.primarySMTPAddress
                    GUID = $member.GUID
                    RecipientType = $null
                    ExchangeRecipientTypeDetails = $null
                    ExchangeRecipientDisplayType = $null
                    ExchangeRemoteRecipientType = $null
                    GroupType = $NULL
                    RecipientOrUser = $null
                    ExternalDirectoryObjectID = $member.externalDirectoryObjectID
                    OnPremADAttribute = $null
                    OnPremADAttributeCommonName = $null
                    DN = $member.legacyExchangeDN
                    ParentGroupSMTPAddress = $null
                    isAlreadyMigrated = $null
                    isError=$True
                    isErrorMessage="Office 365 Unified Groups are not security enabled.  They may not have managed by rights on other groups.  Remove the managed by right on this object in Office 365 to proceed with converstion to an Office 365 Unified Group."
                }

                $global:preCreateErrors+=$functionObject
            }
        }
        else 
        {
            out-logfile -string "No Office 365 Managed By objects were submitted for evaluation this function call."
        }

        if ($allOffice365SendAsAccess -ne $NULL)
        {
            out-logfile -string "Evaluating all Office 365 send as acesss"

            foreach ($member in $allOffice365SendAsAccess)
            {
                out-logfile -string ("Testing member: "+$member.Identity)
                out-logfile -string "Send as error - invalid."

                $functionObject = New-Object PSObject -Property @{
                    Alias = $NULL
                    Name = $member.Identity
                    PrimarySMTPAddressOrUPN = $NULL
                    GUID = $NULL
                    RecipientType = $null
                    ExchangeRecipientTypeDetails = $null
                    ExchangeRecipientDisplayType = $null
                    ExchangeRemoteRecipientType = $null
                    GroupType = $NULL
                    RecipientOrUser = $null
                    ExternalDirectoryObjectID = $NULL
                    OnPremADAttribute = $null
                    OnPremADAttributeCommonName = $null
                    DN = $NULL
                    ParentGroupSMTPAddress = $null
                    isAlreadyMigrated = $null
                    isError=$True
                    isErrorMessage="An Office 365 Unified Group is not a security principal and may not have send as rights on other objects.  Remove the send as rights from these objects to proceed with Office 365 Unified Group conversion."
                }

                $global:preCreateErrors+=$functionObject
            }
        }
        else
        {
            out-logfile -string "No Office 365 Send As permissions were submitted in this function call for evaluation."
        }

        if ($allOffice365FullMailboxAccess -ne $NULL)
        {
            out-logfile -string "Evaluating all Office 365 full mailbox access."

            foreach ($member in $allOffice365FullMailboxAccess)
            {
                out-logfile -string ("Testing member: "+$member.Identity)
                out-logfile -string "Full Mailbox Access Permission Error - invalid permission."

                $functionObject = New-Object PSObject -Property @{
                    Alias = $NULL
                    Name = $member.Identity
                    PrimarySMTPAddressOrUPN = $NULL
                    GUID = $NULL
                    RecipientType = $null
                    ExchangeRecipientTypeDetails = $null
                    ExchangeRecipientDisplayType = $null
                    ExchangeRemoteRecipientType = $null
                    GroupType = $NULL
                    RecipientOrUser = $null
                    ExternalDirectoryObjectID = $NULL
                    OnPremADAttribute = $null
                    OnPremADAttributeCommonName = $null
                    DN = $NULL
                    ParentGroupSMTPAddress = $null
                    isAlreadyMigrated = $null
                    isError=$True
                    isErrorMessage="An Office 365 group is not a security principal.  Either remove the full mailbox access rights assigned to the group on this object or do not inclue useCollectedOffice365FullMailboxAccess."
                }

                $global:preCreateErrors+=$functionObject
            }
        }

        if ($allOffice365MailboxFolderPermissions -ne $NULL)
        {
            out-logfile -string "Evaluating all Office 365 send as acesss"

            foreach ($member in $allOffice365MailboxFolderPermissions)
            {
                out-logfile -string ("Testing member: "+$member.Identity)
                out-logfile -string "Mailbox Folder Permission Error - invalid permission."

                $functionObject = New-Object PSObject -Property @{
                    Alias = $member.FolderName
                    Name = $member.Identity
                    PrimarySMTPAddressOrUPN = $NULL
                    GUID = $NULL
                    RecipientType = $null
                    ExchangeRecipientTypeDetails = $null
                    ExchangeRecipientDisplayType = $null
                    ExchangeRemoteRecipientType = $null
                    GroupType = $NULL
                    RecipientOrUser = $null
                    ExternalDirectoryObjectID = $NULL
                    OnPremADAttribute = $null
                    OnPremADAttributeCommonName = $null
                    DN = $NULL
                    ParentGroupSMTPAddress = $null
                    isAlreadyMigrated = $null
                    isError=$True
                    isErrorMessage="An Office 365 Unified Group is not a security principal.  Remove the folder permissions assigned to the group or do not use the useCollectedOffice365MailboxFolders switch."
                }

                $global:preCreateErrors+=$functionObject
            }
        }
        else 
        {
            out-logfile -string "No Office 365 mailbox folder permissions were submitted for evaluation this function call."
        }

        Out-LogFile -string "END start-testO365UnifiedGroupDependency"
        Out-LogFile -string "********************************************************************************"
    }