function start-collectOnPremFullMailboxAccess
{
    <#
    .SYNOPSIS

    This function exports all of the mailbox folders from the on premises environment with custome permissions.

    .DESCRIPTION

    Trigger function..

        .PARAMETER EXCHANGESERVER

    *OPTIONAL*
    *REQUIRED with enableHybridMailFlow:TRUE*
    This parameter specifies that local Exchange on premises installation utilized for hybrid mail flow enablement.
    Exchange server is no required for migrations unlss enable hyrbid mail flow is required.

    .PARAMETER EXCHANGECREDENTIAL

    *OPTIONAL*
    *REQUIRED with ExchangeServer specified*
    This is the credential utilized to connect to the Exchange server remote powershell instance.
    Exchange Organization Adminitrator rights are recommended.

    .PARAMETER EXCHANGEAUTHENTICATIONMETHOD

    *OPTIONAL*
    *DEFAULT:  BASIC*
    This specifies the authentication method for the Exchage on-premsies remote powershell session.

    .PARAMETER LOGFOLDERPATH

    *REQUIRED*
    This is the logging directory for storing the migration log and all backup XML files.
    If running multiple SINGLE instance migrations use different logging directories..

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
        $bringMyOwnMailboxes=$NULL
    )

    $windowTitle = "Start-collectOnPremFullMailboxAccess"
    $host.ui.RawUI.WindowTitle = $windowTitle

    #Delare global variables.

    $global:logFile=$NULL #This is the global variable for the calculated log file name
    [string]$global:staticFolderName="\AuditData\"

    #Declare function variables.

    $auditMailboxes=@()
    [array]$auditFullMailboxAccess=@()
    [int]$forCounter=0
    [int]$powershellCounter = 0
    [int]$mailboxCounter=0
    [int]$totalMailboxes=0

    $commandStartTime = get-date
    $commandEndTime = $NULL
    [int]$kerberosRunTime = 4

    $xmlFiles = @{
        onPremRecipientFullMailboxAccess= @{"Value" = "onPremRecipientFullMailboxAccess.xml" ; "Desscription" = "XML file of discovered permissions"}
        onPremMailboxList= @{"Value" = "onPremMailboxListFullMailboxAccess.xml" ; "Description" = "XML file of all mailboxes to be processed"}
        onPremRecipientProcessed= @{"Value" = "onPremRecipientProcessedFullMailboxAccess.xml" ; "Description" = "XML file of the last mailbox processed"}
    }

    #Static variables utilized for the Exchange On-Premsies Powershell.

    $onPremExchangePowershell = @{
        exchangeServerConfiguration = @{"Value" = "Microsoft.Exchange" ; "Description" = "Defines the Exchange Remote Powershell configuration"} 
        exchangeServerAllowRedirection = @{"Value" = $TRUE ; "Description" = "Defines the Exchange Remote Powershell redirection preference"} 
        exchangeServerURI = @{"Value" = "https://"+$exchangeServer+"/powershell" ; "Description" = "Defines the Exchange Remote Powershell connection URL"} 
        exchangeServerURIKerberos = @{"Value" = "http://"+$exchangeServer+"/powershell" ; "Description" = "Defines the Exchange Remote Powershell connection URL"} 
        exchangeOnPremisesPowershellSessionName = @{ "Value" = "ExchangePowershell" ; "Description" = "Exchange On-Premises powershell session name."}
    }

    new-LogFile -groupSMTPAddress OnPremFullMailboxAccessPermissions -logFolderPath $logFolderPath

    out-logfile -string "Output bound parameters..."

   #Output all parameters bound or unbound and their associated values.

   write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

   write-hashTable -hashTable $onPremExchangePowershell
   write-hashTable -hashTable $xmlFiles

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
            out-logfile -string "Major issue creating on-premsies Exchange powershell session - unknown - ending." -isError:$TRUE
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

    if (($bringMyOwnMailboxes -ne $NULL )-and ($retryCollection -eq $TRUE))
    {
        out-logfile -string "You cannot bring your own mailboxes when you are retrying the collection."
        out-logfile -string "If mailboxes were previously provided - rerun command with just retry collection." -iserror:$TRUE -isAudit:$TRUE
    }

    
    #Call powershell sesssion.

    session-toImport

    #Define the log file path one time.

    $logFolderPath = $logFolderPath+$global:staticFolderName

    try 
    {
        out-logfile -string "Determining mailboxes to process."

        if ($retryCollection -eq $FALSE)
        {
            if ($bringMyOwnMailboxes -eq $NULL)
            {
                out-logFile -string "Obtaining all on premises mailboxes."

                try {
                    $auditMailboxes = get-mailbox -resultsize unlimited -errorAction STOP | select-object Identity,primarySMTPAddress
                }
                catch {
                    out-logfile -string "Unable to capture on premises mailboxes."
                    out-logfile $_ -isError:$TRUE -isAudit:$TRUE
                }

                #Exporting mailbox operations to csv - the goal here will be to allow retry.
    
                $fileName = $xmlFiles.onPremMailboxList.value
                $exportFile=Join-path $logFolderPath $fileName
                
                $auditMailboxes | export-clixml -path $exportFile
            }
            else 
            {
                foreach ($mailbox in $bringMyOwnMailboxes)
                {
                    try {
                        $auditMailboxes += get-mailbox -identity $mailbox -errorAction STOP | select-object identity,primarySMTPAddress
                    }
                    catch {
                        out-logfile -string $_
                        out-logfile -string "Unable to locate a specified mailbox in bring your own mailboxes." -isError:$TRUE
                    }
                }
                
    
                #Exporting mailbox operations to csv - the goal here will be to allow retry.
    
                $fileName = $xmlFiles.onPremMailboxList.value
                $exportFile=Join-path $logFolderPath $fileName
                
                $auditMailboxes | export-clixml -path $exportFile
            }

        }
        elseif ($retryCollection -eq $TRUE)
        {
            out-logfile -string "Retry operation - importing the mailboxes from previous export."

            try{
                $fileName = $xmlFiles.onPremMailboxList.value
                $importFile=Join-path $logFolderPath $fileName

                $auditMailboxes = import-clixml -path $importFile
            }
            catch{
                out-logfile -string "Retry was specified - unable to import the XML file."
                out-logfile -string $_ -isError:$TRUE -isAudit:$true
            }

            out-logfile -string "Import the count of the last mailbox processed."

            try {
                $fileName = $xmlFiles.onPremRecipientProcessed.value
                $importFile=Join-path $logFolderPath $fileName

                $mailboxCounter=Import-Clixml -path $importFile

                #The import represents the last mailbox processed. 
                #It's permissions were already exported - add 1 to start with the next mailbox in the list.

                $mailboxCounter=$mailboxCounter+1

                out-logfile -string ("Next recipient to process = "+$mailboxCounter.toString())
            }
            catch {
                out-logfile -string "Unable to read the previous mailbox processed."
                out-logfile -string $_ -isError:$TRUE -isAudit:$true
            }

            out-logfile -string "Importing the previously exported permissions."

            try {

                $fileName=$xmlFiles.onPremRecipientFullMailboxAccess.value
                $importFile=Join-path $logFolderPath $fileName
    
                $auditFullMailboxAccess = import-clixml -Path $importFile
            }
            catch {
                out-logfile -string "Unable to import the previously exported permissions." -isError:$TRUE -isAudit:$true
            }
        }
    }
    catch 
    {
        out-logFile -string "Unable to get mailboxes."
        out-logfile -string $_ -isError:$TRUE
    }

    #For each mailbox - we will iterate and grab the folders for processing.

    $ProgressDelta = 100/($auditMailboxes.count); $PercentComplete = (($mailboxCounter / $auditMailboxes.count)*100); $mailboxNumber = 0

    $totalMailboxes=$auditMailboxes.count

    #Here we're going to use a for loop based on count.
    #This is to support a retry operation.

    for ($mailboxCounter ; $mailboxCounter -lt $totalMailboxes ; $mailboxCounter++)
    {
        #Drop the mailbox into a working variable.

        $mailbox = $auditMailboxes[$mailboxCounter]
        $commandEndTime = get-Date

        if (($forCounter -gt 500) -and (($commandEndTime - $commandStartTime).totalHours -lt $kerberosRunTime))
        {
            start-sleepProgress -sleepstring "Powershell pause at 500 operations - total operation time less than ." -sleepSeconds 5 -sleepParentID 1 -sleepID 2
            $forCounter=0
            out-logfile -string (($commandEndTime - $commandStartTime).totalhours).tostring()
        }
        elseif ($forCounter -gt 500) 
        {
            start-sleepProgress -sleepstring "Powershell pause at 500 operations - evaluate powershell session reset." -sleepSeconds 5 -sleepParentID 1 -sleepID 2
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

        out-logfile -string ("Processing recipient = "+$mailbox.primarySMTPAddress)
        out-logfile -string ("Processing recipient number: "+$mailboxCounter.toString()+" of "+$totalMailboxes.tostring())
 
        $mailboxNumber++

        $progressString = "Recipient Name: "+$mailbox.primarySMTPAddress+" Recipient Number: "+$mailboxCounter+" of "+$totalMailboxes

        Write-Progress -Activity "Processing recipient" -Status $progressString -PercentComplete $PercentComplete -Id 1

        $PercentComplete += $ProgressDelta

        try {
            $auditFullMailboxAccess+=get-mailboxPermission -identity $mailbox.identity | where {($_.isInherited -ne $TRUE) -and ($_.user -notlike "NT Authority\Self")}
        }
        catch {
            out-logfile -string "Error obtaining folder statistics."
            out-logfile -string $_ -isError:$TRUE -isAudit:$TRUE
        }

        $fileName = $xmlFiles.onPremRecipientFullMailboxAccess.value
        $exportFile=Join-path $logFolderPath $fileName

        $auditFullMailboxAccess | Export-Clixml -Path $exportFile
        
        $fileName = $xmlFiles.onPremRecipientProcessed.value
        $exportFile=Join-path $logFolderPath $fileName

        $mailboxCounter | export-clixml -path $exportFile
    }

    write-shamelessPlug

    disable-allPowerShellSessions
}