<#
    .SYNOPSIS

    This function returns the elapsed time between two UTC provided times.
    
    .DESCRIPTION

    This function returns the elapsed time between two UTC provided times.

    .PARAMETER StartTime

    The start time for evaluation.

    .PARAMETER EndTime

    The end time for evaluation.

    .OUTPUTS

    The difference between the start time and end time.

    .EXAMPLE

    get-elapsedTime -startTime TIME -endTime TIME

    #>

Function get-elapsedTime
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $TRUE)]
            $startTime,
            [Parameter(Mandatory = $TRUE)]
            $EndTime
        )

        $functionElapsedTime = ($endTime - $startTime).totalSeconds

        return $functionElapsedTime
     }