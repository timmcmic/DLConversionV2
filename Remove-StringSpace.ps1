<#
    .SYNOPSIS

    This function removes all spaces from any user inputted string.  Prevents trianing and leading spaces.

    .DESCRIPTION

    This function removes all spaces from any user inputted string.  Prevents trianing and leading spaces.

	.OUTPUTS

    Empty status file directory.

    .EXAMPLE

    remove-statusFiles

    #>
    Function remove-StringSpace
    {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $false)]
            [string]$stringToFix=0
        )

        
        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN remove-StringSpace"
        Out-LogFile -string "********************************************************************************"

        out-logfile -string ("String to remove spaces: "+$stringToFix)
        out-logfile -string ("String Length "+$stringToFix.length.toString())

        $workingString = $stringToFix.trim()

        out-logfile -string ("String with spaces removed: "+$workingString)
        out-logfile -string ("String Length "+$workingString.length.toString())

        return $workingString

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "END remove-StringSpace"
        Out-LogFile -string "********************************************************************************"
    }