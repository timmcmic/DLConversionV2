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

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN OUT-STATUSFILE"
        Out-LogFile -string "********************************************************************************"
    
        #Define the status file.

        [string]$threadOneStatus="ThreadOneStatus.txt"
        [string]$threadTwoStatus="ThreadTwoStatus.txt"
        [string]$threadThreeStatus="ThreadThreeStatus.txt"
        [string]$threadFourStatus="ThreadFourStatus.txt"
        [string]$threadFiveStatus="ThreadFiveStatus.txt"

        [string]$statusString="DONE"


        if ($threadNumber -eq 1)
        {
            out-logfile -string "Building status file for thread 1."

            [String]$functionStatus = Join-path $global:fullStatusPath $threadOneStatus
        }
        elseif ($threadNumber -eq 2)
        {
            out-logfile -string "Building status file for thread 2."

            [String]$functionStatus = Join-path $global:fullStatusPath $threadTwoStatus
        }
        elseif ($threadNumber -eq 3)
        {
            out-logfile -string "Building status file for thread 3."

            [String]$functionStatus = Join-path $global:fullStatusPath $threadThreeStatus
        }
        elseif ($threadNumber -eq 4)
        {
            out-logfile -string "Building status file for thread 4."

            [String]$functionStatus = Join-path $global:fullStatusPath $threadFourStatus
        }
        elseif ($threadNumber -eq 5)
        {
            out-logfile -string "Building status file for thread 5."

            [String]$functionStatus = Join-path $global:fullStatusPath $threadFiveStatus
        }

        #Write the generic thread to the file - we only care that the file was created.

        $statusString | Out-File -FilePath $functionStatus

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "END OUT-STATUSFILE"
        Out-LogFile -string "********************************************************************************"

    }