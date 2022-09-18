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

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Define variables that will be utilzed in the function.

        [array]$commandsArray=$NULL
        [string]$azureADModuleName = "AzureAD"

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
            if ($powershellModuleName -eq $azureADModuleName)
            {
                out-logfile -string "Please see https://timmcmic.wordpress.com/2022/09/18/office-365-distribution-list-migration-version-2-0-part-20/ for more information on a new requirement."
            }

            Out-LogFile -string $_ -isError:$TRUE
        }

        if ($commandsArray.count -eq 0)
        {
            Out-LogFile -string "The powershell module was not found and is required for script functionality." -iserror:$TRUE
        }
        else
        {
            if ($powershellModuleName -eq $azureADModuleName)
            {
                out-logfile -string "Please see https://timmcmic.wordpress.com/2022/09/18/office-365-distribution-list-migration-version-2-0-part-20/ for more information on a new requirement."
            }

            Out-LogFile -string "The powershell module was found."
        }    

        if ($powershellVersionTest -eq $TRUE)
        {
            if (get-PackageProvider nuget)
            {
                out-logfile -string "Proceed with version test NUGET package provider installed."

                out-logfile -string "The powershell module is gallery installed - check versions and advise."

                $galleryModule = Find-Module -name $powershellModuleName -ErrorAction Continue

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
                    out-logfile -string ("Current gallery module is not installed for module"+$powershellModuleName)    
                    out-logfile -string ("Gallery Module "+$galleryModule.version)
                    out-logfile -string ("Installed Module "+$commandsArray[0].version)
                    out-logfile -string "RECOMMEND MODULE UPGRADE FOR FUTURE MIGRATIONS"   
                    out-logfile -string "*******************"
                    out-logfile -string "*******************"  
                }
            }
            else 
            {
                out-logfile -string "NUGET package provier not available - version testing unavailable."    
            }
        }

        Out-LogFile -string "END TEST-POWERSHELLMODULE"
        Out-LogFile -string "********************************************************************************"
    }