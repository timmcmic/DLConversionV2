<#
    .SYNOPSIS

    This function queries Office 365 for any cloud only dependencies on the migrated groups.
    
    .DESCRIPTION

    This function queries Office 365 for any cloud only dependencies on the migrated groups.

    .PARAMETER DN

    The DN of the object to search attributes for.

    .PARAMETER ATTRIBUTETYPE

    The attribute type of the object we're looking for.

    .OUTPUTS

    An array of PS objects that are the canonicalNames of the dependencies.

    .EXAMPLE

    get-o36GroupDependency -dn DN -attributeType multiValuedExchangeAttribute

    #>
    Function Get-O365GroupDependency
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$DN,
            [Parameter(Mandatory = $TRUE)]
            [string]$attributeType
        )

        #Declare function variables.

        $functionTest=$NULL #Holds the return information for the group query.
        $functionCommand=$NULL #Holds the expression that will be utilized to query office 365.
        [array]$functionObjectArray=$NULL #This is used to hold the object that will be returned.

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN GET-O365GroupDependency"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        OUt-LogFile -string ("DN Set = "+$DN)
        out-logfile -string ("Attribute Type = "+$attributeType)
        
        #Get the specific user using ad providers.
        
        try 
        {
            Out-LogFile -string "Attempting to search Office365 for any groups or users that have the requested dependency."

            if ($attributeType -eq "Members")
            {
                Out-LogFile -string "Entering query office 365 for DL membership."

                $functionCommand = "Get-o365Recipient -Filter { (Members -eq '$dn') -and (isDirSynced -eq '$FALSE') }"

                out-logfile -string ("The query exectued is = "+$functionCommand)

                $functionTest = invoke-expression -command $functionCommand
            }
            else
            {
                Out-LogFile -string "Entering query office 365 for other multi-valued attribute."

                $functionTest = get-adUser -filter {$attributeType -eq $DN} -errorAction STOP
            }

            if ($functionTest -eq $NULL)
            {
                out-logfile -string "There were no groups or users with the request dependency."
            }
            else 
            {
                $functionObjectArray = $functionTest
            }
        }
        catch 
        {
            Out-LogFile -string $_ -isError:$TRUE
        }

        return $functionObjectArray
    }