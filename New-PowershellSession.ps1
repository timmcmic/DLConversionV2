<#
    .SYNOPSIS

    This function creates a powershell session to an on premises server to invoke winRM commands.

    .DESCRIPTION

    This function creates a powershell session to an on premises server to invoke winRM commands.

    .PARAMETER Credential

    This is the credential that will be utilized to establish the connection

    .PARAMETER Server

    This is the server that the connection will be made to.

    .PARAMETER PowershellSessionName

    This is the name of the powershell session that will be created.

	.OUTPUTS

    Powershell session to use for aad connect commands.

    .EXAMPLE

    new-PowershellSession -Server SERVER -Credential Credential -PowershellSessionName Name

    #>
    Function New-AADConnectPowershellSession
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [pscredential]$Credentials,
            [Parameter(Mandatory = $true)]
            [string]$Server,
            [Parameter(Mandatory = $true)]
            [string]$PowershellSessionName
        )

        #Declare function variables.

        #Start function processing.

        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "****************************************"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "BEGIN NEW-POWERSHELLSESSION"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "****************************************"

        #Log the parameters and variables for the function.

        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "Server"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $Server
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "Credential"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $Credentials.userName
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "PowershellSessionName"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $PowershellSessionName

        try 
        {
            Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "Creating the powershell to server." 
            New-PSSession -computername $Server -credential $Credentials -name $PowershellSessionName -errorAction STOP
        }
        catch 
        {
            Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $_ -isError:$TRUE
        }

        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "The powershell session was created successfully."

        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "END NEW-POWERSHELLSESSION"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "****************************************"
    }