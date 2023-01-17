function convert-O365DLSettingsToOnPremSettings
{
    [Parameter(Mandatory = $true)]
    $office365DLConfiguration

    $functionObject = $null
    
    #Output all parameters bound or unbound and their associated values.

    write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "BEGIN convert-O365DLSettingsToOnPremSettings"
    Out-LogFile -string "********************************************************************************"

    [boolean]$msExchEnableModeration=$office365DLConfiguration.ModerationEnabled
    [boolean]$msExchHideFromAddressLists=$office365DLConfiguration.HiddenFromAddressListsEnabled
    [boolean]$msExchRequireAuthToSendTo=$office365DLConfiguration.RequireSenderAuthenticationEnabled
    [string]$mailNickName=$office365DLConfiguration.Alias
    [string]$displayName=$office365DLConfiguration.DisplayName
    [string]$msExchSenderHintTranslations=$office365DLConfiguration.MailTipTranslations
    [string]$extensionAttribute1=$office365DLConfiguration.CustomAttribute1
    [string]$extensionAttribute10=$office365DLConfiguration.CustomAttribute10
    [string]$extensionAttribute11=$office365DLConfiguration.CustomAttribute11
    [string]$extensionAttribute12=$office365DLConfiguration.CustomAttribute12
    [string]$extensionAttribute13=$office365DLConfiguration.CustomAttribute13
    [string]$extensionAttribute14=$office365DLConfiguration.CustomAttribute14
    [string]$extensionAttribute15=$office365DLConfiguration.CustomAttribute15
    [string]$extensionAttribute2=$office365DLConfiguration.CustomAttribute2
    [string]$extensionAttribute3=$office365DLConfiguration.CustomAttribute3
    [string]$extensionAttribute4=$office365DLConfiguration.CustomAttribute4
    [string]$extensionAttribute5=$office365DLConfiguration.CustomAttribute5
    [string]$extensionAttribute6=$office365DLConfiguration.CustomAttribute6
    [string]$extensionAttribute7=$office365DLConfiguration.CustomAttribute7
    [string]$extensionAttribute8=$office365DLConfiguration.CustomAttribute8
    [string]$extensionAttribute9=$office365DLConfiguration.CustomAttribute9
    [string]$msExchExtensionCustomAttribute1=$office365DLConfiguration.ExtensionCustomAttribute1
    [string]$msExchExtensionCustomAttribute2=$office365DLConfiguration.ExtensionCustomAttribute2
    [string]$msExchExtensionCustomAttribute3=$office365DLConfiguration.ExtensionCustomAttribute3
    [string]$msExchExtensionCustomAttribute4=$office365DLConfiguration.ExtensionCustomAttribute4
    [string]$msExchExtensionCustomAttribute5=$office365DLConfiguration.ExtensionCustomAttribute5
    [array]$proxyAddresses=$office365DLConfiguration.emailAddresses
    [string]$mail=$office365DlConfiguration.windowsEmailAddress
    [string]$legacyExchangeDN=$office365DLConfiguration.legacyExchangeDN

    $functionObject = New-Object PSObject -Property @{
        msExchEnableModeration=$msExchEnableModeration
    }

    out-logfile -string $functionObject

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END convert-O365DLSettingsToOnPremSettings"
    Out-LogFile -string "********************************************************************************"

    return $functionObject
}