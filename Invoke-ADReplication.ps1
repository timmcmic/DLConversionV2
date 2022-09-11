<#
    .SYNOPSIS

    This function triggers ad replication inbound or outbound from the DC where we process changes.

    .DESCRIPTION

    This function triggers ad replication inbound or outbound from the DC where we process changes.

    .PARAMETER PowershellSessionName

    This is the name of the powershell session that will be used to trigger ad connect.

    .PARAMETER GlobalCatalogServer

    This is the global catalog server where replication will be triggered.

	.OUTPUTS

    Powershell session to use for aad connect commands.

    .EXAMPLE

    invoke-adreplication -powershellsessionName NAME -globalCatalogServer NAME

    #>
    Function Invoke-ADReplication
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $PowershellSessionName,
            [Parameter(Mandatory = $true)]
            $globalCatalogServer
        )

        out-logfile -string "Output bound parameters..."

        foreach ($paramName in $MyInvocation.MyCommand.Parameters.Keys)
        {
            $bound = $PSBoundParameters.ContainsKey($paramName)

            $parameterObject = New-Object PSObject -Property @{
                ParameterName = $paramName
                ParameterValue = if ($bound) { $PSBoundParameters[$paramName] }
                                else { Get-Variable -Scope Local -ErrorAction Ignore -ValueOnly $paramName }
                Bound = $bound
            }

            out-logfile -string $parameterObject
        }

        #Declare function variables.

        $workingPowershellSession=$NULL
        $invokeTest=$null

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN INVOKE-ADREPLICATION"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        Out-LogFile -string ("PowershellSessionName = "+$PowershellSessionName)
        out-logfile -string ("Global CatalogServer = "+$globalCatalogServer)

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
            out-logfile -string "Replication domain controllers inbound."

            $invokeTest=invoke-command -session $workingPowershellSession -ScriptBlock { repadmin /syncall /A } *>&1

            $invokeTest = $invokeTest -join "`r`n"

            out-logfile -string $invokeTest
        }
        catch 
        {
            Out-LogFile -string $_ -isError:$TRUE
        }

        try 
        {
            out-logfile -string "Replication domain controllers outbound."

            $invokeTest=invoke-command -session $workingPowershellSession -ScriptBlock { repadmin /syncall /APe } *>&1

            $invokeTest = $invokeTest -join "`r`n"

            out-logfile -string $invokeTest
        }
        catch 
        {
            Out-LogFile -string $_ -isError:$TRUE
        }

        Out-LogFile -string "END INVOKE-ADReplication"
        Out-LogFile -string "********************************************************************************"
    }