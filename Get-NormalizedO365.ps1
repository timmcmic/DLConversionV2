<#
    .SYNOPSIS

    This function is used to normalize the DN information of users on premises to SMTP addresses utilized in Office 365.

    .DESCRIPTION

    This function is used to normalize the DN information of users on premises to SMTP addresses utilized in Office 365.

    .PARAMETER GlobalCatalog

    The global catalog to make the query against.

    .PARAMETER DN

    The DN of the object to pass to normalize.

    .PARAMETER CN

    THe canonical name of an object to normalize.

    .PARAMETER adCredential

    The AD credential for global catalog connections.

    .PARAMETER originalGroupDN

    The DN of the original group on premises.

    .PARAMETER isMember

    Boolean if the object to be tested is a member.

    .OUTPUTS

    Selects the mail address of the user by DN and returns the mail address.

    .EXAMPLE

    get-normalizedDN -globalCatalog GC -DN DN -adCredential CRED -isMember FALSE

    #>
    Function Get-NormalizedO365
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $attributeToNormalize
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Funtion variables.

        $functionRecipient = $null
        $functionObject = $null
        $functionReturnArray = @()

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN GET-NormalizedO365"
        Out-LogFile -string "********************************************************************************"
        
        #Get the specific user using ad providers.

        out-logfile -string "Determine if attribute has values to convert."

        if ($attributeToNormalize.count -gt 0)
        {
            out-logfile -string "Attribute to convert has values."

            foreach ($member in $attributeToNormalize)
            {
                if ($member -ne "Organization Management")
                {
                    out-logfile -string ("Testing member: "+$member)

                    try {
                        out-logfile -string "Testing for recipient type."

                        $functionCommand = "get-o365Recipient -filter {name -eq `"$member`"} -errorAction STOP"

                        out-logfile -string ("Command to execute: "+$functionCommand)

                        $scriptBlock=[scriptBlock]::create($functionCommand)

                        $functionRecipient = invoke-command -scriptBlock $scriptBlock

                        if ($functionRecipient.count -eq 0)
                        {
                            out-logfile -string "No recipient was found - assume this is a user."

                            throw
                        }
                        else 
                        {
                            out-logfile -string "Valid recipient found."

                            $functionObject = New-Object PSObject -Property @{
                                DisplayName = $functionRecipient.displayName
                                PrimarySMTPAddressOrUPN = $functionRecipient.primarySMTPAddress
                                ExternalDirectoryObjectID = ("User_"+$functionRecipient.externalDirectoryObjectID)
                                RecipientType = $functionRecipient.recipientType
                                RecipientTypeDetails = $functionRecipient.RecipientTypeDetails
                                isError=$NULL
                                isErrorMessage=$null
                                isAmbiguous=$false
                            }

                            out-logfile -string $functionObject

                            $functionReturnArray += $functionObject
                        }
                        
                    }
                    catch {

                        out-logfile -string $_
                        out-logfile -string "Testing for recipient type failed - assume USER."

                        try {

                            out-logfile -string "Testing object for user type."

                            $functionRecipient = get-o365user -identity $member -errorAction STOP

                            if ($functionRecipient.count -eq 0)
                            {
                                out-logfile -string "Not good - the user could not be located."

                                throw
                            }
                            else
                            {
                                out-logfile -string "The user was located successfully capturing information."

                                $functionObject = New-Object PSObject -Property @{
                                    DisplayName = $object.DisplayName
                                    PrimarySMTPAddressOrUPN = $object.UserPrincipalName
                                    ExternalDirectoryObjectID = ("User_"+$object.externalDirectoryObjectID)
                                    RecipientType = $functionRecipient.recipientType
                                    RecipientTypeDetails = $functionRecipient.RecipientTypeDetails
                                    isError=$NULL
                                    isErrorMessage=$null
                                    isAmbiguous=$true
                                }

                                out-logfile -string $functionObject  

                                $functionReturnArray += $functionObject
                            }
                        }
                        catch {
                            out-logfile -string $_
                            out-logfile -string "A user or recipient in the group cannot be located." -isError:$TRUE
                        }
                    }
                }
                else {
                    out-logfile -string "Member is the organization management built in role group - skip."
                }
            }
        }
        else 
        {
            out-logfile -string "No values to normalize were provided."
            $functionReturnArray = @()
        }

        Out-LogFile -string "END GET-NormalizedO365"
        Out-LogFile -string "********************************************************************************"
        
        return $functionReturnArray
    }