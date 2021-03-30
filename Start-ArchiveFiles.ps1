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
       out-logFile -string "Archiving files associated with run."

        $functionWorkingPath=

        $functionDate = Get-Date -Format FileDateTime
       
        if ($isSuccess -eq $TRUE)
        {
            out-logfile -string "Success - renaming directory."

            $functionFolderName = $functionDate+"-Success"

            out-logfile -string $functionFolderName

            rename-item $global:staticFolderName -newName $functionFolderName
        }
    }