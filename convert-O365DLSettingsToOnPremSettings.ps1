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
  
    
    #Output all parameters bound or unbound and their associated values.

    write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "BEGIN convert-O365DLSettingsToOnPremSettings"
    Out-LogFile -string "********************************************************************************"

    $functionObject = New-Object PSObject -Property @{
        msExchEnableModeration=$office365DConfiguration.ModerationEnabled
        msExchHideFromAddressLists=$office365DConfiguration.HiddenFromAddressListsEnabled
        msExchRequireAuthToSendTo=$office365DConfiguration.RequireSenderAuthenticationEnabled
        mailNickName=$office365DConfiguration.Alias
        displayName=$office365DConfiguration.DisplayName
        msExchSenderHintTranslations=$office365DConfiguration.MailTipTranslations
        extensionAttribute1=$office365DConfiguration.CustomAttribute1
        extensionAttribute10=$office365DConfiguration.CustomAttribute10
        extensionAttribute11=$office365DConfiguration.CustomAttribute11
        extensionAttribute12=$office365DConfiguration.CustomAttribute12
        extensionAttribute13=$office365DConfiguration.CustomAttribute13
        extensionAttribute14=$office365DConfiguration.CustomAttribute14
        extensionAttribute15=$office365DConfiguration.CustomAttribute15
        extensionAttribute2=$office365DConfiguration.CustomAttribute2
        extensionAttribute3=$office365DConfiguration.CustomAttribute3
        extensionAttribute4=$office365DConfiguration.CustomAttribute4
        extensionAttribute5=$office365DConfiguration.CustomAttribute5
        extensionAttribute6=$office365DConfiguration.CustomAttribute6
        extensionAttribute7=$office365DConfiguration.CustomAttribute7
        extensionAttribute8=$office365DConfiguration.CustomAttribute8
        extensionAttribute9=$office365DConfiguration.CustomAttribute9
        msExchExtensionCustomAttribute1=$office365DConfiguration.ExtensionCustomAttribute1
        msExchExtensionCustomAttribute2=$office365DConfiguration.ExtensionCustomAttribute2
        msExchExtensionCustomAttribute3=$office365DConfiguration.ExtensionCustomAttribute3
        msExchExtensionCustomAttribute4=$office365DConfiguration.ExtensionCustomAttribute4
        msExchExtensionCustomAttribute5=$office365DConfiguration.ExtensionCustomAttribute5
        proxyAddresses=$office365DConfiguration.EmailAddresses
        mail=$office365DConfiguration.WindowsEmailAddress
        legacyExchangeDN=$office365DConfiguration.LegacyExchangeDN
    }

    out-logfile -string $functionObject

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END convert-O365DLSettingsToOnPremSettings"
    Out-LogFile -string "********************************************************************************"

    return $functionObject
}