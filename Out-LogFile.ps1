<#
    .SYNOPSIS

    This function provides the logging functionality of the script.

    .DESCRIPTION

    Logging

    .PARAMETER string

    The string to be written to the log file.

    .PARAMETER logFolderPath

    The path of the log file.

    .PARAMETER groupSMTPAddress

    The SMTP address of the group being migrated - this will be parsed for the log file name.

	.OUTPUTS

    Logs all activities and backs up all original data to the log folder directory.

    .EXAMPLE

    Out-LogFile -string "MESSAGE" -path "c:\temp\Start-DistributionListMigration.log"

    #>
    Function Out-LogFile
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$String,
            [Parameter(Mandatory = $true)]
            [string]$groupSMTPAddress,
            [Parameter(Mandatory = $true)]
            [string]$logFolderPath
        )

        #Define the string separator and then separate the string.

        [string]$separator="@"
        [array]$fileNameSplit = $groupSMTPAddress.Split($separator)

        #First entry in split array is the prefix of the group - use that for log file name.

        [string]$fileName=$fileNameSplit[0]+".log"
   
        # Get our log file path

        $LogFile = Join-path $logFolderPath $fileName
    
        # Get the current date

        [string]$date = Get-Date -Format G
    
        # Build output string

        [string]$logstring = ( "[" + $date + "] - " + $string)

        #Test the path to see if this exists if not create.

        [boolean]$pathExists = Test-Path -Path $logFolderPath

        if ($pathExists -eq $false)
        {
            New-Item -Path $logFolderPath -Type Directory
        }
    
        # Write everything to our log file and the screen

        try 
        {
            $logstring | Out-File -FilePath $LogFile -Append
            Write-Verbose  $logstring 
        }
        catch 
        {
            Write-Error $_
        }
    }