#All credits to author - link below.  Code modified by publisher.
#https://millerb.co.uk/2019/07/16/Get-DistinguishedName-From-CanonicalName.html


function  Get-DistinguishedName {
    param (
        [Parameter(Mandatory)]
        [string]$CanonicalName
    )

    [string]$returnDN = ""

    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "BEGIN GET-DistinguishedName"
    Out-LogFile -string "********************************************************************************"

    out-logfile -string ("Canonical name to convert: "+$CanonicalName)

    foreach ($cn in $CanonicalName) 
    {
        $arr = $cn -split '/'
        [array]::reverse($arr)
        $output = @()
        $output += $arr[0] -replace '^.*$', 'CN=$0'
        $output += ($arr | select -Skip 1 | select -SkipLast 1) -replace '^.*$', 'OU=$0'
        $output += ($arr | ? { $_ -like '*.*' }) -split '\.' -replace '^.*$', 'DC=$0'
        $returnDN = $output -join ','
    }

    out-logfile -string ("Converted canonical name: "+$returnDN)
    
    Out-LogFile -string "********************************************************************************"
    Out-LogFile -string "END Get-DistinguishedName"
    Out-LogFile -string "********************************************************************************"

    return $returnDN   
}