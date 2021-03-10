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
    Function New-PowershellSession
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(ParameterSetName="NotOnline",Mandatory = $true)]
            [Parameter(ParameterSetName="Online",Mandatory = $true)]
            [pscredential]$Credentials,
            [Parameter(ParameterSetName="NotOnline",Mandatory = $true)]
            [string]$Server,
            [Parameter(ParameterSetName="NotOnline",Mandatory = $true)]
            [Parameter(ParameterSetName="Online",Mandatory = $true)]
            [string]$PowershellSessionName,
            [Parameter(ParameterSetName="Online",Mandatory = $true)]
            [string]$connectionURI,
            [Parameter(ParameterSetName="Online",Mandatory = $true)]
            [string]$authenticationType,
            [Parameter(ParameterSetName="Online",Mandatory = $true)]
            [string]$configurationName,
            [Parameter(ParameterSetName="Online")]
            [boolean]$allowRedirection=$FALSE,
            [Parameter(ParameterSetName="Online")]
            [boolean]$requiresImport=$FALSE
        )

        #Declare function variables.

        $sessionToImport=$NULL

        #Start function processing.

        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************************************************************************"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "BEGIN NEW-POWERSHELLSESSION"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************************************************************************"

        #Log the parameters and variables for the function.

        if ($server -ne "")
        {
            Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string ("Server = "+$Server)
        }
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string ("Credential = "+$Credentials.userName.tostring())
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string ("PowershellSessionName = "+$PowershellSessionName)

        if ($connectionURI -ne "")
        {
            Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string ("ConnectionURI = "+$connectionURI)
        }

        if ($authenticationType -ne "")
        {
            Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string ("AuthenticationType = "+$authenticationType)
        }

        if ($configurationName -ne "")
        {
            Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string ("ConfigurationName = "+$configurationName)
        }
    
        if ($allowRedirection -ne $FALSE)
        {
            Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string ("AllowRedirection = "+$allowRedirection)
        }
        
        if ($requiresImport -ne $FALSE)
        {
            Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string ("RequireImport = "+$requiresImport)
        }
        
        try 
        {
            if ($requiresImport -eq $FALSE)
            {
                #The session was flagged by the caller as requiring import.
                #This would usually be reserved for things like Exchange On Premises / Exchange Online

                Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "Creating the powershell to server." 
                New-PSSession -computername $Server -credential $Credentials -name $PowershellSessionName -errorAction STOP
            }
            elseif ($requiresImport -eq $TRUE)
            {
                #No import is required - this is a local powershell session

                Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "Creating the powershell to server that requires import." 
                $sessiontoimport=New-PSSession -ConfigurationName $configurationName -ConnectionUri $connectionURI -Credential $credentials -AllowRedirection:$allowRedirection -Authentication $authenticationType -name $PowershellSessionName
            }
        }
        catch 
        {
            Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $_ -isError:$TRUE
        }

        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "The powershell session was created successfully."

        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "END NEW-POWERSHELLSESSION"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "********************************************************************************"
    
        #This function is designed to open local and remote powershell sessions.
        #If the session requires import - for example exchange - return the session for later work.
        #If not no return is required.
        
        if ($requiresImport -eq $TRUE)
        {
            return ,$sessionToImport
        }  
    }