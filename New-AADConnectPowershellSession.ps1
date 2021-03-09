<#
    .SYNOPSIS

    This function creates a powershell session to the ad connect server to run delta syncs.

    .DESCRIPTION

    This function creates a powershell session to the ad connect server to run delta syncs.

    .PARAMETER aadConnectCredential

    This is the credential that will be utilized to establish the connection to aad connect.

    .PARAMETER aadConnectServer

    This is the server that runs aad connect.

	.OUTPUTS

    Powershell session to use for aad connect commands.

    .EXAMPLE

    new-aadConectPowershellSession -aadConnectServer SERVER -aadConnectCredential Credential

    #>
    Function New-AADConnectPowershellSession
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [pscredential]$aadConnectCredentials,
            [Parameter(Mandatory = $true)]
            [string]$aadConnectServer,
            [Parameter(Mandatory = $true)]
            [string]$aadConnectPowershellSessionName
        )

        #Declare function variables.

        #Start function processing.

        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "BEGIN NEW-AADCNNECTPOWERSHELLSESSION"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************"

        #Log the parameters and variables for the function.

        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "AADConnectServer"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $aadConnectServer
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "AADConnectCredential"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $aadconnectcredentials.userName

           
        try 
        {
            Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "Creating the powershell to aadConnect." 
            New-PSSession -computername $aadConnectServer -credentials $aadconnectcredentials -name $aadConnectPowershellSessionName -errorAction STOP
        }
        catch 
        {
            Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $_ -isError:$TRUE
        }

        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "The aadConnect powershell session was created successfully."

        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "END NEW-AADCONNECTPOWERSHELLSESSION"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************"
    }