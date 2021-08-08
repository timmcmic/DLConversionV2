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

        try
        {
            remove-item -path $functionPath -force -errorAction STOP
        }
        catch
        {
            $_
        }
    }