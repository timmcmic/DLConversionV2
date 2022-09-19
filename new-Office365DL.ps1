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
    Function new-office365dl
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $originalDLConfiguration,
            [Parameter(Mandatory = $true)]
            $office365DLConfiguration,
            [Parameter(Mandatory = $true)]
            [string]$groupTypeOverride
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Declare function variables.

        [string]$functionGroupType=$NULL #Holds the return information for the group query.
        [string]$functionMailNickName = ""
        [string]$functionName = ((Get-Date -Format FileDateTime)+(Get-Random)).tostring()
        $functionDL = $NULL

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN New-Office365DL"
        Out-LogFile -string "********************************************************************************"

        #Calculate the group type to be utilized.
        #Three values - either NULL,Security,or Distribution.

        out-Logfile -string ("The group type for evaluation is = "+$originalDLConfiguration.groupType)

        if ($groupTypeOverride -Eq "Security")
        {
            out-logfile -string "The administrator overrode the group type to security."

            $functionGroupType = "Security"
        }
        elseif ($groupTypeOverride -eq "Distribution")
        {
            out-logfile -string "The administrator overrode the group type to distribution."

            $functionGroupType = "Distribution"
        }
        elseif ($groupTypeOverride -eq "None") 
        {
            out-logfile -string "A group type override was not specified.  Using group type from on premises."

            if (($originalDLConfiguration.groupType -eq "-2147483640") -or ($originalDLConfiguration.groupType -eq "-2147483646") -or ($originalDLConfiguration.groupType -eq "-2147483644"))
            {
                out-logfile -string "The group type from on premises is security."

                $functionGroupType = "Security"
            }
            elseif (($originalDLConfiguration.grouptype -eq "8") -or ($originalDLConfiguration.grouptype -eq "4") -or ($originalDLConfiguration.grouptype -eq "2"))
            {
                out-logfile -string "The group type from on premises is distribution."

                $functionGroupType = "Distribution"
            }
            else 
            {
                out-logfile -string "A group type override was not provided and the input did not include a valid on premises group type."    
            }
        }
        else 
        {
            out-logfile -string "An invalid group type was utilized in function new-Office365DL" -isError:$TRUE    
        }

        out-logfile -string ("Random DL name: "+$functionName)

        #Create the distribution group in office 365.
        
        try 
        {
            out-logfile -string "Creating the distribution group in Office 365."

            $functionDL = new-o365distributionGroup -name $functionName -type $functionGroupType -ignoreNamingPolicy:$TRUE -errorAction STOP 

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