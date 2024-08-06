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

        $functionDomain = $ou.Substring($ou.IndexOf("DC="))

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        out-logfile -string ("Function domain name for testing: "+$functionDomain)
        out-logfile -string ("Function OU for testing: "+$ou)

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

        out-logfile -string "Test that the OU is not synchronized in AD Connect."


        $testReturn = invoke-command -Session $workingPowershellSession -ScriptBlock {

            #Define working variables.

            $returnData = @()
            $settingsFiles = @()
            $workingSettingsFile = $null
            $workingSettingsFilePath = ""
            $workingSettingsJSON = $null
            $workingPartition = $null
            $workingInclusions = $null
            $workingExclusions = $null
            $parentIncluded = $false
            $exclusionFound = $false

            $programData = $env:programData
            $adConnectPath = $programData + "\AADConnect\"
            $fileFilter = "Applied-SynchronizationPolicy*.json"
            $sortFilter = "LastWriteTime"
            

            #Log calculated information to return variable.

            $returnData += ("Program Data Environment Path: "+$programData)
            $returnData += ("ADConnect Program Data Path: "+$adConnectPath)
            $returnData += ("File filter: "+$fileFilter)
            $returnData += ("Sort filter: "+$sortFilter)
            $returnData += ("OU: "+$args[1])
            $returnData += ("DomainName: "+$args[0])

            #Obtain all of the applied settings files in the directory.

            try
            {
                $settingsFiles += get-childItem -Path $adConnectPath -Filter $fileFilter -errorAction STOP | Sort-Object $sortFilter -Descending

                $returnData += "The following applied settings files were located:"

                foreach ($file in $settingsFiles)
                {
                    $returnData+=$file.name
                }
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
            }

            #Take the first settings file entry and utilize this as the settings file for review.

            $workingSettingsFile = $settingsFiles[0]
            
            $returnData += ("Settings file utilized for evaluation: "+$workingSettingsFile)

            $workingSettingsFilePath = $adConnectPath + $settingsFiles[0]

            $returnData += ("Settings file utilize for JSON import: "+$workingSettingsFilePath)

            #Import the content of the settings file.

            try {
                $workingSettingsJSON = get-content -raw -path $workingSettingsFilePath -ErrorAction STOP
                $returnData += "Successfully able to obtain the raw applied settings content."
            }
            catch {
                $returnData += $_
                $returnData += "ERROR: Unable to import the content of the current applied synchronization settings file.  Unable to validate OU is a non-sync OU."
                return $returnData
            }

            #Convert the settings file to JSON.

            try {
                $workingSettingsJSON = $workingSettingsJSON | ConvertFrom-Json -ErrorAction Stop
                $returnData += "Successfully able to convert the raw content from JSON."
            }
            catch {
                $returnData += $_
                $returnData += "ERROR:  Unable to convert imported applied synchroniztion file to JSON.  Unable to validate OU is a non-sync OU."
                return $returnData
            }

            #JSON file succssfully found and imported.  Look for multiple partitions.

            foreach ($partition in $workingSettingsJSON.onpremisesDirectoryPolicy.partitionFilters)
            {
                $returnData += ("Evaluating directory partition: "+$partition)

                if ($args[0] -eq $partition.distinguishedName)
                {
                    $returnData += ("Distinguished name partition matching group found: "+$partition.distinguishedName)
                    $workingPartition = $partition
                }
                else
                {
                    out-logfile -string "This is not the partition that you were looking for...use the force and find the next one..."
                }
            }

            $returnData += ("Working domain partition: "+$workingPartition)

            #The working partition has been discovered.
            #Caputure the inclusions and exclusions

            $workingInclusions = $workingPartition.containerinclusions
            $workingExclusions = $workingPartition.containerexclusions

            #Start attempt to determine if the directory is excluded from sync.

            foreach ($inclusion in $workingInclusions)
            {
                $returnData += ("Processing inclusion: "+$inclusion)

                if ($args[1].contains($inclusion))
                {
                    $returnData += "A parent OU or the OU itself was found on the list of inclusions."
                    $returnData += "Proceed with validating that an exclusion exists for the OU."
                    $parentIncluded = $true
                }
                else
                {
                    $returnData += "The OU does not contain the inclusion."
                }
            }

            if ($parentIncluded -eq $TRUE)
            {
                foreach ($exclusion in $workingExclusions)
                {
                    $returnData += ("Processing exclusion: "+$exclusion)

                    if ($exclusion -eq $args[1])
                    {
                        $returnData += "Parent included / OU explicitly excluded."
                        $returnData += "SUCCESS:  The specified OU is excluded from synchronization"
                        $exclusionFound = $true
                    }
                }
            }
            else
            {
                $returnData += "Parent OU is excluded therefore the sub OU is excluded.."
                $returnData += "SUCCESS:  The specified OU is excluded from synchronization"
                $exclusionFound = $true
            }

            if ($exclusionFound -eq $false)
            {
                $returnData +="ERROR:  Specified OU was not found as not syncing."
            }

            return $returnData
            
        } -ArgumentList $functionDomain,$ou

        foreach ($entry in $testReturn)
        {
            out-logfile -string $entry
        }

        if ($testReturn[-1].contains("ERROR:"))
        {
            throw 
        }

        Out-LogFile -string "END TEST-NONSYNCOU"
        Out-LogFile -string "********************************************************************************"
    }