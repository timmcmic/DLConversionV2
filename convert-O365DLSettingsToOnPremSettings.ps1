function convert-O365DLSettingsToOnPremSettings
{

    <#
    .SYNOPSIS

    This function converts Office 365 Distribution List settings to on premises distribution list LDAP settings for code reuse.

    .DESCRIPTION

    Trigger function.

    .PARAMETER OFFICE365DLCONFIGURATION

    This is the configuration extracted from Office 365 for the group conversion.

	.OUTPUTS

    Returns DL attributes mapped to LDAP attributes.

    .NOTES

    The following blog posts maintain documentation regarding this module.

    https://timmcmic.wordpress.com/2023/01/08/office-365-distribution-list-migration-version-2-0/

    .EXAMPLE

    convert-o365DLSettingsToOnPremisesSettings -office365DLConfiguration $office365DLConfiguration

    #>

    [CmdletBinding()]
    
    param (
        [Parameter(Mandatory = $true)]
        $office365DLConfiguration
    )
  
    $functionGroupType = $NULL
    $functionCloudSecurity = "MailUniversalSecurityGroup"
    $functionADSecurity = "-2147483640"
    
    #Output all parameters bound or unbound and their associated values.

    write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "BEGIN convert-O365DLSettingsToOnPremSettings"
    Out-LogFile -string "********************************************************************************"

    if ($office365DLConfiguration.recipientType -eq $functionCloudSecurity)
    {
        out-logfile -string "Group is security type in Office 365 - setting active directory equivilient"

        $functionGroupType = $functionADSecurity
    }
    else 
    {
        $functionGroupType = "0"
    }

    out-logfile -string ("The function group type: "+$functionGroupType)

    $functionObject = New-Object PSObject -Property @{
        msExchEnableModeration=$office365DLConfiguration.ModerationEnabled
        msExchHideFromAddressLists=$office365DLConfiguration.HiddenFromAddressListsEnabled
        msExchRequireAuthToSendTo=$office365DLConfiguration.RequireSenderAuthenticationEnabled
        mailNickName=$office365DLConfiguration.Alias
        displayName=$office365DLConfiguration.DisplayName
        msExchSenderHintTranslations=$office365DLConfiguration.MailTipTranslations
        extensionAttribute1=$office365DLConfiguration.CustomAttribute1
        extensionAttribute10=$office365DLConfiguration.CustomAttribute10
        extensionAttribute11=$office365DLConfiguration.CustomAttribute11
        extensionAttribute12=$office365DLConfiguration.CustomAttribute12
        extensionAttribute13=$office365DLConfiguration.CustomAttribute13
        extensionAttribute14=$office365DLConfiguration.CustomAttribute14
        extensionAttribute15=$office365DLConfiguration.CustomAttribute15
        extensionAttribute2=$office365DLConfiguration.CustomAttribute2
        extensionAttribute3=$office365DLConfiguration.CustomAttribute3
        extensionAttribute4=$office365DLConfiguration.CustomAttribute4
        extensionAttribute5=$office365DLConfiguration.CustomAttribute5
        extensionAttribute6=$office365DLConfiguration.CustomAttribute6
        extensionAttribute7=$office365DLConfiguration.CustomAttribute7
        extensionAttribute8=$office365DLConfiguration.CustomAttribute8
        extensionAttribute9=$office365DLConfiguration.CustomAttribute9
        msExchExtensionCustomAttribute1=$office365DLConfiguration.ExtensionCustomAttribute1
        msExchExtensionCustomAttribute2=$office365DLConfiguration.ExtensionCustomAttribute2
        msExchExtensionCustomAttribute3=$office365DLConfiguration.ExtensionCustomAttribute3
        msExchExtensionCustomAttribute4=$office365DLConfiguration.ExtensionCustomAttribute4
        msExchExtensionCustomAttribute5=$office365DLConfiguration.ExtensionCustomAttribute5
        proxyAddresses=$office365DLConfiguration.EmailAddresses
        mail=$office365DLConfiguration.WindowsEmailAddress
        legacyExchangeDN=$office365DLConfiguration.LegacyExchangeDN
        groupType=$functionGroupType
        msExchRemoteRecipientType="N/A"
        msExchRecipientDisplayType=$office365DLConfiguration.RecipientType
        msExchRecipientTypeDetails=$office3365DLConfiguration.RecipientTypeDetails
        'msDS-ExternalDirectoryObjectId' = $office365DLConfiguration.externalDirectoryObjectID
        distinguishedName = $office365DLConfiguration.distinguishedName
    }

    out-logfile -string $functionObject

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END convert-O365DLSettingsToOnPremSettings"
    Out-LogFile -string "********************************************************************************"

    return $functionObject
}