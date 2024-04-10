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
            $PowershellSessionName,
            [Parameter(Mandatory = $false)]
            $isSingleAttempt = $false
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Declare function variables.

        $workingPowershellSession=$null
        $invokeTest=$null
        $invokeSleep=$false

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN INVOKE-ADCONNECT"
        Out-LogFile -string "********************************************************************************"

        #Obtain the powershell session to work with.

        try 
        {
            $workingPowershellSession = Get-PSSession -Name $PowershellSessionName
            out-logfile -string $workingPowershellSession
        }
        catch 
        {
            Out-LogFile -string $_ -isError:$TRUE
        }


        #Using the powershell session import the ad connect module.
    
        try 
        {
            out-logfile -string "Importing ADSync module..."
            invoke-command -session $workingPowershellSession -ScriptBlock {Import-Module -Name 'AdSync'} *>&1
        }
        catch 
        {
            Out-LogFile -string
        }

        #Establisha a retry counter.
        #The script will try to trigger ad connect 10 times - if not successful move on.
        #Eventually AD conn\ect will run on it's own or potentially there is an issue with the remote powershell session <or> the server itself.

        if ($isSingleAttempt -eq $FALSE)
        {
            $doCounter=0

            do 
            {
                if ($invokeSleep -eq $TRUE)
                {
                    start-sleepProgress -sleepString "Retrying after waiting 30 seconds." -sleepSeconds 30
                }
                else 
                {
                    out-logfile -string "This is first attempt - skipping sleep."

                    $invokeSleep = $true
                }

                $invokeTest = Invoke-Command -Session $workingPowershellSession -ScriptBlock {start-adsyncsynccycle -policyType 'Delta'} *>&1

                out-logfile -string $invokeTest

                if ($invokeTest.result -ne "Success")
                {
                    out-logFile -string "An error has occurred - this is not necessarily uncommon."
                    out-logFile -string $invokeTest.exception.toString()
                }
                else 
                {
                    out-logfile -string "The results of the AD Sync."
                    out-logfile -string $invokeTest.result
                }

                $doCounter=$doCounter+1

                out-logfile ("Retry counter incremented:  "+$doCounter.tostring())
                
            } until (($invokeTest.result -eq "Success") -or ($doCounter -eq 10))
        }
        else 
        {
            out-logfile -string "Attempting one time invocation of AD Connect for multi-threaded retry."

            $invokeTest = Invoke-Command -Session $workingPowershellSession -ScriptBlock {start-adsyncsynccycle -policyType 'Delta' -errorAction Continue} *>&1

            out-logfile -string $invokeTest

            if ($invokeTest.result -ne "Success")
            {
                out-logFile -string "An error has occurred - this is not necessarily uncommon."
                out-logFile -string $invokeTest.exception.toString()
            }
            else {
                out-logfile -string "The results of the AD Sync."
                out-logfile -string $invokeTest.result
            }
        }

        if ($doCounter -eq 10)
        {
            out-logfile -string "AD Connect was not triggered due to retry limit reached."
            out-logfile -string "Consider reviewing the AD Connect server for any potential issues."
        }

        Out-LogFile -string "Function to trigger AD Connect."

        Out-LogFile -string "END INVOKE-ADCONNECT"
        Out-LogFile -string "********************************************************************************"
    }