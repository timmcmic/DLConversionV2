<#
    .SYNOPSIS

    This function updates the membership of any cloud only distribution lists for the migrated distribution group.

    .DESCRIPTION

    This function updates the membership of any cloud only distribution lists for the migrated distribution group.

    .PARAMETER office365Group

    The member that is being added.

    .PARAMETER groupSMTPAddress

    The member that is being added.

    .OUTPUTS

    None

    .EXAMPLE

    sstart-replaceOffice365Members -office365Group $group -groupSMTPAddress $address

    #>
    Function start-replaceOffice365Members
    {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $office365Group,
            [Parameter(Mandatory = $true)]
            [string]$groupSMTPAddress
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        [string]$isTestError="No"

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN start-ReplaceOffice365Members"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        $functionCommand=$NULL

        #Declare function variables.

        out-Logfile -string "Processing operation..."

        try{
            add-o365DistributionGroupMember -identity $office365Group.primarySMTPAddress -member $groupSMTPAddress -errorAction STOP -BypassSecurityGroupManagerCheck
        }
        catch{
            out-logfile -string $_
            $isTestError="Yes"
        }


        Out-LogFile -string "END start-replaceOffice365Members"
        Out-LogFile -string "********************************************************************************"

        return $isTestError
    }