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

        $functionInstrumentationKey = $traceModuleName+".ApplicationInsights.InstrumentationKey"
        $functionConnectionStringKey = $traceModuleName+".ApplicationInsights.ConnectionString"
        $functionOptIn = $traceModuleName+".OptIn"
        $functionIgnoreGDPR = $traceModuleName+".IgnoreGDPR"
        $functionRemovePII = $traceModuleName+".RemovePII"
        $functionModuleName = "TelemetryHelper"
        [string]$functionConnectionString = "InstrumentationKey=63d673af-33f4-401c-931e-f0b64a218d89;IngestionEndpoint=https://eastus2-3.in.applicationinsights.azure.com/;LiveEndpoint=https://eastus2.livediagnostics.monitor.azure.com/"

        Set-PSFConfig -Module $functionModuleName -Name $functionInstrumentationKey -Value $appInsightAPIKey -Initialize -Validation string -Description 'Your ApplicationInsights instrumentation key' -Hidden
        Set-PSFConfig -Module $functionModuleName -Name $functionConnectionStringKey -value $functionConnectionString -Initialize -validation string -Description "Connection string for api workspace." -Hidden
        #Set-PSFConfig -Module 'TelemetryHelper' -Name 'TelemetryHelper.OptInVariable' -Value 'TelemetryHelperTelemetryOptIn' -Initialize -Validation string -Description 'The name of the environment variable used to indicate that telemetry should be sent'
        Set-PSFConfig -Module $functionModuleName -Name $functionOptIn -Value $allowTelemetryCollection -Initialize -Validation bool -Description 'Whether user opts into telemetry or not'
        Set-PSFConfig -Module $functionModuleName -Name $functionIgnoreGDPR -Value $false -Initialize -Validation bool -Description 'Whether telemetry client should ignore user settings, e.g. if you are not bound by GDPR or other regulations'
        Set-PSFConfig -Module $functionModuleName -Name $functionRemovePII -VAlue $true -Initialize -Validation bool -Description "Whether information like the computer name should be stripped from the data that is sent"
     }