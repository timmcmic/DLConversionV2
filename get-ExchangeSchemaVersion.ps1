<#
    .SYNOPSIS

    This function gets the range upper for the exchange schema versions.

    .DESCRIPTION

    This function gets the range upper for the exchange schema versions.

    .OUTPUTS

    Returns the range upper of the Exchange schema versions.

    .EXAMPLE

    get-ExchangeSchemaVersion

    #>
    Function get-ExchangeSchemaVersion
     {

        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            [string]$globalCatalogServer,
            [Parameter(Mandatory = $true)]
            $adCredential
        )

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
            $functionSchemaNamingContext=Get-ADRootDSE -server $globalCatalogServer -credential $adCredential -errorAction STOP
            out-logfile -string "The AD Root Schema:"
            out-logfile -string $functionSchemaNamingContext
        }
        catch
        {
            out-logfile -string "Error getting PSSessions - hard abort since this is called in exit code."
        }

        $functionSchemaNamingContext=($functionADRootDSE).SchemaNamingContext

        out-logfile -string ("The functionSchemaNamingContext is :"+$functionSchemaNamingContext)

        $functionExchangeSchemaContext = "CN=ms-Exch-Schema-Version-Pt," + $functionSchemaNamingContext

        out-logfile -string ("The functionExchangeSchemaContext is: "+$functionExchangeSchemaContext)

        try{
            $functionExchangeSchemaObject = Get-AdObject $functionExchangeSchemaObject -server $globalCatalogServer -credential $adCredential -errorAction STOP
            out-logfile -string ("The Exchange Schema Object is: "+$functionExchangeSchemaObject)
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