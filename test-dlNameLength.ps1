<#
    .SYNOPSIS

    This function checks the prefix and suffix to ensure that character limit constraints are not exceeded.
    
    .DESCRIPTION

    This function checks the prefix and suffix to ensure that character limit constraints are not exceeded.

    .PARAMETER DLConfiguration

    The DL configuration from active directory.

    .PARAMETER Prefix

    The DL name prefix.

    .PARAMETER Suffix

    The DL name suffix.

    .OUTPUTS

    None

    .EXAMPLE

    test-CloudDLPresent -groupSMTPAddress SMTPAddress

    #>
    Function test-CloudDLPresent
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $dlConfiguration,
            [Parameter(Mandatory = $true)]
            [string]$prefix,
            [Parameter(Mandatory = $true)]
            [string]$suffix
        )

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        #Declare function variables.

        [int]$functionMaxNameLength = 64
        [string]$functionTestString = ""

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN TEST-dlNameLength"
        Out-LogFile -string "********************************************************************************"

        out-logfile -string ("Testing the DLName: "+$DLConfiguration.name)
        
        $functionTestString = $prefix + $dlConfiguration.Name

        out-logfile -string ("String with prefix: "+$functionTestString)

        $functionTestString = $functionTestString + $suffix

        out-logfile -string ("String with suffix: "+$functionTestString)

        if ($functionTestString.length -gt $functionMaxNameLength)
        {
            out-logfile -string "The max character length of 64 is exceeded."
            out-logfile -string "Record and error and fail."

            $functionObject = New-Object PSObject -Property @{
                Alias = ""
                Name = $dlConfiguration.Name
                PrimarySMTPAddressOrUPN = ""
                GUID = ""
                RecipientType = ""
                ExchangeRecipientTypeDetails = ""
                ExchangeRecipientDisplayType = ""
                ExchangeRemoteRecipientType = ""
                GroupType = ""
                RecipientOrUser = ""
                ExternalDirectoryObjectID = ""
                OnPremADAttribute = ""
                DN = ""
                ParentGroupSMTPAddress = ""
                isAlreadyMigrated = $false
                isError=$TRUE
                isErrorMessage="NAME_LENGTH_EXCEPTION: The DL Name plus the prefix and / or suffix exceeds 64 characters.  To complete migration wih the prefix and / or suffix the group name must be shortened to prefix + name + suffix to less than 64 characters."
            }

            $global:preCreateErrors+=$functionObject
        }
        else 
        {
            out-logfile -string "Name with prefix and suffix is less than 64 characters - proceed with migration."
        }


        Out-LogFile -string "END TEST-dlNameLength"
        Out-LogFile -string "********************************************************************************"
    }