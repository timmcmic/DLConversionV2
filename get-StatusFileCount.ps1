<#
    .SYNOPSIS

    This function returns the file count of the status directory.

    .DESCRIPTION

    This function returns the count of the status file directory.

	.OUTPUTS

    Count of status directory.

    .EXAMPLE

    get-StatusFileCount

    #>
    Function get-statusFileCount
    {
        out-logfile -string "================================================================================"
        out-logfile -string "START Get-StatusFileCount"
        out-logfile -string "================================================================================"

        [int]$functionFileCount = 0
        [array]$childItems=@()

        $childItems=get-childitem -path $global:fullStatusPath -file

        out-logfile -string "The child items found in the status directory."
        out-logfile -string $childItems

        $functionFileCount = $childItems.count

        out-logfile -string "The number of items found in the status directory."
        out-logfile -string $functionFileCount

        out-logfile -string "================================================================================"
        out-logfile -string "END Get-StatusFileCount"
        out-logfile -string "================================================================================"

        return $functionFileCount
    }