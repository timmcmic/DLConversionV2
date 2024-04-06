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
    Function test-nonSyncOU
    {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $PowershellSessionName,
            [Parameter(Mandatory = $true)]
            $ou
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Declare function variables.

        $testReturn = $null

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN TEST-NONSYNCOU"
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

        out-logfile -string "Test that the OU is not syncrhonized in AD Connect."


        $testReturn = invoke-command -Session $workingPowershellSession -ScriptBlock {

            #Define working variables.

            $returnData = @()
            $settingsFiles = @()

            $programData = $env:programData
            $adConnectPath = $programData + "\AADConnect\"
            $fileFilter = "Applied-SynchronizationPolicy*.json"
            $sortFilter = "LastWriteTime"

            #Log calculated information to return variable.

            $returnData += ("Program Data Environment Path: "+$programData)
            $returnData += ("ADConnect Program Data Path: "+$adConnectPath)
            $returnData += ("File filter: "+$fileFilter)
            $returnData += ("Sort filter: "+$sortFilter)

            #Obtain all of the applied settings files in the directory.

            try
            {
                $settingsFiles += get-childItem -Path $adConnectPath -Filter $fileFilter -errorAction STOP | Sort-Object $sortFilter -Descending
            }
            catch
            {
                $returnData += $_
                $returnData += "ERROR:  Unable to obtain the applied synchronization files.  Unable to validate OU is a non-sync OU."
                return $returnData
            }

            $returnData +=("Applied synchronization settings files successfully obtained.")
            $returnData +- ("Applied settings files count: "+$settingsFiles.count.toString())
            

        } -ArgumentList $ou
        

        Out-LogFile -string "END TEST-NONSYNCOU"
        Out-LogFile -string "********************************************************************************"
    }