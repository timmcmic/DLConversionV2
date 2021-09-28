<#
    .SYNOPSIS

    This function moves the group to the non-SYNC OU.  This is necessary to process the group deletion from Office 365.
    
    .DESCRIPTION

    This function moves the group to the non-SYNC OU.  This is necessary to process the group deletion from Office 365.

    .PARAMETER GlobalCatalogServer

    The global catalog to make the query against.

    .PARAMETER DN

    The original DN of the object.

    .PARAMETER OU

    This is the OU that is set to not synchonize in AD Connect.

    .OUTPUTS

    None

    .EXAMPLE

    move-toNonSyncOU -globalCatalogServer GC -OU NonSyncOU -DN groupDN

    #>
    Function move-toNonSyncOU
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$globalCatalogServer,
            [Parameter(Mandatory = $true)]
            $OU,
            [Parameter(Mandatory = $true)]
            $DN,
            [Parameter(Mandatory = $true)]
            $adCredential
        )

        #Declare function variables.

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "START MOVE-TONONSYNCOU"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        Out-LogFile -string ("GlobalCatalogServer = "+$globalCatalogServer)
        out-logfile -string ("DN = "+$dn)
        out-logfile -string ("OU = "+$OU)
        
        try 
        {
            Out-LogFile -string "Move the group to the non-SYNC OU..."

            move-adObject -identity $DN -targetPath $OU -credential $adCredential -server $globalCatalogServer
        }
        catch 
        {
            Out-LogFile -string $_ 
        }

        Out-LogFile -string "END MOVE-TONONSYNCOU"
        Out-LogFile -string "********************************************************************************"
    }