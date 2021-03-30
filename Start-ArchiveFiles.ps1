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

        out-logFile -string "Disconnecting Exchange Online Session"

        $functionDate = Get-Date -Format FileDateTime

        

        Out-LogFile -string "END Start-ArchiveFiles"
        Out-LogFile -string "********************************************************************************"
    }