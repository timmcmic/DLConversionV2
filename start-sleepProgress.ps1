<#
    .SYNOPSIS

    This function performs a sleep operation with progress.

    .DESCRIPTION

    This function performs a sleep operation with progress.

    .PARAMETER sleepString

    String to display in the status window.

    .PARAMETER sleepSeconds

    Seconds to sleep.

    .OUTPUTS

    No return.

    .EXAMPLE

    start-sleepProgess -sleepString "String" -seconds Seconds

    #>
    Function  start-sleepProgress
    {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$sleepString,
            [Parameter(Mandatory = $true)]
            [int]$sleepSeconds,
            [Parameter(Mandatory = $false)]
            [int]$sleepParentID=0,
            [Parameter(Mandatory = $false)]
            [int]$sleepID=0
        )

        out-logfile -string "Output bound parameters..."

        $parameteroutput = @()

        foreach ($paramName in $MyInvocation.MyCommand.Parameters.Keys)
        {
            $bound = $PSBoundParameters.ContainsKey($paramName)

            $parameterObject = New-Object PSObject -Property @{
                ParameterName = $paramName
                ParameterValue = if ($bound) { $PSBoundParameters[$paramName] }
                                    else { Get-Variable -Scope Local -ErrorAction Ignore -ValueOnly $paramName }
                Bound = $bound
                }

            $parameterOutput+=$parameterObject
        }

        out-logfile -string $parameterOutput

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN  start-sleepProgess"
        Out-LogFile -string "********************************************************************************"

        out-logfile -string $sleepString
        out-logfile -string $sleepSeconds.tostring()

        if(($sleepId -eq 0)-and ($sleepParentID -eq 0))
        {
            For ($i=$sleepSeconds; $i -gt 0; $i--) 
            {  
                Write-Progress -Activity $sleepString -SecondsRemaining $i
                Start-Sleep 1
            }

            write-progress -activity $sleepString -Completed
        }
        else 
        {
            For ($i=$sleepSeconds; $i -gt 0; $i--) 
            {  
                Write-Progress -Activity $sleepString -SecondsRemaining $i -Id $sleepID -ParentId $sleepParentID
                Start-Sleep 1
            }

            Write-Progress -Activity $sleepString -Id $sleepID -ParentId $sleepParentID -Completed
        }

        Out-LogFile -string "END start-sleepProgess"
        Out-LogFile -string "********************************************************************************"
    }