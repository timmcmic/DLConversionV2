<#
    .SYNOPSIS

    This function ensures the code executes only in Powershell 5.1 until other module dependencies are corrected.

    .DESCRIPTION

    This function ensures the code executes only in Powershell 5.1 until other module dependencies are corrected.

    .EXAMPLE

    Test-PowershellVersion

    #>
    Function Test-PowershellModule
     {
        [cmdletbinding()]

        $functionPowerShellVersion = $NULL

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN TEST-POWERSHELLVERSION"
        Out-LogFile -string "********************************************************************************"

        #Write function parameter information and variables to a log file.

        $functionPowerShellVersion = $PSVersionTable.PSVersion

        out-logfile -string "Determining powershell version."
        out-logfile -string ("Major: "+$powershellVersion.major)
        out-logfile -string ("Minor: "+$powershellVersion.minor)
        out-logfile -string ("Patch: "+$powershellVersion.patch)
        out-logfile -string $functionPowerShellVersion

        if ($powerShellVersion.Major -ge 7)
        {
            out-logfile -string "Powershell 7 and higher is currently not supported due to module compatability issues."
            out-logfile -string "Please run module from Powershell 5.x"
            out-logfile -string "" -isError:$true
        }
        else
        {
            out-logfile -string "Powershell version is not powershell 7.1 proceed."
        }
    }