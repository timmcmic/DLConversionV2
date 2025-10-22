<#
    .SYNOPSIS

    This function gets the range upper for the exchange schema versions.

    .DESCRIPTION

    This function gets the range upper for the exchange schema versions.

    .OUTPUTS

    Returns the range upper of the Exchange schema versions.

    .EXAMPLE

    get-ExchangeSchemaVersion -globalCatalogServer $GC -adCredential $cred

    #>
    Function get-ExchangeSchemaVersion
     {

        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$globalCatalogServer,
            [Parameter(Mandatory = $true)]
            $adCredential,
            [Parameter(Mandatory = $false)]
            [ValidateSet("Basic","Negotiate")]
            $activeDirectoryAuthenticationMethod="Negotiate"
        )

        out-logfile -string "Output bound parameters..."

        #Output all parameters bound or unbound and their associated values.

        write-functionParameters -keyArray $MyInvocation.MyCommand.Parameters.Keys -parameterArray $PSBoundParameters -variableArray (Get-Variable -Scope Local -ErrorAction Ignore)

        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN get-exchangeSchemaVersion"
        Out-LogFile -string "********************************************************************************"

        out-logfile "Getting the exchange schema version to determine what property set will be cleared during disablment."

        $functionADRootDSE = $null
        $functionExchangeSchemaVersion = $null  #Exchange schema version detected from AD.
        $functionSchemaNamingContext=$null  #AD Schema context.
        $functionExchangeSchemaContext = $null  #Calculated exchange schema location.
        $functionExchangeSchemaObject= $null
        $functionExchangeRangeUpper = $null

        try{
            $functionADRootDSE=Get-ADRootDSE -server $globalCatalogServer -credential $adCredential -authType $activeDirectoryAuthenticationMethod -errorAction STOP
            out-logfile -string "The AD Root Schema:"
            out-logfile -string $functionADRootDSE
        }
        catch
        {
            out-logfile -string $_
            out-logfile -string "Unable to get AD Root DSE." -isError:$TRUE
        }

        $functionSchemaNamingContext=($functionADRootDSE).SchemaNamingContext

        out-logfile -string ("The functionSchemaNamingContext is :"+$functionSchemaNamingContext)

        $functionExchangeSchemaContext = "CN=ms-Exch-Schema-Version-Pt," + $functionSchemaNamingContext

        out-logfile -string ("The functionExchangeSchemaContext is: "+$functionExchangeSchemaContext)

        try{
            $functionExchangeSchemaObject = Get-AdObject $functionExchangeSchemaContext -server $globalCatalogServer -credential $adCredential -authType $activeDirectoryAuthenticationMethod -properties * -errorAction STOP 
            out-logfile -string ("The Exchange Schema Object is: ")
            out-logfile -string $functionExchangeSchemaObject
        }
        catch{
            out-logfile -string ("Unable to retrieve the Exchange Schema object.")
        }
      
        $functionExchangeRangeUpper = $functionExchangeSchemaObject.rangeUpper

        out-logfile -string ("The range upper of the Exchange Schema: "+$functionExchangeRangeUpper)

        Out-LogFile -string "END get-exchangeSchemaVersion"
        Out-LogFile -string "********************************************************************************"

        return $functionExchangeRangeUpper
    }