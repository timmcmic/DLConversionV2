function start-collectOffice365MailboxFolders
{
    <#
    .SYNOPSIS

    This function collects all of the mailbox permissions for folders in office 365 mailboxes.

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
        $bringMyOwnMailboxes=$NULL
    )

    $global:blogURL = "https://timmcmic.wordpress.com"

    $windowTitle = "Start-collectOffice365MailboxFolders"
    $host.ui.RawUI.WindowTitle = $windowTitle

    #Delare global variables.

    $global:logFile=$NULL #This is the global variable for the calculated log file name
    [string]$global:staticFolderName="\AuditData\"
    [array]$auditMailboxes=@()

    #Declare function variables.

    $auditMailboxes=$NULL
    $auditFolders=$NULL
    [array]$auditFolderNames=@()
    [array]$auditFolderPermissions=@()
    [int]$forCounter=0
    [int]$mailboxCounter=0
    [int]$totalMailboxes=0
    [string]$office365MailboxFolderPermissions="office365MailboxFolderPermissions.xml"
    [string]$office365MailboxList="office365MailboxListMailboxFolderPerms.xml"
    [string]$office365MailboxProcessed="office365MailboxProcessedMailboxFolderPerms.xml"
    [int]$auditPermissionsFound=0

    new-LogFile -groupSMTPAddress Office365MailboxFolderPermissions -logFolderPath $logFolderPath

    $traceFilePath = $logFolderPath + $global:staticFolderName

    out-logfile -string ("Trace file path: "+$traceFilePath)

    out-logfile -string "Output bound parameters..."

    #Output all parameters bound or unbound and their associated values.

    write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

    #Validate that only one method of engaging exchange online was specified.

    Out-LogFile -string "Validating Exchange Online Credentials."

    start-parameterValidation -exchangeOnlineCredential $exchangeOnlineCredential -exchangeOnlineCertificateThumbprint $exchangeOnlineCertificateThumbprint -threadCount 0

    #Validating that all portions for exchange certificate auth are present.

    out-logfile -string "Validating parameters for Exchange Online Certificate Authentication"

    start-parametervalidation -exchangeOnlineCertificateThumbPrint $exchangeOnlineCertificateThumbprint -exchangeOnlineOrganizationName $exchangeOnlineOrganizationName -exchangeOnlineAppID $exchangeOnlineAppID
    #Ensure bring your own mailboes not included with retry.

    if (($bringMyOwnMailboxes -ne $NULL)-and ($retryCollection -EQ $TRUE))
    {
        out-logfile -string "Cannot combine bring your own mailboxes with retry collection."
        out-logfile -string "If this is a retry after bringing your own mailbox - specify just retry." -isError:$TRUE -isAudit:$true
    }

    #Start the connection to Exchange Online.

    if ($exchangeOnlineCredential -ne $NULL)
    {
       #User specified non-certifate authentication credentials.

       try {
        New-ExchangeOnlinePowershellSession -exchangeOnlineCredentials $exchangeOnlineCredential -exchangeOnlineEnvironmentName $exchangeOnlineEnvironmentName -debugLogPath $traceFilePath -isAudit:$TRUE
       }
       catch {
           out-logfile -string "Unable to create the exchange online connection using credentials."
           out-logfile -string $_ -isError:$TRUE
       }
       

    }
    elseif ($exchangeOnlineCertificateThumbPrint -ne "")
    {
       #User specified thumbprint authentication.

       try {
        new-ExchangeOnlinePowershellSession -exchangeOnlineCertificateThumbPrint $exchangeOnlineCertificateThumbPrint -exchangeOnlineAppId $exchangeOnlineAppID -exchangeOnlineOrganizationName $exchangeOnlineOrganizationName -exchangeOnlineEnvironmentName $exchangeOnlineEnvironmentName -debugLogPath $traceFilePath -isAudit:$TRUE
       }
       catch {
        out-logfile -string "Unable to create the exchange online connection using certificate."
        out-logfile -string $_ -isError:$TRUE -isAudit:$true
       }

    }

    #Define the log file path one time.

    $logFolderPath = $logFolderPath+$global:staticFolderName

    try 
    {
        if ($retryCollection -eq $FALSE)
        {
            if ($bringMyOwnMailboxes -eq $NULL)
            {
                out-logFile -string "Obtaining all office 365 mailboxes."

                #$auditMailboxes = get-exomailbox -resultsize unlimited | select-object identity,primarySMTPAddress,userPrincipalName
                $auditMailboxes = get-o365mailbox -resultsize unlimited | select-object identity,primarySMTPAddress,userPrincipalName,externalDirectoryObjectID

                #Exporting mailbox operations to csv - the goal here will be to allow retry.

                $fileName = $office365MailboxList
                $exportFile=Join-path $logFolderPath $fileName
            
                $auditMailboxes | export-clixml -path $exportFile
            }
            else 
            {
                out-logfile -string "Using the mailboxes that the administrator provided."
                out-logfile -string "Following the same logic as our get so that the retry file aligns if necessary."

                foreach ($auditMailbox in $bringMyOwnMailboxes)
                {
                    out-logfile -string ("Processing mailbox: "+$auditMailbox)
                    #$auditMailboxes += get-exomailbox -identity $auditMailbox | select-object identity,primarySMTPAddress,userPrincipalName
                    $auditMailboxes += get-o365mailbox -identity $auditMailbox | select-object identity,primarySMTPAddress,userPrincipalName,externalDirectoryObjectID
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
                $fileName = $office365MailboxProcessed
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

                $fileName=$office365MailboxFolderPermissions
                $importFile=Join-path $logFolderPath $fileName

                out-logfile -string $fileName
                out-logfile -string $importFile
    
                $auditFolderPermissions = import-clixml -Path $importFile -ErrorAction Stop
            }
            catch {
                out-logfile -string $_
                out-logfile -string "Unable to import the previously exported permissions." -isError:$TRUE -isAudit:$TRUE
            }
        }
    }
    catch 
    {
        out-logFile -string "Unable to get mailboxes."
        out-logfile -string $_ -isError:$TRUE -isAudit:$true
    }

    #Ensure the count of mailboxes is greater than zero before proceeding.

    if ($auditMailboxes.count -gt 0)
    {
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
                start-sleepProgress -sleepString "Throttling for 5 seconds at 500 operations." -sleepSeconds 5

                $forCounter=0
            }
            else 
            {
                $forCounter++    
            }

            out-logfile -string ("Processing mailbox = "+$mailbox.primarySMTPAddress)
            out-logfile -string ("Processing mailbox number: "+($mailboxCounter+1).toString())

            $MbxNumber++

            $progressString = "Mailbox Name: "+$mailbox.primarySMTPAddress+"_"+$mailbox.externalDirectoryObjectID+" Mailbox Number: "+($mailboxCounter+1)+" of "+$totalMailboxes

            Write-Progress -Activity "Processing mailbox" -Status $progressString -PercentComplete $PercentComplete -Id 1

            $PercentComplete += $ProgressDelta

            $stopLoop = $FALSE
            [int]$loopCounter = 0

            do {
                try 
                {
                    out-logfile -string "Pulling mailbox folder statistics."
    
                    #$auditFolders=get-exomailboxFolderStatistics -identity $mailbox.identity -UserPrincipalName $mailbox.userPrincipalName -errorAction STOP | where {$_.FolderType -eq "User Created" -or $_.FolderType -eq "Inbox" -or $_.FolderType -eq "SentItems" -or $_.FolderType -eq "Contacts" -or $_.FolderType -eq "Calendar"} 
                    $auditFolders=get-o365mailboxFolderStatistics -identity $mailbox.externalDirectoryObjectID -errorAction STOP | where {$_.FolderType -eq "User Created" -or $_.FolderType -eq "Inbox" -or $_.FolderType -eq "SentItems" -or $_.FolderType -eq "Contacts" -or $_.FolderType -eq "Calendar"} 
    
                    out-logfile -string "Mailbox folder statistics obtained."

                    $stopLoop = $TRUE
                }
                catch [System.Exception]
                {
                    if ($loopCounter -gt 4)
                    {
                        out-logfile -string "Error obtaining mailbox folder statistics."
                        out-logfile -string "Collection operation will need to be retried - STOP failure."
                        out-logfile -string $_ -isError:$TRUE -isAudit:$true
                    }                     
                    else 
                    {
                        out-logfile -string "Error on attempt to gather folder statistics.  -  trying again..."
                        $loopcounter = $loopCounter+1
                    }     
                }
                catch
                {
                    if ($loopCounter -gt 4)
                    {
                        out-logfile -string "Error obtaining mailbox folder statistics."
                        out-logfile -string "Collection operation will need to be retried - STOP failure."
                        out-logfile -string $_ -isError:$TRUE -isAudit:$true
                    }                    
                    else 
                    {
                        out-logfile -string "Error on attempt to gather folder statistics.  -  trying again..."
                        $loopcounter = $loopCounter+1
                    }     
                }
            } while ($stopLoop -eq $FALSE)

            if ($auditFolders.count -gt 0)
            {
                #Audit folders have been obtained.
                #For each folder - normalize the folder names.

                $ProgressDeltaFolders = 100/($auditFolders.count); $PercentCompleteFolders = 0; $FolderNumber = 0

                foreach ($folder in $auditFolders)
                {
                    out-logFile -string ("Processing folder name ="+$folder.Identity)
                    out-logfile -string ("Processing folder = "+$folder.FolderId)
                    out-logfile -string ("Processing content mailbox guid = "+$folder.ContentMailboxGuid)
            
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
                        start-sleepProgress -sleepString "Throttling for 5 seconds at 1000 operations." -sleepSeconds 5 -sleepParentID 1 -sleepID 2

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

                    $stopLoop=$FALSE
                    [int]$loopCounter=0

                    do {
                        try {
                            out-logfile -string "Obtaining folder permissions..."
                            #$forPermissions = Get-exomailboxFolderPermission -Identity $FolderName -UserPrincipalName $mailbox.userPrincipalName  -ErrorAction Stop
                            $forPermissions = Get-o365mailboxFolderPermission -Identity $FolderName -ErrorAction Stop
                            out-logfile -string "Folder permissions obtained..."

                            $stopLoop=$TRUE
                        }
                        catch {
                            if ($loopCounter -gt 4)
                            {
                                out-logfile -string "Unable to obtain folder permissions."
                                out-logfile -string "This is a hard stop error - retry collection."
                                out-logfile -string $_ -isError:$TRUE -isAudit:$true
                            }
                            else 
                            {
                                out-logfile -string "Issues obtaining folder permissions - retry."
                                $loopCounter = $loopCounter+1    
                            }
                        }
                    } while ($stopLoop -eq $FALSE)

                    if ($forPermissions.count -gt 0)
                    {
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
                                    sharingpermissionflags = $permission.SharingPermissionFlags
                                }

                                out-logfile -string $forPermissionObject

                                $auditFolderPermissions+=$forPermissionObject

                                $auditPermissionsFound = 1
                            }
                        }

                        write-progress -activity 'Processing permissions' -ParentId 2 -id 3 -Completed
                    }
                    else 
                    {
                        out-logfile -string "There were no permissions to process."    
                    }
                }

                write-progress "Processing folders" -ParentId 1 -id 2 -Completed

                #At this time write out the permissions.

                $fileName = $office365MailboxFolderPermissions
                $exportFile=Join-path $logFolderPath $fileName

                if ($auditFolderPermissions.count -gt 0)
                {
                    $auditFolderPermissions | Export-Clixml -Path $exportFile
                }
                else 
                {
                    out-logfile -string "No permissions to write to file."    
                }
                
                $fileName = $office365MailboxProcessed
                $exportFile=Join-path $logFolderPath $fileName

                $mailboxCounter | export-clixml -path $exportFile

                #Null out all the arrays for the next run except mailboxes.

                $auditFolderNames=@()
                $auditFolders=@()
            }
            else 
            {
                out-logfile -string "There were no audit folders to process."
            }
        }
    }
    else 
    {
        out-logfile -string "There were no mailboxes to process."
    }

    write-shamelessPlug

    disable-allPowerShellSessions
}