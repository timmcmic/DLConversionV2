    Function start-testO365UnifiedGroupDependency
    {
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

    .PARAMETER allOffice365ManagedBy

    All groups that have the list as a manager.

    .PARAMETER allOffice365SendAsAccess

    All groups in Office 365 that this group has send as rights on.

    .PARAMETER allOffice365FullMailboxAccess

    All objects in Office 365 the migrated group has full mailbox access on.

    .PARAMETER allOffice365MailboxFolderPermissions

    All objects in Office 365 the migrated group has mailbox folder permissions on.

    .PARAMETER addManagersAsMembers

    Specifies if managers will be added as members - since owners must be members of a unified group.

    .OUTPUTS

    None

    .EXAMPLE

    sstart-replaceOffice365 -office365Attribute Attribute -office365Member groupMember -groupSMTPAddress smtpAddess

    #>
    
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true , ParameterSetName = 'FirstPass')]
            [AllowNull()]
            $exchangeDLMembershipSMTP,
            [Parameter(Mandatory = $true , ParameterSetName = 'FirstPass')]
            [AllowNull()]
            $exchangeBypassModerationSMTP,
            [Parameter(Mandatory = $true , ParameterSetName = 'FirstPass')]
            [AllowNull()]
            $exchangeManagedBySMTP,
            [Parameter(Mandatory = $true , ParameterSetName = 'FirstPass')]
            [AllowNull()]
            $allObjectsSendAsAccessNormalized,
            [Parameter(Mandatory = $true , ParameterSetName = 'SecondPass')]
            [AllowNull()]
            $allOffice365ManagedBy,
            [Parameter(Mandatory = $true , ParameterSetName = 'SecondPass')]
            [AllowNull()]
            $allOffice365SendAsAccess,
            [Parameter(Mandatory = $true , ParameterSetName = 'SecondPass')]
            [AllowNull()]
            $allOffice365FullMailboxAccess,
            [Parameter(Mandatory = $true , ParameterSetName = 'SecondPass')]
            [AllowNull()]
            $allOffice365MailboxFolderPermissions,
            [Parameter(Mandatory = $true , ParameterSetName = 'FirstPass')]
            [AllowNull()]
            [boolean]$addManagersAsMembers,
            [Parameter(Mandatory = $true , ParameterSetName = 'FirstPass')]
            [AllowNull()]
            $originalDLConfiguration,
            [Parameter(Mandatory = $true , ParameterSetName = 'FirstPass')]
            [AllowNull()]
            $overrideSecurityGroupCheck
        )

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        $functionObjectClassContact = "Contact"
        $functionObjectClassGroup = "Group"
        $functionObjectClassDynamic = "msExchDynamicDistributionList"
        $functionCoManagers = "msExchCoManagedByLink"
        $functionManagers = "managedBy"
        $functionFirstPassParameterSetName = "FirstPass"
        $functionRoomRecipientTypeDetails = "268435456"

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN start-testO365UnifiedGroupDependency"
        Out-LogFile -string "********************************************************************************"

        if ($PSCmdlet.ParameterSetName -eq $functionFirstPassParameterSetName)
        {

            Out-logfile -string "Validating security group override."

            if ((($originalDLConfiguration.groupType -eq "-2147483640") -or ($originalDLConfiguration.groupType -eq "-2147483646") -or ($originalDLConfiguration.groupType -eq "-2147483644")) -and ($overrideSecurityGroupCheck -eq $FALSE))
            {
                $errorObject = New-Object PSObject -Property @{
                    Alias = $originalDLConfiguration.mailNickName
                    Name = $originalDLConfiguration.Name
                    PrimarySMTPAddressOrUPN = $originalDLConfiguration.mail
                    GUID = $originalDLConfiguraiton.objectGUID
                    RecipientType = $originalDLConfiguration.objectClass
                    ExchangeRecipientTypeDetails = $originalDLConfiguration.msExchRecipientTypeDetails
                    ExchangeRecipientDisplayType = $originalDLConfiguration.msExchRecipientDisplayType
                    ExchangeRemoteRecipientType = $originalDLConfiguration.msExchRemoteRecipientType
                    GroupType = $originalDLConfiguration.groupType
                    RecipientOrUser = "Recipient"
                    ExternalDirectoryObjectID = $originalDLConfiguration.'msDS-ExternalDirectoryObjectId'
                    OnPremADAttribute = "SecurityGroupCheck"
                    OnPremADAttributeCommonName = "SecurityGroupCheck"
                    DN = $originalDLConfiguration.distinguishedName
                    ParentGroupSMTPAddress = $groupSMTPAddress
                    isAlreadyMigrated = "N/A"
                    isError=$true
                    isErrorMessage="UNIFIED_GROUP_MIGRATION_GROUP_IS_SECURITY_EXCEPTION:  To perform an Office 365 Unified Group migration of a mail-enabled security group on premsies the administrator must use -overrideSecurityGroupCheck acknolwedging that permissions may be lost in Office 365 as a result of the migration."
                }

                $global:preCreateErrors+=$errorObject
            }
            else 
            {
                out-logfile -string "Group is not security on premises therefore the administrator does not need to override and acknowledge potentially lost permissions."
            }

            out-logfile -string "Ensuring that the group is not a room distribution list."

            if ($originalDLConfiguration.msExchRecipientTypeDetails -eq $functionRoomRecipientTypeDetails)
            {
                out-logfile -string "Generate error - room distribution list found."

                $functionObject = New-Object PSObject -Property @{
                    Alias = $null
                    Name = $null
                    PrimarySMTPAddressOrUPN = $null
                    GUID = $null
                    RecipientType = $null
                    ExchangeRecipientTypeDetails = $null
                    ExchangeRecipientDisplayType = $null
                    ExchangeRemoteRecipientType = $null
                    GroupType = $NULL
                    RecipientOrUser = $null
                    ExternalDirectoryObjectID = $null
                    OnPremADAttribute = $null
                    OnPremADAttributeCommonName = $null
                    DN = $null
                    ParentGroupSMTPAddress = $null
                    isAlreadyMigrated = $null
                    isError=$True
                    isErrorMessage="UNIFIED_GROUP_MIGRATION_ROOMLIST_EXCEPTION:  The distribution list requested for migration to an Office 365 Unified Group is a room distribution list.  Room distribution lists cannot be converted to Office 365 Unified Groups."
                }

                $global:preCreateErrors+=$functionObject
            }
            else
            {
                out-logfile -string "Distribution list to be migrated is not a room distribution group."
            }


            out-logfile -string "Test managers for count > 1 which is required for migration."

            if (($exchangeManagedBySMTP -eq $NULL) -or ($exchangeManagedBySMTP.count -eq 0))
            {
                out-logfile -string "A manager attribute is required on premises.  Managers is the source of owners for Unified Group."

                $functionObject = New-Object PSObject -Property @{
                    Alias = $null
                    Name = $null
                    PrimarySMTPAddressOrUPN = $null
                    GUID = $null
                    RecipientType = $null
                    ExchangeRecipientTypeDetails = $null
                    ExchangeRecipientDisplayType = $null
                    ExchangeRemoteRecipientType = $null
                    GroupType = $NULL
                    RecipientOrUser = $null
                    ExternalDirectoryObjectID = $null
                    OnPremADAttribute = $null
                    OnPremADAttributeCommonName = "ManagedBy / msExchCoManagedBy"
                    DN = $null
                    ParentGroupSMTPAddress = $null
                    isAlreadyMigrated = $null
                    isError=$True
                    isErrorMessage="UNIFIED_GROUP_MIGRATION_NO_MANAGERS_EXCEPTION: No managers are specified on the on-premsies group.  All Office 365 Unified Groups must have at least one owners.  Managers are the source of owners in an Office 365 Unified Group Migration."
                }

                $global:preCreateErrors+=$functionObject
            }
            elseif (($exchangeManagedBySMTP -eq $NULL) -or ($exchangeManagedBySMTP.count -gt 100)) 
            {
                out-logfile -string "Manager count is greater than 100 - this migration may not proceed."

                $functionObject = New-Object PSObject -Property @{
                    Alias = $null
                    Name = $null
                    PrimarySMTPAddressOrUPN = $null
                    GUID = $null
                    RecipientType = $null
                    ExchangeRecipientTypeDetails = $null
                    ExchangeRecipientDisplayType = $null
                    ExchangeRemoteRecipientType = $null
                    GroupType = $NULL
                    RecipientOrUser = $null
                    ExternalDirectoryObjectID = $null
                    OnPremADAttribute = $null
                    OnPremADAttributeCommonName = "managedBy / msExchCoManagedBy"
                    DN = $null
                    ParentGroupSMTPAddress = $null
                    isAlreadyMigrated = $null
                    isError=$True
                    isErrorMessage="UNIFIED_GROUP_MIGRATION_TOO_MANY_MANAGERS_EXCEPTION: The managedBy count is greater than 100.  An Office 365 Unified Group may not have more than 100 managers."
                }

                $global:preCreateErrors+=$functionObject
            }
            else 
            {
                out-logfile -string "There is at least one manager of the on premises group - proceed with further verification."
            }
        }
        else 
        {
            out-logfile -string "This is not the first pass function call - manager evaluation skipped."
        }

        if ($addManagersAsMembers -eq $FALSE)
        {
            if ($exchangeManagedBySMTP -ne $NULL)
            {
                out-logfile -string "Ensure that each manager is a member prior to proceeding."

                foreach ($member in $exchangeManagedBySMTP)
                {
                    out-logfile -string ("Testing manager in members: "+$member.primarySMTPAddressOrUPN)

                    if ($exchangeDLMembershipSMTP.primarySMTPAddressOrUPN -contains $member.primarySMTPAddressOrUPN)
                    {
                        out-logfile -string "The manager / owner is a member."
                    }
                    else 
                    {
                        out-logfile -string "Manager is not a member of the DL - error."

                        $member.isError = $TRUE
                        $member.isErrorMessage = "UNIFIED_GROUP_MIGRATION_MANAGER_NOT_MEMBER_EXCEPTION: Office 365 Groups require all owners to be members.  ManagedBY is mapped to owners - this manager is not a member of the group.  The manage must be removed, use the switch -addManagersAsMembers to add all managers, or manually add this manager as a member."

                        $global:preCreateErrors+=$member
                    }
                }
            }
            else 
            {
                out-logfile -string "No On Premises Managed By objects were submitted for evaluation this function call."
            }
        }
        else
        {
            out-logfile -string "Adding managers to membership for evalution."

            $exchangeDLMembershipSMTP += $exchangeManagedBySMTP
        }

        if ($exchangeDLMembershipSMTP -ne $NULL)
        {
            out-logfile -string "Evaluating Exchange DL Membership"

            foreach ($member in $exchangeDLMembershipSMTP)
            {
                out-logfile -string ("Testing member: "+$member.name)

                if (($member.recipientType -eq $functionObjectClassContact) -and ($member.isAlreadyMigrated -eq $TRUE))
                {
                    if (($member.OnPremADAttribute -eq $functionCoManagers) -or ($member.OnPremADAttribute -eq $functionManagers))
                    {
                        out-logfile -string "Member is a contact associated with a previously migrated group and is a group manager added to membership - record as error."

                        $member.isError = $true
                        $member.isErrorMessage = "UNIFIED_GROUP_MIGRATION_MIGRATED_CONTACT_MANAGEDBY_EXCEPTION:  The contact found is a manager of the group added to members by -addManagersAsMembers.  The contact must be removed from managers."  

                        $global:preCreateErrors+=$member
                    }
                    else 
                    {
                        out-logfile -string "Member is a contact associated with a previously migrated group - record as error."

                        $member.isError = $true
                        $member.isErrorMessage = "UNIFIED_GROUP_MIGRATION_MIGRATED_CONTACT_MEMBERSHIP_EXCEPTION: The contact found in this group is from a previously migrated group.  This would typically mean this was the parent group that had a child DL that was migrated.  Office 365 Groups do not support nested groups.  This contact will need to be removed for migration."  

                        $global:preCreateErrors+=$member
                    }
                }
                elseif ($member.recipientType -eq $functionObjectClassContact)
                {
                    if (($member.OnPremADAttribute -eq $functionCoManagers) -or ($member.OnPremADAttribute -eq $functionManagers))
                    {
                        out-logfile -string "Member is a contact added to members with -addManagersAsMembers - record as error"

                        $member.isError = $true
                        $member.isErrorMessage = "UNIFIED_GROUP_MIGRATION_CONTACT_MANAGEDBY_EXCEPTION: The contact found is a manager of the group added to members by -addManagersAsMembers.  The contact must be removed from managers."  

                        $global:preCreateErrors+=$member
                    }
                    else
                    {
                        out-logfile -string "Member is a contact - record as error."

                        $member.isError = $true
                        $member.isErrorMessage = "UNIFIED_GROUP_MIGRATION_CONTACT_MEMBERSHIP_EXCEPTION Contacts may not be included in an Office 365 Unified Group.  Remove the contact in order to migrate to an Office 365 Unified Group."  

                        $global:preCreateErrors+=$member
                    }
                }
                elseif ($member.recipientType -eq $functionObjectClassGroup)
                {
                    if (($member.OnPremADAttribute -eq $functionCoManagers) -or ($member.OnPremADAttribute -eq $functionManagers))
                    {
                        out-logfile -string "Groups may not be included in an Office 365 Unified Group.  Remove the group in order to migrate to an Office 365 Unified Group.  Group was added as a member by -addManagersAsMembers."

                        $member.isError = $true
                        $member.isErrorMessage = "UNIFIED_GROUP_MIGRATION_GROUP_MANAGEDBY_EXCEPTION: Groups may not be members of Office 365 Unified Groups.  This group was added as a member becuase it is a manager and the migration used -addManagersAsMembers.  Remove the group from managers."  

                        $global:preCreateErrors+=$member
                    }
                    else 
                    {
                        out-logfile -string "Member is a group - record as error."

                        $member.isError = $TRUE
                        $member.isErrorMessage = "UNIFIED_GROUP_MIGRATION_GROUP_MEMBERSHIP_EXCEPTION: Groups may not be included in an Office 365 Unified Group.  Remove the group in order to migrate to an Office 365 Unified Group"

                        $global:preCreateErrors+=$member
                    }
                }
                elseif ($member.recipientType -eq $functionObjectClassDynamic)
                {
                    out-logfile -string "Member is a dynamic group group - record as error."

                    $member.isError = $TRUE
                    $member.isErrorMessage = "UNIFIED_GROUP_MIGRATION_DYNAMIC_MEMBERSHIP_EXCEPTION: Dyanmic Groups may not be included in an Office 365 Unified Group.  Remove the group in order to migrate to an Office 365 Unified Group"

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
                $member.isErrorMessage = "UNIFIED_GROUP_MIGRATION_BYPASS_MODERATION_FROM_SENDERS_OR_MEMBERS_EXCEPTION: Office 365 Unified Groups do not have BypassModerationFromSendersOrMembers.  To migrate to an Office 365 Unified Group the bypass moderation from senders or members must be cleared."

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
                $member.isErrorMessage = "UNIFIED_GROUP_MIGRATION_SENDAS_FOUND_EXCEPTION: In order to retain or mirror send as permissiosn the group must be a security group.  Office 365 Unified Groups are not securtiy groups.  Remove all send as rights for this group on premises to continue converation to an Office 365 Group."

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
                    isErrorMessage="UNIFIED_GROUP_MIGRATION_MANAGEDBY_ON_OTHER_OBJECTS_EXCEPTION: Office 365 Unified Groups are not security enabled.  They may not have managed by rights on other groups.  Remove the managed by right on this object in Office 365 to proceed with converstion to an Office 365 Unified Group."
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
                    isErrorMessage="UNIFIED_GROUP_MIGRATION_SENDAS_FOUND_EXCEPTION:  An Office 365 Unified Group is not a security principal and may not have send as rights on other objects.  Remove the send as rights from these objects to proceed with Office 365 Unified Group conversion."
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
                    isErrorMessage="UNIFIED_GROUP_MIGRATION_FULL_MAILOBOX_ACCESS_EXCEPTION: An Office 365 group is not a security principal.  Either remove the full mailbox access rights assigned to the group on this object or do not inclue useCollectedOffice365FullMailboxAccess."
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
                    isErrorMessage="UNIFIED_GROUP_MIGRATION_MAILBOX_FOLDER_PERMISSION_EXCEPTION:  An Office 365 Unified Group is not a security principal.  Remove the folder permissions assigned to the group or do not use the useCollectedOffice365MailboxFolders switch."
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