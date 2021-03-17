<#
    .SYNOPSIS

    This function is designed to pull exchange specific dependencies for multi-valued attributes.
    
    .DESCRIPTION

    This function is designed to pull exchange specific dependencies for multi-valued attributes.

    .PARAMETER GlobalCatalog

    The global catalog to make the query against.

    .PARAMETER DN

    The DN of the object to search attributes for.

    .PARAMETER ATTRIBUTETYPE

    The attribute type of the object we're looking for.

    .OUTPUTS

    An array of PS objects that are the canonicalNames of the dependencies.

    .EXAMPLE

    get-groupDependency -globalCatalog GC -dn DN -attributeType multiValuedExchangeAttribute

    #>
    Function get-groupDependency
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$globalCatalogServer,
            [Parameter(Mandatory = $true)]
            [string]$DN,
            [Parameter(Mandatory = $TRUE)]
            [string]$attributeType,
            [Parameter(Mandatory = $false)]
            [ValidateSet("User","UserSMTP","Group")]
            [string]$attributeUserorGroup="Group"
        )

        #Declare function variables.

        $functionTest=$NULL #Holds the return information for the group query.
        [array]$functionObjectArray=$NULL #This is used to hold the object that will be returned.

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN GET-GroupDependency"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        Out-LogFile -string ("GlobalCatalogServer = "+$globalCatalogServer)
        OUt-LogFile -string ("DN Set = "+$DN)
        out-logfile -string ("Attribute Type = "+$attributeType)
        out-logfile -string ("Attribute User or Group = "+$attributeUserOrGroup)
        
        #Get the specific user using ad providers.
        
        try 
        {
            Out-LogFile -string "Attempting to search directory for any groups that have the requested dependency."

            if ($attributeUserOrGroup -eq "GROUP")
            {
                $functionTest = get-adgroup -filter {$attributeType -eq $dn} -errorAction STOP
            }

            if ($functionTest -eq $NULL)
            {
                out-logfile -string "There were no groups or users with the request dependency."
            }
            else 
            {
                #Groups were found.
                
                out-logFile -string "Groups were found with the requested dependency."
                out-logfile -string "Normalizing DN to Canonical Name"

                foreach ($member in $functionTest)
                {
                    $functionObjectArray+=get-canonicalName -globalCatalogServer $globalCatalogServer -dn $member.DistinguishedName
                }
            }
        }
        catch 
        {
            Out-LogFile -string $_ -isError:$TRUE
        }

        return $functionObjectArray
    }