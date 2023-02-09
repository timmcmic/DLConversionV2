<#
    .SYNOPSIS

    This function archives the files associated with the distribution list migration.

    .DESCRIPTION

    his function archives the files associated with the distribution list migration.

    .PARAMETER isSuccess

    .OUTPUTS

    No return.

    .EXAMPLE

    start-archiveFiles -isSuccess:$TRUE

    #>
    Function Start-ArchiveFiles
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [boolean]$isSuccess=$FALSE,
            [Parameter(Mandatory = $true)]
            [string]$logFolderPath=$NULL,
            [Parameter(Mandatory = $false)]
            [boolean]$isHealthCheck=$FALSE   
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        out-logFile -string "Archiving files associated with run."

        if ($isHealthCheck -eq $TRUE)
        {
            $functionDate = Get-Date -Format FileDateTime
            $functionDate = "PreReqTest-"+$functionDate
        }
        else 
        {
            $functionDate = Get-Date -Format FileDateTime
        }
        
        $functionNameSplit = $global:logFile.split("\")

        out-logfile -string "Split string for group name."
        out-logfile -string $functionNameSplit

        $functionNameSplit = $functionNameSplit[-1].split(".")

        if ($funtionNameSplit.count -gt 2)
        {
            out-logfile -string "DL Name contains one or more periods."

            [string]$tempName = ""

            for ($i = 0 ; $i -lt $functionNameSplit.count - 1 ; $i++)
            {
                $tempName = $tempName + $functionSplitName[$i]

                if (($i+1) -lt ($functionSplitName.count - 1))
                {
                    $tempName = $tempName + "."
                }
            }

            out-logfile -string $tempName
        }

        $functionSplitName = $tempName

        out-logfile -string "Split string for group name."
        out-logfile -string $functionNameSplit

        if ($isSuccess -eq $TRUE)
        {
            write-shamelessPlug

            out-logfile -string "Success - renaming directory."

            $functionFolderName = $functionNameSplit[0]+"-Success"
            $functionFolderName = $functionDate+"-"+$functionFolderName
            $functionOriginalPath= $logFolderPath+$global:staticFolderName

            out-logfile -string $functionFolderName
            out-logfile -string $functionOriginalPath

            rename-item -path $functionOriginalPath -newName $functionFolderName
        }
        else 
        {
            write-shamelessPlug
            
            out-logfile -string "FAILED - renaming directory."

            $functionFolderName = $functionNameSplit[0]+"-FAILED"
            $functionFolderName = $functionDate+"-"+$functionFolderName
            $functionOriginalPath= $logFolderPath+$global:staticFolderName

            out-logfile -string $functionFolderName
            out-logfile -string $functionOriginalPath

            $doCounter=0
            $stopLoop=$FALSE

            do {
                try {
                    rename-item -path $functionOriginalPath -newName $functionFolderName -errorAction Stop

                    $stopLoop=$true
                }
                catch {
                    if ($doCounter -gt 5)
                    {
                        $stopLoop-$TRUE
                    }
                    else 
                    {
                        start-sleep -s 5
                        $doCounter=$doCounter+1
                    }
                }
            } until ($stopLoop -eq $TRUE)
        }
    }