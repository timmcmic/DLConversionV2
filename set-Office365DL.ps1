<#
    .SYNOPSIS

    This function sets the single value attributes of the group created in Office 365.

    .DESCRIPTION

    This function sets the single value attributes of the group created in Office 365.

    .PARAMETER originalDLConfiguration

    The original configuration of the DL on premises.

    .PARAMETER groupTypeOverride

    Submits the group type override of specified by the administrator at run time.

    .OUTPUTS

    None

    .EXAMPLE

    set-Office365DL -originalDLConfiguration DLConfiguration -groupTypeOverride TYPEOVERRIDE.

    #>
    Function set-Office365DL
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $originalDLConfiguration,
            [Parameter(Mandatory = $true)]
            [string]$groupTypeOverride
        )

        #Declare function variables.

        $functionMemberDepartRestrictionType=$NULL #Holds the return information for the group query.

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN SET-Office365DL"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        Out-LogFile -string ("OriginalDLConfiguration = ")
        out-logfile -string $originalDLConfiguration
        out-logfile -string ("Group Type Override = "+$groupTypeOverride)

        #If the group type was overridden from the default - the member join restriction has to be adjusted.

        if ( $groupTypeOverride -eq "Security" )
		{
			$functionMemberDepartRestriction = "Closed"
		}
		else 
		{
			#$functionMemberDepartRestriction = 
		}

        #Create the distribution group in office 365.
        
        try 
        {
            out-logfile -string "Creating the distribution group in Office 365."

            new-o365distributionGroup -name $originalDLConfiguration.cn -alias $originalDLConfiguration.mailNickName -type $functionGroupType
        }
        catch 
        {
            Out-LogFile -string $_ -isError:$TRUE
        }

        Out-LogFile -string "END SET-Office365DL"
        Out-LogFile -string "********************************************************************************"
    }