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
            if ($sleepAtSync -ne $FALSE)
            {
                out-logfile -string "Sleeping for 30 seconds."

                start-sleep -s 30
            }
            else 
            {
                $sleepAtSync = $true    
            }

            out-logfile -string "Attempting to run AD Sync."

            $error.Clear()

            invoke-command -session $workingPowershellSession -ScriptBlock {start-adsyncsynccycle -policyType 'Delta' -errorAction 'STOP'} -ErrorAction 'STOP'

            if ($error.count -ne 0)
            {
                out-logfile -string "Error encoutered on delta sync.  This may be perfectly normal."
                out-logfile -string $_
            }
        }while ($error.count -gt 0)     

        Out-LogFile -string "ADConnect was successfully triggered."

        Out-LogFile -string "END INVOKE-ADCONNECT"
        Out-LogFile -string "********************************************************************************"
    }