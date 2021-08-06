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

        [array]$threadStatus="ThreadZeroStatus.txt","ThreadOneStatus.txt","ThreadTwoStatus.txt",,"ThreadThreeStatus.txt","ThreadFourStatus.txt","ThreadFiveStatus.txt",,"ThreadSixStatus.txt","ThreadSevenStatus.txt","ThreadEightStatus.txt",,"ThreadNineStatus.txt",,"ThreadTenStatus.txt"

        [string]$statusString="DONE"

        [String]$functionStatus = Join-path $global:fullStatusPath $threadStatus[$threadNumber]

        #Write the generic thread to the file - we only care that the file was created.

        $statusString | Out-File -FilePath $functionStatus

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "END OUT-STATUSFILE"
        Out-LogFile -string "********************************************************************************"

    }