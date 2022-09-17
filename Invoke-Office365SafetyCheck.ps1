<#
    .SYNOPSIS

    This function confirms that the distribution list specified and found in Office 365 is DirSynced=TRUE
    
    .DESCRIPTION

    This function confirms that the distribution list specified and found in Office 365 is DirSynced=TRUE

    .PARAMETER O365DLConfiguration

    The DL configuration obtained by the service.

    .OUTPUTS

    No returns.

    .EXAMPLE

    invoke-office365safetycheck -o365dlconfiguration o365dlconfiguration

    #>
    Function Invoke-Office365SafetyCheck
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $o365dlconfiguration,
            [Parameter(Mandatory = $true)]
            $azureADDLConfiguration
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN INVOKE-OFFICE365SAFETYCHECK"
        Out-LogFile -string "********************************************************************************"

        #Comapre the isDirSync attribute.
        
        try 
        {
            Out-LogFile -string ("Distribution list isDirSynced = "+$o365dlconfiguration.isDirSynced)

            if ($o365dlconfiguration.isDirSynced -eq $FALSE)
            {
                out-logfile -string "Exchange Online is reporting that the distribution list is not directory synced.  Testing azure..."

                if ($azureADDLConfiguration.dirSyncEnabled -eq $FALSE)
                {
                    Out-LogFile -string "The distribution list requested is not directory synced and cannot be migrated." -isError:$TRUE
                }
            }
            else 
            {
                Out-LogFile -string "The distribution list requested is directory synced."
            }
        }
        catch 
        {
            Out-LogFile -string $_ -isError:$TRUE
        }

        Out-LogFile -string "END INVOKE-OFFICE365SAFETYCHECK"
        Out-LogFile -string "********************************************************************************"
    }