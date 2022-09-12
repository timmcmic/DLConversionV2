<#
    .SYNOPSIS

    This function tests for and creates the log file / log file path for the script.

    .DESCRIPTION

    This function tests for and creates the log file / log file path for the script.

    .PARAMETER logFolderPath

    The path of the log file.

	.OUTPUTS

    Ensure the directory exists.
    Establishes the logfile path/name for subsequent function calls.

    .EXAMPLE

    new-statusFile -logFolderPath LOGFOLDERPATH

    #>
    Function new-statusFile
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$logFolderPath
        )

        out-logfile -string "Output bound parameters..."

        $parameteroutput = @()

        foreach ($paramName in $MyInvocation.MyCommand.Parameters.Keys)
        {
            $bound = $PSBoundParameters.ContainsKey($paramName)

            $parameterObject = New-Object PSObject -Property @{
                ParameterName = $paramName
                ParameterValue = if ($bound) { $PSBoundParameters[$paramName] }
                                    else { Get-Variable -Scope Local -ErrorAction Ignore -ValueOnly $paramName }
                Bound = $bound
                }

            $parameterOutput+=$parameterObject
        }

        out-logfile -string $parameterOutput
   
        # Get our log file path

        $logFolderPath = $logFolderPath+$global:statusPath

        #Set the global status path.

        $global:fullStatusPath = $logFolderPath

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
    }