<#
    .SYNOPSIS

    This function gets the original DL configuration for the on premises group using AD providers.

    .DESCRIPTION

    This function gets the original DL configuration for the on premises group using AD providers.

    .PARAMETER PowershellSessionName

    The name associated with the powershell session to the ad server to invoke the get command.

    .PARAMETER GroupSMTPAddress

    The mail attribute of the group to search.

    .OUTPUTS

    Returns the DL configuration from the LDAP / AD call to the calling function.

    .EXAMPLE

    get-originalDLConfiguration -powershellsessionname NAME -groupSMTPAddress Address

    #>
    Function Get-OriginalDLConfiguration
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$powershellSessionName,
            [Parameter(Mandatory = $true)]
            [string]$groupSMTPAddress
        )

        #Declare function variables.

        $functionPSSession=$NULL #Holds the PS session to perform the work.
        $functionDLConfiguration=$NULL #Holds the return information for the group query.

        #Start function processing.

        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************************************************************************"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "BEGIN GET-ORIGINALDLCONFIGURATION"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************************************************************************"

        #Log the parameters and variables for the function.

        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string ("GroupSMTPAddress = "+$groupSMTPAddress)
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string ("PowershellSessionName = "+$PowershellSessionName)

        #Get the named PS session for the domain controller.

        try 
        {
            Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "Gathering powershell session for the domain controller." 
            $functionPSSession = Get-PSSession -Name $powershellSessionName -ErrorAction Stop
        }
        catch 
        {
            Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $_ -isError:$TRUE
        }

        #Get the group using LDAP / AD providers.
        
        try 
        {
            Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "Executing query to global catalog for original DL configuration." 

            $functionDLConfiguration=Invoke-Command -Session $functionPSSession -ScriptBlock {get-adgroup -filter "mail -eq '$args'" -properties * -errorAction STOP} -ArgumentList $groupSMTPAddress -ErrorAction Stop
        }
        catch 
        {
            Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $_ -isError:$TRUE
        }

        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "END GET-ORIGINALDLCONFIGURATION"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************************************************************************"
        
        #This function is designed to open local and remote powershell sessions.
        #If the session requires import - for example exchange - return the session for later work.
        #If not no return is required.
        
        return $functionDLConfiguration
    }