<#
    .SYNOPSIS

    This function is used to normalize the DN information of users on premises to SMTP addresses utilized in Office 365.

    .DESCRIPTION

    This function is used to normalize the DN information of users on premises to SMTP addresses utilized in Office 365.

    .PARAMETER GlobalCatalog

    The global catalog to make the query against.

    .PARAMETER DN

    The DN of the object to pass to normalize.

    .OUTPUTS

    Selects the mail address of the user by DN and returns the mail address.

    .EXAMPLE

    get-normalizedDN -globalCatalog GC -DN DN

    #>
    Function Get-NormalizedDN
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$globalCatalogServer,
            [Parameter(Mandatory = $true)]
            [string]$DN,
            [Parameter(Mandatory = $TRUE)]
            $adCredential,
            [Parameter(Mandatory = $TRUE)]
            [string]$originalGroupDN,
            [Parameter(Mandatory = $false)]
            [boolean]$isMember=$FALSE

        )

        #Declare function variables.

        $functionTest=$NULL #Holds the return information for the group query.
        $functionObject=$NULL #This is used to hold the object that will be returned.
        [string]$functionSMTPAddress=$NULL

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN GET-NormalizedDN"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        Out-LogFile -string ("GlobalCatalogServer = "+$globalCatalogServer)
        OUt-LogFile -string ("DN Set = "+$DN)
        out-logfile -string ("Credential user name = "+$adCredential.UserName)
        out-logfile -string ("Original Group DN = "+$originalGroupDN)
        
        #Get the specific user using ad providers.
        
        try 
        {
            Out-LogFile -string "Attempting to find the AD object associated with the member."

            $functionTest = get-adObject -filter {distinguishedname -eq $dn} -properties * -credential $adCredential -errorAction STOP

            if ($functionTest -eq $NULL)
            {
                throw "The array member cannot be found by DN in Active Directory."
            }

            Out-LogFile -string "The array member was found by DN."
        }
        catch 
        {
            Out-LogFile -string $_ -isError:$TRUE
        }

        try
        {
            #In this iteraction of the script were changing how we track recipients - since we're using adsi.
            #First step check to see if the object has a recipient display type - that means it's mail enabled.
            #If the object is mail enabled - regardless of object type - look to see if the previous migration was done (group to contact conversion.)
            #If the group was not migrated or is not a group - take those attributes.
            #The next case is that we do allow contacts to have a mail attribute but not be a full recipient.  (The only wayt to get them into the group is to use ADUC to do it - but it happens.)
            #If the object has MAIL and is a CONTACT record information we can.  It can be migrated.
            #Otherwise we've found non-mail present object (user with mail attribute / bad user / bad group - end.)

            #Check to see if the recipient has a recipient display type and is a user, or is a contact.

            Out-LogFile -string "Interpreting DN evaluation..."

            if ($functiontest.msExchRecipientDisplayType -eq "3")
            {
                out-logfile -string "A dynamic distribution group was found."
                out-logfile -string "This could be either member or permission."
                out-logfile -string "It will be included as an object but failure will occur if not already provisioned in Office 365."

                $functionObject = New-Object PSObject -Property @{
                    Alias = $functionTest.mailNickName
                    Name = $functionTest.Name
                    PrimarySMTPAddressOrUPN = $functionTest.mail
                    GUID = $NULL
                    RecipientType = $functionTest.objectClass
                    RecipientOrUser = "Recipient"
                    ExternalDirectoryObjectID = $null
                    isAlreadyMigrated = $false
                }
            }
            elseif (($functionTest.msExchRecipientDisplayType -ne $NULL) -and (($functionTest.objectClass -eq "User") -or ($functionTest.objectClass -eq "Contact")))
            {
                Out-LogFile -string "The object has a recipient display type and is a user or contact."

                #If the object has already been mirgated - then custom attribute 1 is migrated by script. 
                #Update the object to include the custom attribute not the object itself.

                if ($functionTest.extensionAttribute1 -eq "MigratedByScript")
                {
                    Out-LogFile -string "The object was previously migrated - using migrated information."

                    $functionObject = New-Object PSObject -Property @{
                        Alias = $functionTest.mailNickName
                        Name = $functionTest.Name
                        PrimarySMTPAddressOrUPN = $functionTest.extensionAttribute2
                        GUID = $NULL
                        RecipientType = $functionTest.objectClass
                        RecipientOrUser = "Recipient"
                        ExternalDirectoryObjectID = $functionTest.'msDS-ExternalDirectoryObjectId'
                        isAlreadyMigrated = $true
                    }
                }

                #If the object has not been migrated - then proceed with recording the original attributes.

                else 
                {
                    Out-LogFile -string "The object was not previously migrated - using directory information."
                    
                    $functionObject = New-Object PSObject -Property @{
                        Alias = $functionTest.mailNickName
                        Name = $functionTest.Name
                        PrimarySMTPAddressOrUPN = $functionTest.mail
                        GUID = $NULL
                        RecipientType = $functionTest.objectClass
                        RecipientOrUser = "Recipient"
                        ExternalDirectoryObjectID = $functionTest.'msDS-ExternalDirectoryObjectId'
                        isAlreadyMigrated = $false
                    }
                }
            }
            elseif (($functiontest.mail -ne $NULL) -and ($functiontest.msExchRecipientDisplayType -eq $NULL) -and ($functionTest.objectClass -eq "Contact"))
            {
                Out-LogFile -string "The object is a contact with a mail attribute - but is not fully exchange enabled."
                    
                    $functionObject = New-Object PSObject -Property @{
                        Alias = $NULL
                        Name = $functionTest.Name
                        PrimarySMTPAddressOrUPN = $functionTest.mail
                        GUID = $NULL
                        RecipientType = $functionTest.objectClass
                        RecipientOrUser = "Recipient"
                        ExternalDirectoryObjectID = $functionTest.'msDS-ExternalDirectoryObjectId'
                        isAlreadyMigrated = $false
                    }
            }
            elseif ($functionTest.objectClass -eq "User")
            {
                Out-LogFile -string "The object is a user only object hopefully in managedBY or USERS."
                    
                    $functionObject = New-Object PSObject -Property @{
                        Alias = $NULL
                        Name = $functionTest.Name
                        PrimarySMTPAddressOrUPN = $functionTest.userPrincipalName
                        GUID = $NULL
                        RecipientType = $functionTest.objectClass
                        ExternalDirectoryObjectID = $functionTest.'msDS-ExternalDirectoryObjectId'
                        RecipientOrUser = "User"
                }
            }
            elseif ($functionTest.objectClass -eq "Group")
            {
                out-logfile -string "The recipient is a group."
                #It is possible that the group has permissions to itself.

                if (($functionTest.distinguishedname -eq $originalGroupDN) -and ($isMember -eq $FALSE))
                {
                    out-logFile -string "The group has permissions to itself - this is permissable - adding to array."
                    #The group has permissions to itself and this is permissiable.

                    $functionObject = New-Object PSObject -Property @{
                        Alias = $functionTest.mailNickName
                        Name = $functionTest.Name
                        PrimarySMTPAddressOrUPN = $functionTest.mail
                        GUID = $NULL
                        RecipientType = $functionTest.objectClass
                        RecipientOrUser = "Recipient"
                        ExternalDirectoryObjectID = $functionTest.'msDS-ExternalDirectoryObjectId'
                        isAlreadyMigrated = $false
                    }
                }

                #A group can be present that was previously migrated and then disabled - if so allow the migration to proceed.
                #Otherwise the group was not previously migrated and would need to be cleaned up.

                elseif ($functionTest.extensionattribute1 -eq "MigratedByScript")
                {
                    out-logfile -string "A group was found as a member and that group was previously migrated."

                    $functionObject = New-Object PSObject -Property @{
                        Alias = $functionTest.mailNickName
                        Name = $functionTest.Name
                        PrimarySMTPAddressOrUPN = $functionTest.extensionAttribute2
                        GUID = $NULL
                        RecipientType = $functionTest.objectClass
                        RecipientOrUser = "Recipient"
                        ExternalDirectoryObjectID = $functionTest.'msDS-ExternalDirectoryObjectId'
                        isAlreadyMigrated = $true
                    }
                }
                
                elseif (($functionTest.msExchRecipientDisplayType -ne $NULL) -and ($isMember -eq $TRUE)) 
                {
                    #The group is mail enabled and a member.  All nested groups have to be migrated first.

                    out-logfile -string "A mail enabled group was found as a member of the DL or has permissions on the DL."
                    out-logfile -string $DN
                    out-logFile -string ("A mail enabled group is a member of the group to be migrated or has permission on the group to be migrated.  This group must first be migrated - "+$DN) -isError:$TRUE
                }
                elseif (($functionTest.msExchRecipientDisplayType -ne $NULL) -and ($isMember -eq $FALSE)) 
                {
                    #The group is a recipient and has permissions to an attribute.
                        
                    out-logfile -string "The group has permissions on the DL and this is permissiable."
                    out-logfile -string $dn

                    $functionObject = New-Object PSObject -Property @{
                        Alias = $functionTest.mailNickName
                        Name = $functionTest.Name
                        PrimarySMTPAddressOrUPN = $functionTest.mail
                        GUID = $NULL
                        RecipientType = $functionTest.objectClass
                        RecipientOrUser = "Recipient"
                        ExternalDirectoryObjectID = $functionTest.'msDS-ExternalDirectoryObjectId'
                        isAlreadyMigrated = $false
                    }
                }
                else 
                {
                    out-logfile -string ("The following object "+$dn+" is not mail enabled and must be removed or mail enabled to continue.") -isError:$TRUE
                }
            }
            else 
            {
                out-logfile -string ("The following object "+$dn+" is not mail enabled and must be removed or mail enabled to continue.") -isError:$TRUE
            }    
        }
        catch
        {
            Out-LogFile -string $_ -isError:$true  
        }

        Out-LogFile -string "END GET-NormalizedDN"
        Out-LogFile -string "********************************************************************************"
        
        #This function is designed to open local and remote powershell sessions.
        #If the session requires import - for example exchange - return the session for later work.
        #If not no return is required.
        
        return $functionObject
    }