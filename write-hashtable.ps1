<#
    .SYNOPSIS

    This function writes the hash table to the log file.

    .DESCRIPTION

    This function writes the hash table to the log file.

    #>
    Function write-hashTable
    {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $hashTable
        )

        Out-LogFile -string "********************************************************************************"
    
        foreach ($key in $hastable)
        {
            out-logfile -string ("Key: "+$key.name+" is "+$key.Value.Description+" with value "+$key.Value.Value)
        }      

        Out-LogFile -string "********************************************************************************"
    }