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

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Declare function variables.

        [array]$functionTest=@() #Holds the return information for the group query.
        $functionCommand=$NULL #Holds the expression that will be utilized to query office 365.
        [array]$functionObjectArray=@() #This is used to hold the object that will be returned.

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN GET-O365GroupDependency"
        Out-LogFile -string "********************************************************************************"
        
        #Escape double quotes if present in the DN.

        $DN = $dn.replace('`','``')
        $DN = $dn.Replace('"','`"')

        out-logfile -string ("Updated DN = "+$dn)

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

                $functionCommand = "Get-o365Recipient -Filter { ($attributeType -eq `"$dn`") -and (isDirSynced -eq '$FALSE') } -errorAction 'STOP'"

                $scriptBlock=[scriptBlock]::create($functionCommand)

                $functiontest += invoke-command -scriptBlock $scriptBlock

                out-logfile -string ("The function command executed = "+$functionCommand)
            }
            elseif ($attributeType -eq "ForwardingAddress")
            {
                 #The attribute type is forwarding address - search only mailboxes.

                 Out-LogFile -string "Entering query office 365 mailboxes."

                 $functionCommand = "Get-o365Mailbox -Filter { $attributeType -eq `"$dn`" } -errorAction 'STOP'"

                 $scriptBlock=[scriptBlock]::create($functionCommand)

                 $functiontest += invoke-command -scriptBlock $scriptBlock
                 
                 out-logfile -string ("The function command executed = "+$functionCommand)
            }
            elseif ($attributeType -eq "ManagedBy")
            {
                #The attribute type is managed by.  This is only relevant to groups.

                out-logfile "Managed by is only relevant to groups - performing query on only groups."

                out-logfile -string "Starting collection of distribution groups."

                $functionCommand = "Get-o365DistributionGroup -Filter { ($attributeType -eq `"$dn`") -and (isDirSynced -eq '$FALSE') } -errorAction 'STOP'"

                $scriptBlock=[scriptBlock]::create($functionCommand)

                $functiontest += invoke-command -scriptBlock $scriptBlock
                
                out-logfile -string ("The function command executed = "+$functionCommand)

                out-logfile -string "Starting collection of dynamic distribution groups."

                $functionCommand = "Get-o365DynamicDistributionGroup -Filter { $attributeType -eq `"$dn`" } -errorAction 'STOP'"

                $scriptBlock=[scriptBlock]::create($functionCommand)

                $functionTest += invoke-command -scriptBlock $scriptBlock
                
                out-logfile -string ("The function command executed = "+$functionCommand)
            }
            else
            {
                out-logfile -string "Starting to gather attribute for all recipient types."
                out-logfile -string "Starting collection of distribution groups."

                $functionCommand = "Get-o365DistributionGroup -Filter { ($attributeType -eq `"$dn`") -and (isDirSynced -eq '$FALSE') } -errorAction 'STOP'"

                $scriptBlock=[scriptBlock]::create($functionCommand)

                $functiontest += invoke-command -scriptBlock $scriptBlock
                
                out-logfile -string ("The function command executed = "+$functionCommand)

                out-logfile -string "Starting collection of dynamic distribution groups."

                $functionCommand = "Get-o365DynamicDistributionGroup -Filter { $attributeType -eq `"$dn`" } -errorAction 'STOP'"

                $scriptBlock=[scriptBlock]::create($functionCommand)

                $functionTest += invoke-command -scriptBlock $scriptBlock
                
                out-logfile -string ("The function command executed = "+$functionCommand)

                out-logfile -string "Starting collection of universal distribution groups."

                $functionCommand = "Get-o365UnifiedGroup -Filter { $attributeType -eq `"$dn`" } -errorAction 'STOP'"

                $scriptBlock=[scriptBlock]::create($functionCommand)

                $functionTest += invoke-command -scriptBlock $scriptBlock
                
                out-logfile -string ("The function command executed = "+$functionCommand)

                out-logfile -string "Starting collection of mailbox recipients."

                $functionCommand = "Get-o365Mailbox -Filter { ($attributeType -eq `"$dn`") -and (isDirSynced -eq '$FALSE') } -errorAction 'STOP'"

                $scriptBlock=[scriptBlock]::create($functionCommand)

                $functionTest += invoke-command -scriptBlock $scriptBlock

                out-logfile -string ("The function command executed = "+$functionCommand)

                out-logfile -string "Starting collection of mail user recipients."

                $functionCommand = "Get-o365Mailuser -Filter { ($attributeType -eq `"$dn`") -and (isDirSynced -eq '$FALSE') } -errorAction 'STOP'"

                $scriptBlock=[scriptBlock]::create($functionCommand)

                $functionTest += invoke-command -scriptBlock $scriptBlock

                out-logfile -string ("The function command executed = "+$functionCommand)

                out-logfile -string "Starting collection of mail contact recipients."

                $functionCommand = "Get-o365MailContact -Filter { ($attributeType -eq `"$dn`") -and (isDirSynced -eq '$FALSE') } -errorAction 'STOP'"

                $scriptBlock=[scriptBlock]::create($functionCommand)

                $functionTest += invoke-command -scriptBlock $scriptBlock

                out-logfile -string ("The function command executed = "+$functionCommand)

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