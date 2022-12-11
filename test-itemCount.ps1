<#
    .SYNOPSIS

    This function validates the parameters within the script.  Paramter validation is shared across functions.
    
    .DESCRIPTION

    This function validates the parameters within the script.  Paramter validation is shared across functions.

    #>
    Function test-itemCount
    {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $itemsToCount,
            [Parameter(Mandatory = $true)]
            $itemsToCompareCount,
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN test-itemCount"
        Out-LogFile -string "********************************************************************************"

        if ($greaterThan -eq $FALSE)
        {
            if ($itemsToCount.count -lt $itemsToCompareCount.count)
            {
                out-logfile -string "ERROR:  Credentials arrays must have one credential for each server specified." -isError:$TRUE
            }
            else 
            {
                out-logfile -string "The number of credentials in the credentials array matches the number of servers provided."  
            }
             
        }

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "END test-ItemCount"
        Out-LogFile -string "********************************************************************************"
    }