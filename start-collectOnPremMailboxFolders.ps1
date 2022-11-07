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

    $windowTitle = "Start-collectOnPremMailboxFolders"
    $host.ui.RawUI.WindowTitle = $windowTitle

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
    [int]$auditPermissionsFound=0


    #Static variables utilized for the Exchange On-Premsies Powershell.

    $onPremExchangePowershell = @{
        exchangeServerConfiguration = @{"Value" = "Microsoft.Exchange" ; "Description" = "Defines the Exchange Remote Powershell configuration"} 
        exchangeServerAllowRedirection = @{"Value" = $TRUE ; "Description" = "Defines the Exchange Remote Powershell redirection preference"} 
        exchangeServerURI = @{"Value" = "https://"+$exchangeServer+"/powershell" ; "Description" = "Defines the Exchange Remote Powershell connection URL"} 
        exchangeServerURIKerberos = @{"Value" = "http://"+$exchangeServer+"/powershell" ; "Description" = "Defines the Exchange Remote Powershell connection URL"} 
        exchangeOnPremisesPowershellSessionName = @{ "Value" = "ExchangePowershell" ; "Description" = "Exchange On-Premises powershell session name."}
    }

    $xmlFiles = @{
        onPremMailboxFolderPermissions= @{"Value" = "onPremailboxFolderPermissions.xml" ; "Description" = "XML file to hold exported folder permissions"}
        onPremMailboxList= @{"Value" = "onPremMailboxListMailboxFolderPerms.xml" ; "Description" = "XML file to hold recipients to be processed"}
        onPremMailboxProcessed= @{"Value" = "onPremMailboxProcessedMailboxFolderPerms.xml" ;"Description" = "XML file to hold the last recipient processed"}
    }

    new-LogFile -groupSMTPAddress OnPremMailboxFolderPermissions -logFolderPath $logFolderPath

    #Output all parameters bound or unbound and their associated values.

    write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

    write-hashTable -hashTable $onPremExchangePowershell
    write-hashTable -hashTable $xmlFiles

    if (($bringMyOwnMailboxes -ne $NULL )-and ($retryCollection -eq $TRUE))
    {
        out-logfile -string "You cannot bring your own mailboxes when you are retrying the collection."
        out-logfile -string "If mailboxes were previously provided - rerun command with just retry collection." -iserror:$TRUE -isAudit:$TRUE
    }

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

                $fileName = $xmlFiles.onPremMailboxList.value
                $exportFile=Join-path $logFolderPath $fileName
                
                $auditMailboxes | export-clixml -path $exportFile
            }
            else 
            {
                out-logFile -string "Obtaining all on premises mailboxes."

                $auditMailboxes = $bringMyOwnMailboxes

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
                $fileName = $xmlFiles.onPremMailboxProcessed.value
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

                $fileName=$xmlFiles.onPremMailboxFolderPermissions.value
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

        if ($forCounter -gt 500)
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

        $progressString = "Mailbox Name: "+$mailbox.primarySMTPAddress+" Mailbox Number: "+$mailboxCounter+" of "+$totalMailboxes

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
            if ($forCounter -gt 500)
            {
                start-sleepProgress -sleepString "Sleeping for 5 seconds - powershell refresh." -sleepSeconds 5 -sleepParentID 1 -sleepID 2

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
                        sharingPermissionFlags = $permission.sharingPermissionFlags
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

        $fileName = $xmlFiles.onPremMailboxFolderPermissions.value
        $exportFile=Join-path $logFolderPath $fileName

        $auditFolderPermissions | Export-Clixml -Path $exportFile
        
        $fileName = $xmlFiles.onPremMailboxProcessed.value
        $exportFile=Join-path $logFolderPath $fileName

        $mailboxCounter | export-clixml -path $exportFile

        #Null out all the arrays for the next run except mailboxes.

        $auditFolderNames=@()
        $auditFolders=@()
    }

    disable-allPowerShellSessions
}