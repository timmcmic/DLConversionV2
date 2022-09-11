<#
    .SYNOPSIS

    This function archives the files associated with the distribution list migration.

    .DESCRIPTION

    his function archives the files associated with the distribution list migration.

    .PARAMETER isSuccess

    .OUTPUTS

    No return.

    .EXAMPLE

    start-archiveFiles -isSuccess:$TRUE

    #>
    Function Start-ArchiveFiles
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [boolean]$isSuccess=$FALSE,
            [Parameter(Mandatory = $true)]
            [string]$logFolderPath=$NULL
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

        out-logFile -string "Archiving files associated with run."

        $functionDate = Get-Date -Format FileDateTime
        $functionNameSplit = $global:logFile.split("\")

        out-logfile -string "Split string for group name."
        out-logfile -string $functionNameSplit

        $functionNameSplit = $functionNameSplit[-1].split(".")

        out-logfile -string "Split string for group name."
        out-logfile -string $functionNameSplit

        if ($isSuccess -eq $TRUE)
        {
            out-logfile -string "Success - renaming directory."

            $functionFolderName = $functionNameSplit[0]+"-Success"
            $functionFolderName = $functionDate+"-"+$functionFolderName
            $functionOriginalPath= $logFolderPath+$global:staticFolderName

            out-logfile -string $functionFolderName
            out-logfile -string $functionOriginalPath

            rename-item -path $functionOriginalPath -newName $functionFolderName
        }
        else 
        {
            out-logfile -string "FAILED - renaming directory."

            $functionFolderName = $functionNameSplit[0]+"-FAILED"
            $functionFolderName = $functionDate+"-"+$functionFolderName
            $functionOriginalPath= $logFolderPath+$global:staticFolderName

            out-logfile -string $functionFolderName
            out-logfile -string $functionOriginalPath

            $doCounter=0
            $stopLoop=$FALSE

            do {
                try {
                    rename-item -path $functionOriginalPath -newName $functionFolderName -errorAction Stop

                    $stopLoop=$true
                }
                catch {
                    if ($doCounter -gt 5)
                    {
                        $stopLoop-$TRUE
                    }
                    else 
                    {
                        start-sleep -s 5
                        $doCounter=$doCounter+1
                    }
                }
            } until ($stopLoop -eq $TRUE)
            
           
            
        }
    }