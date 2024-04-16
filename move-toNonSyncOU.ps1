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

    .PARAMETER adCredential

    This is the credential for active directory operations.

    .OUTPUTS

    None

    .EXAMPLE

    move-toNonSyncOU -globalCatalogServer GC -OU NonSyncOU -DN groupDN -adCredential CRED

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
            $adCredential,
            [Parameter(Mandatory = $false)]
            [ValidateSet("Basic","Negotiate")]
            $activeDirectoryAuthenticationMethod="Negotiate",
            [Parameter(Mandatory = $false)]
            $dlMoveCleanup=$FALSE,
            [Parameter(Mandatory = $false)]
            $dlPostCreate=$FALSE
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Declare function variables.

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "START MOVE-TONONSYNCOU"
        Out-LogFile -string "********************************************************************************"

        [boolean]$stopLoop=$false
        [int]$loopCounter = 0

        if ($dlMoveCleanup -eq $FALSE)
        {
            if ($dlPostCreate -eq $FALSE)
            {
                do
                {
                    Out-LogFile -string "Move the group to the non-SYNC OU..."
        
                    try {
                        move-adObject -identity $DN -targetPath $OU -credential $adCredential -server $globalCatalogServer -authType $activeDirectoryAuthenticationMethod -errorAction Stop
        
                        $stopLoop = $true
                    }
                    catch {
                        if ($loopCounter -lt 5)
                        {
                            out-logfile -string "Attempt to move to non-sync OU failed - wait and retry."
                            out-logfile -string ("Attempt number: "+$loopcounter.tostring())
        
                            $loopCounter++
        
                            start-sleepProgress -sleepSeconds 5 -sleepString "Attempt to move to non-sync OU failed - sleep 5 seconds retry."
                        }
                        else {
                            out-logfile -string "Unable to move the group to a non-sync OU - abandon the move."
                            out-logfile -string $_ -isError:$true
                        }
                    }
                } until ($stopLoop -eq $TRUE)
            }
            else 
            {
                try {
                    move-adObject -identity $DN -targetPath $OU -credential $adCredential -server $globalCatalogServer -authType $activeDirectoryAuthenticationMethod -errorAction Stop
                }
                catch {
                    out-logfile -string "Unable to move the group between organizational units.  Manual intervention required."

                    $isErrorObject = new-Object psObject -property @{
                        PrimarySMTPAddressorUPN = ""
                        ExternalDirectoryObjectID = ""
                        Alias = ""
                        Name = $DN
                        Attribute = ""
                        ErrorMessage = "Unable to move the on premises group between OUs.  Manual administrator intervention required."
                        ErrorMessageDetail = $_
                    }

                    out-logfile -string $isErrorObject

                    $global:postCreateErrors += $isErrorObject
                }
            }
        }
        else 
        {
            out-logfile -string "Attempting one move back to the source OU - on premises group was moved to no-sync and failure occurred."

            move-adObject -identity $DN -targetPath $OU -credential $adCredential -server $globalCatalogServer -authType $activeDirectoryAuthenticationMethod -errorAction SilentlyContinue
        }

        Out-LogFile -string "END MOVE-TONONSYNCOU"
        Out-LogFile -string "********************************************************************************"
    }