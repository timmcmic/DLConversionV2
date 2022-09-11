<#
    .SYNOPSIS

    This function removes all status files in the status file directory.

    .DESCRIPTION

    This function removes all status files in the status file directory.

	.OUTPUTS

    Empty status file directory.

    .EXAMPLE

    remove-statusFiles

    #>
    Function remove-statusFiles
    {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $false)]
            [int]$functionThreadNumber=0,
            [Parameter(Mandatory = $false)]
            [boolean]$fullCleanup=$FALSE
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

        [array]$threadStatus="ThreadZeroStatus.txt","ThreadOneStatus.txt","ThreadTwoStatus.txt","ThreadThreeStatus.txt","ThreadFourStatus.txt","ThreadFiveStatus.txt","ThreadSixStatus.txt","ThreadSevenStatus.txt","ThreadEightStatus.txt","ThreadNineStatus.txt","ThreadTenStatus.txt"

        [string]$functionPath=$NULL

        
        if ($fullCleanUp -eq $FALSE)
        {
            Out-LogFile -string "********************************************************************************"
            Out-LogFile -string "BEGIN remove-StatusFile"
            Out-LogFile -string "********************************************************************************"

            $functionPath=Join-path $global:fullStatusPath $threadStatus[$functionThreadNumber]

            out-logfile -string $functionPath
        }
        else 
        {
            $functionPath=$global:fullStatusPath+"*"
        }
        
        try
        {
            if ($fullCleanup -eq $FALSE)
            {
                out-logfile -string "Removing files from the status directory."
            }

            remove-item -path $functionPath -force -errorAction STOP
        }
        catch
        {
            if ($fullCleanup -eq $FALSE)
            {
                out-logfile -string "Error removing log files." -isError:$TRUE
            }
            else 
            {
                $_
            }
           
        }

        if ($fullCleanup -eq $FALSE)
        {
            Out-LogFile -string "********************************************************************************"
            Out-LogFile -string "END remove-StatusFile"
            Out-LogFile -string "********************************************************************************"
        }
    }