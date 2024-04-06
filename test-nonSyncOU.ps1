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
            $workingSettingsFile = $null
            $workingSettingsFilePath = ""
            $workingSettingsJSON = $null
            $workingPartition = $null

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

            #Validate that the count of settings files is not zero.

            if ($settingsFiles.count -eq 0)
            {
                $returnData += "ERROR:  Applied synchorniztion settings file count is zero.  Unable to validate OU is non-sync OU."
                return $returnData
            }
            else 
            {
                $returnData +=("Applied synchronization settings files successfully obtained.")
                $returnData +- ("Applied settings files count: "+$settingsFiles.count.toString())
            }

            #Take the first settings file entry and utilize this as the settings file for review.

            $workingSettingsFile = $settingsFiles[0]
            
            $returnData += ("Settings file utilized for evaluation: "+$workingSettingsFile)

            $workingSettingsFilePath = $adConnectPath + $settingsFiles[0]

            $returnData += ("Settings file utilize for JSON import: "+$workingSettingsFilePath)

            #Import the content of the settings file.

            try {
                $workingSettingsJSON = get-content -raw -path $workingSettingsFilePath -ErrorAction STOP
            }
            catch {
                $returnData += $_
                $returnData += "ERROR: Unable to import the content of the current applied synchronization settings file.  Unable to validate OU is a non-sync OU."
                return $returnData
            }

            $returnData += $workingSettingsJSON

            #Convert the settings file to JSON.

            try {
                $workingSettingsJSON = $workingSettingsJSON | ConvertFrom-Json -ErrorAction Stop
            }
            catch {
                $returnData += $_
                $returnData += "ERROR:  Unable to convert imported applied synchroniztion file to JSON.  Unable to validate OU is a non-sync OU."
            }

            $returnData += $workingSettingsJSON

            #JSON file succssfully found and imported.  Look for multiple partitions.

            foreach ($partition in $workingSettingsJSON.onpremisesDirectoryPolicy.partitionFilters)
            {
                $returnData += ("Evaluating directory partition: "+$partition)

                if ($args[0].contains($partition.distinguishedName))
                {
                    $returnData += ("Distinguished name parittion matching group found: "+$partition.distinguishedName)
                    $workingPartition = $partition
                }
            }

            $returnData += ("Working domain partition: "+$workingPartition)

            #The working partition has been discovered.

            
            
        } -ArgumentList $ou
        

        Out-LogFile -string "END TEST-NONSYNCOU"
        Out-LogFile -string "********************************************************************************"
    }