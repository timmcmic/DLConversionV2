<#
    .SYNOPSIS

    This function utilizes exchange on premises and searches for all send as rights across all recipients.

    .DESCRIPTION

    This function utilizes exchange on premises and searches for all send as rights across all recipients.

    .PARAMETER originalDLConfiguration

    The mail attribute of the group to search.

    .OUTPUTS

    Returns a list of all objects with send-As rights and exports them.

    .EXAMPLE

    get-o365dlconfiguration -groupSMTPAddress Address

    #>
    Function Get-onPremSendAs
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$originalDLConfiguration
        )

        #Declare function variables.

        $functionSendAsRights=$NULL
        $functionRecipients=$NULL
        $functionQueryName="*"+$originalDLConfiguration.samAccountName+"*"

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN Get-onPremSendAs"
        Out-LogFile -string "********************************************************************************"

        out-logfile -string ("DL query name = "+$functionDLQueryName)

        #Start function processing.

        out-logfile -string "Gathering all on premises recipients."

        $functionRecipients = invoke-command {get-recipient -resultsize unlimited}

        out-logfile -string "Test for send as rights."

        foreach ($recipient in $functionRecipients)
        {
            write-host ("Processing recipient = "+$recipient.identity)
            $functionSendAsRights+= invoke-command {Get-ADPermission | Where-Object {($_.ExtendedRights -like "*send-as*") -and -not ($_.User -like "nt authority\self") -and ($_.isInherited -eq $false) -and $_.user -like $args} -ArgumentList $functionQueryName}
        }

        out-logfile -string $functionSendAsRights

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "END Get-onPremSendAs"
        Out-LogFile -string "********************************************************************************" 
    }