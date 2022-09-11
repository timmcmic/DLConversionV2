<#
    .SYNOPSIS

    This function returns the file count of the status directory.

    .DESCRIPTION

    This function returns the count of the status file directory.

	.OUTPUTS

    Count of status directory.

    .EXAMPLE

    get-StatusFileCount

    #>
    Function get-statusFileCount
    {

        out-logfile -string "Output bound parameters..."

        foreach ($paramName in $MyInvocation.MyCommand.Parameters.Keys)
        {
            $bound = $PSBoundParameters.ContainsKey($paramName)

            $parameterObject = New-Object PSObject -Property @{
                ParameterName = $paramName
                ParameterValue = if ($bound) { $PSBoundParameters[$paramName] }
                                else { Get-Variable -Scope Local -ErrorAction Ignore -ValueOnly $paramName }
                Bound = $bound
            }

            out-logfile -string $parameterObject
        }
        
        out-logfile -string "================================================================================"
        out-logfile -string "START Get-StatusFileCount"
        out-logfile -string "================================================================================"

        [int]$functionFileCount = 0
        [array]$childItems=@()

        try{
            $childItems=get-childitem -path $global:fullStatusPath -file -errorAction STOP
        }
        catch{
            out-logfile -string "Unable to get count of files in status directory." -isError:$TRUE
        }
        
        $functionFileCount = $childItems.count

        if ($functionFileCount -gt 0)
        {
            out-logfile -string "The child items found in the status directory."
            out-logfile -string $childItems     

            out-logfile -string "The number of items found in the status directory."
            out-logfile -string $functionFileCount
        }
        else 
        {
            out-logfile -string "No files found in directory."    
        }
        
        out-logfile -string "================================================================================"
        out-logfile -string "END Get-StatusFileCount"
        out-logfile -string "================================================================================"

        return $functionFileCount
    }