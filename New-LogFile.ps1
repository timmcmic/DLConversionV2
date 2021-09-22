<#
    .SYNOPSIS

    This function tests for and creates the log file / log file path for the script.

    .DESCRIPTION

    This function tests for and creates the log file / log file path for the script.

    .PARAMETER logFolderPath

    The path of the log file.

    .PARAMETER groupSMTPAddress

    The SMTP address of the group being migrated - this will be parsed for the log file name.

	.OUTPUTS

    Ensure the directory exists.
    Establishes the logfile path/name for subsequent function calls.

    .EXAMPLE

    new-logfile -groupSMTPAddress ADDRESS -logFolderPath LOGFOLDERPATH

    #>
    Function new-LogFile
    {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$groupSMTPAddress,
            [Parameter(Mandatory = $true)]
            [string]$logFolderPath
        )

        #Define the string separator and then separate the string.
        
        $groupsSMTPAddress = $groupSMTPAddress.trim()
        [string]$separator="@"
        [array]$fileNameSplit = $groupSMTPAddress.Split($separator)

        #First entry in split array is the prefix of the group - use that for log file name.
        #The SMTP address may contain letters that are not permitted in a file name - for example ?.
        #Using regex and a pattern to replace invalid file name characters with a -

        [string]$fileName=$fileNameSplit[0]+".log"
        $pattern = '[' + ([System.IO.Path]::GetInvalidFileNameChars() -join '').Replace('\','\\')
        $fileName=[regex]::Replace($fileName, $pattern, "-")
   
        # Get our log file path

        $logFolderPath = $logFolderPath+$global:staticFolderName
        
        #Since $logFile is defined in the calling function - this sets the log file name for the entire script
        
        $global:LogFile = Join-path $logFolderPath $fileName

        #Test the path to see if this exists if not create.

        [boolean]$pathExists = Test-Path -Path $logFolderPath

        if ($pathExists -eq $false)
        {
            try 
            {
                #Path did not exist - Creating

                New-Item -Path $logFolderPath -Type Directory
            }
            catch 
            {
                throw $_
            } 
        }

        out-logfile -string "================================================================================"
        out-logfile -string "START LOG FILE"
        out-logfile -string "================================================================================"
    }