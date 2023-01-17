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
        msExchEnableModeration=$office365DConfiguration.ModerationEnabled
        msExchHideFromAddressLists=$office365DConfiguration.HiddenFromAddressListsEnabled
        msExchRequireAuthToSendTo=$office365DConfiguration.RequireSenderAuthenticationEnabled
        mailNickName=$office365DConfiguration.Alias
        displayName=$office365DConfiguration.DisplayName
        msExchSenderHintTranslations=$office365DConfiguration.MailTipTranslations
        extensionAttribute1=($office365DConfiguration.CustomAttribute1).toString
        extensionAttribute10=($office365DConfiguration.CustomAttribute10).toString
        extensionAttribute11=($office365DConfiguration.CustomAttribute11).toString
        extensionAttribute12=($office365DConfiguration.CustomAttribute12).toString
        extensionAttribute13=($office365DConfiguration.CustomAttribute13).toString
        extensionAttribute14=($office365DConfiguration.CustomAttribute14).toString
        extensionAttribute15=($office365DConfiguration.CustomAttribute15).toString
        extensionAttribute2=($office365DConfiguration.CustomAttribute2).toString
        extensionAttribute3=($office365DConfiguration.CustomAttribute3).toString
        extensionAttribute4=($office365DConfiguration.CustomAttribute4).toString
        extensionAttribute5=($office365DConfiguration.CustomAttribute5).toString
        extensionAttribute6=($office365DConfiguration.CustomAttribute6).toString
        extensionAttribute7=($office365DConfiguration.CustomAttribute7).toString
        extensionAttribute8=($office365DConfiguration.CustomAttribute8).toString
        extensionAttribute9=($office365DConfiguration.CustomAttribute9).toString
        msExchExtensionCustomAttribute1=$office365DConfiguration.ExtensionCustomAttribute1
        msExchExtensionCustomAttribute2=$office365DConfiguration.ExtensionCustomAttribute2
        msExchExtensionCustomAttribute3=$office365DConfiguration.ExtensionCustomAttribute3
        msExchExtensionCustomAttribute4=$office365DConfiguration.ExtensionCustomAttribute4
        msExchExtensionCustomAttribute5=$office365DConfiguration.ExtensionCustomAttribute5
        proxyAddresses=@($office365DConfiguration.EmailAddresses)
        mail=$office365DConfiguration.WindowsEmailAddress
        legacyExchangeDN=$office365DConfiguration.LegacyExchangeDN
    }

    out-logfile -string $functionObject

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END convert-O365DLSettingsToOnPremSettings"
    Out-LogFile -string "********************************************************************************"

    return $functionObject
}