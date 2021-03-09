<#
    .SYNOPSIS

    This function tests to see if there are any powershell commands associated with the Exchange Online V2 module.

    .DESCRIPTION

    This function tests to see if there are any powershell commands associated with the Exchange Online V2 module.

    .EXAMPLE

    Test-ExchangeOnlinePowershell

    #>
    Function Test-ExchangeOnlinePowershell
     {
        [cmdletbinding()]

        #Define variables that will be utilzed in the function.

        [string]$exchangeOnlinePowershellModuleName="ExchangeOnlineManagement"
        [array]$exchangeOnlinePowershellCommands=$NULL

        #Initiate the test.
        
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "****************************************"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "BEGIN TEST-EXCHANGEONLINEPOWERSHELL"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "****************************************"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string " "
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string " "

        #Write function parameter information and variables to a log file.

        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "ExchangeOnlinePowershellModuleName"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $exchangeOnlinePowershellModuleName

        try 
        {
            $exchangeOnlinePowershellCommands = get-command -module $exchangeOnlinePowershellModuleName -errorAction STOP
        }
        catch 
        {
            Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string $_ -isError:$TRUE
        }

        if ($exchangeOnlinePowershellCommands.count -eq 0)
        {
            Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "The exchange online powershell module v2 was not found." -iserror:$TRUE
        }
        else
        {
            Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "The exchange online powershell module v2 was found.."
        }    

        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "END TEST-EXCHANGEONLINEPOWERSHELL"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string "****************************************"
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string " "
        Out-LogFile -groupSMTPAddress $groupSMTPAddress -logFolderPath $logFolderPath -string " "
    }