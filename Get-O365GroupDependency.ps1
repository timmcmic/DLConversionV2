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
            [string]$attributeType,
            [Parameter(Mandatory = $false)]
            [ValidateSet("Standard","Unified","Dynamic")]
            [string]$groupType="Standard"
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
        out-logfile -string ("Group Type = "+$groupType)
        
        #Get the specific user using ad providers.
        
        try 
        {
            Out-LogFile -string "Attempting to search Office365 for any groups or users that have the requested dependency."

            if ($attributeType -eq "Members")
            {
                #The attribute type is member - so we need to query recipients.

                Out-LogFile -string "Entering query office 365 for DL membership."

                $functionCommand = "Get-o365Recipient -Filter { ($attributeType -eq '$dn') -and (isDirSynced -eq '$FALSE') } -errorAction 'STOP'"

                $functionTest = invoke-expression -command $functionCommand

                out-logfile -string ("The function command executed = "+$functionCommand)
            }
            elseif ($attributeType -eq "ForwardingAddress")
            {
                 #The attribute type is forwarding address - search only mailboxes.

                 Out-LogFile -string "Entering query office 365 mailboxes."

                 $functionCommand = "Get-o365Mailbox -Filter { $attributeType -eq '$dn' } -errorAction 'STOP'"
 
                 $functionTest = invoke-expression -command $functionCommand 
                 
                 out-logfile -string ("The function command executed = "+$functionCommand)
            }
            else
            {
                #The attribute type is a property of the DL - attempt to obtain.

                Out-LogFile -string "Entering query office 365 for DL to be set on property."

                if ($groupType -eq "Standard")
                {
                    out-logfile -string "The group type is standard - querying distribution groups."
                    
                    $functionCommand = "Get-o365DistributionGroup -Filter { ($attributeType -eq '$dn') -and (isDirSynced -eq '$FALSE') } -errorAction 'STOP'"

                    $functionTest = invoke-expression -command $functionCommand
                    
                    out-logfile -string ("The function command executed = "+$functionCommand)
                }
                elseif ($groupType -eq "Unified")
                {
                    out-logfile -string "The group type is unified - querying distribution groups."
                    
                    $functionCommand = "Get-o365UnifiedGroup -Filter { $attributeType -eq '$dn' } -errorAction 'STOP'"

                    $functionTest = invoke-expression -command $functionCommand
                    
                    out-logfile -string ("The function command executed = "+$functionCommand)
                }
                elseif ($groupType -eq "Dynamic")
                {
                    out-logfile -string "The group type is dynamic - querying distribution groups."
                    
                    $functionCommand = "Get-o365DynamicDistributionGroup -Filter { $attributeType -eq '$dn' } -errorAction 'STOP'"

                    $functionTest = invoke-expression -command $functionCommand
                    
                    out-logfile -string ("The function command executed = "+$functionCommand)
                }
                else 
                {
                    throw "Invalid group type specified in function call.  Acceptable Standard or Universal"    
                } 
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