<#
    .SYNOPSIS

    This function writes the status file for migrations.

    .DESCRIPTION

    Logging

    .PARAMETER threadNumber

    Boolean value to signify exception / log it / terminate script.

	.OUTPUTS

    Logs all activities and backs up all original data to the log folder directory.

    .EXAMPLE

    Out-LogFile -string "MESSAGE" -isError BOOLEAN

    #>
    Function Out-StatusFile
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $false)]
            [int]$threadNumber=$FALSE
        )
    
        #Define the status file.

        [string]$threadOneStatus="ThreadOneStatus.txt"
        [string]$threadTwoStatus="ThreadTwoStatus.txt"
        [string]$threadThreeStatus="ThreadThreeStatus.txt"
        [string]$threadFourStatus="ThreadFourStatus.txt"
        [string]$threadFiveStatus="ThreadFiveStatus.txt"

        [string]$statusString="DONE"


        if ($threadNumber -eq 1)
        {
            out-logfile -string "Building status file for threadd 1."

            [String]$functionStatus = Join-path $global:fullStatusPath $threadOneStatus
        }
        elseif ($threadNumber -eq 2)
        {
            out-logfile -string "Building status file for threadd 2."

            [String]$functionStatus = Join-path $global:fullStatusPath $threadTwoStatus
        }
        elseif ($threadNumber -eq 3)
        {
            out-logfile -string "Building status file for threadd 3."

            [String]$functionStatus = Join-path $global:fullStatusPath $threadThreeStatus
        }
        elseif ($threadNumber -eq 4)
        {
            out-logfile -string "Building status file for threadd 4."

            [String]$functionStatus = Join-path $global:fullStatusPath $threadFourStatus
        }
        elseif ($threadNumber -eq 5)
        {
            out-logfile -string "Building status file for threadd 5."

            [String]$functionStatus = Join-path $global:fullStatusPath $threadFiveStatus
        }

    
        # Build output string
        #In this case since I abuse the function to write data to screen and record it in log file
        #If the input is not a string type do not time it just throw it to the log.
       
        # Write everything to our log file and the screen

        $statusString | Out-File -FilePath $functionStatus

    }