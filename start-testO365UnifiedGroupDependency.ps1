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

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN start-testO365UnifiedGroupDependency"
        Out-LogFile -string "********************************************************************************"

        Out-LogFile -string "END start-testO365UnifiedGroupDependency"
        Out-LogFile -string "********************************************************************************"
    }