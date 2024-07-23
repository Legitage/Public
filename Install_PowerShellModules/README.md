# Install_PowerShellModules

Automates installation of PSGallery PowerShell modules specified in JSON file

## Description

Automatically elevates the PowerShell script and installs JSON specified PowerShell modules with the latest version.
Includes upgrade from Pester v3 to Pester v5.
Installs latest version of PowerShell 7

## Getting Started

Copy the Install_PowerShellModules folder to install location.

### Dependencies

- User account with Administrative privileges on the local workstation
- Install_PowerShellModules.psm1 PowerShell module
- PowerShellModulesList JSON file

### Configurable information in PowerShellModulesList.json

- List of PowerShell modules to install
- Option to upgrade Pester module
- Option to install/update PowerShell 7

## Logic Flow


## Version History

- Change history located in DEOS_M365_UG_Creation.psd1

```PowerShell
(Import-PowerShellDataFile .\DEOS_M365_UG_Creation.psd1).PrivateData.PSData.ReleaseNotes
```
  