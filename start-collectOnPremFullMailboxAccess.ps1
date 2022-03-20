function start-collectOnPremFullMailboxAccess
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
        $bringMyOwnMailboxes=$NULL
    )

    $windowTitle = "Start-collectOnPremFullMailboxAccess"
    $host.ui.RawUI.WindowTitle = $windowTitle

    #Delare global variables.

    $global:logFile=$NULL #This is the global variable for the calculated log file name
    [string]$global:staticFolderName="\AuditData\"

    #Declare function variables.

    $auditMailboxes=$NULL
    [array]$auditFullMailboxAccess=@()
    [int]$forCounter=0
    [int]$mailboxCounter=0
    [int]$totalMailboxes=0
    [string]$onPremRecipientFullMailboxAccess="onPremRecipientFullMailboxAccess.xml"
    [string]$onPremMailboxList="onPremMailboxList.xml"
    [string]$onPremRecipientProcessed="onPremRecipientProcessed.xml"

    #Static variables utilized for the Exchange On-Premsies Powershell.
   
    [string]$exchangeServerConfiguration = "Microsoft.Exchange" #Powershell configuration.
    [boolean]$exchangeServerAllowRedirection = $TRUE #Allow redirection of URI call.
    [string]$exchangeServerURI = "https://"+$exchangeServer+"/powershell" #Full URL to the on premises powershell instance based off name specified parameter.
    [string]$exchangeOnPremisesPowershellSessionName="ExchangeOnPremises" #Defines universal name for on premises Exchange Powershell session.

    new-LogFile -groupSMTPAddress OnPremFullMailboxAccessPermissions -logFolderPath $logFolderPath

    if (($bringMyOwnMailboxes -ne $NULL )-and ($retryCollection -eq $TRUE))
    {
        out-logfile -string "You cannot bring your own mailboxes when you are retrying the collection."
        out-logfile -string "If mailboxes were previously provided - rerun command with just retry collection." -iserror:$TRUE -isAudit:$TRUE
    }

    try 
    {
        out-logFile -string "Creating session to import."

        $sessiontoImport=new-PowershellSession -credentials $exchangecredential -powershellSessionName $exchangeOnPremisesPowershellSessionName -connectionURI $exchangeServerURI -authenticationType $exchangeAuthenticationMethod -configurationName $exchangeServerConfiguration -allowredirection $exchangeServerAllowRedirection -requiresImport:$TRUE -isAudit:$TRUE
    }
    catch 
    {
        out-logFile -string "Unable to create session to import."
        out-logfile -string $_ -isError:$TRUE -isAudit:$TRUE
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
    
                $fileName = $onPremMailboxList
                $exportFile=Join-path $logFolderPath $fileName
                
                $auditMailboxes | export-clixml -path $exportFile
            }
            else 
            {
                $auditMailboxes = $bringMyOwnMailboxes
    
                #Exporting mailbox operations to csv - the goal here will be to allow retry.
    
                $fileName = $onPremMailboxList
                $exportFile=Join-path $logFolderPath $fileName
                
                $auditMailboxes | export-clixml -path $exportFile
            }

        }
        elseif ($retryCollection -eq $TRUE)
        {
            out-logfile -string "Retry operation - importing the mailboxes from previous export."

            try{
                $fileName = $onPremMailboxList
                $importFile=Join-path $logFolderPath $fileName

                $auditMailboxes = import-clixml -path $importFile
            }
            catch{
                out-logfile -string "Retry was specified - unable to import the XML file."
                out-logfile -string $_ -isError:$TRUE -isAudit:$true
            }

            out-logfile -string "Import the count of the last mailbox processed."

            try {
                $fileName = $onPremRecipientProcessed
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

                $fileName=$onPremRecipientFullMailboxAccess
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

        if ($forCounter -gt 500)
        {
            start-sleepProgress -sleepstring "Powershell pause at 500 operations." -sleepSeconds 5 -sleepParentID 1 -sleepID 2
            $forCounter=0
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

        $fileName = $onPremRecipientFullMailboxAccess
        $exportFile=Join-path $logFolderPath $fileName

        $auditFullMailboxAccess | Export-Clixml -Path $exportFile
        
        $fileName = $onPremRecipientProcessed
        $exportFile=Join-path $logFolderPath $fileName

        $mailboxCounter | export-clixml -path $exportFile
    }

    disable-allPowerShellSessions
}