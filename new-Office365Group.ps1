<#
    .SYNOPSIS

    This function creates the new distribution group in office 365.

    .DESCRIPTION

    This function creates the new distribution group in office 365.

    .PARAMETER originalDLConfiguration

    The original configuration of the DL on premises.

    .PARAMETER groupTypeOverride

    Submits the group type override of specified by the administrator at run time.

    .OUTPUTS

    None

    .EXAMPLE

    new-Office365DL -groupTypeOverride "Security" -originalDLConfiguration adConfigVariable -office365DLConfiguration CONFIG

    #>
    Function new-office365Group
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $originalDLConfiguration,
            [Parameter(Mandatory = $true)]
            $office365DLConfiguration
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Declare function variables.

        [string]$functionGroupType=$NULL #Holds the return information for the group query.
        [string]$functionMailNickName = ""
        [string]$functionName = ((Get-Date -Format FileDateTime)+(Get-Random)).tostring()
        $functionDL = $NULL
        $functionIsRoom = $FALSE

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN New-Office365DL"
        Out-LogFile -string "********************************************************************************"

        out-logfile -string ("Random DL name: "+$functionName)

        #Create the distribution group in office 365.
        
        try 
        {
            out-logfile -string "Creating the distribution group in Office 365."

            $functionDL = new-o365UnifiedGroup -displayname $functionName -errorAction STOP 
    
            out-logfile -string $functionDL
        }
        catch 
        {
            Out-LogFile -string $_ -isError:$TRUE
        }

        Out-LogFile -string "END New-Office365DL"
        Out-LogFile -string "********************************************************************************"

        return $functionDL
    }