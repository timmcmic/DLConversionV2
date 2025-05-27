function start-collectOnPremSendAs
{
    <#
    .SYNOPSIS

    This function exports all of the mailbox folders from the on premises environment with custome permissions.

    .DESCRIPTION

    Trigger function.

    .PARAMETER logFolder

    *REQUIRED*
    The location where logging for the migration should occur including all XML outputs for backups.

    .PARAMETER exchangeServer

    *REQUIRED IF HYBRID MAIL FLOW ENALBED*
    This is the on-premises Exchange server that is required for enabling hybrid mail flow if the option is specified.
    If using a load balanced namespace - basic authentication on powershell must be enabled on all powersell virtual directories.
    If using a single server (direct connection) then kerberos authentication may be utilized.
    
    .PARAMETER exchangeCredential

    *REQUIRED IF HYBRID MAIL FLOW ENABLED*
    This is the credential utilized to establish remote powershell sessions to Exchange on-premises.
    This acccount requires Exchange Organization Management rights in order to enable hybrid mail flow.

    .PARAMETER exchangeAuthenticationMethod

    *OPTIONAL*
    This allows the administrator to specify either Kerberos or Basic authentication for on premises Exchange Powershell.
    Basic is the assumed default and requires basic authentication be enabled on the powershell virtual directory of the specified exchange server.

    .OUTPUTS

    Logs all activities and backs up all original data to the log folder directory.
    Moves the distribution group from on premieses source of authority to office 365 source of authority.

    .EXAMPLE

    Start-collectOnPremFolderPermissions -exchangeServer Server -exchangeCredential $credential

    #>

    #Portions of the audit code adapted from Tony Redmon's project.
    #https://github.com/12Knocksinna/Office365itpros/blob/master/ReportPermissionsFolderLevel.PS1
    #Don't tell him - he can get grumpy at times.

    [cmdletbinding()]

    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$logFolderPath,
        [Parameter(Mandatory = $false)]
        [string]$exchangeServer=$NULL,
        [Parameter(Mandatory = $false)]
        [pscredential]$exchangeCredential=$NULL,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Basic","Kerberos")]
        [string]$exchangeAuthenticationMethod="Basic",
        [Parameter(Mandatory = $false)]
        [boolean]$retryCollection=$FALSE,
        [Parameter(Mandatory = $false)]
        $bringMyOwnRecipients=$NULL
    )

    $global:blogURL = "https://timmcmic.wordpress.com"

    $windowTitle = "Start-collectOnPremSendAs"
    $host.ui.RawUI.WindowTitle = $windowTitle

    #Delare global variables.

    $global:logFile=$NULL #This is the global variable for the calculated log file name
    [string]$global:staticFolderName="\AuditData\"

    #Declare function variables.

    $auditRecipients=@()
    [array]$auditSendAs=@()
    [int]$forCounter=0
    [int]$recipientCounter=0
    [int]$totalRecipients=0

    $commandStartTime = get-date
    $commandEndTime = $NULL
    [int]$kerberosRunTime = 4

    $xmlFiles = @{
        onPremRecipientSendAs= @{"Value" = "onPremRecipientSendAs.xml" ; "Description" = "XML file that holds send as permissions from on premises"}
        onPremRecipientList= @{"Value" = "onPremRecipientListSendAs.xml" ; "Description" = "XML file that holds recipients to process for send as rights"}
        onPremRecipientProcessed= @{"Value" = "onPremRecipientProcessedSendAs.xml" ; "Description" = "XML file that holds the last processed recipient"}
    }

    $onPremExchangePowershell = @{
        exchangeServerConfiguration = @{"Value" = "Microsoft.Exchange" ; "Description" = "Defines the Exchange Remote Powershell configuration"} 
        exchangeServerAllowRedirection = @{"Value" = $TRUE ; "Description" = "Defines the Exchange Remote Powershell redirection preference"} 
        exchangeServerURI = @{"Value" = "https://"+$exchangeServer+"/powershell" ; "Description" = "Defines the Exchange Remote Powershell connection URL"} 
        exchangeServerURIKerberos = @{"Value" = "http://"+$exchangeServer+"/powershell" ; "Description" = "Defines the Exchange Remote Powershell connection URL"} 
        exchangeOnPremisesPowershellSessionName = @{ "Value" = "ExchangePowershell" ; "Description" = "Exchange On-Premises powershell session name."}
    }

    new-LogFile -groupSMTPAddress OnPremSendAsPermissions -logFolderPath $logFolderPath

    $traceFilePath = $logFolderPath + $global:staticFolderName

    out-logfile -string ("Trace file path: "+$traceFilePath)

    if (($bringMyOwnRecipients -ne $NULL )-and ($retryCollection -eq $TRUE))
    {
        out-logfile -string "You cannot bring your own mailboxes when you are retrying the collection."
        out-logfile -string "If mailboxes were previously provided - rerun command with just retry collection." -iserror:$TRUE -isAudit:$TRUE
    }

    #Output all parameters bound or unbound and their associated values.

    write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

    function session-toImport
    {
        if ($exchangeAuthenticationMethod -eq "Basic")
        {
            try 
            {
                Out-LogFile -string "Calling New-PowerShellSession"

                $sessiontoImport=new-PowershellSession -credentials $exchangecredential -powershellSessionName $onPremExchangePowershell.exchangeOnPremisesPowershellSessionName.value -connectionURI $onPremExchangePowershell.exchangeServerURI.value -authenticationType $exchangeAuthenticationMethod -configurationName $onPremExchangePowershell.exchangeServerConfiguration.value -allowredirection $onPremExchangePowershell.exchangeServerAllowRedirection.value -requiresImport:$TRUE
            }
            catch 
            {
                out-logfile -string $_
                Out-LogFile -string "ERROR:  Unable to create powershell session." -isError:$TRUE
            }
        }
        elseif ($exchangeAuthenticationMethod -eq "Kerberos")
        {
            try 
            {
                Out-LogFile -string "Calling New-PowerShellSession"

                $sessiontoImport=new-PowershellSession -credentials $exchangecredential -powershellSessionName $onPremExchangePowershell.exchangeOnPremisesPowershellSessionName.value -connectionURI $onPremExchangePowershell.exchangeServerURIKerberos.value -authenticationType $exchangeAuthenticationMethod -configurationName $onPremExchangePowershell.exchangeServerConfiguration.value -allowredirection $onPremExchangePowershell.exchangeServerAllowRedirection.value -requiresImport:$TRUE
            }
            catch 
            {
                out-logfile -string $_
                Out-LogFile -string "ERROR:  Unable to create powershell session." -isError:$TRUE
            }
        }
        else 
        {
            out-logfile -string "Major issue creating on-premises Exchange powershell session - unknown - ending." -isError:$TRUE
        }
        
        try 
        {
            out-logFile -string "Attempting to import powershell session."

            import-powershellsession -powershellsession $sessionToImport -isAudit:$TRUE
        }
        catch 
        {
            out-logFile -string "Unable to import powershell session."
            out-logfile -string $_ -isError:$TRUE -isAudit:$TRUE
        }

        try 
        {
            out-logFile -string "Attempting to set view entire forest to TRUE."

            enable-ExchangeOnPremEntireForest -isAudit:$TRUE
        }
        catch 
        {
            out-logFile -string "Unable to set view entire forest to TRUE."
            out-logfile -string $_ -isError:$TRUE -isAudit:$TRUE
        }
    }

    session-toImport

    #Define the log file path one time.

    $logFolderPath = $logFolderPath+$global:staticFolderName

    try 
    {
        if ($retryCollection -eq $FALSE)
        {
            if ($bringMyOwnRecipients -eq $NULL)
            {
                out-logFile -string "Obtaining all on premises mailboxes."

                $auditRecipients = get-recipient -resultsize unlimited | select-object identity,GUID
    
                #Exporting mailbox operations to csv - the goal here will be to allow retry.
    
                $fileName = $xmlFiles.onPremRecipientList.value
                $exportFile=Join-path $logFolderPath $fileName
                
                $auditRecipients | export-clixml -path $exportFile
            }
            else 
            {
                out-logFile -string "Using recipients provided by function caller.."

                foreach ($mailbox in $bringMyOwnRecipients)
                {
                    out-logfile -string ("Testing recipient: "+$mailbox)

                    try{
                        $auditRecipients += get-recipient -identity $mailbox -errorAction STOP | select-object identity,GUID
                    }
                    catch {
                        out-logfile -string $_
                        out-logfile -string $mailbox
                        out-logfile -string "The SMTP address specified is not a recipient - skipping."
                    }
                }
                
                #Exporting mailbox operations to csv - the goal here will be to allow retry.
    
                $fileName = $xmlFiles.onPremRecipientList.value
                $exportFile=Join-path $logFolderPath $fileName
                
                $auditRecipients | export-clixml -path $exportFile
            }
        }
        elseif ($retryCollection -eq $TRUE)
        {
            out-logfile -string "Retry operation - importing the mailboxes from previous export."

            try{
                $fileName = $xmlFiles.onPremRecipientList.value
                $importFile=Join-path $logFolderPath $fileName

                $auditRecipients = import-clixml -path $importFile
            }
            catch{
                out-logfile -string "Retry was specified - unable to import the XML file."
                out-logfile -string $_ -isError:$TRUE -isAudit:$true
            }

            out-logfile -string "Import the count of the last mailbox processed."

            try {
                $fileName = $xmlFiles.onPremRecipientProcessed.value
                $importFile=Join-path $logFolderPath $fileName

                $recipientCounter=Import-Clixml -path $importFile

                #The import represents the last mailbox processed. 
                #It's permissions were already exported - add 1 to start with the next mailbox in the list.

                $recipientCounter=$recipientCounter+1

                out-logfile -string ("Next recipient to process = "+$recipientCounter.toString())
            }
            catch {
                out-logfile -string "Unable to read the previous mailbox processed."
                out-logfile -string $_ -isError:$TRUE -isAudit:$true
            }

            out-logfile -string "Importing the previously exported permissions."

            try {

                $fileName=$xmlFiles.onPremRecipientSendAs.value
                $importFile=Join-path $logFolderPath $fileName
    
                $auditSendAs = import-clixml -Path $importFile
            }
            catch {
                out-logfile -string "Unable to import the previously exported permissions." -isError:$TRUE -isAudit:$true
            }
        }
    }
    catch 
    {
        out-logFile -string "Unable to get mailboxes."
        out-logfile -string $_ -isError:$TRUE -isAudit:$TRUE
    }

    #For each mailbox - we will iterate and grab the folders for processing.

    $ProgressDelta = 100/($auditRecipients.count); $PercentComplete = (($recipientCounter / $auditRecipients.count)*100); $recipientNumber = 0

    $totalRecipients=$auditRecipients.count

    #Here we're going to use a for loop based on count.
    #This is to support a retry operation.

    for ($recipientCounter ; $recipientCounter -lt $totalRecipients ; $recipientCounter++)
    {
        #Drop the mailbox into a working variable.

        $recipient = $auditRecipients[$recipientCounter]

        $commandEndTime = get-Date

        if (($forCounter -gt 500) -and (($commandEndTime - $commandStartTime).totalHours -lt $kerberosRunTime))
        {
            start-sleepProgress -sleepstring "Powershell pause at 500 operations - total operation time less than ." -sleepSeconds 5 -sleepParentID 1 -sleepID 2
            $forCounter=0
            out-logfile -string (($commandEndTime - $commandStartTime).totalhours).tostring()
        }
        elseif ($forCounter -gt 500)
        {
            start-sleepProgress -sleepString "Throttling for 5 seconds at 500 operations." -sleepSeconds 5

            $forCounter=0

            $commandStartTime = get-Date

            if ($exchangeAuthenticationMethod -eq "Kerberos")
            {
                out-logfile -string "Kerberos authentication utilized - reset powershell session."

                disable-allPowerShellSessions
                
                session-toImport
            }
        }
        else 
        {
            $forCounter++    
        }

        out-logfile -string ("Processing recipient = "+$recipient.primarySMTPAddress)
        out-logfile -string ("Processing recipient number: "+$recipientCounter.toString()+" of "+$totalRecipients.tostring())
 
        $recipientNumber++

        $progressString = "Recipient Name: "+$recipient.primarySMTPAddress+"_"+$recipient.GUID+" Recipient Number: "+$recipientCounter+" of "+$totalRecipients

        Write-Progress -Activity "Processing recipient" -Status $progressString -PercentComplete $PercentComplete -Id 1

        $PercentComplete += $ProgressDelta

        try {
            $auditSendAs+=get-adPermission -identity $recipient.guid | where {($_.ExtendedRights -like "*send-as*") -and -not ($_.User -like "nt authority\self") -and ($_.isInherited -eq $false)} -errorAction STOP
        }
        catch {
            out-logfile -string "Error obtaining folder statistics."
            out-logfile -string $_ -isError:$TRUE -isAudit:$TRUE
        }

        $fileName = $xmlFiles.onPremRecipientSendAs.value
        $exportFile=Join-path $logFolderPath $fileName

        $auditSendAs | Export-Clixml -Path $exportFile
        
        $fileName = $xmlFiles.onPremRecipientProcessed.value
        $exportFile=Join-path $logFolderPath $fileName

        $recipientCounter | export-clixml -path $exportFile
    }

    write-shamelessPlug
    
    disable-allPowerShellSessions
}