<#
    .SYNOPSIS

    This function confirms that the distribution list specified and found in Office 365 is DirSynced=TRUE
    
    .DESCRIPTION

    This function confirms that the distribution list specified and found in Office 365 is DirSynced=TRUE

    .PARAMETER O365DLConfiguration

    The DL configuration obtained by the service.

    .PARAMETER azureADDLConfiguration

    .OUTPUTS

    No returns.

    .EXAMPLE

    invoke-office365safetycheck -o365dlconfiguration o365dlconfiguration -azureADDLConfiguration azureDLConfiguration

    #>
    Function Invoke-Office365SafetyCheck
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $o365dlconfiguration,
            [Parameter(Mandatory = $true)]
            $azureADDLConfiguration,
            [Parameter(Mandatory = $false)]
            $isCloudOnly = $FALSE
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN INVOKE-OFFICE365SAFETYCHECK"
        Out-LogFile -string "********************************************************************************"

        #Comapre the isDirSync attribute.

        if ($isCloudOnly -eq $FALSE)
        {
            try 
            {
                Out-LogFile -string ("Distribution list isDirSynced = "+$o365dlconfiguration.isDirSynced)

                if ($o365dlconfiguration.isDirSynced -eq $FALSE)
                {
                    out-logfile -string $o365DLConfiguration.isDirSynced
                    out-logfile -string "Exchange Online is reporting that the distribution list is not directory synced.  Testing azure..."

                    if ($azureADDLConfiguration.dirSyncEnabled -eq $FALSE)
                    {
                        out-logfile -string $azureADDLConfiguration.dirSyncEnabled
                        Out-LogFile -string "The distribution list requested is not directory synced and cannot be migrated." -isError:$TRUE
                    }
                    elseif ($azureADDLConfiguration.dirSyncEnabled -eq $null)
                    {
                        out-logfile -string "DirSyncEnabled NULL in AzureAD - not synced."
                        out-logfile -string "The distribution list requested is not directory synced and cannot be migrated." -isError:$TRUE
                    }
                    else 
                    {
                        out-logfile -string $azureADDLConfiguration.dirSyncEnabled
                        out-logfile -string "Azure is reporting the list is directory syncrhonized.  Allow the migration to proceed."
                    }
                }
                else 
                {
                    out-logfile -string ("Exchange: "+$o365dlconfiguration.isDirSynced)
                    out-logfile -string ("Azure: "+$azureADDLConfiguration.dirSyncEnabled)
                    Out-LogFile -string "The distribution list requested is directory synced."
                }
            }
            catch 
            {
                Out-LogFile -string $_ -isError:$TRUE
            }
        }
        else
        {
            out-logfile -string "Testing to ensure dir sync is disabled and group is a mail enabled security or distribution."

            try 
            {
                Out-LogFile -string ("Distribution list isDirSynced = "+$o365dlconfiguration.isDirSynced)

                if ($o365dlconfiguration.isDirSynced -eq $TRUE)
                {
                    out-logfile -string $o365DLConfiguration.isDirSynced
                    out-logfile -string "Exchange Online is reporting that the distribution list is directory synced.  Testing azure..."

                    if ($azureADDLConfiguration.dirSyncEnabled -eq $TRUE)
                    {
                        out-logfile -string $azureADDLConfiguration.dirSyncEnabled
                        Out-LogFile -string "The distribution list requested is directory synced and cannot be converted." -isError:$TRUE
                    }
                }
                else 
                {
                    out-logfile -string ("Exchange: "+$o365dlconfiguration.isDirSynced)
                    out-logfile -string ("Azure: "+$azureADDLConfiguration.dirSyncEnabled)
                    Out-LogFile -string "The distribution list requested is directory synced."
                }
            }
            catch 
            {
                Out-LogFile -string $_ -isError:$TRUE
            }
        }
        
        if (($office365DLConfiguration.recipientType -ne "MailUniversalDistributionGroup") -and ($office365DLConfiguration.recipientType -ne "MailUniversalSecurityGroup"))
        {
            out-logfile -string "The email address specified does not belong to a mail universal distribution group or mail universal security group." -isError:$TRUE
        }
        
        Out-LogFile -string "END INVOKE-OFFICE365SAFETYCHECK"
        Out-LogFile -string "********************************************************************************"
    }