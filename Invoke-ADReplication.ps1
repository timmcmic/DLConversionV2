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

        #Declare function variables.

        $workingPowershellSession=$NULL

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
            invoke-command -session $workingPowershellSession -ScriptBlock { repadmin /syncall /A }
        }
        catch 
        {
            Out-LogFile -string $_ -isError:$TRUE
        }

        try 
        {
            invoke-command -session $workingPowershellSession -ScriptBlock { repadmin /syncall /APe }
        }
        catch 
        {
            Out-LogFile -string $_ -isError:$TRUE
        }

        Out-LogFile -string "END INVOKE-ADReplication"
        Out-LogFile -string "********************************************************************************"
    }