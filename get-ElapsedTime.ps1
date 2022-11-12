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

        $functionElapsedTime = ($endTime - $startTime).seconds

        return $functionElapsedTime
     }