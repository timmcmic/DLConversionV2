<#
    .SYNOPSIS

    This function gathers all Office 365 Send as permissions for the migrated DLs.

    .DESCRIPTION

    This function gathers all Office 365 Send as permissions for the migrated DLs.

    .PARAMETER GroupSMTPAddress

    The mail attribute of the group to search.

    .PARAMETER isTrustee

    Determines if we're searching for permissions on the group itself or permissions for the migrated DL on other objects.

    .OUTPUTS

    Returns either send as permissions on the migrated DL or all objects that the migrated DL has send as permissions on.

    .EXAMPLE

    Get-O365DLSendAs -groupSMTPAddress Address -isTrustee:$TRUE

    #>
    Function Get-O365DLSendAs
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$groupSMTPAddress,
            [Parameter(Mandatory = $false)]
            [string]$isTrustee=$FALSE,
            [Parameter(Mandatory = $false)]
            $office365GroupConfiguration,
            [Parameter(Mandatory = $false)]
            $collectedData=$null
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Declare function variables.

        [array]$functionSendAs=@()

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN Get-O365DLSendAs"
        Out-LogFile -string "********************************************************************************"

        #Get the recipient using the exchange online powershell session.

        if ($collectedData -ne $NULL)
        {
            out-logfile -string "Collected data was provided - return data from offline analysis."

            $functionSendAs = $collectedData | where {$_.trustee -eq $office365GroupConfiguration.Name}
        }
        elseif ($isTrustee -eq $TRUE)
        {
            try 
            {
                Out-LogFile -string "Obtaining all Office 365 groups the migrated DL has send as permissions on."

                $functionSendAs = get-o365RecipientPermission -Trustee $groupSMTPAddress -resultsize unlimited -errorAction STOP
            }
            catch 
            {
                Out-LogFile -string $_ -isError:$TRUE
            }

            <#

            out-logfile -string "Determining if the group has permissions to itself and excluding it from the array."
            out-logfile -string ("PreCount: "+$functionSendAs.Count)

            $functionSendAs = $functionSendAs | where {$_.TrusteeSidString -ne $office365GroupConfiguration.SID}

            out-logfile -string ("PostCount: "+$functionSendAs.Count)
            
            #>
        }
        else
        {
            try
            {
                out-logfile -string "Obtaining all send as permissions set directly in Office 365 on the group to be migrated."

                $functionSendAs = get-O365RecipientPermission -identity $groupSMTPAddress -resultsize unlimited -errorAction STOP

                out-logfile -string ("Number of send as located: "+$functionSendAs.Count)
            }
            catch
            {
                out-logfile -string $_ -isError:$TRUE
            }
        }
        
        Out-LogFile -string "END Get-O365DLSendAs"
        Out-LogFile -string "********************************************************************************"
        
        return $functionSendAs
    }