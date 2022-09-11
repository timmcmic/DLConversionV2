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
            [int]$threadNumber=0
        )

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