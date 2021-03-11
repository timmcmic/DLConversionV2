<#
    .SYNOPSIS

    This function tests to see if a powershell module necessary for script execution is present.

    .DESCRIPTION

    This function tests to see if a powershell module necessary for script execution is present.

    .EXAMPLE

    Test-PowershellModule

    #>
    Function Test-PowershellModule
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$powershellModuleName
        )

        #Define variables that will be utilzed in the function.

        [array]$commandsArray=$NULL

        #Initiate the test.
        
        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN TEST-POWERSHELLMODULE"
        Out-LogFile -string "********************************************************************************"

        #Write function parameter information and variables to a log file.

        Out-LogFile -string ("PowerShellModuleName = "+$powershellModuleName)

        try 
        {
            $commandsArray = get-command -module $powershellModuleName -errorAction STOP
        }
        catch 
        {
            Out-LogFile -string $_ -isError:$TRUE
        }

        if ($commandsArray.count -eq 0)
        {
            Out-LogFile -string "The powershell module was not found and is required for script functionality." -iserror:$TRUE
        }
        else
        {
            Out-LogFile -string "The powershell module was found."
        }    

        Out-LogFile -string "END TEST-POWERSHELLMODULE"
        Out-LogFile -string "********************************************************************************"
    }