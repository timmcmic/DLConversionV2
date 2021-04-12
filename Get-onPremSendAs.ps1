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
        $functionQueryName="*"+$originalDLConfiguration.samAccountName+"*"

        #Start function processing.

        $functionSendAsRights = invoke-command {get-recipient -resultsize unlimited | Get-ADPermission | Where-Object {($_.ExtendedRights -like "*send-as*") -and -not ($_.User -like "nt authority\self") -and ($_.isInherited -eq $false) -and $_.user -like $functionQueryName}}

        out-logfile -string $functionSendAsRights

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN Get-onPremSendAs"
        Out-LogFile -string "********************************************************************************"
    }