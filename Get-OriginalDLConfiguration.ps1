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

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN GET-ORIGINALDLCONFIGURATION"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        Out-LogFile -string ("PowershellSessionName = "+$powershellSessionName)
        Out-LogFile -string ("GroupSMTPAddress = "+$groupSMTPAddress)

        #Get the named PS session for the domain controller.

        try 
        {
            Out-LogFile -string "Getting the PS Session for command invocation."
            $functionPSSession = Get-PSSession -Name $powershellSessionName -ErrorAction Stop
        }
        catch 
        {
            out-logFile -string $_ -isError:$TRUE
        }

        #Get the group using LDAP / AD providers.
        
        try 
        {
            Out-LogFile -string "Using AD / LDAP provider to get original DL configuration"

            $functionDLConfiguration=Invoke-Command -Session $functionPSSession -ScriptBlock {get-adgroup -filter "mail -eq '$args'" -properties * -errorAction STOP} -ArgumentList $groupSMTPAddress -ErrorAction Stop

            Out-LogFile -string "Original DL configuration found and recorded."

            $fucntionDLConfiguration
        }
        catch 
        {
            Out-LogFile -string $_ -isError:$TRUE
        }

        Out-LogFile -string "END GET-ORIGINALDLCONFIGURATION"
        Out-LogFile -string "********************************************************************************"
        
        #This function is designed to open local and remote powershell sessions.
        #If the session requires import - for example exchange - return the session for later work.
        #If not no return is required.
        
        return $functionDLConfiguration
    }