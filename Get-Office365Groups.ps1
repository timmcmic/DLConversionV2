<#
    .SYNOPSIS

    This function pulls all cloud only groups for the specified group types to local variables for work.

    .DESCRIPTION

    This function pulls all cloud only groups for the specified group types to local variables for work.

    .PARAMETER groupType

    Either Unified or Normal

    .OUTPUTS

    Returns an array of all the groups found.

    .EXAMPLE

    get-office365groups -groupType NORMAL

    #>
    Function Get-Office365Groups
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [ValidateSet("Normal","Unified")]
            [string]$groupType
        )

        #Declare function variables.

        $functionGroups=$NULL #Holds the return information for the group query.
        $functionCommand=$NULL #Command to hold the invoke expression.

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN GET-Office365Groups"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        Out-LogFile -string ("GroupType = "+$groupType)

        #Get the recipient using the exchange online powershell session.
        
        try 
        {
            Out-LogFile -string "Gathering all cloud only groups."

            if ($groupType -eq "Normal")
            {
                Out-LogFile -string "Locating all non-dir synced distribution groups."

                $functionGroups = get-O365DistributionGroup -resultsize unlimited -filter { isDirSynced -eq $FALSE }
            }
            
            out-logFile -string $functionGroups.count
            Out-LogFile -string "All cloud only groups were located."
        }
        catch 
        {
            Out-LogFile -string $_ -isError:$TRUE
        }

        Out-LogFile -string "END Get-Office365Groups"
        Out-LogFile -string "********************************************************************************"
        
        return $functionGroups
    }