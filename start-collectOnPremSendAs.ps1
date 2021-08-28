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

    #Delare global variables.

    $global:logFile=$NULL #This is the global variable for the calculated log file name
    [string]$global:staticFolderName="\AuditData\"

    #Declare function variables.

    $auditRecipients=$NULL
    [array]$auditSendAs=@()
    [int]$forCounter=0
    [int]$recipientCounter=0
    [int]$totalRecipients=0
    [string]$onPremRecipientSendAs="onPremRecipientSendAs.xml"
    [string]$onPremRecipientList="onPremRecipientList.xml"
    [string]$onPremRecipientProcessed="onPremRecipientProcessed.xml"

    #Static variables utilized for the Exchange On-Premsies Powershell.
   
    [string]$exchangeServerConfiguration = "Microsoft.Exchange" #Powershell configuration.
    [boolean]$exchangeServerAllowRedirection = $TRUE #Allow redirection of URI call.
    [string]$exchangeServerURI = "https://"+$exchangeServer+"/powershell" #Full URL to the on premises powershell instance based off name specified parameter.
    [string]$exchangeOnPremisesPowershellSessionName="ExchangeOnPremises" #Defines universal name for on premises Exchange Powershell session.

    if (($bringMyOwnRecipients -ne $NULL )-and ($retryCollection -eq $TRUE))
    {
        out-logfile -string "You cannot bring your own mailboxes when you are retrying the collection."
        out-logfile -string "If mailboxes were previously provided - rerun command with just retry collection." -iserror:$TRUE -isAudit:$TRUE
    }

    new-LogFile -groupSMTPAddress OnPremSendAsPermissions -logFolderPath $logFolderPath

    try 
    {
        out-logFile -string "Creating session to import."

        $sessionToImport=new-PowershellSession -credentials $exchangecredential -powershellSessionName $exchangeOnPremisesPowershellSessionName -connectionURI $exchangeServerURI -authenticationType $exchangeAuthenticationMethod -configurationName $exchangeServerConfiguration -allowredirection $exchangeServerAllowRedirection -requiresImport:$TRUE -isAudit:$TRUE
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
        if ($retryCollection -eq $FALSE)
        {
            if ($bringMyOwnRecipients -eq $NULL)
            {
                out-logFile -string "Obtaining all on premises mailboxes."

                $auditRecipients = get-recipient -resultsize unlimited | select-object identity,primarySMTPAddress
    
                #Exporting mailbox operations to csv - the goal here will be to allow retry.
    
                $fileName = $onPremRecipientList
                $exportFile=Join-path $logFolderPath $fileName
                
                $auditRecipients | export-clixml -path $exportFile
            }
            else 
            {
                out-logFile -string "Using recipients provided by function caller.."

                $auditRecipients = $bringMyOwnRecipients
    
                #Exporting mailbox operations to csv - the goal here will be to allow retry.
    
                $fileName = $onPremRecipientList
                $exportFile=Join-path $logFolderPath $fileName
                
                $auditRecipients | export-clixml -path $exportFile
            }
        }
        elseif ($retryCollection -eq $TRUE)
        {
            out-logfile -string "Retry operation - importing the mailboxes from previous export."

            try{
                $fileName = $onPremRecipientList
                $importFile=Join-path $logFolderPath $fileName

                $auditRecipients = import-clixml -path $importFile
            }
            catch{
                out-logfile -string "Retry was specified - unable to import the XML file."
                out-logfile -string $_ -isError:$TRUE -isAudit:$true
            }

            out-logfile -string "Import the count of the last mailbox processed."

            try {
                $fileName = $onPremRecipientProcessed
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

                $fileName=$onPremRecipientSendAs
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

    $ProgressDelta = 100/($auditRecipients.count); $PercentComplete = 0; $recipientNumber = 0

    $totalRecipients=$auditRecipients.count

    #Here we're going to use a for loop based on count.
    #This is to support a retry operation.

    for ($recipientCounter ; $recipientCounter -lt $totalRecipients ; $recipientCounter++)
    {
        #Drop the mailbox into a working variable.

        $recipient = $auditRecipients[$recipientCounter]

        if ($forCounter -gt 250)
        {
            start-sleepProgress -sleepString "Throttling for 5 seconds at 250 operations." -sleepSeconds 5

            $forCounter=0
        }
        else 
        {
            $forCounter++    
        }

        out-logfile -string ("Processing recipient = "+$recipient.primarySMTPAddress)
        out-logfile -string ("Processing recipient number: "+$recipientCounter.toString()+" of "+$totalRecipients.tostring())
 
        $recipientNumber++

        $progressString = "Recipient Name: "+$recipient.primarySMTPAddress+" Recipient Number: "+$recipientCounter+" of "+$totalRecipients

        Write-Progress -Activity "Processing recipient" -Status $progressString -PercentComplete $PercentComplete -Id 1

        $PercentComplete += $ProgressDelta

        try {
            $auditSendAs+=get-adPermission -identity $recipient.identity | Where-Object {($_.ExtendedRights -like "*send-as*") -and -not ($_.User -like "nt authority\self") -and ($_.isInherited -eq $false)} -errorAction STOP
        }
        catch {
            out-logfile -string "Error obtaining folder statistics."
            out-logfile -string $_ -isError:$TRUE -isAudit:$TRUE
        }

        $fileName = $onPremRecipientSendAs
        $exportFile=Join-path $logFolderPath $fileName

        $auditSendAs | Export-Clixml -Path $exportFile
        
        $fileName = $onPremRecipientProcessed
        $exportFile=Join-path $logFolderPath $fileName

        $recipientCounter | export-clixml -path $exportFile
    }
}