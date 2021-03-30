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
        [string]$functionWorkingPath = $global:functionlogFolderPath+$global:staticFailureFolderName
        [string]$functionSuccessPath = $global:functionlogFolderPath+$global:staticSuccessFolderName+$functionDate
        [string]$functionFailurePath = $global:functionlogFilePath+$global:staticFailureFolderName+$functionDate

        out-logfile -string ("Function Date = "+$functionDate)
        out-logfile -string ("Function Working Path = "+ $functionWorkingPath)
        out-logfile -string ("Function Succes Path = "+$functionSuccessPath)
        out-logfile -string ("Function Failure Path = "+$functionFailurePath)
     
        Out-LogFile -string "END Start-ArchiveFiles"
        Out-LogFile -string "********************************************************************************"
    }