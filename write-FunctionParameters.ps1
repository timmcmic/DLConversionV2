<#
    .SYNOPSIS

    This function outputs all of the paramters from a function to the log file for review.

    .DESCRIPTION

    This function outputs all of the paramters from a function to the log file for review.

    

    #>
    Function write-FunctionParameters
    {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $keyArray,
            [Parameter(Mandatory = $true)]
            $parameterArray,
            [Parameter(Mandatory = $true)]
            $variableArray
        )

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "START write-FunctionParameters"
        Out-LogFile -string "********************************************************************************"
    
        $parameteroutput = @()
    
        foreach ($paramName in $keyArray)
        {
            $bound = $parameterArray.ContainsKey($paramName)
    
            $parameterObject = New-Object PSObject -Property @{
                ParameterName = $paramName
                ParameterValue = if ($bound) { $parameterArray[$paramName] }
                                    else { ($variableArray | where {$_.name -eq $paramName } ).value }
                Bound = $bound
                }
    
            $parameterOutput+=$parameterObject
        }
    
        out-logfile -string $parameterOutput

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "END write-FunctionParameters"
        Out-LogFile -string "********************************************************************************"
    }