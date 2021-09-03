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
            [string]$powershellModuleName,
            [Parameter(Mandatory = $false)]
            [boolean]$powershellVersionTest=$FALSE
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

        if ($powershellVersionTest -eq $TRUE)
        {
            out-logfile -string "The powershell module is gallery installed - check versions and advise."

            $galleryModule = Find-Module -name $powershellModuleName

            if ($galleryModule.version -eq $commandsArray[0].version)
            {
                out-logfile -string "The version of the installed module is current."
                out-logfile -string ("Gallery Module "+$galleryModule.version)
                out-logfile -string ("Installed Module "+$commandsArray[0].version)
            }
            else 
            {
                out-logfile -string "*******************"
                out-logfile -string "*******************"   
                out-logfile -string "Current gallery module is not installed for module"+$powershellModuleName
                out-logfile -string ("Gallery Module "+$galleryModule.version)
                out-logfile -string ("Installed Module "+$commandsArray[0].version)
                out-logfile -string "RECOMMEND MODULE UPGRADE FOR FUTURE MIGRATIONS"   
                out-logfile -string "*******************"
                out-logfile -string "*******************"  
            }
        }

        Out-LogFile -string "END TEST-POWERSHELLMODULE"
        Out-LogFile -string "********************************************************************************"
    }