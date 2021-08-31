<#
    .SYNOPSIS

    This function calculates the correct OU to place an object.

    .DESCRIPTION

    This function calculates the correct OU to place an object.

    .PARAMETER originalDLConfiguration

    The mail attribute of the group to search.

    .OUTPUTS

    Returns the organizational unit where the object should be stored.

    .EXAMPLE

    get-OULocation -originalDLConfiguration $originalDLConfiguration

    #>

    Function Get-OULocation
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $originalDLConfiguration
        )

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN Get-OULocation"
        Out-LogFile -string "********************************************************************************"

        #Declare function variables.

        [string]$returnOU=$NULL

        $tempOUSubstring = $originalDLConfiguration.distinguishedname.substring($originalDLConfiguration.distinguishedName.indexof(",OU="))
        out-logfile -string "Temp OU Substring = "
        out-logfile -string $tempOUSubstring
        $tempOUSubstring = $tempOUSubstring.substring($tempOUSubstring.indexOF("OU"))
        out-logfile -string "Temp OU Substring Substring ="
        out-logfile -string $tempOUSubstring

        $returnOU = $testOUSubstring

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "END Get-OULocation"
        Out-LogFile -string "********************************************************************************"

        return $returnOU
     }