#
# Module manifest for module 'DLConversionV2'
#
# Generated by: timmcmic
#
# Generated on: 3/1/2021
#

@{

# Script module or binary module file associated with this manifest.
RootModule = '.\DLConversionV2.psm1'

# Version number of this module.
ModuleVersion = '2.3.97.13'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '2dd8852b-fe83-453d-abcd-e0b8e424c677'

# Author of this module
Author = 'timmcmic@microsoft.com'

# Company or vendor of this module
CompanyName = 'Microsoft CSS'

# Copyright statement for this module
Copyright = '(c) 2021 CSS Support. All rights reserved.'

# Description of the functionality provided by this module
Description = 'This module is use to facilitate DL migrations from on premsies to Office 365'

# Minimum version of the Windows PowerShell engine required by this module
# PowerShellVersion = ''

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
NestedModules = @('remove-stringspace.ps1','get-migrationSummary.ps1','start-MultipleMachineDistributionListMigration.ps1','Get-OULocation.ps1','Start-SleepProgress.ps1','Start-MultipleDistributionListMigration.ps1','Remove-statusFiles.ps1','get-StatusFileCount.ps1','out-statusFile.ps1','new-statusfile.ps1','get-ExchangeSchemaVersion.ps1','start-ReplaceOffice365Dynamic.ps1','set-OnPremDLPermissions.ps1','Get-O365DLMailboxFolderPermissions.ps1','get-onPremFolderPermissions.ps1','start-collectOffice365FullMailboxAccess.ps1','start-collectOnPremFullMailboxAccess.ps1','start-collectOnPremSendAs.ps1','start-collectOffice365MailboxFolders.ps1','start-collectOnPremMailboxFolders.ps1','set-Office365DLPermissions.ps1','Get-O365DLFullMaiboxAccess.ps1','Get-O365DLSendAs.ps1','Get-onPremFullMailboxAccess.ps1','Get-onPremSendAs.ps1','enable-ExchangeOnPremEntireForest.ps1','Get-GroupSendAsPermission.ps1','remove-onPremGroup.ps1','Start-ArchiveFiles.ps1','disable-allPowerShellSessions.ps1','start-upgradeToOffice365Group.ps1','Enable-MailDynamicGroup.ps1','Enable-MailRoutingContact.ps1','start-replaceOffice365Members.ps1','start-replaceOffice365Unified.ps1','start-replaceOffice365.ps1','start-ReplaceOnPremSV.ps1','start-replaceOnPrem.ps1','new-RoutingContact.ps1','Get-O365DLMembership.ps1','Set-Office365DLMV.ps1','Set-Office365DL.ps1','New-Office365DL.ps1','Test-CloudDLPresent.ps1','Move-toNonSyncOU.ps1','Set-NewDLName.ps1','Invoke-ADReplication.ps1','Invoke-ADConnect.ps1','Disable-OriginalDL.ps1','Get-O365GroupDependency.ps1','Test-O365Recipient.ps1','Get-CanonicalName.ps1','Get-NormalizedDN.ps1','Invoke-Office365SafetyCheck.ps1','Get-O365DLConfiguration.ps1','New-LogFile.ps1','Out-XMLFile.ps1','Get-ADObjectConfiguration.ps1','New-PowershellSession.ps1','Test-PowershellModule.ps1','Out-LogFile.ps1','Import-PowershellSession.ps1','New-ExchangeOnlinePowershellSession.ps1')

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @('start-MultipleMachineDistributionListMigration','Start-MultipleDistributionListMigration','start-collectOffice365FullMailboxAccess','start-collectOnPremFullMailboxAccess','start-collectOnPremSendAs','Start-DistributionListMigration','start-collectOnPremMailboxFolders','start-collectOffice365MailboxFolders')

# Cmdlets to export from th'is module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @("Exchange","Office365","AzureAD","AzureActiveDirectory","ExchangeOnline","DistributionList","DL","DLMigration","ExchangeOnline")

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/microsoft/DLConversionV2'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes ='
        2.0.0 Initial release of version 2.
        '

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

