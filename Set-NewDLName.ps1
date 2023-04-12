<#
    .SYNOPSIS

    This function add a character to the DL name if exchange hybrid is enabled (allows for the dynamic group creation.)
    
    .DESCRIPTION

    This function add a character to the DL name if exchange hybrid is enabled (allows for the dynamic group creation.)

    .PARAMETER GlobalCatalogServer

    The global catalog to make the query against.

    .PARAMETER DN

    The original DN of the object.

    .PARAMETER DLName

    The name of the DL from the original configuration.

    .PARAMETER DLSamAccountName

    The original DN of the object.

    .PARAMETER adCredential

    .OUTPUTS

    None

    .EXAMPLE

    set-newDLName -dlConfiguration dlConfiguration -globalCatalogServer globalCatalogServer

    #>
    Function set-newDLName
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$globalCatalogServer,
            [Parameter(Mandatory = $true)]
            $dlName,
            [Parameter(Mandatory = $true)]
            $dlSAMAccountName,
            [Parameter(Mandatory = $true)]
            $DN,
            [Parameter(Mandatory = $true)]
            $adCredential
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Declare function variables.

        [string]$functionGroupName=$NULL #Holds the calculated name.
        [string]$functionGroupSAMAccountName=$NULL #Holds the calculated sam account name.
        [string]$functionMaxLength = 64
        [string]$functionGroupNameCharacter = "!"

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN SET-NEWDLNAME"
        Out-LogFile -string "********************************************************************************"

        #Establish new names

        if ($dlName.length -eq $functionMaxLength)
        {
            out-logfile -string "Group name is 64 characters - truncate single character to support rename."

            [string]$functionGroupName = $dlName.substring(0,63)+$functionGroupNameCharacter
        }
        else
        {
            out-logfile -string "Group name does not exceed 64 characters - rename as normal."
        }

        [string]$functionGroupName = $dlName+"!"
        [string]$functionGroupSAMAccountName = $dlSAMAccountName+"!"

        out-logfile -string ("New group name = "+$functionGroupName)
        out-logfile -string ("New group sam account name = "+$functionGroupSAMAccountName)
        
        #Get the specific user using ad providers.
        
        try 
        {
            Out-LogFile -string "Set the AD group name."

            set-adGroup -identity $dn -samAccountName $functionGroupSAMAccountName -server $globalCatalogServer -Credential $adCredential
        }
        catch 
        {
            Out-LogFile -string $_ -isError:$TRUE
        }

        try
        {
            out-logfile -string "Setting the new group name.."

            rename-adobject -identity $dn -newName $functionGroupName -server $globalCatalogServer -credential $adCredential
        }
        catch
        {
            Out-LogFile -string $_ -isError:$true  
        }

        Out-LogFile -string "END Set-NewDLName"
        Out-LogFile -string "********************************************************************************"
    }