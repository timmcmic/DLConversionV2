<#
    .SYNOPSIS

    This function invokes AD Connect to sync the user if credentials were provided.

    .DESCRIPTION

    This function invokes AD Connect to sync the user if credentials were provided.

    .PARAMETER PowershellSessionName

    This is the name of the powershell session that will be used to trigger ad connect.

	.OUTPUTS

    Powershell session to use for aad connect commands.

    .EXAMPLE

    invoke-adConnect -powerShellSessionName NAME

    #>
    Function Invoke-ADConnect
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $PowershellSessionName
        )

        #Declare function variables.

        $workingPowershellSession=$null
        $sleepAtSync=$false

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN INVOKE-ADCONNECT"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        Out-LogFile -string ("PowershellSessionName = "+$PowershellSessionName)

        #Obtain the powershell session to work with.

        try 
        {
            $workingPowershellSession = Get-PSSession -Name $PowershellSessionName
        }
        catch 
        {
            Out-LogFile -string $_ -isError:$TRUE
        }


        #Using the powershell session import the ad connect module.
    
        try 
        {
            invoke-command -session $workingPowershellSession -ScriptBlock {Import-Module -Name 'AdSync'}
        }
        catch 
        {
            Out-LogFile -string $_ -isError:$TRUE
        }

        do 
        {
            $error.clear()

            try 
            {
                out-logfile -string "Invoking ad sync through remote powershell."

                invoke-command -Session $workingPowershellSession -script { start-adsyncsynccycle -policyType Delta -errorAction STOP}
            }
            catch 
            {
                write-host $error.count()
                out-logfile -string "An error has been encountered - this is not necessarily bad."
                out-logfile -string $_
            }    
        } until ($error.count -eq 0)

        Out-LogFile -string "ADConnect was successfully triggered."

        Out-LogFile -string "END INVOKE-ADCONNECT"
        Out-LogFile -string "********************************************************************************"
    }