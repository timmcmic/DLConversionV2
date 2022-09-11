<#
    .SYNOPSIS

    This function begins the process of replacing the Office 365 settings for dynamic groups that have been migrated that had cloud only dependencies.

    .DESCRIPTION

    This function begins the process of replacing the Office 365 settings for dynamic groups that have been migrated that had cloud only dependencies.

    .PARAMETER office365Attribute

    The office 365 attribute.

    .PARAMETER office365Member

    The member that is being added.

    .PARAMETER groupSMTPAddress

    The member that is being added.

    .OUTPUTS

    None

    .EXAMPLE

    sstart-ReplaceOffice365Dynamic -office365Attribute Attribute -office365Member groupMember -groupSMTPAddress smtpAddess

    #>
    Function start-ReplaceOffice365Dynamic
    {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $office365Attribute,
            [Parameter(Mandatory = $true)]
            [string]$office365Member,
            [Parameter(Mandatory = $true)]
            [string]$groupSMTPAddress
        )

        out-logfile -string "Output bound parameters..."

        foreach ($paramName in $MyInvocation.MyCommand.Parameters.Keys)
        {
            $bound = $PSBoundParameters.ContainsKey($paramName)

            $parameterObject = New-Object PSObject -Property @{
                ParameterName = $paramName
                ParameterValue = if ($bound) { $PSBoundParameters[$paramName] }
                                else { Get-Variable -Scope Local -ErrorAction Ignore -ValueOnly $paramName }
                Bound = $bound
            }

            out-logfile -string $parameterObject
        }

        [string]$isTestError="No"

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN start-ReplaceOffice365Dynamic"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        $functionCommand=$NULL

        Out-LogFile -string ("Office 365 Attribute = "+$office365Attribute)
        out-logfile -string ("Office 365 Member = "+$office365Member.primarySMTPAddress)

        #Declare function variables.

        out-Logfile -string "Processing operation..."

        if ($office365Attribute -eq "ManagedBy")
        {
            out-logfile -string "Attribute is managedBy - this is single value on Dynamic DLs"

            $functionCommand="set-o365DynamicDistributionGroup -identity $office365Member -$office365Attribute '$groupSMTPAddress' -errorAction STOP"

            $scriptBlock = [scriptBlock]::create($functionCommand)

            out-logfile -string ("The command to execute:  "+$functionCommand)

            try{
                & $scriptBlock
            }
            catch{
                out-logfile -string $_
                $isTestError="Yes"
            }
        }
        else 
        {
            $functionCommand="set-o365DynamicDistributionGroup -identity $office365Member -$office365Attribute @{add='$groupSMTPAddress'} -errorAction STOP"
            out-logfile -string ("The command to execute:  "+$functionCommand)

            $scriptBlock = [scriptBlock]::create($functionCommand)

            out-logfile -string ("The script block to execute is: "+$scriptBlock)

            try {
                & $scriptBlock
            }
            catch {
                out-logfile -string $_
                $isTestError="Yes"
            }
        }
        
        Out-LogFile -string "END start-ReplaceOffice365Dynamic"
        Out-LogFile -string "********************************************************************************"

        return $isTestError
    }