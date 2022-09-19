<#
    .SYNOPSIS

    This function writes the status file for migrations.

    .DESCRIPTION

    Logging

    .PARAMETER threadNumber

    Thread number for the associated status file.

	.OUTPUTS

    Creates a text file to allow for tracking multi-threaded operations.

    .EXAMPLE

    Out-StatusFile -threadNumber 0

    #>
    Function Out-StatusFile
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $false)]
            [int]$threadNumber=0
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN OUT-STATUSFILE"
        Out-LogFile -string "********************************************************************************"
    
        #Define the status file.

        [array]$threadStatus="ThreadZeroStatus.txt","ThreadOneStatus.txt","ThreadTwoStatus.txt","ThreadThreeStatus.txt","ThreadFourStatus.txt","ThreadFiveStatus.txt","ThreadSixStatus.txt","ThreadSevenStatus.txt","ThreadEightStatus.txt","ThreadNineStatus.txt","ThreadTenStatus.txt"

        [string]$statusString="DONE"

        [String]$functionStatus = Join-path $global:fullStatusPath $threadStatus[$threadNumber]

        out-logFile -string $functionStatus

        #Write the generic thread to the file - we only care that the file was created.

        try
        {
            $statusString | Out-File -FilePath $functionStatus -force
        }
        catch
        {
            out-logfile $_ -isError:$TRUE
        }

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "END OUT-STATUSFILE"
        Out-LogFile -string "********************************************************************************"

    }