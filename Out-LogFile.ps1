<#
    .SYNOPSIS

    This function provides the logging functionality of the script.

    .DESCRIPTION

    Logging

    .PARAMETER string

    The string to be written to the log file.

    .PARAMETER path

    The path of the log file.

	.OUTPUTS

    Logs all activities and backs up all original data to the log folder directory.

    .EXAMPLE

    Out-LogFile -string "MESSAGE" -path "c:\temp\Start-DistributionListMigration.log"

    #>
    Function Out-LogFile
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$String
        )
    
        # Get our log file path

        $LogFile = Join-path $env:LOCALAPPDATA ExPefwiz.log
    
        # Get the current date

        [string]$date = Get-Date -Format G
    
        # Build output string

        [string]$logstring = ( "[" + $date + "] - " + $string)
    
        # Write everything to our log file and the screen
        
        $logstring | Out-File -FilePath $LogFile -Append
        Write-Verbose  $logstring
    }