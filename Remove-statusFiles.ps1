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
            [int]$threadNumber=0,
            [Parameter(Mandatory = $false)]
            [boolean]$fullCleanup=$FALSE
        )

        [array]$threadStatus="ThreadZeroStatus.txt","ThreadOneStatus.txt","ThreadTwoStatus.txt","ThreadThreeStatus.txt","ThreadFourStatus.txt","ThreadFiveStatus.txt","ThreadSixStatus.txt","ThreadSevenStatus.txt","ThreadEightStatus.txt","ThreadNineStatus.txt","ThreadTenStatus.txt"

        [string]$functionPath=$NULL

        
        if ($fullCleanUp -eq $TRUE)
        {
            $functionPath=Join-path $global:fullStatusPath $threadStatus[$threadNumber]
        }
        else 
        {
            $functionPath=$global:fullStatusPath+"*"
        }
        

        try
        {
            remove-item -path $functionPath -force -errorAction STOP
        }
        catch
        {
            $_
        }
    }