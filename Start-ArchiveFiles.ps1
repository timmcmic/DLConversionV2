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

        out-logFile -string "Archiving files associated with run."

        $functionDate = Get-Date -Format FileDateTime
       
        if ($isSuccess -eq $TRUE)
        {
            out-logfile -string "Success - renaming directory."

            $functionFolderName = $functionDate+"-Success"
            $functionOriginalPath= $logFolderPath+$global:staticFolderName

            out-logfile -string $functionFolderName
            out-logfile -string $functionOriginalPath

            rename-item -path $functionOriginalPath -newName $functionFolderName
        }
        else 
        {
            out-logfile -string "FAILED - renaming directory."

            $functionFolderName = $functionDate+"-FAILED"
            $functionOriginalPath= $logFolderPath+$global:staticFolderName

            out-logfile -string $functionFolderName
            out-logfile -string $functionOriginalPath

            rename-item -path $functionOriginalPath -newName $functionFolderName
        }
    }