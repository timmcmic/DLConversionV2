<#
    .SYNOPSIS

    This function disables all open powershell sessions.

    .DESCRIPTION

    This function disables all open powershell sessions.

    .PARAMETER globalCatalogServer

    The global catalog server to run operations on.

    .PARAMETER originalDLConfiguration

    The original DL configuration

    .PARAMETER adCredential

    The active directory credential

    .OUTPUTS

    No return.

    .EXAMPLE

    disable-allPowerShellSessions -globalCatalogServer $GC -originalDLConfiguration $config -adCredential $CRED

    #>
    Function remove-onPremGroup
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$globalCatalogServer,
            [Parameter(Mandatory = $true)]
            $originalDLConfiguration,
            [Parameter(Mandatory = $true)]
            $adCredential,
            [Parameter(Mandatory = $false)]
            [ValidateSet("Basic","Negotiate")]
            $activeDirectoryAuthenticationMethod="Negotiate"
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        [string]$isTestError="No"

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN remove-onPremGroup"
        Out-LogFile -string "********************************************************************************"

        out-logFile -string "Remove on premises distribution group."

        try
        {
            remove-adobject -identity $originalDLConfiguration.distinguishedName -server $globalCatalogServer -credential $adCredential -authType $activeDirectoryAuthenticationMethod -confirm:$FALSE -errorAction STOP
        }
        catch
        {
            out-logfile -string $_
            $isTestError="Yes"
        }

        Out-LogFile -string "END remove-onPremGroup"
        Out-LogFile -string "********************************************************************************"

        return $isTestError
    }