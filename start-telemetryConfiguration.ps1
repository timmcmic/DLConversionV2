<#
    .SYNOPSIS

    This function prepares telemetry configuration data submission to Azure App Insights

    .DESCRIPTION

    This function prepares telemetry configuration data submission to Azure App Insights.

    .PARAMETER allowTelemetryCollection

    Boolean to allow for basic telemetry collection.

    .OUTPUTS

    None

    .EXAMPLE

    start-telemetryConfiguration -allowTelemetryConfiguration $TRUE

    #>
    Function start-telemetryConfiguration
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [boolean]$allowTelemetryCollection,
            [Parameter(Mandatory = $TRUE)]
            [string]$appInsightAPIKey,
            [Parameter(Mandatory = $TRUE)]
            [string]$traceModuleName
        )

        Set-PSFConfig -Module 'TelemetryHelper' -Name 'TelemetryHelper.ApplicationInsights.InstrumentationKey' -Value $appInsightAPIKey -Initialize -Validation string -Description 'Your ApplicationInsights instrumentation key' -Hidden
        #Set-PSFConfig -Module 'TelemetryHelper' -Name 'TelemetryHelper.OptInVariable' -Value 'TelemetryHelperTelemetryOptIn' -Initialize -Validation string -Description 'The name of the environment variable used to indicate that telemetry should be sent'
        Set-PSFConfig -Module 'TelemetryHelper' -Name 'TelemetryHelper.OptIn' -Value $allowTelemetryCollection -Initialize -Validation bool -Description 'Whether user opts into telemetry or not'
        Set-PSFConfig -Module 'TelemetryHelper' -Name 'TelemetryHelper.IgnoreGdpr' -Value $false -Initialize -Validation bool -Description 'Whether telemetry client should ignore user settings, e.g. if you are not bound by GDPR or other regulations'
        Set-PSFConfig -Module 'TelemetryHelper' -Name 'TelemetryHelper.RemovePII' -VAlue $true -Initialize -Validation bool -Description "Whether information like the computer name should be stripped from the data that is sent"
     }