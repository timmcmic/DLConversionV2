<#
    .SYNOPSIS

    This function tests if the recipient is found in Office 365.

    .DESCRIPTION

    This function tests to ensure a recipient is found in Office 365.

    .PARAMETER recipientSMTPAddress

    The address of the recipient to look for.

    .PARAMETER externalDirectoryObjectID

    The external directory objectID of the object.

    .OUTPUTS

    None

    .EXAMPLE

    test-O365Recipient -recipientSMTPAddress address
    test-O365Recipient -externalDirectoryObjectID

    #>
    Function Test-O365Recipient
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $false)]
            [string]$recipientSMTPAddress=$NULL,
            [Parameter(Mandatory = $false)]
            [string]$externalDirectoryObjectID=$NULL,
            [Parameter(Mandatory = $false)]
            [string]$userPrincipalName=$NULL
        )

        #Declare local variables.

        [array]$functionDirectoryObjectID = $NULL
        $functionTest=$NULL

        #Start function processing.

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN TEST-O365RECIPIENT"
        Out-LogFile -string "********************************************************************************"

        #Log the parameters and variables for the function.

        if ($externalDirectoryObjectID -ne $NULL)
        {
            out-logfile -string ("External directory object id to test = "+$externalDirectoryObjectID)

            #Modify the external directory object id.

            $functionDirectoryObjectID=$externalDirectoryObjectID.Split("_")

            out-logfile -string ("Modified external directory object id to test ="+$functionDirectoryObjectID[1])
        }
        else 
        {
            out-logfile -string "Function called without parameter - failure." -isError:$TRUE    
        }
        
        #Get the recipient using the exchange online powershell session.
        
        try 
        {
            if ($recipientSMTPAddress -ne $NULL)
            {
                Out-LogFile -string "Testing for recipient by SMTP Address"

                #get-exorecipient -identity $recipientSMTPAddress -errorAction STOP
            }
            elseif ($externalDirectoryObjectID -ne $NULL)
            {
                Out-LogFile -string "Function received external directory object ID to test."

                $functionTest=get-o365Recipient -identity $functionDirectoryObjectID[1] -errorAction STOP

                out-logfile -string $functionTest
            }
            elseif ($userPrincipalName -ne $NULL)
            {
                Out-LogFile -string "Testing for user by user principal name."

                get-o365User -identity $userPrincipalName -errorAction STOP
            }
        }
        catch 
        {
            Out-LogFile -string $_ -isError:$TRUE
        }

        Out-LogFile -string "END TEST-O365RECIPIENT"
        Out-LogFile -string "********************************************************************************"    
    }