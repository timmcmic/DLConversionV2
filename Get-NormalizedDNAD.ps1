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
    Function Get-NormalizedDNAD
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$globalCatalogServer,
            [Parameter(Mandatory = $true)]
            [string]$groupSMTPAddress,
            [Parameter(Mandatory = $true)]
            [string]$DN,
            [Parameter(Mandatory = $true)]
            [string]$CN,
            [Parameter(Mandatory = $TRUE)]
            $adCredential,
            [Parameter(Mandatory = $false)]
            [ValidateSet("Basic","Negotiate")]
            $activeDirectoryAuthenticationMethod="Negotiate",
            [Parameter(Mandatory = $TRUE)]
            [string]$originalGroupDN,
            [Parameter(Mandatory = $false)]
            [boolean]$isMember=$FALSE,
            [Parameter(Mandatory = $true)]
            [string]$activeDirectoryAttribute,
            [Parameter(Mandatory = $true)]
            [string]$activeDirectoryAttributeCommon
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Declare function variables.

        $functionTest=$NULL #Holds the return information for the group query.
        $functionObject=$NULL #This is used to hold the object that will be returned.
        [string]$functionSMTPAddress=$NULL
        $functionDN=$NULL

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN GET-NormalizedDNAD"
        Out-LogFile -string "********************************************************************************"
        
        #Get the specific user using ad providers.

        $stopLoop = $FALSE
        [int]$loopCounter = 0
        $activeDirectoryDomainName =""

        do {
            try 
            {
                Out-LogFile -string "Attempting to find the AD object associated with the member."

                if ($DN -ne "None")
                {
                    try
                    {
                        out-logfile -string "Obtaining the active directory domain for this operation."
                        $activeDirectoryDomainName=get-activeDirectoryDomainName -dn $DN -errorAction STOP
                        out-logfile -string ("Active Directory Domain Calculated: "+$activeDirectoryDomainName)
                    }
                    catch
                    {
                        out-logfile $_
                        out-logfile "Unable to calculate the active directory domain name via DN." -isError:$TRUE
                    }

                    out-logfile -string "Attempting to find the user via distinguished name."

                    $functionTest = get-adObject -filter {distinguishedname -eq $dn} -properties * -credential $adCredential -authType $activeDirectoryAuthenticationMethod -errorAction STOP -server $activeDirectoryDomainName
    
                    if ($functionTest -eq $NULL)
                    {
                        throw "The array member cannot be found by DN in Active Directory."
                    }
    
                    Out-LogFile -string "The array member was found by DN."
                }
                else
                {
                    out-logfile -string "Attempting to find member by canonical name converted to distinguished name." 

                    #Canonical name is a calculated value - need to tranlate to DN and then search directory.

                    try
                    {
                        $DN = get-distinguishedName -canonicalName $CN -errorAction STOP
                    }
                    catch
                    {
                        out-logfile -string "Unable to obtain the DN from canonical name." -isError:$TRUE
                    }

                    try
                    {
                        out-logfile -string "Obtaining the active directory domain for this operation."
                        $activeDirectoryDomainName=get-activeDirectoryDomainName -dn $DN -errorAction STOP
                        out-logfile -string ("Active Directory Domain Calculated: "+$activeDirectoryDomainName)
                    }
                    catch
                    {
                        out-logfile $_
                        out-logfile "Unable to calculate the active directory domain name via DN." -isError:$TRUE
                    }

                    $functionTest = get-adObject -filter {distinguishedname -eq $dn} -properties * -credential $adCredential -authType $activeDirectoryAuthenticationMethod -errorAction STOP -server $activeDirectoryDomainName
    
                    if ($functionTest -eq $NULL)
                    {
                        throw "The array member cannot be found by DN in Active Directory."
                    }
    
                    Out-LogFile -string "The array member was found by DN."
                }

                $stopLoop=$TRUE
            }
            catch 
            {
                if ($loopCounter -gt 4)
                {
                    Out-LogFile -string $_ -isError:$TRUE
                }
                else 
                {
                    out-logfile -string "Error getting AD object.  Sleep and try again."
                    $loopcounter = $loopCounter+1
                    start-sleepProgress -sleepString "Sleeping for 5 seconds get-adobjectError" -sleepSeconds 5
                }
            }
        } until ($stopLoop -eq $TRUE)
        
        
        $functionObject = New-Object PSObject -Property @{
            Alias = $functionTest.mailNickName
            Name = $functionTest.CN
            DisplayName = $functionTest.displayName
            PrimarySMTPAddress = $functionTest.mail
            UserPrincipalName = $functionTest.userPrincipalName
            GUID = $functionTest.objectGUID
            RecipientType = $functionTest.objectClass
            GroupType = $functionTest.groupType
            ExternalDirectoryObjectID = $functionTest.'msDS-ExternalDirectoryObjectId'
            ObjectSID = $functionTest.ObjectSID.value
            OnPremADAttribute = $activeDirectoryAttribute
            OnPremADAttributeCommonName = $activeDirectoryAttributeCommon
            DN = $DN
            ParentGroupSMTPAddress = $groupSMTPAddress
        }
        
        out-logfile -string $functionObject
        
        Out-LogFile -string "END GET-NormalizedDNAD"
        Out-LogFile -string "********************************************************************************"
        
        #This function is designed to open local and remote powershell sessions.
        #If the session requires import - for example exchange - return the session for later work.
        #If not no return is required.
        
        return $functionObject
    }