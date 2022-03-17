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

    new-Office365DL -groupTypeOverride "Security" -originalDLConfiguration adConfigVariable.

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

        #Declare function variables.

        [string]$functionGroupType=$NULL #Holds the return information for the group query.
        [string]$functionMailNickName = ""
        $functionDL = $NULL

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN New-Office365DL"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        Out-LogFile -string ("OriginalDLConfiguration = ")
        out-logfile -string $originalDLConfiguration
        out-logfile -string ("Office365DLConfiguration = ")
        out-logfile -string $office365DLConfiguration
        out-logfile -string ("Group Type Override = "+$groupTypeOverride)

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

        #Create the distribution group in office 365.
        
        try 
        {
            out-logfile -string "Creating the distribution group in Office 365."

            #It is possible that the group is not fully mail enabled.
            #Groups may now be represented as mail enabled if only MAIL is populated.
            #If on premsies attributes are not specified - use the attributes that were obtained from office 365.

            if ($originalDLConfiguration.mailNickName -eq $NULL)
            {
                out-logfile -string "On premsies group does not have alias / mail nick name -> using Office 365 value."

                $functionMailNickName = $office365DLConfiguration.alias

                out-logfile -string ("Office 365 alias used for group creation: "+$functionMailNickName)
            }
            else 
            {
                out-logfile -string "On premises group has a mail nickname specified - using on premsies value."
                $functionMailNickName = $originalDLConfiguration.mailNickName
                out-logfile -string $functionMailNickName    
            }

            $functionDL = new-o365distributionGroup -name $originalDLConfiguration.cn -alias $functionMailNickName -type $functionGroupType -ignoreNamingPolicy:$TRUE -errorAction STOP 

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