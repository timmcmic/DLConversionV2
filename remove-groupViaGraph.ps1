<#
    .SYNOPSIS

    This function removes the group from EntraID via Graph.
    
    .DESCRIPTION

    This function removes the group from EntraID via Graph.

    .PARAMETER groupObjectID

    The object ID of the group from EntraID

    .OUTPUTS

    None

    .EXAMPLE

    remove-groupViaGraph -groupObjectID $groupObjectID

    #>
    Function remove-groupViaGraph
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$groupObjectID
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN REMOVE-GROUPVIAGRAPH"
        Out-LogFile -string "********************************************************************************"

        try {
            Remove-MGGroup -groupID $groupObjectID -errorAction STOP
        }
        catch {
            out-logfile -string $_
            out-logfile -string "Unable to remove group via graph - hard failure." -isError:$TRUE
        }

        Out-LogFile -string "END REMOVE-GROUPVIAGRAPH"
        Out-LogFile -string "********************************************************************************"
    }