#This function opens the current quick start guide for the version of DL Conversion V2 loaded.

function show-QuickStartGuide
{
    #First - determine where the module is installed.

    $moduleName = "DLConversionV2"
    $ModulePSD1 = "DLConversionV2.psd1"
    $quickStartName = "QuickStartGuide.txt"

    write-host ("Module Name: "+$moduleName)

    $availableModules=@()

    $availableModules += get-module $moduleName -listAvailable | sort-object Version -Descending

    foreach ($module in $availableModules)
    {
        write-host ("Module Version: "+$module.version + " Module Path: "+$module.path )
    }

    $modulePath = $availableModules[0].path

    write-host $modulePath

    $quickStartPath = $modulePath.replace($modulePSD1,$quickStartName)

    write-host $quickStartPath

    Invoke-Item $quickStartPath
}