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
            $String,
            [Parameter(Mandatory = $false)]
            [boolean]$isError=$FALSE,
            [Parameter(Mandatory = $false)]
            [boolean]$isAudit=$FALSE
        )
    
        # Get the current date

        [string]$date = Get-Date -Format G
    
        # Build output string
        #In this case since I abuse the function to write data to screen and record it in log file
        #If the input is not a string type do not time it just throw it to the log.

        if ($string.gettype().name -eq "String")
        {
            [string]$logstring = ( "[" + $date + "] - " + $string)
        }
        else 
        {
            $logString = $String
        }
        
        # Write everything to our log file and the screen

        $logstring | Out-File -FilePath $global:LogFile -Append
    
        #Write to the screen the information passed to the log.

        if ($string.gettype().name -eq "String")
        {
            Write-Host $logString
        }
        else 
        {
            write-host $logString | select-object -expandProperty *
        }

        #If the output to the log is terminating exception - throw the same string.

        if ($isError -eq $TRUE)
        {
            if ($global:ThreadNumber -gt 0)
            {
                out-statusFile -threadNumber $global:ThreadNumber
            }

            write-error $logString
            disable-allPowerShellSessions

            if ($isAudit -eq $FALSE)
            {
                Start-ArchiveFiles -isSuccess:$FALSE -logFolderPath $logFolderPath
            }
            exit
        }
    }