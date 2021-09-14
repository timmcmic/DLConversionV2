<#
    .SYNOPSIS

    This function scans the folders and outputs a migration summary.

    .DESCRIPTION

    This function scans the folders and outputs a migration summary.

    .PARAMETER logFolderPath

    This is the log folder path that contains the files for auditing.

    .OUTPUTS

    No return.

    .EXAMPLE

    get-MigrationSummary -logFolderPath $logFolderPath

    #>
    Function get-MigrationSummary
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $logFolderPath
        )

        [array]$failedJobs = @()
        [array]$successJobs = @()
        $workingDirectories = $NULL

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN GET-MIGRATIONSUMMARY"
        Out-LogFile -string "********************************************************************************"

        $workingDirectories = get-childItems -path $logFolderPath -recurse -directory

        foreach ($directory in $workingDirectories)
        {
            out-logfile -string ("Evaluating Directory: "+$directory.name)

            if ($directory.name -like "*FAILED")
            {
                out-logfile -string ("Failed Detected: "+$directory.name)
                $failedJobs+=$directory
            }
            elseif ($directory.name -like "*SUCCESS*")
            {
                out-logfile -string ("Success Detected: "+$directory.name)
                $successJobs+=$directory
            }
            else 
            {
                out-logfile -string "Directory neither success or fail."
            }
        }

        out-logfile -string "================================================================================"
        out-logfile -string "***MIGRATION SUMMARY***"
        out-logfile -string "================================================================================"
        out-logfile -string ""
        out-logfile -string "+++FAILED SUMMARY+++"
        out-logfile -string ("Number of failed migrations: " + $failedJobs.count)

        foreach ($job in $failedJobs)
        {
            $temp = $job.name.split("-")
            out-logfile -string ("Group: "+$temp[1]+ "Status: "+$temp[2])
        }

        out-logfile -string ""
        out-logfile -string "+++SUCCESS SUMMARY+++"
        out-logfile -string ("Number of successful migrations: " + $successJobs.count)

        foreach ($job in $successJobs)
        {
            $temp = $job.name.split("-")
            out-logfile -string ("Group: "+$temp[1]+ "Status: "+$temp[2])
        }

        out-logfile -string "================================================================================"
        out-logfile -string "================================================================================"


        Out-LogFile -string "END GET-MIGRATIONSUMMARY"
        Out-LogFile -string "********************************************************************************"
    }