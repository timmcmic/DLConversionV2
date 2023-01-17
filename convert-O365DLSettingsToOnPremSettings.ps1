function convert-O365DLSettingsToOnPremSettings
{
    [Parameter(Mandatory = $true)]
    $office365DLConfiguration
    
    #Output all parameters bound or unbound and their associated values.

    write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "BEGIN convert-O365DLSettingsToOnPremSettings"
    Out-LogFile -string "********************************************************************************"

    $functionObject = New-Object PSObject -Property @{
        msExchEnableModeration=$office365DLConfiguration.ModerationEnabled
        msExchHideFromAddressLists=$office365DLConfiguration.HiddenFromAddressListsEnabled
        msExchRequireAuthToSendTo=$office365DLConfiguration.RequireSenderAuthenticationEnabled
        mailNickName=$office365DLConfiguration.Alias
        displayName=$office365DLConfiguration.DisplayName
        msExchSenderHintTranslations=$office365DLConfiguration.MailTipTranslations
        extensionAttribute1=($office365DLConfiguration.CustomAttribute1).toString
        extensionAttribute10=($office365DLConfiguration.CustomAttribute10).toString
        extensionAttribute11=($office365DLConfiguration.CustomAttribute11).toString
        extensionAttribute12=($office365DLConfiguration.CustomAttribute12).toString
        extensionAttribute13=($office365DLConfiguration.CustomAttribute13).toString
        extensionAttribute14=($office365DLConfiguration.CustomAttribute14).toString
        extensionAttribute15=($office365DLConfiguration.CustomAttribute15).toString
        extensionAttribute2=($office365DLConfiguration.CustomAttribute2).toString
        extensionAttribute3=($office365DLConfiguration.CustomAttribute3).toString
        extensionAttribute4=($office365DLConfiguration.CustomAttribute4).toString
        extensionAttribute5=($office365DLConfiguration.CustomAttribute5).toString
        extensionAttribute6=($office365DLConfiguration.CustomAttribute6).toString
        extensionAttribute7=($office365DLConfiguration.CustomAttribute7).toString
        extensionAttribute8=($office365DLConfiguration.CustomAttribute8).toString
        extensionAttribute9=($office365DLConfiguration.CustomAttribute9).toString
        msExchExtensionCustomAttribute1=$office365DLConfiguration.ExtensionCustomAttribute1
        msExchExtensionCustomAttribute2=$office365DLConfiguration.ExtensionCustomAttribute2
        msExchExtensionCustomAttribute3=$office365DLConfiguration.ExtensionCustomAttribute3
        msExchExtensionCustomAttribute4=$office365DLConfiguration.ExtensionCustomAttribute4
        msExchExtensionCustomAttribute5=$office365DLConfiguration.ExtensionCustomAttribute5
        proxyAddresses=$office365DLConfiguration.EmailAddresses
        mail=$office365DLConfiguration.WindowsEmailAddress
        legacyExchangeDN=$office365DLConfiguration.LegacyExchangeDN
    }

    out-logfile -string $functionObject

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END convert-O365DLSettingsToOnPremSettings"
    Out-LogFile -string "********************************************************************************"

    return $functionObject
}