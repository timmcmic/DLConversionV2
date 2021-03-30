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

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN Start-ArchiveFiles"
        Out-LogFile -string "********************************************************************************"

        out-logFile -string "Archiving files associated with run."

        $functionWorkingPath=

        $functionDate = Get-Date -Format FileDateTime
       
        if ($isSucecss -eq $TRUE)
        {
            out-logfile -string "Success - renaming directory."

            $functionFolderName = $functionDate+"-Success"

            out-logfile -string $functionFolderName

            rename-item $global:staticFolderName -newName $functionFolderName
        }
        
     
        Out-LogFile -string "END Start-ArchiveFiles"
        Out-LogFile -string "********************************************************************************"
    }