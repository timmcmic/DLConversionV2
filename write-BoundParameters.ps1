<#
    .SYNOPSIS

    This function writes all the bound parameters of a given function call.
    
    .DESCRIPTION

    This function writes all the bound parameters of a given function call.

    .OUTPUTS

    Enters into the log file all parameters associted with a function call.

    .EXAMPLE

    write-BoundParameters -parameterArray parameters

    #>
    Function write-BoundParameters
    {
        Param
        (
            [Parameter(Mandatory = $true)]
            $keyArray,
            [Parameter(Mandatory = $true)]
            $parameterArray
        )

        foreach ($paramName in $keyArray.MyCommand.Parameters.Keys)
        {
            $bound = $parameterArray.ContainsKey($paramName)
    
            $parameterObject = New-Object PSObject -Property @{
                ParameterName = $paramName
                ParameterValue = if ($bound) { $parameterArray[$paramName] }
                                 else { Get-Variable -Scope Local -ErrorAction Ignore -ValueOnly $paramName }
                Bound = $bound
              }
    
              out-logfile -string $parameterObject
        }
    }
        