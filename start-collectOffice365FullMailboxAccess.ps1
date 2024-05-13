function start-collectOffice365FullMailboxAccess
{
    <#
    .SYNOPSIS

    This function exports all of the mailbox folders from the on premises environment with custome permissions.

    .DESCRIPTION

    Trigger function.

    .PARAMETER logFolder

    *REQUIRED*
    The location where logging for the migration should occur including all XML outputs for backups.

   .PARAMETER EXCHANGEONLINECREDENTIAL

    *REQUIRED if ExchangeOnlineCertificateThumbprint not specified*
    *NOT ALLOWED if ExchangeCertificateThubprint is specified*
    The credential utilized to connect to Exchange Online.
    This account cannot have interactive logon requirements such as multi-factored authentication.
    Exchange Organization Administrator rights recommened.

    .PARAMETER EXCHANGEONLINECERTIFICATETHUMBPRINT

    *REQUIRED if ExchangeOnlineCredential is not specified*
    *NOT ALLOWED if ExchangeCredential is specified*
    This is the thumbprint of the certificate utilized to authenticate to the Azure application created for Exchange Certificate Authentication

    .PARAMETER EXCHANGEONLINEORGANIZATIONNAME

    *REQUIRED only with ExchangeCertificateThumbpint*
    This specifies the Exchange Online oragnization name in domain.onmicroosft.com format.

    .PARAMETER EXCHANGEONLINEENVIRONMENTNAME

    *OPTIONAL*
    *DEFAULT:  O365DEFAULT
    This specifies the Exchange Online environment to connect to if a non-commercial forest is utilized.

    .PARAMETER EXCHANGEONLINEAPPID

    *REQUIRED with ExchangeCertificateThumbprint*
    This specifies the application ID of the Azure application for Exchange certificate authentication.

    .OUTPUTS

    Logs all activities and backs up all original data to the log folder directory.
    Moves the distribution group from on premieses source of authority to office 365 source of authority.

    .EXAMPLE

    Start-collectoffice365FolderPermissions -exchangeServer Server -exchangeCredential $credential

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
        [pscredential]$exchangeOnlineCredential=$NULL,
        [Parameter(Mandatory = $false)]
        [string]$exchangeOnlineCertificateThumbPrint="",
        [Parameter(Mandatory = $false)]
        [string]$exchangeOnlineOrganizationName="",
        [Parameter(Mandatory = $false)]
        [ValidateSet("O365Default","O365GermanyCloud","O365China","O365USGovGCCHigh","O365USGovDoD")]
        [string]$exchangeOnlineEnvironmentName="O365Default",
        [Parameter(Mandatory = $false)]
        [string]$exchangeOnlineAppID="",
        [Parameter(Mandatory = $false)]
        [boolean]$retryCollection=$FALSE,
        [Parameter(Mandatory = $false)]
        $bringMyOwnMailboxes=@()
    )

    $global:blogURL = "https://timmcmic.wordpress.com"

    $windowTitle = "Start-collectOffice365FullMailboxAccess"
    $host.ui.RawUI.WindowTitle = $windowTitle

    #Delare global variables.

    $global:logFile=$NULL #This is the global variable for the calculated log file name
    [string]$global:staticFolderName="\AuditData\"
    [array]$auditMailboxes=@()

    #Declare function variables.

    #Declare function variables.

    $auditMailboxes=$NULL
    [array]$auditFullMailboxAccess=@()
    [int]$forCounter=0
    [int]$mailboxCounter=0
    [int]$totalMailboxes=0
    [string]$office365RecipientFullMailboxAccess="office365RecipientFullMailboxAccess.xml"
    [string]$office365MailboxList="office365MailboxListFullMailboxAccess.xml"
    [string]$office365RecipientProcessed="office365RecipientProcessedFullMailboxAccess.xml"

    new-LogFile -groupSMTPAddress Office365FullMailboxAccessPermissions -logFolderPath $logFolderPath

    out-logfile -string "Output bound parameters..."

   #Output all parameters bound or unbound and their associated values.

   write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

    #Validate that only one method of engaging exchange online was specified.

    Out-LogFile -string "Validating Exchange Online Credentials."

    start-parameterValidation -exchangeOnlineCredential $exchangeOnlineCredential -exchangeOnlineCertificateThumbprint $exchangeOnlineCertificateThumbprint -threadCount 0

    #Validating that all portions for exchange certificate auth are present.

    out-logfile -string "Validating parameters for Exchange Online Certificate Authentication"

    start-parametervalidation -exchangeOnlineCertificateThumbPrint $exchangeOnlineCertificateThumbprint -exchangeOnlineOrganizationName $exchangeOnlineOrganizationName -exchangeOnlineAppID $exchangeOnlineAppID

    if (($bringMyOwnMailboxes.count -gt 0 )-and ($retryCollection -eq $TRUE))
    {
        out-logfile -string "You cannot bring your own mailboxes when you are retrying the collection."
        out-logfile -string "If mailboxes were previously provided - rerun command with just retry collection." -iserror:$TRUE -isAudit:$TRUE
    }

    #Start the connection to Exchange Online.

    if ($exchangeOnlineCredential -ne $NULL)
    {
       #User specified non-certifate authentication credentials.

       try {
        New-ExchangeOnlinePowershellSession -exchangeOnlineCredentials $exchangeOnlineCredential -exchangeOnlineEnvironmentName $exchangeOnlineEnvironmentName -isAudit:$TRUE -debugLogPath $logFolderPath
       }
       catch {
           out-logfile -string "Unable to create the exchange online connection using credentials."
           out-logfile -string $_ -isError:$TRUE -isAudit:$TRUE
       }
       

    }
    elseif ($exchangeOnlineCertificateThumbPrint -ne "")
    {
       #User specified thumbprint authentication.

       try {
        new-ExchangeOnlinePowershellSession -exchangeOnlineCertificateThumbPrint $exchangeOnlineCertificateThumbPrint -exchangeOnlineAppId $exchangeOnlineAppID -exchangeOnlineOrganizationName $exchangeOnlineOrganizationName -exchangeOnlineEnvironmentName $exchangeOnlineEnvironmentName -isAudit:$true -debugLogPath $logFolderPath
       }
       catch {
        out-logfile -string "Unable to create the exchange online connection using certificate."
        out-logfile -string $_ -isError:$TRUE
       }

    }

    #Define the log file path one time.

    $logFolderPath = $logFolderPath+$global:staticFolderName

    try 
    {
        if ($retryCollection -eq $FALSE)
        {
            out-logfile -string "Mailboxes are not retried - evaluating all or bring your own."

            if ($bringMyOwnMailboxes.count -eq 0)
            {
                out-logFile -string "Obtaining all Office 365 mailboxes."
                out-logfile -string "Admin did not specify a mailbox subset."

                #$auditMailboxes = get-exomailbox -resultsize unlimited | select-object identity,userPrincipalName,primarySMTPAddress
                $auditMailboxes = get-o365mailbox -resultsize unlimited | select-object identity,userPrincipalName,primarySMTPAddress

                #Exporting mailbox operations to csv - the goal here will be to allow retry.

                $fileName = $office365MailboxList
                $exportFile=Join-path $logFolderPath $fileName
            
                $auditMailboxes | export-clixml -path $exportFile
            }
            else 
            {
                out-logfile -string "Bring your own mailboxes was specified - evaluating only mailboxes specified."

                foreach ($auditMailbox in $bringMyOwnMailboxes)
                {
                    out-logfile -string ("Processing mailbox: "+$auditMailbox)
                    #$auditMailboxes += get-exomailbox -identity $auditMailbox | select-object identity,userPrincipalName,primarySMTPAddress
                    $auditMailboxes += get-o365mailbox -identity $auditMailbox | select-object identity,userPrincipalName,primarySMTPAddress
                }
                #Exporting mailbox operations to csv - the goal here will be to allow retry.

                $fileName = $office365MailboxList
                $exportFile=Join-path $logFolderPath $fileName
            
                $auditMailboxes | export-clixml -path $exportFile
            }
        }
        elseif ($retryCollection -eq $TRUE)
        {
            out-logfile -string "Retry operation - importing the mailboxes from previous export."

            try{
                $fileName = $office365MailboxList
                $importFile=Join-path $logFolderPath $fileName

                $auditMailboxes = import-clixml -path $importFile
            }
            catch{
                out-logfile -string "Retry was specified - unable to import the XML file."
                out-logfile -string $_ -isError:$TRUE -isAudit:$true
            }

            out-logfile -string "Import the count of the last mailbox processed."

            try {
                $fileName = $office365RecipientProcessed
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

                $fileName=$office365RecipientFullMailboxAccess
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
        out-logfile -string $_ -isError:$TRUE -isAudit:$TRUE
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

        if ($forCounter -gt 1000)
        {
            start-sleepProgress -sleepString "Throttling for 5 seconds at 1000 operations." -sleepSeconds 5

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
            if ($forCounter -gt 1000)
            {
                start-sleepProgress -sleepString "Throttling for 5 seconds at 1000 operations." -sleepSeconds 5

                $forCounter=0
            }
            else 
            {
                $forCounter++    
            }

            #$auditFullMailboxAccess+=get-exomailboxPermission -identity $mailbox.identity -userPrincipalName $mailbox.userPrincipalName | where {$_.user -notlike "NT Authority\Self"}
            $auditFullMailboxAccess+=get-o365mailboxPermission -identity $mailbox.identity | where {$_.user -notlike "NT Authority\Self"}
        }
        catch {
            out-logfile -string "Error obtaining folder statistics."
            out-logfile -string $_ -isError:$TRUE -isAudit:$TRUE
        }

        $fileName = $office365RecipientFullMailboxAccess
        $exportFile=Join-path $logFolderPath $fileName

        $auditFullMailboxAccess | Export-Clixml -Path $exportFile
        
        $fileName = $office365RecipientProcessed
        $exportFile=Join-path $logFolderPath $fileName

        $mailboxCounter | export-clixml -path $exportFile
    }

    write-shamelessPlug

    disable-allPowerShellSessions
}