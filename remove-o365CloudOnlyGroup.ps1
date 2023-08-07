<#
    .SYNOPSIS

    This function disabled the on premies distribution list - removing it from azure ad and exchange online.

    .DESCRIPTION

    This function disabled the on premies distribution list - removing it from azure ad and exchange online.

    .PARAMETER parameterSet

    These are the parameters that will be manually cleared from the object in AD mode.

    .PARAMETER DN

    The DN of the group to remove.

    .PARAMETER GlobalCatalog

    The global catalog server the operation should be performed on.

    .PARAMETER UseExchange

    If set to true disablement will occur using the exchange on premises powershell commands.

    .OUTPUTS

    No return.

    .EXAMPLE

    Disable-OriginalDL -originalDLConfiguration $configuration -globalCatalogServer $GC -parameterSet $parameterArray -adCredential $cred

    #>
    Function remove-o365CloudOnlyGroup
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $office365DLConfiguration,
            [Parameter(Mandatory = $false)]
            $DLCleanupRequired=$false
        )

        #Output all parameters bound or unbound and their associated values.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGINE remove-o365CloudOnlyGroup"
        Out-LogFile -string "********************************************************************************"

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        if ($DLCleanupRequired -eq $FALSE)
        {
            try{
                remove-o365DistributionGroup -identity $office365DLConfiguration.externalDirectoryObjectID -confirm:$FALSE -BypassSecurityGroupManagerCheck -errorAction STOP
            }
            catch{
                out-logfile -string "Error removing the original distribution list from Office 365."
                out-logfile -string $_ -isError:$TRUE
            }
        }
        else 
        {
            try{
                remove-o365DistributionGroup -identity $office365DLConfiguration.externalDirectoryObjectID -confirm:$FALSE -BypassSecurityGroupManagerCheck -errorAction STOP
            }
            catch{
                out-logfile -string "Error removing the original distribution list from Office 365 - not failing is optional cleanup operation."
                out-logfile -string $_
            }
        }
        
        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "END remove-o365CloudOnlyGroup"
        Out-LogFile -string "********************************************************************************"
    }