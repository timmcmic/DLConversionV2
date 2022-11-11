<#
    .SYNOPSIS

    This function submits telemetry events to Azure.

    .DESCRIPTION

    This function submits telemetry events to Azure.

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
            [Parameter(Mandatory = $TRUE)]
            [string]$traceModuleName,
            [Parameter(Mandatory = $TRUE)]
            $eventProperties,
            [Parameter(Mandatory = $TRUE)]
            $eventMetrics,
            [Paramter(Mandatory = $TRUE)]
            $eventName
        )

        Send-THEvent -EventName ModuleImportEvent -PropertiesHash $eventProperties -MetricsHash $eventMetrics -ModuleName $traceModuleName -Verbose
     }