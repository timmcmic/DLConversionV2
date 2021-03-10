<#
    .SYNOPSIS

    This function provides the logging functionality of the script.

    .DESCRIPTION

    Logging

    .PARAMETER string

    The string to be written to the log file.

    .PARAMETER isError

    Boolean value to signify exception / log it / terminate script.

	.OUTPUTS

    Logs all activities and backs up all original data to the log folder directory.

    .EXAMPLE

    Out-LogFile -string "MESSAGE" -isError BOOLEAN

    #>
    Function Out-LogFile
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$String,
            [Parameter(Mandatory = $false)]
            [boolean]$isError=$FALSE
        )
    
        # Get the current date

        [string]$date = Get-Date -Format G
    
        # Build output string

        [string]$logstring = ( "[" + $date + "] - " + $string)

        # Write everything to our log file and the screen

        try 
        {
            $logstring | Out-File -FilePath $LogFile -Append
        }
        catch 
        {
            throw $_
        }

        #Write to the screen the information passed to the log.

        Write-Host $String

        #If the output to the log is terminating exception - throw the same string.

        if ($isError -eq $TRUE)
        {
            Write-Error $String -ErrorAction Stop
        }
    }