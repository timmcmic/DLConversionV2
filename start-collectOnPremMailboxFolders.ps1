function start-collectOnPremMailboxFolders
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

    #Delare global variables.

    $global:logFile=$NULL #This is the global variable for the calculated log file name
    [string]$global:staticFolderName="\AuditData\"

    #Declare function variables.

    $auditMailboxes=$NULL
    $auditFolders=$NULL
    [array]$auditFolderNames=@()
    [array]$auditFolderPermissions=@()
    [int]$forCounter=0
    [int]$mailboxCounter=0
    [int]$totalMailboxes=0
    [string]$onPremMailboxFolderPermissions="onPremailboxFolderPermissions.xml"
    [string]$onPremMailboxList="onPremMailboxList.xml"
    [string]$onPremMailboxProcessed="onPremMailboxProcessed.xml"
    [int]$auditPermissionsFound=0

    #Static variables utilized for the Exchange On-Premsies Powershell.
   
    [string]$exchangeServerConfiguration = "Microsoft.Exchange" #Powershell configuration.
    [boolean]$exchangeServerAllowRedirection = $TRUE #Allow redirection of URI call.
    [string]$exchangeServerURI = "https://"+$exchangeServer+"/powershell" #Full URL to the on premises powershell instance based off name specified parameter.
    [string]$exchangeOnPremisesPowershellSessionName="ExchangeOnPremises" #Defines universal name for on premises Exchange Powershell session.

    new-LogFile -groupSMTPAddress OnPremMailboxFolderPermissions -logFolderPath $logFolderPath

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
        if ($retryCollection -eq $FALSE)
        {
            if ($bringMyOwnMailboxes -eq $NULL)
            {
                out-logFile -string "Obtaining all on premises mailboxes."

                $auditMailboxes = get-mailbox -resultsize unlimited | select-object identity,primarySMTPAddress

                #Exporting mailbox operations to csv - the goal here will be to allow retry.

                $fileName = $onPremMailboxList
                $exportFile=Join-path $logFolderPath $fileName
                
                $auditMailboxes | export-clixml -path $exportFile
            }
            else 
            {
                out-logFile -string "Obtaining all on premises mailboxes."

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
                $fileName = $onPremMailboxProcessed
                $importFile=Join-path $logFolderPath $fileName

                $mailboxCounter=Import-Clixml -path $importFile

                #The import represents the last mailbox processed. 
                #It's permissions were already exported - add 1 to start with the next mailbox in the list.

                $mailboxCounter=$mailboxCounter+1

                out-logfile -string ("Next mailbox to process = "+$mailboxCounter.toString())
            }
            catch {
                out-logfile -string "Unable to read the previous mailbox processed."
                out-logfile -string $_ -isError:$TRUE -isAudit:$true
            }

            out-logfile -string "Importing the previously exported permissions."

            try {

                $fileName=$onPremMailboxFolderPermissions
                $importFile=Join-path $logFolderPath $fileName
    
                $auditFolderPermissions = import-clixml -Path $importFile
            }
            catch {
                out-logfile -string "Unable to import the previously exported permissions." -isError:$TRUE -isAudit:$TRUE
            }
        }
    }
    catch 
    {
        out-logFile -string "Unable to get mailboxes."
        out-logfile -string $_ -isError:$TRUE -isAudit:$TRUE
    }

    #For each mailbox - we will iterate and grab the folders for processing.

    out-logfile -string "Gathering mailbox folders for assessment."

    $ProgressDelta = 100/($auditMailboxes.count); $PercentComplete = (($mailboxCounter / $auditMailboxes.count)*100); $MbxNumber = 0

    $totalMailboxes=$auditMailboxes.count

    #Here we're going to use a for loop based on count.
    #This is to support a retry operation.

    for ($mailboxCounter ; $mailboxCounter -lt $totalMailboxes ; $mailboxCounter++)
    {
        #Drop the mailbox into a working variable.

        $mailbox = $auditMailboxes[$mailboxCounter]

        if ($forCounter -gt 1000)
        {
            start-sleepProgress -sleepString "Sleeping for 5 seconds - powershell refresh." -sleepSeconds 5
            $forCounter=0
        }
        else 
        {
            $forCounter++    
        }

        out-logfile -string ("Processing mailbox = "+$mailbox.primarySMTPAddress)
        out-logfile -string ("Processing mailbox number: "+$mailboxCounter.toString())

        $MbxNumber++

        $progressString = "Mailbox Name: "+$mailbox.primarySMTPAddress+" Mailbox Number: "+$mailboxCounter

        Write-Progress -Activity "Processing mailbox" -Status $progressString -PercentComplete $PercentComplete -Id 1

        $PercentComplete += $ProgressDelta

        try {
            $auditFolders=get-mailboxFolderStatistics -identity $mailbox.identity | where {$_.FolderType -eq "User Created" -or $_.FolderType -eq "Inbox" -or $_.FolderType -eq "SentItems" -or $_.FolderType -eq "Contacts" -or $_.FolderType -eq "Calendar"}
        }
        catch {
            out-logfile -string "Error obtaining folder statistics."
            out-logfile -string $_ -isError:$TRUE -isAudit:$TRUE
        }

        #Audit folders have been obtained.
        #For each folder - normalize the folder names.

        $ProgressDeltaFolders = 100/($auditFolders.count); $PercentCompleteFolders = 0; $FolderNumber = 0

        foreach ($folder in $auditFolders)
        {
            out-logFile -string ("Processing folder name ="+$folder.Identity)
            out-logfile -string ("Processing folder = "+$folder.FolderId)
            out-logfile -string ("Processing cotent mailbox guid = "+$folder.ContentMailboxGuid)
    
            $folderNumber++
    
            Write-Progress -Activity "Processing folder" -Status $folder.identity -PercentComplete $PercentCompleteFolders -id 2 -ParentId 1
    
            $PercentCompleteFolders += $ProgressDeltaFolders
    
            $tempFolderName=$folder.ContentMailboxGuid.tostring()+":"+$folder.FolderId.tostring()

            #start-sleep -Seconds 5 #Debug sleep to watch status bar.
    
            out-logfile -string ("Temp folder name = "+$tempFolderName)
    
            $auditFolderNames+=$tempFolderName
        }

        write-progress -activity "Processing Folders" -ParentId 1 -Id 2 -Completed

        #At this time the folder names have been normalized to mailbox ID and folder ID - this allows us to store them in an object later.

        out-logfile -string "Obtaining any custom folder permissions that are not default or anonymous."

        $ProgressDeltaAuditNames = 100/($auditFolderNames.count); $PercentCompleteAuditNames = 0; $FolderNameCount = 0

        foreach ($folderName in $auditFolderNames)
        {
            if ($forCounter -gt 1000)
            {
                out-logfile -string "Sleeping for 5 seconds - powershell refresh."
                start-sleep -seconds 5
                $forCounter=0
            }
            else 
            {
                $forCounter++    
            }

            out-logfile -string ("Obtaining permissions on the following folder = "+$folderName)

            $FolderNameCount++

            Write-Progress -Activity "Processing folder" -Status $folderName -PercentComplete $PercentCompleteAuditNames -parentid 1 -Id 2

            $PercentCompleteAuditNames += $ProgressDeltaAuditNames

            try {
                $forPermissions = get-mailboxFolderPermission -Identity $FolderName -ErrorAction Stop
            }
            catch {
                out-logfile -string "Unable to obtain folder permissions."
                out-logfile -string $_ -isError:$TRUE -isAudit:$TRUE
            }

            #Check the permissions found to see if they meet the criteria.

            $ProgressDeltaPermissions = 100/($forPermissions.count); $PercentCompletePermissions = 0; $permissionNumber = 0

            foreach ($permission in $forPermissions)
            {
                $forUser = $Permission.User.tostring()
                out-logfile -string ("Found User = "+$forUser)

                $forNumberr++

                Write-Progress -Activity "Processing permission" -Status $permission.identity -PercentComplete $PercentCompletePermissions -parentID 2 -id 3

                $PercentCompletePermissions += $ProgressDeltaPermissions

                #start-sleep -seconds 5 #Debug sleep to watch status bar.

                if (($forUser -ne "Default") -and ($foruser -ne "Anonymous") -and ($foruser -notLike "NT:S-1-5-21*"))
                {
                    out-logfile -string ("Not default or anonymous permission = "+$permission.user)

                    $forPermissionObject = New-Object PSObject -Property @{
                        identity = $permission.identity
                        folderName = $permission.folderName
                        user = $permission.user
                        accessRights = $permission.accessRights
                    }

                    out-logfile -string $forPermissionObject

                    $auditFolderPermissions+=$forPermissionObject

                    $auditPermissionsFound = 1
                }
            }

            write-progress -activity 'Processing permissions' -ParentId 2 -id 3 -Completed
        }

        write-progress "Processing folders" -ParentId 1 -id 2 -Completed

        #At this time write out the permissions.

        $fileName = $onPremMailboxFolderPermissions
        $exportFile=Join-path $logFolderPath $fileName

        $auditFolderPermissions | Export-Clixml -Path $exportFile
        
        $fileName = $onPremMailboxProcessed
        $exportFile=Join-path $logFolderPath $fileName

        $mailboxCounter | export-clixml -path $exportFile

        #Null out all the arrays for the next run except mailboxes.

        $auditFolderNames=@()
        $auditFolders=@()
    }
}