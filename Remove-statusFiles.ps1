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
        [string]$functionPath=$global:fullStatusPath+"*"

        out-logfile -string "================================================================================"
        out-logfile -string "START remove-statusFiles"
        out-logfile -string "================================================================================"

        try
        {
            remove-item -path $functionPath -force -errorAction SilentlyContinue
        }
        catch
        {
            out-logfile -string "Unable to remove status files from directory."
        }
        
        out-logfile -string "================================================================================"
        out-logfile -string "END remove-statusFiles"
        out-logfile -string "================================================================================"
    }