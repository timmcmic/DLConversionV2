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