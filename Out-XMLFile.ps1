<#
    .SYNOPSIS

    This function backs up the data for relevant entries to XML.

    .DESCRIPTION

    Backup to XML

    .PARAMETER itemToExport

    This is the item to export to XML

    .PARAMETER logFolderPath

    The path of the log file.

    .PARAMETER itemNameToExport

    What the XML file will be named.

	.OUTPUTS

    Backs up the associated information to XML.

    .EXAMPLE

    Out-XMLFile -itemToExport ITEM -logFolderPath Path -itemNameToExport

    #>
    Function Out-XMLFile
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $itemToExport,
            [Parameter(Mandatory = $true)]
            [string]$itemNameToExport
        )

        #Declare function variables.

        $fileName = $itemNameToExport+".xml"
        
        # Get our log file path and combine it with the filename

        $LogFile = Join-path $logFolderPath $fileName

        #Write our variables to the log.

        # Write everything to our log file and the screen

        try 
        {
            $itemToExport | export-CLIXML -path $LogFile
        }
        catch 
        {
            throw $_
        }
    }